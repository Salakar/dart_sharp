import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

import 'helpers/webp_lossless_fixture.dart';
import 'helpers/webp_lossy_fixture.dart';

void main() {
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
