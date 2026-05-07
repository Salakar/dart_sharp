import 'dart:math';

import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

import 'helpers/generated_fixtures.dart';

void main() {
  test('random resize dimensions stay within requested bounds', () {
    final random = Random(42);
    for (var i = 0; i < 50; i += 1) {
      final sourceWidth = 1 + random.nextInt(200);
      final sourceHeight = 1 + random.nextInt(200);
      final width = 1 + random.nextInt(100);
      final height = 1 + random.nextInt(100);
      final resolved = resolveResize(
        sourceWidth: sourceWidth,
        sourceHeight: sourceHeight,
        options: ResizeOptions(
          width: width,
          height: height,
          fit: ResizeFit.inside,
        ),
      );

      expect(resolved.width, inInclusiveRange(1, width));
      expect(resolved.height, inInclusiveRange(1, height));
    }
  });

  test('pixel operations keep channel samples in byte range', () async {
    for (var seed = 0; seed < 20; seed += 1) {
      final raw = RawPixels(
        bytes: GeneratedFixtures.rawBuffer(4 * 4 * 4, seed: seed),
        width: 4,
        height: 4,
        channels: ChannelCount.four,
      );
      final image = await ImagePipeline.fromRawPixels(raw)
          .blur()
          .normalize()
          .modulate(brightness: 1.2, saturation: 0.8, hue: 30)
          .toPixelImage();

      for (final value in image.firstFrameBytes()) {
        expect(value, inInclusiveRange(0, 255));
      }
    }
  });

  test('idempotent operations remain stable', () async {
    final once = await ImagePipeline.fromRawPixels(
      GeneratedFixtures.alphaGrid(),
    ).removeAlpha().removeAlpha().toPixelImage();
    final twice = await ImagePipeline.fromRawPixels(
      GeneratedFixtures.alphaGrid(),
    ).removeAlpha().toPixelImage();

    expect(once.firstFrameBytes(), twice.firstFrameBytes());
  });
}
