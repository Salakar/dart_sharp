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

/// Returns the exclusive end offset of a chunk payload.
int webpChunkPayloadEnd(Uint8List bytes, int offset, int containerEnd) {
  final end = offset + 8 + readUint32Le(bytes, offset + 4);
  if (end > containerEnd) {
    throw const InvalidImageException('Truncated WebP chunk.');
  }
  return end;
}

/// Returns the offset of the next chunk, validating RIFF padding when present.
int webpNextChunkOffset(
  Uint8List bytes, {
  required int payloadEnd,
  required int payloadLength,
  required int containerEnd,
}) {
  if (payloadLength.isEven) {
    return payloadEnd;
  }
  if (payloadEnd >= containerEnd) {
    throw const InvalidImageException('Truncated WebP chunk.');
  }
  if (bytes[payloadEnd] != 0) {
    throw const InvalidImageException('Invalid WebP chunk padding.');
  }
  return payloadEnd + 1;
}
