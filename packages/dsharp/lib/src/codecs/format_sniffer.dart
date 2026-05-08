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
    final brand = String.fromCharCodes(bytes.sublist(8, 12)).toLowerCase();
    if (brand == 'avif') {
      return ImageFormat.avif;
    }
    if (brand == 'heic' || brand == 'heif' || brand == 'mif1') {
      return ImageFormat.heif;
    }
  }
  if (_startsWith(bytes, const <int>[0x00, 0x00, 0x00, 0x0c]) &&
      bytes.length >= 12 &&
      _rangeEquals(bytes, 4, 'JXL '.codeUnits)) {
    return ImageFormat.jxl;
  }
  if (_startsWith(bytes, const <int>[0x00, 0x00, 0x00, 0x0c]) &&
      bytes.length >= 12 &&
      _rangeEquals(bytes, 4, 'jP  '.codeUnits)) {
    return ImageFormat.jp2;
  }
  if (_startsWith(bytes, '%PDF'.codeUnits)) {
    return ImageFormat.pdf;
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
      (bytes[1] == 0x32 ||
          bytes[1] == 0x33 ||
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

bool _isWhitespace(int byte) {
  return byte == 0x20 ||
      byte == 0x09 ||
      byte == 0x0a ||
      byte == 0x0b ||
      byte == 0x0c ||
      byte == 0x0d;
}
