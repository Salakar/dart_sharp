import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

import 'helpers/webp_lossless_fixture.dart';
import 'helpers/webp_lossy_fixture.dart';

void main() {
  test('decodes extended static WebP with VP8L payload', () async {
    final bytes = extendedVp8lWebp(
      width: 2,
      height: 1,
      red: 33,
      green: 44,
      blue: 55,
      alpha: 123,
    );

    final metadata = await ImagePipeline.fromBytes(bytes).metadata();
    final image = await ImagePipeline.fromBytes(bytes).toPixelImage();

    expect(metadata.format, ImageFormat.webp);
    expect(metadata.hasAlpha, isTrue);
    expect(image.firstFrameBytes(), <int>[33, 44, 55, 123, 33, 44, 55, 123]);
  });

  test('decodes animated WebP with VP8L frame payloads', () async {
    final bytes = animatedVp8lWebp();

    final metadata = await ImagePipeline.fromBytes(bytes).metadata();
    final image = await ImagePipeline.fromBytes(bytes).toPixelImage();

    expect(metadata.format, ImageFormat.webp);
    expect(metadata.width, 4);
    expect(metadata.height, 1);
    expect(metadata.frames, 2);
    expect(metadata.loopCount, 3);
    expect(image.isAnimated, isTrue);
    expect(image.loopCount, 3);
    expect(image.frames[0].delay, const Duration(milliseconds: 10));
    expect(image.frames[1].delay, const Duration(milliseconds: 20));
    expect(image.frames[0].pixels.bytes, <int>[
      220,
      10,
      20,
      255,
      220,
      10,
      20,
      255,
      5,
      6,
      7,
      255,
      5,
      6,
      7,
      255,
    ]);
    expect(image.frames[1].pixels.bytes, <int>[
      5,
      6,
      7,
      255,
      5,
      6,
      7,
      255,
      20,
      30,
      240,
      255,
      20,
      30,
      240,
      255,
    ]);
  });

  test('alpha-blends animated VP8L frames onto retained canvas', () async {
    final bytes = blendedAnimatedVp8lWebp();

    final image = await ImagePipeline.fromBytes(bytes).toPixelImage();

    expect(image.frames.length, 2);
    expect(image.frames[0].pixels.bytes, <int>[255, 0, 0, 255, 255, 0, 0, 255]);
    expect(image.frames[1].pixels.bytes, <int>[
      127,
      0,
      128,
      255,
      255,
      0,
      0,
      255,
    ]);
  });

  test('decodes animated WebP with VP8 frame payloads', () async {
    final bytes = animatedVp8Webp(width: 2, height: 1);

    final metadata = await ImagePipeline.fromBytes(bytes).metadata();
    final image = await ImagePipeline.fromBytes(bytes).toPixelImage();

    expect(metadata.format, ImageFormat.webp);
    expect(metadata.frames, 1);
    expect(image.loopCount, 1);
    expect(image.frames.first.delay, const Duration(milliseconds: 15));
    expect(image.firstFrameBytes(), <int>[
      128,
      128,
      128,
      255,
      128,
      128,
      128,
      255,
    ]);
  });

  test('rejects unsupported VP8 color spaces in animation frames', () async {
    final bytes = animatedVp8Webp(
      width: 1,
      height: 1,
      unsupportedColorSpace: true,
    );

    final metadata = await ImagePipeline.fromBytes(bytes).metadata();

    expect(metadata.format, ImageFormat.webp);
    expect(metadata.frames, 1);
    await expectLater(
      ImagePipeline.fromBytes(bytes).toPixelImage(),
      throwsA(isA<UnsupportedCodecException>()),
    );
  });

  test('applies ALPH chunks to animated VP8 frame payloads', () async {
    final bytes = animatedVp8Webp(width: 2, height: 1, alpha: <int>[0, 255]);

    final metadata = await ImagePipeline.fromBytes(bytes).metadata();
    final image = await ImagePipeline.fromBytes(bytes).toPixelImage();

    expect(metadata.hasAlpha, isTrue);
    expect(image.firstFrameBytes(), <int>[
      128,
      128,
      128,
      0,
      128,
      128,
      128,
      255,
    ]);
  });

  test('rejects VP8L animation frames with ALPH chunks', () async {
    final bytes = animatedVp8lWebpWithAlphaChunk();

    await expectLater(
      ImagePipeline.fromBytes(bytes).metadata(),
      throwsA(isA<InvalidImageException>()),
    );
    await expectLater(
      ImagePipeline.fromBytes(bytes).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
  });

  test('rejects animation frames with duplicate image chunks', () async {
    final bytes = animatedVp8lWebpWithDuplicateImageChunk();

    await expectLater(
      ImagePipeline.fromBytes(bytes).metadata(),
      throwsA(isA<InvalidImageException>()),
    );
    await expectLater(
      ImagePipeline.fromBytes(bytes).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
  });

  test('rejects animation frames with duplicate ALPH chunks', () async {
    final bytes = animatedVp8WebpWithDuplicateAlphaChunks(
      width: 2,
      height: 1,
      alpha: <int>[0, 255],
    );

    await expectLater(
      ImagePipeline.fromBytes(bytes).metadata(),
      throwsA(isA<InvalidImageException>()),
    );
    await expectLater(
      ImagePipeline.fromBytes(bytes).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
  });

  test('rejects animation frames with trailing partial chunks', () async {
    final bytes = animatedVp8lWebpWithTrailingFrameBytes();

    await expectLater(
      ImagePipeline.fromBytes(bytes).metadata(),
      throwsA(isA<InvalidImageException>()),
    );
    await expectLater(
      ImagePipeline.fromBytes(bytes).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
  });

  test('rejects animation frames with reserved flags', () async {
    final bytes = animatedVp8Webp(width: 1, height: 1);
    final frameOffset = _chunkOffset(bytes, 'ANMF');
    bytes[frameOffset + 23] |= 0x04;

    await expectLater(
      ImagePipeline.fromBytes(bytes).metadata(),
      throwsA(
        isA<InvalidImageException>().having(
          (error) => error.message,
          'message',
          contains('Invalid WebP animation frame flags'),
        ),
      ),
    );
    await expectLater(
      ImagePipeline.fromBytes(bytes).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
  });

  test('rejects animated WebP with top-level image chunks', () async {
    final bytes = animatedVp8lWebpWithTopLevelImageChunk();

    await expectLater(
      ImagePipeline.fromBytes(bytes).metadata(),
      throwsA(isA<InvalidImageException>()),
    );
    await expectLater(
      ImagePipeline.fromBytes(bytes).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
  });

  test('rejects animation frames with mismatched payload dimensions', () async {
    final bytes = animatedVp8lWebpWithMismatchedFramePayload();

    await expectLater(
      ImagePipeline.fromBytes(bytes).metadata(),
      throwsA(isA<InvalidImageException>()),
    );
    await expectLater(
      ImagePipeline.fromBytes(bytes).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
  });

  test('rejects animation frames without image payloads', () async {
    final bytes = animatedVp8Webp(width: 1, height: 1);
    final frameOffset = _chunkOffset(bytes, 'ANMF');
    _writeU32(bytes, frameOffset + 4, 16);

    await expectLater(
      ImagePipeline.fromBytes(bytes).metadata(),
      throwsA(
        isA<InvalidImageException>().having(
          (error) => error.message,
          'message',
          contains('WebP animation frame has no image data'),
        ),
      ),
    );
    await expectLater(
      ImagePipeline.fromBytes(bytes).toPixelImage(),
      throwsA(
        isA<InvalidImageException>().having(
          (error) => error.message,
          'message',
          contains('WebP animation frame has no image data'),
        ),
      ),
    );
  });

  test('rejects animated WebP missing ANIM header', () async {
    final bytes = animatedVp8lWebpWithoutAnimHeader();

    await expectLater(
      ImagePipeline.fromBytes(bytes).metadata(),
      throwsA(isA<InvalidImageException>()),
    );
    await expectLater(
      ImagePipeline.fromBytes(bytes).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
  });

  test('rejects animated WebP missing animation flag', () async {
    final bytes = animatedVp8lWebpWithoutAnimationFlag();

    await expectLater(
      ImagePipeline.fromBytes(bytes).metadata(),
      throwsA(isA<InvalidImageException>()),
    );
    await expectLater(
      ImagePipeline.fromBytes(bytes).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
  });

  test('rejects animated WebP without frames', () async {
    final bytes = animatedVp8lWebpWithoutFrames();

    await expectLater(
      ImagePipeline.fromBytes(bytes).metadata(),
      throwsA(isA<InvalidImageException>()),
    );
    await expectLater(
      ImagePipeline.fromBytes(bytes).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
  });
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
