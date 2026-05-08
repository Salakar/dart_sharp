import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

import 'pipeline_test_helpers.dart';

void main() {
  test('ensureAlpha handles grayscale and RGB inputs', () async {
    final gray = await pixels(
      ImagePipeline.fromRawPixels(rawGray(1, 1, <int>[9])).ensureAlpha(),
    );
    final rgb = await pixels(
      ImagePipeline.fromRawPixels(
        rawRgb(1, 1, <int>[1, 2, 3]),
      ).ensureAlpha(0.5),
    );

    expect(firstBytes(gray), <int>[9, 9, 9, 255]);
    expect(firstBytes(rgb), <int>[1, 2, 3, 128]);
    expect(
      () => ImagePipeline.fromRawPixels(
        rawRgb(1, 1, <int>[1, 2, 3]),
      ).ensureAlpha(1.1),
      throwsA(isA<OperationValidationException>()),
    );
    expect(
      () => ImagePipeline.fromRawPixels(
        rawRgb(1, 1, <int>[1, 2, 3]),
      ).ensureAlpha(-0.1),
      throwsA(isA<OperationValidationException>()),
    );
    expect(
      () => ImagePipeline.fromRawPixels(
        rawRgb(1, 1, <int>[1, 2, 3]),
      ).ensureAlpha(double.nan),
      throwsA(isA<OperationValidationException>()),
    );
  });

  test('removeAlpha and flatten handle RGBA alpha', () async {
    final removed = await pixels(
      ImagePipeline.fromRawPixels(
        rawRgba(1, 1, <int>[1, 2, 3, 4]),
      ).removeAlpha(),
    );
    final flattened = await pixels(
      ImagePipeline.fromRawPixels(
        rawRgba(1, 1, <int>[100, 0, 0, 128]),
      ).flatten(const RgbaColor(red: 0, green: 0, blue: 100)),
    );
    final flattenedDefault = await pixels(
      ImagePipeline.fromRawPixels(
        rawRgba(1, 1, <int>[100, 0, 0, 128]),
      ).flatten(true),
    );
    final flattenDisabled = await pixels(
      ImagePipeline.fromRawPixels(
        rawRgba(1, 1, <int>[100, 0, 0, 128]),
      ).flatten(false),
    );

    expect(removed.channels, ChannelCount.three);
    expect(firstBytes(removed), <int>[1, 2, 3]);
    expect(firstBytes(flattened), <int>[50, 0, 50]);
    expect(firstBytes(flattenedDefault), <int>[50, 0, 0]);
    expect(firstBytes(flattenDisabled), <int>[100, 0, 0, 128]);
    expect(
      ImagePipeline.fromRawPixels(
        rawRgba(1, 1, <int>[100, 0, 0, 128]),
      ).flatten(false).operations,
      isEmpty,
    );
    expect(
      () => ImagePipeline.fromRawPixels(
        rawRgba(1, 1, <int>[100, 0, 0, 128]),
      ).flatten('black'),
      throwsA(isA<OperationValidationException>()),
    );
  });

  test(
    'unflatten makes white transparent and preserves non-white pixels',
    () async {
      final image = await pixels(
        ImagePipeline.fromRawPixels(
          rawRgb(2, 1, <int>[255, 255, 255, 10, 20, 30]),
        ).unflatten(),
      );

      expect(image.channels, ChannelCount.four);
      expect(firstBytes(image), <int>[255, 255, 255, 0, 10, 20, 30, 255]);
    },
  );

  test('premultiply and unpremultiply round trip straight alpha', () async {
    final premultiplied = await pixels(
      ImagePipeline.fromRawPixels(
        rawRgba(1, 1, <int>[128, 64, 32, 128]),
      ).premultiplyAlpha(),
    );
    final restored = await pixels(
      ImagePipeline.fromRawPixels(
        premultiplied.firstFrame.pixels,
      ).unpremultiplyAlpha(),
    );

    expect(firstBytes(premultiplied), <int>[64, 32, 16, 128]);
    expect(firstBytes(restored), <int>[128, 64, 32, 128]);
  });

  test('extractChannel accepts indexes and names', () async {
    final raw = rawRgba(1, 1, <int>[1, 2, 3, 4]);
    final byIndex = await pixels(
      ImagePipeline.fromRawPixels(raw).extractChannel(2),
    );
    final byName = await pixels(
      ImagePipeline.fromRawPixels(raw).extractChannel('alpha'),
    );
    final byEnum = await pixels(
      ImagePipeline.fromRawPixels(raw).extractChannel(ImageChannel.green),
    );

    expect(firstBytes(byIndex), <int>[3]);
    expect(firstBytes(byName), <int>[4]);
    expect(firstBytes(byEnum), <int>[2]);
  });

  test('joinChannel appends one-channel images and validates inputs', () async {
    final joined = await pixels(
      ImagePipeline.fromRawPixels(
        rawRgb(1, 1, <int>[1, 2, 3]),
      ).joinChannel(PixelImage.fromRawPixels(rawGray(1, 1, <int>[9]))),
    );

    expect(firstBytes(joined), <int>[1, 2, 3, 9]);
    expect(
      ImagePipeline.fromRawPixels(rawRgb(1, 1, <int>[1, 2, 3]))
          .joinChannel(PixelImage.fromRawPixels(rawGray(2, 1, <int>[1, 2])))
          .toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
    expect(
      ImagePipeline.fromRawPixels(rawRgb(1, 1, <int>[1, 2, 3]))
          .joinChannel(PixelImage.fromRawPixels(rawRgb(1, 1, <int>[1, 2, 3])))
          .toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
  });
}
