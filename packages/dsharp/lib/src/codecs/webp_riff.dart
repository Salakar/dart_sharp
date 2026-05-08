import 'dart:typed_data';

import '../api/exceptions.dart';
import 'binary_io.dart';

/// Returns the declared exclusive end offset of a RIFF/WebP payload.
int webpRiffEnd(Uint8List bytes) {
  if (bytes.length < 20 ||
      String.fromCharCodes(bytes.sublist(0, 4)) != 'RIFF' ||
      String.fromCharCodes(bytes.sublist(8, 12)) != 'WEBP') {
    throw const InvalidImageException('Invalid WebP signature.');
  }
  final riffEnd = 8 + readUint32Le(bytes, 4);
  if (riffEnd > bytes.length) {
    throw const InvalidImageException('Truncated WebP RIFF payload.');
  }
  if (riffEnd < 12) {
    throw const InvalidImageException('Invalid WebP signature.');
  }
  return riffEnd;
}
