import 'dart:convert';
import 'dart:typed_data';

import '../api/exceptions.dart';
import '../codecs/image_format.dart';
import '../source/input_options.dart';
import 'metadata.dart';

/// Reads metadata for simple self-describing formats without pixel decode.
ImageMetadata? readSimpleEncodedImageMetadata(
  Uint8List bytes,
  ImageFormat format,
) {
  return switch (format) {
    ImageFormat.ppm => _ppmMetadata(bytes),
    ImageFormat.fits => _fitsMetadata(bytes),
    ImageFormat.rad => _radMetadata(bytes),
    _ => null,
  };
}

ImageMetadata _ppmMetadata(Uint8List bytes) {
  final scanner = _TokenScanner(bytes, 'PPM');
  final magic = scanner.nextToken();
  final isBitmap = magic == 'P1' || magic == 'P4';
  final isGray = isBitmap || magic == 'P2' || magic == 'P5';
  if (!isGray && magic != 'P3' && magic != 'P6') {
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
  const InputSafetyLimits().checkImage(width: width, height: height, frames: 1);
  return ImageMetadata(
    format: ImageFormat.ppm,
    size: bytes.length,
    width: width,
    height: height,
    channels: isGray ? 1 : 3,
    hasAlpha: false,
    colorSpace: isGray ? (maxValue > 0xff ? 'grey16' : 'b-w') : 'srgb',
    bitDepth: maxValue.bitLength,
  );
}

ImageMetadata _fitsMetadata(Uint8List bytes) {
  if (bytes.length < 80 || !_startsWithAscii(bytes, 0, 'SIMPLE  =')) {
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
  if (values['SIMPLE'] != true) {
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
  if (width <= 0 || height <= 0) {
    throw const InvalidImageException('Invalid FITS dimensions.');
  }
  if (planes != 1 && planes != 3 && planes != 4) {
    throw const UnsupportedCodecException(
      'Only grayscale, RGB, and RGBA FITS images are supported.',
    );
  }
  _bytesPerFitsSample(bitpix);
  const InputSafetyLimits().checkImage(width: width, height: height, frames: 1);
  return ImageMetadata(
    format: ImageFormat.fits,
    size: bytes.length,
    width: width,
    height: height,
    channels: planes,
    hasAlpha: planes == 4,
    colorSpace: _fitsColorSpace(planes, bitpix),
    bitDepth: bitpix.abs(),
  );
}

ImageMetadata _radMetadata(Uint8List bytes) {
  final scanner = _LineScanner(bytes);
  final signature = scanner.nextLine();
  if (signature != '#?RADIANCE' && signature != '#?RGBE') {
    throw const InvalidImageException('Invalid Radiance HDR signature.');
  }
  var hasFormat = false;
  while (true) {
    final line = scanner.nextLine();
    if (line == null) {
      throw const InvalidImageException('Radiance HDR missing resolution.');
    }
    final trimmed = line.trim();
    if (trimmed == 'FORMAT=32-bit_rle_rgbe') {
      hasFormat = true;
      continue;
    }
    final resolution = _parseRadResolution(trimmed);
    if (resolution == null) {
      continue;
    }
    if (!hasFormat) {
      throw const InvalidImageException('Radiance HDR missing RGBE format.');
    }
    const InputSafetyLimits().checkImage(
      width: resolution.width,
      height: resolution.height,
      frames: 1,
    );
    return ImageMetadata(
      format: ImageFormat.rad,
      size: bytes.length,
      width: resolution.width,
      height: resolution.height,
      channels: 3,
      hasAlpha: false,
      colorSpace: 'srgb',
      bitDepth: 8,
    );
  }
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

String _fitsColorSpace(int planes, int bitpix) {
  if (planes == 1) {
    return bitpix.abs() > 8 ? 'grey16' : 'b-w';
  }
  return bitpix.abs() > 8 ? 'rgb16' : 'srgb';
}

({int width, int height})? _parseRadResolution(String line) {
  final match = RegExp(
    r'^([+-])([XY])\s+(\d+)\s+([+-])([XY])\s+(\d+)$',
  ).firstMatch(line);
  if (match == null) {
    return null;
  }
  if (match.group(2)! != 'Y' || match.group(5)! != 'X') {
    throw const UnsupportedCodecException(
      'Only Y-major Radiance HDR scanline order is supported.',
    );
  }
  final height = int.parse(match.group(3)!);
  final width = int.parse(match.group(6)!);
  if (width <= 0 || height <= 0) {
    throw const InvalidImageException('Invalid Radiance HDR dimensions.');
  }
  return (width: width, height: height);
}

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

final class _TokenScanner {
  _TokenScanner(this.bytes, this.formatName);

  final Uint8List bytes;
  final String formatName;
  var offset = 0;

  String nextToken() {
    _skipWhitespaceAndComments();
    if (offset >= bytes.length) {
      throw InvalidImageException('Truncated $formatName header.');
    }
    final start = offset;
    while (offset < bytes.length &&
        !_isWhitespace(bytes[offset]) &&
        bytes[offset] != 0x23) {
      offset += 1;
    }
    if (start == offset) {
      throw InvalidImageException('Invalid $formatName header.');
    }
    return ascii.decode(bytes.sublist(start, offset));
  }

  int nextInt(String name) {
    final value = int.tryParse(nextToken());
    if (value == null) {
      throw InvalidImageException('Invalid $formatName $name.');
    }
    return value;
  }

  void _skipWhitespaceAndComments() {
    while (offset < bytes.length) {
      final byte = bytes[offset];
      if (_isWhitespace(byte)) {
        offset += 1;
      } else if (byte == 0x23) {
        while (offset < bytes.length &&
            bytes[offset] != 0x0a &&
            bytes[offset] != 0x0d) {
          offset += 1;
        }
      } else {
        break;
      }
    }
  }
}

final class _LineScanner {
  _LineScanner(this.bytes);

  final Uint8List bytes;
  var offset = 0;

  String? nextLine() {
    if (offset >= bytes.length) {
      return null;
    }
    final start = offset;
    while (offset < bytes.length && bytes[offset] != 0x0a) {
      offset += 1;
    }
    var end = offset;
    if (end > start && bytes[end - 1] == 0x0d) {
      end -= 1;
    }
    if (offset < bytes.length) {
      offset += 1;
    }
    return ascii.decode(bytes.sublist(start, end));
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
