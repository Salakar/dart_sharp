import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

import 'helpers/webp_lossless_fixture.dart';

void main() {
  test('decodes a minimal VP8L WebP into pixels', () async {
    final bytes = solidVp8lWebp(
      width: 3,
      height: 2,
      red: 12,
      green: 34,
      blue: 56,
      alpha: 200,
    );

    final image = await ImagePipeline.fromBytes(bytes).toPixelImage();
    final metadata = await ImagePipeline.fromBytes(bytes).metadata();

    expect(metadata.format, ImageFormat.webp);
    expect(metadata.width, 3);
    expect(metadata.height, 2);
    expect(metadata.hasAlpha, isTrue);
    expect(image.width, 3);
    expect(image.height, 2);
    expect(image.firstFrameBytes(), <int>[
      for (var i = 0; i < 6; i += 1) ...<int>[12, 34, 56, 200],
    ]);
  });

  test('duplicate VP8L transforms fail clearly', () async {
    final bytes = duplicateTransformVp8lWebp();

    await expectLater(
      ImagePipeline.fromBytes(bytes).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
  });

  test('malformed VP8L payloads fail clearly', () async {
    final invalidSignature = solidVp8lWebp(
      width: 1,
      height: 1,
      red: 1,
      green: 2,
      blue: 3,
      alpha: 255,
    );
    invalidSignature[20] = 0;

    await expectLater(
      ImagePipeline.fromBytes(invalidSignature).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );

    final truncated = solidVp8lWebp(
      width: 1,
      height: 1,
      red: 1,
      green: 2,
      blue: 3,
      alpha: 255,
    ).sublist(0, 20);

    await expectLater(
      ImagePipeline.fromBytes(truncated).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );

    final oversizedChunk = solidVp8lWebp(
      width: 1,
      height: 1,
      red: 1,
      green: 2,
      blue: 3,
      alpha: 255,
    );
    oversizedChunk[16] = 0xff;
    oversizedChunk[17] = 0xff;
    oversizedChunk[18] = 0xff;
    oversizedChunk[19] = 0xff;

    await expectLater(
      ImagePipeline.fromBytes(oversizedChunk).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
  });

  test('rejects top-level ALPH chunks with VP8L payloads', () async {
    final bytes = extendedVp8lWebpWithAlphaChunk(
      width: 2,
      height: 1,
      red: 1,
      green: 2,
      blue: 3,
      alpha: 128,
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

  test('decodes simple two-symbol VP8L prefix codes', () async {
    final bytes = twoGreenVp8lWebp(
      width: 4,
      height: 1,
      red: 9,
      firstGreen: 20,
      secondGreen: 200,
      blue: 30,
      alpha: 255,
    );

    final image = await ImagePipeline.fromBytes(bytes).toPixelImage();

    expect(image.firstFrameBytes(), <int>[
      9,
      20,
      30,
      255,
      9,
      200,
      30,
      255,
      9,
      20,
      30,
      255,
      9,
      200,
      30,
      255,
    ]);
  });

  test('decodes VP8L normal prefix codes and backward references', () async {
    final bytes = backrefVp8lWebp(red: 9, green: 20, blue: 30, alpha: 255);

    final image = await ImagePipeline.fromBytes(bytes).toPixelImage();

    expect(image.firstFrameBytes(), <int>[
      for (var i = 0; i < 4; i += 1) ...<int>[9, 20, 30, 255],
    ]);
  });

  test('rejects invalid VP8L backward references', () async {
    for (final bytes in <List<int>>[
      invalidInitialBackrefVp8lWebp(),
      invalidOverrunBackrefVp8lWebp(),
    ]) {
      await expectLater(
        ImagePipeline.fromBytes(bytes).toPixelImage(),
        throwsA(
          isA<InvalidImageException>().having(
            (error) => error.message,
            'message',
            contains('Invalid VP8L backward reference'),
          ),
        ),
      );
    }
  });

  test('decodes VP8L color-cache codes', () async {
    final bytes = colorCacheVp8lWebp(red: 91, green: 20, blue: 33, alpha: 244);

    final image = await ImagePipeline.fromBytes(bytes).toPixelImage();

    expect(image.firstFrameBytes(), <int>[91, 20, 33, 244, 91, 20, 33, 244]);
  });

  test('rejects invalid VP8L color-cache sizes', () async {
    await expectLater(
      ImagePipeline.fromBytes(invalidColorCacheSizeVp8lWebp()).toPixelImage(),
      throwsA(
        isA<InvalidImageException>().having(
          (error) => error.message,
          'message',
          contains('Invalid VP8L color cache size'),
        ),
      ),
    );
  });

  test('rejects invalid VP8L prefix symbols', () async {
    await expectLater(
      ImagePipeline.fromBytes(
        invalidDistancePrefixSymbolVp8lWebp(),
      ).toPixelImage(),
      throwsA(
        isA<InvalidImageException>().having(
          (error) => error.message,
          'message',
          contains('Invalid VP8L prefix symbol'),
        ),
      ),
    );
  });

  test('rejects invalid VP8L code length repeats', () async {
    await expectLater(
      ImagePipeline.fromBytes(invalidCodeLengthRepeatVp8lWebp()).toPixelImage(),
      throwsA(
        isA<InvalidImageException>().having(
          (error) => error.message,
          'message',
          contains('Invalid VP8L code length repeat'),
        ),
      ),
    );
  });

  test('rejects empty VP8L prefix codes', () async {
    await expectLater(
      ImagePipeline.fromBytes(invalidEmptyPrefixCodeVp8lWebp()).toPixelImage(),
      throwsA(
        isA<InvalidImageException>().having(
          (error) => error.message,
          'message',
          contains('Invalid empty VP8L prefix code'),
        ),
      ),
    );
  });

  test('rejects invalid VP8L prefix symbol counts', () async {
    await expectLater(
      ImagePipeline.fromBytes(
        invalidPrefixSymbolCountVp8lWebp(),
      ).toPixelImage(),
      throwsA(
        isA<InvalidImageException>().having(
          (error) => error.message,
          'message',
          contains('Invalid VP8L prefix symbol count'),
        ),
      ),
    );
  });

  test('rejects invalid VP8L prefix codes', () async {
    await expectLater(
      ImagePipeline.fromBytes(invalidPrefixCodeVp8lWebp()).toPixelImage(),
      throwsA(
        isA<InvalidImageException>().having(
          (error) => error.message,
          'message',
          contains('Invalid VP8L prefix code'),
        ),
      ),
    );
  });

  test('decodes the VP8L subtract-green transform', () async {
    final bytes = subtractGreenVp8lWebp(
      width: 2,
      height: 1,
      red: 250,
      green: 20,
      blue: 10,
      alpha: 255,
    );

    final image = await ImagePipeline.fromBytes(bytes).toPixelImage();

    expect(image.firstFrameBytes(), <int>[
      for (var i = 0; i < 2; i += 1) ...<int>[250, 20, 10, 255],
    ]);
  });

  test('decodes the VP8L color transform', () async {
    final bytes = colorTransformVp8lWebp(
      width: 2,
      height: 1,
      red: 100,
      green: 64,
      blue: 180,
      alpha: 255,
      greenToRed: 32,
      greenToBlue: 64,
      redToBlue: 16,
    );

    final image = await ImagePipeline.fromBytes(bytes).toPixelImage();

    expect(image.firstFrameBytes(), <int>[
      for (var i = 0; i < 2; i += 1) ...<int>[100, 64, 180, 255],
    ]);
  });

  test('decodes composed VP8L color and subtract-green transforms', () async {
    final bytes = colorAndSubtractGreenVp8lWebp(
      width: 2,
      height: 1,
      red: 181,
      green: 73,
      blue: 29,
      alpha: 244,
      greenToRed: 48,
      greenToBlue: 224,
      redToBlue: 24,
    );

    final image = await ImagePipeline.fromBytes(bytes).toPixelImage();

    expect(image.firstFrameBytes(), <int>[
      for (var i = 0; i < 2; i += 1) ...<int>[181, 73, 29, 244],
    ]);
  });

  test('decodes the VP8L predictor transform', () async {
    final bytes = predictorVp8lWebp();

    final image = await ImagePipeline.fromBytes(bytes).toPixelImage();

    expect(image.firstFrameBytes(), <int>[
      10,
      20,
      30,
      255,
      20,
      40,
      60,
      255,
      20,
      40,
      60,
      255,
      30,
      60,
      90,
      255,
    ]);
  });

  test('rejects invalid VP8L predictor modes', () async {
    await expectLater(
      ImagePipeline.fromBytes(invalidPredictorModeVp8lWebp()).toPixelImage(),
      throwsA(
        isA<InvalidImageException>().having(
          (error) => error.message,
          'message',
          contains('Invalid VP8L predictor mode'),
        ),
      ),
    );
  });

  test('decodes an unpacked VP8L color-indexing transform', () async {
    final bytes = colorIndexingVp8lWebp(
      width: 2,
      height: 1,
      red: 80,
      green: 90,
      blue: 100,
      alpha: 255,
    );

    final image = await ImagePipeline.fromBytes(bytes).toPixelImage();

    expect(image.firstFrameBytes(), <int>[80, 90, 100, 255, 80, 90, 100, 255]);
  });

  test('decodes a packed VP8L color-indexing transform', () async {
    final bytes = packedColorIndexingVp8lWebp();

    final image = await ImagePipeline.fromBytes(bytes).toPixelImage();

    expect(image.firstFrameBytes(), <int>[
      20,
      40,
      60,
      255,
      200,
      80,
      10,
      255,
      20,
      40,
      60,
      255,
      200,
      80,
      10,
      255,
    ]);
  });
}
