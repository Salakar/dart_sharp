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

  test(
    'rejects unsupported VP8 chroma DC coefficient runs explicitly',
    () async {
      final bytes = unsupportedChromaDcRunVp8Webp(width: 2, height: 2);

      await expectLater(
        ImagePipeline.fromBytes(bytes).toPixelImage(),
        throwsA(isA<UnsupportedCodecException>()),
      );
    },
  );

  test('applies supported VP8 chroma DC residuals', () async {
    final bytes = chromaDcResidualVp8Webp(width: 2, height: 2, qIndex: 12);

    final image = await ImagePipeline.fromBytes(bytes).toPixelImage();

    expect(image.firstFrameBytes(), <int>[
      128,
      128,
      131,
      255,
      128,
      128,
      131,
      255,
      128,
      128,
      131,
      255,
      128,
      128,
      131,
      255,
    ]);
  });

  test('caps supported VP8 chroma DC residual quantizers', () async {
    final bytes = chromaDcResidualVp8Webp(width: 2, height: 2, qIndex: 127);

    final image = await ImagePipeline.fromBytes(bytes).toPixelImage();

    expect(image.firstFrameBytes().take(4), <int>[128, 123, 158, 255]);
  });

  test('applies supported VP8 chroma DC token magnitudes and signs', () async {
    final cases = <(int, List<int>)>[
      (2, <int>[128, 128, 129, 255]),
      (3, <int>[128, 128, 131, 255]),
      (4, <int>[128, 128, 131, 255]),
      (5, <int>[128, 127, 133, 255]),
      (6, <int>[128, 127, 133, 255]),
      (7, <int>[128, 127, 135, 255]),
      (8, <int>[128, 127, 135, 255]),
      (9, <int>[128, 127, 136, 255]),
      (10, <int>[128, 127, 136, 255]),
      (11, <int>[128, 126, 138, 255]),
      (18, <int>[128, 125, 143, 255]),
      (19, <int>[128, 125, 145, 255]),
      (34, <int>[128, 123, 158, 255]),
      (35, <int>[128, 122, 159, 255]),
      (66, <int>[128, 117, 186, 255]),
      (67, <int>[128, 117, 188, 255]),
      (2048, <int>[128, 85, 255, 255]),
      (-4, <int>[128, 129, 124, 255]),
    ];

    for (final (coefficient, rgba) in cases) {
      final bytes = chromaDcResidualVp8Webp(
        width: 2,
        height: 2,
        coefficient: coefficient,
      );

      final image = await ImagePipeline.fromBytes(bytes).toPixelImage();

      expect(
        image.firstFrameBytes().take(4),
        rgba,
        reason: 'coefficient $coefficient',
      );
    }
  });
}
