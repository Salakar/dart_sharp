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

  test('unsupported VP8L transforms fail clearly', () async {
    final bytes = solidVp8lWebp(
      width: 1,
      height: 1,
      red: 1,
      green: 2,
      blue: 3,
      alpha: 255,
    );
    bytes[25] |= 1 << 0;

    await expectLater(
      ImagePipeline.fromBytes(bytes).toPixelImage(),
      throwsA(isA<UnsupportedCodecException>()),
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

  test('decodes VP8L color-cache codes', () async {
    final bytes = colorCacheVp8lWebp(red: 91, green: 20, blue: 33, alpha: 244);

    final image = await ImagePipeline.fromBytes(bytes).toPixelImage();

    expect(image.firstFrameBytes(), <int>[91, 20, 33, 244, 91, 20, 33, 244]);
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
}
