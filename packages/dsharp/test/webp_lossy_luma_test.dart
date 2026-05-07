import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

import 'helpers/webp_lossy_fixture.dart';

void main() {
  test('applies supported VP8 luma AC residual magnitudes', () async {
    final cases = <(int, List<int>)>[
      (1, <int>[129, 128, 128, 127]),
      (2, <int>[129, 129, 128, 127]),
      (3, <int>[130, 129, 127, 126]),
      (4, <int>[131, 129, 127, 126]),
    ];

    for (final (coefficient, row) in cases) {
      final bytes = lumaAcResidualVp8Webp(
        width: 4,
        height: 4,
        coefficient: coefficient,
      );

      final image = await ImagePipeline.fromBytes(bytes).toPixelImage();
      final rgba = image.firstFrameBytes();

      expect(
        [for (var i = 0; i < 4; i++) rgba[i * 4]],
        row,
        reason: 'coefficient $coefficient row 0',
      );
      expect(
        [for (var i = 0; i < 4; i++) rgba[16 + i * 4]],
        row,
        reason: 'coefficient $coefficient row 1',
      );
    }
  });
}
