import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

import 'pipeline_test_helpers.dart';

void main() {
  test('ensureAlpha handles grayscale and RGB inputs', () async {
    final gray = await pixels(
      ImagePipeline.fromRawPixels(rawGray(1, 1, <int>[9])).ensureAlpha(7),
    );
    final rgb = await pixels(
      ImagePipeline.fromRawPixels(
        rawRgb(1, 1, <int>[1, 2, 3]),
      ).ensureAlpha(128),
    );

    expect(firstBytes(gray), <int>[9, 9, 9, 7]);
    expect(firstBytes(rgb), <int>[1, 2, 3, 128]);
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

    expect(removed.channels, ChannelCount.three);
    expect(firstBytes(removed), <int>[1, 2, 3]);
    expect(firstBytes(flattened), <int>[50, 0, 50]);
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
