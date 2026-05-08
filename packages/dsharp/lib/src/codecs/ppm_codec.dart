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

/// First-party Netpbm PPM/PGM/PBM codec.
final class PpmImageCodec implements ImageCodec {
  /// Creates a PPM codec.
  const PpmImageCodec();

  @override
  ImageFormat get format => ImageFormat.ppm;

  @override
  PixelImage decode(Uint8List bytes) {
    final scanner = _PnmScanner(bytes);
    final magic = scanner.nextToken();
    final isBitmap = magic == 'P1' || magic == 'P4';
    final isAscii = magic == 'P1' || magic == 'P2' || magic == 'P3';
    final isGray = isBitmap || magic == 'P2' || magic == 'P5';
    if (!isAscii && !isGray && magic != 'P6') {
      throw const InvalidImageException('Invalid PPM signature.');
    }
    final width = scanner.nextInt('width');
    final height = scanner.nextInt('height');
    final maxValue = isBitmap ? 1 : scanner.nextInt('max value');
    if (width <= 0 || height <= 0) {
      throw const InvalidImageException('Invalid PPM dimensions.');
    }
    if (maxValue <= 0 || maxValue > 0xffff) {
      throw const InvalidImageException('Invalid PPM max value.');
    }
    const InputSafetyLimits().checkImage(
      width: width,
      height: height,
      frames: 1,
    );
    final rgba = isAscii
        ? _decodeAsciiPnm(
            scanner,
            width,
            height,
            maxValue,
            isGray: isGray,
            isBitmap: isBitmap,
          )
        : _decodeBinaryPnm(
            scanner,
            width,
            height,
            maxValue,
            isGray: isGray,
            isBitmap: isBitmap,
          );
    return PixelImage.fromRawPixels(
      RawPixels(
        bytes: rgba,
        width: width,
        height: height,
        channels: ChannelCount.four,
      ),
    );
  }

  @override
  EncodedImage encode(PixelImage image, {EncoderOptions? options}) {
    final raw = image.firstFrame.pixels;
    final rgba = rawToRgba(raw);
    final writer = ByteWriter()
      ..writeAscii('P6\n${raw.width} ${raw.height}\n255\n');
    for (var offset = 0; offset < rgba.length; offset += 4) {
      writer
        ..writeByte(rgba[offset])
        ..writeByte(rgba[offset + 1])
        ..writeByte(rgba[offset + 2]);
    }
    final bytes = writer.toBytes();
    return EncodedImage(
      bytes: bytes,
      info: OutputInfo(
        format: format,
        size: bytes.length,
        width: raw.width,
        height: raw.height,
        channels: 3,
      ),
    );
  }
}

Uint8List _decodeAsciiPnm(
  _PnmScanner scanner,
  int width,
  int height,
  int maxValue, {
  required bool isGray,
  required bool isBitmap,
}) {
  final rgba = Uint8List(width * height * 4);
  final samplesPerPixel = isGray ? 1 : 3;
  for (var pixel = 0; pixel < width * height; pixel += 1) {
    final out = pixel * 4;
    if (isBitmap) {
      final gray = _pbmGray(scanner.nextInt('sample'));
      rgba[out] = gray;
      rgba[out + 1] = gray;
      rgba[out + 2] = gray;
    } else if (isGray) {
      final gray = _scalePnmSample(scanner.nextInt('sample'), maxValue);
      rgba[out] = gray;
      rgba[out + 1] = gray;
      rgba[out + 2] = gray;
    } else {
      for (var sample = 0; sample < samplesPerPixel; sample += 1) {
        rgba[out + sample] = _scalePnmSample(
          scanner.nextInt('sample'),
          maxValue,
        );
      }
    }
    rgba[out + 3] = 255;
  }
  return rgba;
}

Uint8List _decodeBinaryPnm(
  _PnmScanner scanner,
  int width,
  int height,
  int maxValue, {
  required bool isGray,
  required bool isBitmap,
}) {
  if (isBitmap) {
    return _decodeBinaryPbm(scanner, width, height);
  }
  scanner.consumeRasterSeparator();
  final samplesPerPixel = isGray ? 1 : 3;
  final bytesPerSample = maxValue < 256 ? 1 : 2;
  final sampleCount = width * height * samplesPerPixel;
  final expectedBytes = sampleCount * bytesPerSample;
  if (scanner.offset + expectedBytes > scanner.bytes.length) {
    throw const InvalidImageException('Truncated PPM raster data.');
  }
  final rgba = Uint8List(width * height * 4);
  var input = scanner.offset;
  for (var pixel = 0; pixel < width * height; pixel += 1) {
    final out = pixel * 4;
    if (isGray) {
      final gray = _scalePnmSample(
        _readPnmSample(scanner.bytes, input, bytesPerSample),
        maxValue,
      );
      input += bytesPerSample;
      rgba[out] = gray;
      rgba[out + 1] = gray;
      rgba[out + 2] = gray;
    } else {
      for (var sample = 0; sample < 3; sample += 1) {
        rgba[out + sample] = _scalePnmSample(
          _readPnmSample(scanner.bytes, input, bytesPerSample),
          maxValue,
        );
        input += bytesPerSample;
      }
    }
    rgba[out + 3] = 255;
  }
  return rgba;
}

Uint8List _decodeBinaryPbm(_PnmScanner scanner, int width, int height) {
  scanner.consumeRasterSeparator();
  final rowBytes = (width + 7) >> 3;
  final expectedBytes = rowBytes * height;
  if (scanner.offset + expectedBytes > scanner.bytes.length) {
    throw const InvalidImageException('Truncated PPM raster data.');
  }
  final rgba = Uint8List(width * height * 4);
  for (var y = 0; y < height; y += 1) {
    final row = scanner.offset + y * rowBytes;
    for (var x = 0; x < width; x += 1) {
      final byte = scanner.bytes[row + (x >> 3)];
      final bit = (byte >> (7 - (x & 7))) & 1;
      final gray = _pbmGray(bit);
      final out = ((y * width) + x) * 4;
      rgba[out] = gray;
      rgba[out + 1] = gray;
      rgba[out + 2] = gray;
      rgba[out + 3] = 255;
    }
  }
  return rgba;
}

int _readPnmSample(Uint8List bytes, int offset, int bytesPerSample) {
  if (bytesPerSample == 1) {
    return bytes[offset];
  }
  return readUint16Be(bytes, offset);
}

int _pbmGray(int value) {
  if (value != 0 && value != 1) {
    throw const InvalidImageException('Invalid PPM sample value.');
  }
  return value == 0 ? 255 : 0;
}

int _scalePnmSample(int value, int maxValue) {
  if (value < 0 || value > maxValue) {
    throw const InvalidImageException('Invalid PPM sample value.');
  }
  return ((value * 255) + (maxValue >> 1)) ~/ maxValue;
}

final class _PnmScanner {
  _PnmScanner(this.bytes);

  final Uint8List bytes;
  var offset = 0;

  String nextToken() {
    _skipWhitespaceAndComments();
    if (offset >= bytes.length) {
      throw const InvalidImageException('Truncated PPM header.');
    }
    final start = offset;
    while (offset < bytes.length &&
        !_isWhitespace(bytes[offset]) &&
        bytes[offset] != 0x23) {
      offset += 1;
    }
    if (start == offset) {
      throw const InvalidImageException('Invalid PPM header.');
    }
    return ascii.decode(bytes.sublist(start, offset));
  }

  int nextInt(String name) {
    final value = int.tryParse(nextToken());
    if (value == null) {
      throw InvalidImageException('Invalid PPM $name.');
    }
    return value;
  }

  void consumeRasterSeparator() {
    if (offset >= bytes.length || !_isWhitespace(bytes[offset])) {
      throw const InvalidImageException('Invalid PPM raster separator.');
    }
    final first = bytes[offset];
    offset += 1;
    if (first == 0x0d && offset < bytes.length && bytes[offset] == 0x0a) {
      offset += 1;
    }
  }

  void _skipWhitespaceAndComments() {
    while (offset < bytes.length) {
      final byte = bytes[offset];
      if (_isWhitespace(byte)) {
        offset += 1;
      } else if (byte == 0x23) {
        _skipComment();
      } else {
        break;
      }
    }
  }

  void _skipComment() {
    while (offset < bytes.length &&
        bytes[offset] != 0x0a &&
        bytes[offset] != 0x0d) {
      offset += 1;
    }
  }
}

bool _isWhitespace(int byte) {
  return byte == 0x20 ||
      byte == 0x09 ||
      byte == 0x0a ||
      byte == 0x0b ||
      byte == 0x0c ||
      byte == 0x0d;
}
