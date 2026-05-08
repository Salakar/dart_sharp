import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

import 'helpers/webp_lossless_fixture.dart';
import 'helpers/webp_lossy_fixture.dart';

void main() {
  test('rejects VP8 WebP with invalid frame tag fields', () async {
    final nonKeyFrame = solidVp8Webp(width: 1, height: 1);
    nonKeyFrame[20] |= 1;
    final hiddenKeyFrame = solidVp8Webp(width: 1, height: 1);
    hiddenKeyFrame[20] &= 0xef;
    final oversizedFirstPartition = solidVp8Webp(width: 1, height: 1);
    oversizedFirstPartition[20] |= 0xe0;
    oversizedFirstPartition[21] = 0xff;
    oversizedFirstPartition[22] = 0x7f;

    final cases = <(Uint8List, Matcher)>[
      (nonKeyFrame, isA<UnsupportedCodecException>()),
      (hiddenKeyFrame, isA<InvalidImageException>()),
      (oversizedFirstPartition, isA<InvalidImageException>()),
    ];

    for (final (bytes, matcher) in cases) {
      await expectLater(
        ImagePipeline.fromBytes(bytes).metadata(),
        throwsA(matcher),
      );
      await expectLater(
        ImagePipeline.fromBytes(bytes).toPixelImage(),
        throwsA(matcher),
      );
    }
  });

  test('rejects VP8 WebP with zero frame dimensions', () async {
    for (final zeroWidth in <bool>[true, false]) {
      final bytes = solidVp8Webp(width: 1, height: 1);
      final offset = zeroWidth ? 26 : 28;
      bytes[offset] = 0;
      bytes[offset + 1] = 0;

      await expectLater(
        ImagePipeline.fromBytes(bytes).metadata(),
        throwsA(isA<InvalidImageException>()),
      );
      await expectLater(
        ImagePipeline.fromBytes(bytes).toPixelImage(),
        throwsA(isA<InvalidImageException>()),
      );
    }
  });

  test('rejects static ALPH chunks after VP8 image data', () async {
    final ordered = alphaSolidVp8Webp(width: 1, height: 1, alpha: <int>[127]);
    final reordered = Uint8List.fromList(<int>[
      ...ordered.sublist(0, 30),
      ...ordered.sublist(40),
      ...ordered.sublist(30, 40),
    ]);

    await expectLater(
      ImagePipeline.fromBytes(reordered).metadata(),
      throwsA(isA<InvalidImageException>()),
    );
    await expectLater(
      ImagePipeline.fromBytes(reordered).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
  });

  test('rejects animation frame ALPH chunks after VP8 image data', () async {
    final ordered = animatedVp8Webp(width: 1, height: 1, alpha: <int>[127]);
    final reordered = Uint8List.fromList(<int>[
      ...ordered.sublist(0, 68),
      ...ordered.sublist(78),
      ...ordered.sublist(68, 78),
    ]);

    await expectLater(
      ImagePipeline.fromBytes(reordered).metadata(),
      throwsA(isA<InvalidImageException>()),
    );
    await expectLater(
      ImagePipeline.fromBytes(reordered).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
  });

  test('rejects VP8X chunks that are not first', () async {
    final imageBeforeVp8x = extendedSolidVp8Webp(width: 1, height: 1);
    final alphaBeforeVp8x = alphaSolidVp8Webp(
      width: 1,
      height: 1,
      alpha: <int>[127],
    );
    final cases = <Uint8List>[
      Uint8List.fromList(<int>[
        ...imageBeforeVp8x.sublist(0, 12),
        ...imageBeforeVp8x.sublist(30),
        ...imageBeforeVp8x.sublist(12, 30),
      ]),
      Uint8List.fromList(<int>[
        ...alphaBeforeVp8x.sublist(0, 12),
        ...alphaBeforeVp8x.sublist(30, 40),
        ...alphaBeforeVp8x.sublist(12, 30),
        ...alphaBeforeVp8x.sublist(40),
      ]),
    ];

    for (final bytes in cases) {
      await expectLater(
        ImagePipeline.fromBytes(bytes).metadata(),
        throwsA(isA<InvalidImageException>()),
      );
      await expectLater(
        ImagePipeline.fromBytes(bytes).toPixelImage(),
        throwsA(isA<InvalidImageException>()),
      );
    }
  });

  test('rejects animation frames before ANIM header', () async {
    final ordered = animatedVp8Webp(width: 1, height: 1);
    final reordered = Uint8List.fromList(<int>[
      ...ordered.sublist(0, 30),
      ...ordered.sublist(44),
      ...ordered.sublist(30, 44),
    ]);

    await expectLater(
      ImagePipeline.fromBytes(reordered).metadata(),
      throwsA(isA<InvalidImageException>()),
    );
    await expectLater(
      ImagePipeline.fromBytes(reordered).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
  });

  test('rejects extended VP8 WebP with mismatched canvas dimensions', () async {
    final bytes = extendedSolidVp8Webp(width: 1, height: 1);
    bytes[24] = 1;

    await expectLater(
      ImagePipeline.fromBytes(bytes).metadata(),
      throwsA(isA<InvalidImageException>()),
    );
    await expectLater(
      ImagePipeline.fromBytes(bytes).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
  });

  test(
    'rejects extended VP8L WebP with mismatched canvas dimensions',
    () async {
      final bytes = extendedVp8lWebp(
        width: 1,
        height: 1,
        red: 1,
        green: 2,
        blue: 3,
        alpha: 255,
      );
      bytes[27] = 1;

      await expectLater(
        ImagePipeline.fromBytes(bytes).metadata(),
        throwsA(isA<InvalidImageException>()),
      );
      await expectLater(
        ImagePipeline.fromBytes(bytes).toPixelImage(),
        throwsA(isA<InvalidImageException>()),
      );
    },
  );
}
