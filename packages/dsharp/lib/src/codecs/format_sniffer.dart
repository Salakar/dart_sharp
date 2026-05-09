import 'dart:typed_data';

import 'image_format.dart';

/// Returns the most likely image format for [bytes].
ImageFormat sniffImageFormat(Uint8List bytes) {
  if (_startsWith(bytes, const <int>[0xff, 0xd8, 0xff])) {
    return ImageFormat.jpeg;
  }
  if (_startsWith(bytes, const <int>[0x89, 0x50, 0x4e, 0x47])) {
    return ImageFormat.png;
  }
  if (_startsWith(bytes, 'GIF87a'.codeUnits) ||
      _startsWith(bytes, 'GIF89a'.codeUnits)) {
    return ImageFormat.gif;
  }
  if (_startsWith(bytes, 'II*\x00'.codeUnits) ||
      _startsWith(bytes, 'MM\x00*'.codeUnits)) {
    return ImageFormat.tiff;
  }
  if (bytes.length >= 12 &&
      _startsWith(bytes, 'RIFF'.codeUnits) &&
      _rangeEquals(bytes, 8, 'WEBP'.codeUnits)) {
    return ImageFormat.webp;
  }
  if (bytes.length >= 12 && _rangeEquals(bytes, 4, 'ftyp'.codeUnits)) {
    final brands = _isoBmffBrands(bytes);
    if (brands.any(_isAvifBrand)) {
      return ImageFormat.avif;
    }
    if (brands.any(_isHeifBrand)) {
      return ImageFormat.heif;
    }
  }
  if (_startsWith(bytes, const <int>[0xff, 0x0a]) ||
      _startsWith(bytes, const <int>[
        0x00,
        0x00,
        0x00,
        0x0c,
        0x4a,
        0x58,
        0x4c,
        0x20,
        0x0d,
        0x0a,
        0x87,
        0x0a,
      ])) {
    return ImageFormat.jxl;
  }
  if (_startsWith(bytes, const <int>[0xff, 0x4f, 0xff, 0x51]) ||
      _startsWith(bytes, const <int>[
        0x00,
        0x00,
        0x00,
        0x0c,
        0x6a,
        0x50,
        0x20,
        0x20,
        0x0d,
        0x0a,
        0x87,
        0x0a,
      ])) {
    return ImageFormat.jp2;
  }
  if (_startsWith(bytes, '%PDF'.codeUnits)) {
    return ImageFormat.pdf;
  }
  if (_looksLikeSvg(bytes)) {
    return ImageFormat.svg;
  }
  if (_startsWith(bytes, const <int>[0x76, 0x2f, 0x31, 0x01])) {
    return ImageFormat.exr;
  }
  if (_startsWith(bytes, 'SIMPLE  ='.codeUnits)) {
    return ImageFormat.fits;
  }
  if (_startsWith(bytes, '#?RADIANCE'.codeUnits) ||
      _startsWith(bytes, '#?RGBE'.codeUnits)) {
    return ImageFormat.rad;
  }
  if (bytes.length >= 3 &&
      bytes[0] == 0x50 &&
      (bytes[1] == 0x31 ||
          bytes[1] == 0x32 ||
          bytes[1] == 0x33 ||
          bytes[1] == 0x34 ||
          bytes[1] == 0x35 ||
          bytes[1] == 0x36) &&
      _isWhitespace(bytes[2])) {
    return ImageFormat.ppm;
  }
  return ImageFormat.unknown;
}

bool _startsWith(Uint8List bytes, List<int> prefix) {
  return _rangeEquals(bytes, 0, prefix);
}

bool _rangeEquals(Uint8List bytes, int offset, List<int> expected) {
  if (bytes.length < offset + expected.length) {
    return false;
  }
  for (var i = 0; i < expected.length; i += 1) {
    if (bytes[offset + i] != expected[i]) {
      return false;
    }
  }
  return true;
}

bool _looksLikeSvg(Uint8List bytes) {
  final offset = _skipSvgPreamble(bytes);
  return _startsSvgElement(bytes, offset) || _startsSvgDoctype(bytes, offset);
}

int _skipSvgPreamble(Uint8List bytes) {
  var offset = _skipWhitespace(bytes, _skipUtf8Bom(bytes));
  while (offset < bytes.length) {
    if (_rangeEqualsAsciiCaseInsensitive(bytes, offset, '<?xml'.codeUnits)) {
      final end = _findSequence(bytes, offset + 5, '?>'.codeUnits);
      if (end < 0) {
        return offset;
      }
      offset = _skipWhitespace(bytes, end + 2);
      continue;
    }
    if (_rangeEquals(bytes, offset, '<!--'.codeUnits)) {
      final end = _findSequence(bytes, offset + 4, '-->'.codeUnits);
      if (end < 0) {
        return offset;
      }
      offset = _skipWhitespace(bytes, end + 3);
      continue;
    }
    return offset;
  }
  return offset;
}

int _skipUtf8Bom(Uint8List bytes) {
  if (_startsWith(bytes, const <int>[0xef, 0xbb, 0xbf])) {
    return 3;
  }
  return 0;
}

int _skipWhitespace(Uint8List bytes, int offset) {
  var cursor = offset;
  while (cursor < bytes.length && _isWhitespace(bytes[cursor])) {
    cursor += 1;
  }
  return cursor;
}

bool _startsSvgElement(Uint8List bytes, int offset) {
  if (!_rangeEqualsAsciiCaseInsensitive(bytes, offset, '<svg'.codeUnits)) {
    return false;
  }
  final next = offset + 4;
  return next >= bytes.length ||
      _isWhitespace(bytes[next]) ||
      bytes[next] == 0x2f ||
      bytes[next] == 0x3a ||
      bytes[next] == 0x3e;
}

bool _startsSvgDoctype(Uint8List bytes, int offset) {
  if (!_rangeEqualsAsciiCaseInsensitive(bytes, offset, '<!doctype'.codeUnits)) {
    return false;
  }
  final token = _skipWhitespace(bytes, offset + 9);
  if (!_rangeEqualsAsciiCaseInsensitive(bytes, token, 'svg'.codeUnits)) {
    return false;
  }
  final next = token + 3;
  return next >= bytes.length ||
      _isWhitespace(bytes[next]) ||
      bytes[next] == 0x3e;
}

bool _rangeEqualsAsciiCaseInsensitive(
  Uint8List bytes,
  int offset,
  List<int> expected,
) {
  if (bytes.length < offset + expected.length) {
    return false;
  }
  for (var i = 0; i < expected.length; i += 1) {
    if (_asciiLower(bytes[offset + i]) != _asciiLower(expected[i])) {
      return false;
    }
  }
  return true;
}

int _asciiLower(int byte) {
  if (byte >= 0x41 && byte <= 0x5a) {
    return byte + 0x20;
  }
  return byte;
}

int _findSequence(Uint8List bytes, int start, List<int> pattern) {
  for (
    var offset = start;
    offset + pattern.length <= bytes.length;
    offset += 1
  ) {
    if (_rangeEquals(bytes, offset, pattern)) {
      return offset;
    }
  }
  return -1;
}

Iterable<String> _isoBmffBrands(Uint8List bytes) sync* {
  yield String.fromCharCodes(bytes.sublist(8, 12)).toLowerCase();
  final boxEnd = _isoBmffBoxEnd(bytes);
  for (var offset = 16; offset + 4 <= boxEnd; offset += 4) {
    yield String.fromCharCodes(bytes.sublist(offset, offset + 4)).toLowerCase();
  }
}

int _isoBmffBoxEnd(Uint8List bytes) {
  final size = (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
  if (size >= 16 && size <= bytes.length) {
    return size;
  }
  return bytes.length;
}

bool _isAvifBrand(String brand) => brand == 'avif' || brand == 'avis';

bool _isHeifBrand(String brand) =>
    brand == 'heic' ||
    brand == 'heix' ||
    brand == 'hevc' ||
    brand == 'hevx' ||
    brand == 'heif' ||
    brand == 'mif1' ||
    brand == 'msf1';

bool _isWhitespace(int byte) {
  return byte == 0x20 ||
      byte == 0x09 ||
      byte == 0x0a ||
      byte == 0x0b ||
      byte == 0x0c ||
      byte == 0x0d;
}
