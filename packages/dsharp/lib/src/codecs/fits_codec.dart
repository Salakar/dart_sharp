import 'dart:convert';
import 'dart:typed_data';

import '../api/exceptions.dart';
import '../pixels/pixel_image.dart';
import '../source/input_options.dart';
import '../source/raw_pixels.dart';
import 'binary_io.dart';
import 'codec.dart';
import 'codec_pixels.dart';
import 'encoder_options.dart';
import 'image_format.dart';
import 'output.dart';

/// First-party FITS primary image codec.
final class FitsImageCodec implements ImageCodec {
  /// Creates a FITS codec.
  const FitsImageCodec();

  @override
  ImageFormat get format => ImageFormat.fits;

  @override
  PixelImage decode(Uint8List bytes) {
    final header = _readFitsHeader(bytes);
    const InputSafetyLimits().checkImage(
      width: header.width,
      height: header.height,
      frames: 1,
    );
    final planes = header.planes;
    final rgba = Uint8List(header.width * header.height * 4);
    final range = _sampleRange(header);
    for (var y = 0; y < header.height; y += 1) {
      for (var x = 0; x < header.width; x += 1) {
        final pixel = y * header.width + x;
        final output = pixel * 4;
        if (planes == 1) {
          final gray = _scaledFitsSample(bytes, header, pixel, range);
          rgba[output] = gray;
          rgba[output + 1] = gray;
          rgba[output + 2] = gray;
        } else {
          rgba[output] = _scaledFitsSample(bytes, header, pixel, range);
          rgba[output + 1] = _scaledFitsSample(
            bytes,
            header,
            pixel + header.width * header.height,
            range,
          );
          rgba[output + 2] = _scaledFitsSample(
            bytes,
            header,
            pixel + header.width * header.height * 2,
            range,
          );
          if (planes == 4) {
            rgba[output + 3] = _scaledFitsSample(
              bytes,
              header,
              pixel + header.width * header.height * 3,
              range,
            );
            continue;
          }
        }
        rgba[output + 3] = 255;
      }
    }
    return PixelImage.fromRawPixels(
      RawPixels(
        bytes: rgba,
        width: header.width,
        height: header.height,
        channels: ChannelCount.four,
      ),
    );
  }

  @override
  EncodedImage encode(PixelImage image, {EncoderOptions? options}) {
    final raw = image.firstFrame.pixels;
    final rgba = rawToRgba(raw);
    final writer = ByteWriter()
      ..writeBytes(_fitsCardBool('SIMPLE', true))
      ..writeBytes(_fitsCardInt('BITPIX', 8))
      ..writeBytes(_fitsCardInt('NAXIS', 2))
      ..writeBytes(_fitsCardInt('NAXIS1', raw.width))
      ..writeBytes(_fitsCardInt('NAXIS2', raw.height))
      ..writeBytes(_fitsEndCard());
    while (writer.length % 2880 != 0) {
      writer.writeByte(0x20);
    }
    for (var offset = 0; offset < rgba.length; offset += 4) {
      writer.writeByte(
        ((rgba[offset] * 299) +
                (rgba[offset + 1] * 587) +
                (rgba[offset + 2] * 114)) ~/
            1000,
      );
    }
    while (writer.length % 2880 != 0) {
      writer.writeByte(0);
    }
    final bytes = writer.toBytes();
    return EncodedImage(
      bytes: bytes,
      info: OutputInfo(
        format: format,
        size: bytes.length,
        width: raw.width,
        height: raw.height,
        channels: 1,
      ),
    );
  }
}

_FitsHeader _readFitsHeader(Uint8List bytes) {
  if (bytes.length < 2880 || !_startsWithAscii(bytes, 0, 'SIMPLE  =')) {
    throw const InvalidImageException('Invalid FITS header.');
  }
  final values = <String, Object>{};
  var offset = 0;
  var foundEnd = false;
  while (offset + 80 <= bytes.length) {
    final card = ascii.decode(bytes.sublist(offset, offset + 80));
    offset += 80;
    final keyword = card.substring(0, 8).trim();
    if (keyword == 'END') {
      foundEnd = true;
      break;
    }
    if (card.length > 10 && card[8] == '=') {
      values[keyword] = _parseFitsValue(card.substring(10));
    }
  }
  if (!foundEnd) {
    throw const InvalidImageException('FITS header missing END card.');
  }
  final dataOffset = ((offset + 2879) ~/ 2880) * 2880;
  final simple = values['SIMPLE'];
  if (simple != true) {
    throw const InvalidImageException('FITS SIMPLE header is required.');
  }
  final bitpix = _requiredFitsInt(values, 'BITPIX');
  final axisCount = _requiredFitsInt(values, 'NAXIS');
  if (axisCount != 2 && axisCount != 3) {
    throw const UnsupportedCodecException(
      'Only 2D/3D FITS images are supported.',
    );
  }
  final width = _requiredFitsInt(values, 'NAXIS1');
  final height = _requiredFitsInt(values, 'NAXIS2');
  final planes = axisCount == 3 ? _requiredFitsInt(values, 'NAXIS3') : 1;
  if (width <= 0 ||
      height <= 0 ||
      (planes != 1 && planes != 3 && planes != 4)) {
    throw const UnsupportedCodecException(
      'Only grayscale, RGB, and RGBA FITS images are supported.',
    );
  }
  final bytesPerSample = _bytesPerFitsSample(bitpix);
  final sampleCount = width * height * planes;
  if (dataOffset + sampleCount * bytesPerSample > bytes.length) {
    throw const InvalidImageException('Truncated FITS image data.');
  }
  return _FitsHeader(
    width: width,
    height: height,
    planes: planes,
    bitpix: bitpix,
    dataOffset: dataOffset,
    bscale: _fitsDouble(values, 'BSCALE') ?? 1,
    bzero: _fitsDouble(values, 'BZERO') ?? 0,
    dataMin: _fitsDouble(values, 'DATAMIN'),
    dataMax: _fitsDouble(values, 'DATAMAX'),
  );
}

Object _parseFitsValue(String field) {
  final value = field.split('/').first.trim();
  if (value == 'T') {
    return true;
  }
  if (value == 'F') {
    return false;
  }
  if (value.startsWith("'") && value.endsWith("'")) {
    return value.substring(1, value.length - 1).trim();
  }
  return int.tryParse(value) ??
      double.tryParse(value.replaceAll('D', 'E')) ??
      value;
}

int _requiredFitsInt(Map<String, Object> values, String key) {
  final value = values[key];
  if (value is int) {
    return value;
  }
  throw InvalidImageException('FITS $key header is required.');
}

double? _fitsDouble(Map<String, Object> values, String key) {
  final value = values[key];
  return switch (value) {
    int() => value.toDouble(),
    double() => value,
    _ => null,
  };
}

_FitsRange _sampleRange(_FitsHeader header) {
  final dataMin = header.dataMin;
  final dataMax = header.dataMax;
  if (dataMin != null && dataMax != null && dataMax > dataMin) {
    return _FitsRange(dataMin, dataMax);
  }
  final (minValue, maxValue) = switch (header.bitpix) {
    8 => (0.0, 255.0),
    16 => (-32768.0, 32767.0),
    32 => (-2147483648.0, 2147483647.0),
    _ => (0.0, 1.0),
  };
  return _FitsRange(
    (minValue * header.bscale) + header.bzero,
    (maxValue * header.bscale) + header.bzero,
  );
}

int _scaledFitsSample(
  Uint8List bytes,
  _FitsHeader header,
  int sample,
  _FitsRange range,
) {
  final offset =
      header.dataOffset + sample * _bytesPerFitsSample(header.bitpix);
  final value =
      (_readFitsRawSample(bytes, offset, header.bitpix) * header.bscale) +
      header.bzero;
  if (range.max <= range.min) {
    return value <= range.min ? 0 : 255;
  }
  return (((value - range.min) * 255) / (range.max - range.min)).round().clamp(
    0,
    255,
  );
}

num _readFitsRawSample(Uint8List bytes, int offset, int bitpix) {
  return switch (bitpix) {
    8 => bytes[offset],
    16 => _signed16(readUint16Be(bytes, offset)),
    32 => _signed32(readUint32Be(bytes, offset)),
    -32 => ByteData.sublistView(bytes, offset, offset + 4).getFloat32(0),
    -64 => ByteData.sublistView(bytes, offset, offset + 8).getFloat64(0),
    _ => throw const UnsupportedCodecException(
      'Unsupported FITS BITPIX value.',
    ),
  };
}

int _bytesPerFitsSample(int bitpix) {
  return switch (bitpix) {
    8 => 1,
    16 => 2,
    32 || -32 => 4,
    -64 => 8,
    _ => throw const UnsupportedCodecException(
      'Unsupported FITS BITPIX value.',
    ),
  };
}

int _signed16(int value) => value >= 0x8000 ? value - 0x10000 : value;

int _signed32(int value) => value >= 0x80000000 ? value - 0x100000000 : value;

bool _startsWithAscii(Uint8List bytes, int offset, String value) {
  if (bytes.length < offset + value.length) {
    return false;
  }
  for (var i = 0; i < value.length; i += 1) {
    if (bytes[offset + i] != value.codeUnitAt(i)) {
      return false;
    }
  }
  return true;
}

Uint8List _fitsCardBool(String keyword, bool value) {
  return _fitsValueCard(keyword, value ? 'T' : 'F');
}

Uint8List _fitsCardInt(String keyword, int value) {
  return _fitsValueCard(keyword, value.toString());
}

Uint8List _fitsValueCard(String keyword, String value) {
  final text = '${keyword.padRight(8)}= ${value.padLeft(20)}';
  return _fitsCard(text);
}

Uint8List _fitsEndCard() => _fitsCard('END');

Uint8List _fitsCard(String text) {
  return Uint8List.fromList(ascii.encode(text.padRight(80).substring(0, 80)));
}

final class _FitsHeader {
  const _FitsHeader({
    required this.width,
    required this.height,
    required this.planes,
    required this.bitpix,
    required this.dataOffset,
    required this.bscale,
    required this.bzero,
    required this.dataMin,
    required this.dataMax,
  });

  final int width;
  final int height;
  final int planes;
  final int bitpix;
  final int dataOffset;
  final double bscale;
  final double bzero;
  final double? dataMin;
  final double? dataMax;
}

final class _FitsRange {
  const _FitsRange(this.min, this.max);

  final double min;
  final double max;
}
