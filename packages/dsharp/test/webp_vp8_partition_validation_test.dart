import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

import 'helpers/webp_lossy_fixture.dart';

void main() {
  test('rejects truncated VP8 coefficient partition tables', () async {
    final bytes = eobResidualVp8Webp(
      width: 2,
      height: 17,
      qIndex: 1,
      tokenPartitionBits: 1,
    );
    final firstEnd = _firstPartitionEnd(bytes);
    final malformed = _withVp8PayloadLength(bytes, firstEnd + 2);

    final metadata = await ImagePipeline.fromBytes(malformed).metadata();
    expect(metadata.width, 2);
    expect(metadata.height, 17);
    await expectLater(
      ImagePipeline.fromBytes(malformed).toPixelImage(),
      throwsA(
        isA<InvalidImageException>().having(
          (error) => error.message,
          'message',
          contains('Truncated VP8 coefficient partitions'),
        ),
      ),
    );
  });

  test('rejects truncated VP8 coefficient partition payloads', () async {
    final bytes = eobResidualVp8Webp(
      width: 2,
      height: 17,
      qIndex: 1,
      tokenPartitionBits: 1,
    );
    final vp8 = _chunk(bytes, 'VP8 ');
    final firstEnd = _firstPartitionEnd(bytes);
    _writeU24(bytes, vp8.start + firstEnd, 0xffffff);

    final metadata = await ImagePipeline.fromBytes(bytes).metadata();
    expect(metadata.width, 2);
    expect(metadata.height, 17);
    await expectLater(
      ImagePipeline.fromBytes(bytes).toPixelImage(),
      throwsA(
        isA<InvalidImageException>().having(
          (error) => error.message,
          'message',
          contains('Truncated VP8 coefficient partition'),
        ),
      ),
    );
  });
}

Uint8List _withVp8PayloadLength(Uint8List bytes, int payloadLength) {
  final vp8 = _chunk(bytes, 'VP8 ');
  final payloadEnd = vp8.start + payloadLength;
  final outLength = payloadEnd + (payloadLength.isOdd ? 1 : 0);
  final out = Uint8List(outLength)..setRange(0, payloadEnd, bytes);
  _writeU32(out, vp8.offset + 4, payloadLength);
  _writeU32(out, 4, out.length - 8);
  return out;
}

int _firstPartitionEnd(Uint8List bytes) {
  final vp8 = _chunk(bytes, 'VP8 ');
  return 10 + (_readU24(bytes, vp8.start) >> 5);
}

({int offset, int start, int length}) _chunk(Uint8List bytes, String type) {
  var offset = 12;
  while (offset + 8 <= bytes.length) {
    final chunkType = String.fromCharCodes(bytes.sublist(offset, offset + 4));
    final length = _readU32(bytes, offset + 4);
    final start = offset + 8;
    if (chunkType == type) {
      return (offset: offset, start: start, length: length);
    }
    offset = start + length + (length.isOdd ? 1 : 0);
  }
  throw StateError('Missing $type chunk.');
}

int _readU24(Uint8List bytes, int offset) {
  return bytes[offset] | (bytes[offset + 1] << 8) | (bytes[offset + 2] << 16);
}

int _readU32(Uint8List bytes, int offset) {
  return bytes[offset] |
      (bytes[offset + 1] << 8) |
      (bytes[offset + 2] << 16) |
      (bytes[offset + 3] << 24);
}

void _writeU24(Uint8List bytes, int offset, int value) {
  bytes[offset] = value & 0xff;
  bytes[offset + 1] = (value >> 8) & 0xff;
  bytes[offset + 2] = (value >> 16) & 0xff;
}

void _writeU32(Uint8List bytes, int offset, int value) {
  bytes[offset] = value & 0xff;
  bytes[offset + 1] = (value >> 8) & 0xff;
  bytes[offset + 2] = (value >> 16) & 0xff;
  bytes[offset + 3] = (value >> 24) & 0xff;
}
