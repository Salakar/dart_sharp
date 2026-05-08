import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

import 'helpers/webp_lossy_fixture.dart';

void main() {
  test('applies VP8 key-frame display scale bits', () async {
    final bytes = solidVp8Webp(width: 4, height: 3);
    _setVp8Scale(bytes, horizontal: 1, vertical: 2);

    final metadata = await ImagePipeline.fromBytes(bytes).metadata();
    final image = await ImagePipeline.fromBytes(bytes).toPixelImage();

    expect(metadata.width, 5);
    expect(metadata.height, 5);
    expect(image.width, 5);
    expect(image.height, 5);
    final pixels = image.firstFrameBytes();
    expect(pixels, hasLength(5 * 5 * 4));
    for (var offset = 0; offset < pixels.length; offset += 4) {
      expect(pixels.sublist(offset, offset + 4), <int>[128, 128, 128, 255]);
    }
  });

  test(
    'validates VP8 display scale against extended canvas dimensions',
    () async {
      final bytes = extendedSolidVp8Webp(width: 4, height: 3);
      _setVp8Scale(bytes, horizontal: 1, vertical: 2);
      _setVp8xCanvas(bytes, width: 5, height: 5);

      final metadata = await ImagePipeline.fromBytes(bytes).metadata();
      final image = await ImagePipeline.fromBytes(bytes).toPixelImage();

      expect(metadata.width, 5);
      expect(metadata.height, 5);
      expect(image.width, 5);
      expect(image.height, 5);
    },
  );
}

void _setVp8Scale(
  Uint8List webp, {
  required int horizontal,
  required int vertical,
}) {
  final offset = _chunkPayloadOffset(webp, 'VP8 ');
  webp[offset + 7] = (webp[offset + 7] & 0x3f) | (horizontal << 6);
  webp[offset + 9] = (webp[offset + 9] & 0x3f) | (vertical << 6);
}

void _setVp8xCanvas(Uint8List webp, {required int width, required int height}) {
  final offset = _chunkPayloadOffset(webp, 'VP8X');
  _writeUint24Le(webp, offset + 4, width - 1);
  _writeUint24Le(webp, offset + 7, height - 1);
}

int _chunkPayloadOffset(Uint8List webp, String type) {
  var offset = 12;
  while (offset + 8 <= webp.length) {
    final chunkType = String.fromCharCodes(webp.sublist(offset, offset + 4));
    final length =
        webp[offset + 4] |
        (webp[offset + 5] << 8) |
        (webp[offset + 6] << 16) |
        (webp[offset + 7] << 24);
    if (chunkType == type) {
      return offset + 8;
    }
    offset += 8 + length + (length.isOdd ? 1 : 0);
  }
  throw StateError('Missing $type chunk.');
}

void _writeUint24Le(Uint8List bytes, int offset, int value) {
  bytes[offset] = value & 0xff;
  bytes[offset + 1] = (value >> 8) & 0xff;
  bytes[offset + 2] = (value >> 16) & 0xff;
}
