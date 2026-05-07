import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

import 'helpers/webp_lossy_fixture.dart';

void main() {
  test('decodes a minimal lossy VP8 WebP into RGBA pixels', () async {
    final bytes = solidVp8Webp(width: 2, height: 2);

    final image = await ImagePipeline.fromBytes(bytes).toPixelImage();

    expect(image.width, 2);
    expect(image.height, 2);
    expect(image.channels, ChannelCount.four);
    expect(image.firstFrameBytes(), <int>[
      128,
      128,
      128,
      255,
      128,
      128,
      128,
      255,
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

  test('crops padded VP8 macroblocks to visible WebP dimensions', () async {
    final bytes = solidVp8Webp(width: 17, height: 18);

    final image = await ImagePipeline.fromBytes(bytes).toPixelImage();

    expect(image.width, 17);
    expect(image.height, 18);
    final rgba = image.firstFrameBytes();
    expect(rgba.length, 17 * 18 * 4);
    for (var i = 3; i < rgba.length; i += 4) {
      expect(rgba[i], 255);
    }
  });

  test('decodes an extended VP8X WebP with lossy VP8 payload', () async {
    final bytes = extendedSolidVp8Webp(width: 3, height: 1);

    final image = await ImagePipeline.fromBytes(bytes).toPixelImage();

    expect(image.width, 3);
    expect(image.height, 1);
    expect(image.firstFrameBytes(), <int>[
      128,
      128,
      128,
      255,
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

  test('decodes supported VP8 luma prediction modes', () async {
    final cases = <(int, int)>[(0, 128), (1, 127), (2, 129), (3, 129)];

    for (final (mode, sample) in cases) {
      final image = await ImagePipeline.fromBytes(
        solidVp8Webp(width: 2, height: 2, yMode: mode),
      ).toPixelImage();

      expect(image.firstFrameBytes(), <int>[
        sample,
        sample,
        sample,
        255,
        sample,
        sample,
        sample,
        255,
        sample,
        sample,
        sample,
        255,
        sample,
        sample,
        sample,
        255,
      ], reason: 'mode $mode');
    }
  });

  test('decodes VP8 streams with EOB residual partitions', () async {
    final bytes = eobResidualVp8Webp(width: 2, height: 2, qIndex: 1);

    final image = await ImagePipeline.fromBytes(bytes).toPixelImage();

    expect(image.width, 2);
    expect(image.height, 2);
    expect(image.firstFrameBytes(), <int>[
      128,
      128,
      128,
      255,
      128,
      128,
      128,
      255,
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

  test('rejects VP8 residual coefficient values explicitly', () async {
    final bytes = nonEmptyResidualVp8Webp(width: 2, height: 2);

    await expectLater(
      ImagePipeline.fromBytes(bytes).toPixelImage(),
      throwsA(isA<UnsupportedCodecException>()),
    );
  });

  test('applies supported VP8 chroma DC residuals', () async {
    final bytes = chromaDcResidualVp8Webp(width: 2, height: 2);

    final image = await ImagePipeline.fromBytes(bytes).toPixelImage();

    expect(image.firstFrameBytes(), <int>[
      128,
      128,
      129,
      255,
      128,
      128,
      129,
      255,
      128,
      128,
      129,
      255,
      128,
      128,
      129,
      255,
    ]);
  });
}
