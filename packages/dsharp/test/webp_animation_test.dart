import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

import 'helpers/webp_lossless_fixture.dart';

void main() {
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
}
