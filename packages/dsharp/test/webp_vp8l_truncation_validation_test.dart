import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

import 'helpers/webp_lossless_fixture.dart';

void main() {
  test('rejects truncated VP8L image bitstreams after valid headers', () async {
    final bytes = solidVp8lWebp(
      width: 1,
      height: 1,
      red: 1,
      green: 2,
      blue: 3,
      alpha: 255,
    );
    final malformed = _withChunkPayloadLength(bytes, 'VP8L', 5);

    final metadata = await ImagePipeline.fromBytes(malformed).metadata();
    expect(metadata.width, 1);
    expect(metadata.height, 1);
    await expectLater(
      ImagePipeline.fromBytes(malformed).toPixelImage(),
      throwsA(
        isA<InvalidImageException>().having(
          (error) => error.message,
          'message',
          contains('Truncated VP8L bitstream'),
        ),
      ),
    );
  });
}

Uint8List _withChunkPayloadLength(
  Uint8List bytes,
  String type,
  int payloadLength,
) {
  final chunk = _chunk(bytes, type);
  final payloadEnd = chunk.start + payloadLength;
  final outLength = payloadEnd + (payloadLength.isOdd ? 1 : 0);
  final out = Uint8List(outLength)..setRange(0, payloadEnd, bytes);
  _writeU32(out, chunk.offset + 4, payloadLength);
  _writeU32(out, 4, out.length - 8);
  return out;
}

({int offset, int start}) _chunk(Uint8List bytes, String type) {
  var offset = 12;
  while (offset + 8 <= bytes.length) {
    final chunkType = String.fromCharCodes(bytes.sublist(offset, offset + 4));
    final length = _readU32(bytes, offset + 4);
    final start = offset + 8;
    if (chunkType == type) {
      return (offset: offset, start: start);
    }
    offset = start + length + (length.isOdd ? 1 : 0);
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
