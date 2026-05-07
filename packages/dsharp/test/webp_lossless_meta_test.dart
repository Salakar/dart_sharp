import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

import 'helpers/webp_lossless_fixture.dart';

void main() {
  test('decodes VP8L meta-prefix image with one prefix group', () async {
    final bytes = metaPrefixVp8lWebp(
      width: 3,
      height: 2,
      red: 70,
      green: 80,
      blue: 90,
      alpha: 255,
    );

    final image = await ImagePipeline.fromBytes(bytes).toPixelImage();

    expect(image.width, 3);
    expect(image.height, 2);
    expect(image.firstFrameBytes(), <int>[
      for (var i = 0; i < 6; i += 1) ...<int>[70, 80, 90, 255],
    ]);
  });

  test('decodes VP8L meta-prefix image with multiple groups', () async {
    final bytes = twoGroupMetaPrefixVp8lWebp();

    final image = await ImagePipeline.fromBytes(bytes).toPixelImage();

    expect(image.width, 5);
    expect(image.height, 1);
    expect(image.firstFrameBytes(), <int>[
      for (var i = 0; i < 4; i += 1) ...<int>[10, 20, 30, 255],
      200,
      150,
      100,
      255,
    ]);
  });
}
