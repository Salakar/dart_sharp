import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

import 'helpers/webp_lossy_fixture.dart';

void main() {
  test('rejects empty WebP ALPH chunks', () async {
    final bytes = _emptyAlphaVp8Webp();

    await expectLater(
      ImagePipeline.fromBytes(bytes).metadata(),
      throwsA(
        isA<InvalidImageException>().having(
          (error) => error.message,
          'message',
          contains('Invalid WebP ALPH chunk'),
        ),
      ),
    );
    await expectLater(
      ImagePipeline.fromBytes(bytes).toPixelImage(),
      throwsA(
        isA<InvalidImageException>().having(
          (error) => error.message,
          'message',
          contains('Invalid WebP ALPH chunk'),
        ),
      ),
    );
  });

  test('rejects uncompressed WebP ALPH payload length mismatches', () async {
    for (final bytes in <Uint8List>[
      _truncatedUncompressedAlphaVp8Webp(),
      _extendedUncompressedAlphaVp8Webp(),
    ]) {
      await expectLater(
        ImagePipeline.fromBytes(bytes).toPixelImage(),
        throwsA(
          isA<InvalidImageException>().having(
            (error) => error.message,
            'message',
            contains('Invalid WebP ALPH payload length'),
          ),
        ),
      );
    }
  });
}

Uint8List _emptyAlphaVp8Webp() {
  final bytes = alphaSolidVp8Webp(width: 1, height: 1, alpha: <int>[127]);
  final alphaOffset = _chunkOffset(bytes, 'ALPH');
  final alphaLength = _readU32(bytes, alphaOffset + 4);
  final payloadStart = alphaOffset + 8;
  final payloadEnd = payloadStart + alphaLength;
  final removeEnd = payloadEnd + (alphaLength.isOdd ? 1 : 0);
  final removed = removeEnd - payloadStart;
  final out = Uint8List(bytes.length - removed)
    ..setRange(0, payloadStart, bytes)
    ..setRange(payloadStart, bytes.length - removed, bytes, removeEnd);
  _writeU32(out, 4, _readU32(bytes, 4) - removed);
  _writeU32(out, alphaOffset + 4, 0);
  return out;
}

Uint8List _truncatedUncompressedAlphaVp8Webp() {
  final bytes = alphaSolidVp8Webp(width: 2, height: 1, alpha: <int>[0, 255]);
  final alphaOffset = _chunkOffset(bytes, 'ALPH');
  final alphaLength = _readU32(bytes, alphaOffset + 4);
  final payloadStart = alphaOffset + 8;
  final removeStart = payloadStart + alphaLength - 1;
  final removeEnd = payloadStart + alphaLength + (alphaLength.isOdd ? 1 : 0);
  final removed = removeEnd - removeStart;
  final out = Uint8List(bytes.length - removed)
    ..setRange(0, removeStart, bytes)
    ..setRange(removeStart, bytes.length - removed, bytes, removeEnd);
  _writeU32(out, 4, _readU32(bytes, 4) - removed);
  _writeU32(out, alphaOffset + 4, alphaLength - 1);
  return out;
}

Uint8List _extendedUncompressedAlphaVp8Webp() {
  final bytes = alphaSolidVp8Webp(width: 2, height: 1, alpha: <int>[0, 255]);
  final alphaOffset = _chunkOffset(bytes, 'ALPH');
  final alphaLength = _readU32(bytes, alphaOffset + 4);
  final out = Uint8List.fromList(bytes);
  _writeU32(out, alphaOffset + 4, alphaLength + 1);
  return out;
}

int _chunkOffset(Uint8List bytes, String type) {
  var offset = 12;
  while (offset + 8 <= bytes.length) {
    final chunkType = String.fromCharCodes(bytes.sublist(offset, offset + 4));
    final length = _readU32(bytes, offset + 4);
    if (chunkType == type) {
      return offset;
    }
    offset += 8 + length + (length.isOdd ? 1 : 0);
  }
  throw StateError('Missing $type chunk.');
}

int _readU32(Uint8List bytes, int offset) {
  return bytes[offset] |
      (bytes[offset + 1] << 8) |
      (bytes[offset + 2] << 16) |
      (bytes[offset + 3] << 24);
}

void _writeU32(Uint8List bytes, int offset, int value) {
  bytes[offset] = value & 0xff;
  bytes[offset + 1] = (value >> 8) & 0xff;
  bytes[offset + 2] = (value >> 16) & 0xff;
  bytes[offset + 3] = (value >> 24) & 0xff;
}
