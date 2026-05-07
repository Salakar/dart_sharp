import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

import 'helpers/webp_lossy_fixture.dart';

void main() {
  test('applies supported VP8 luma AC residuals', () async {
    final bytes = lumaAcResidualVp8Webp(width: 4, height: 4);

    final image = await ImagePipeline.fromBytes(bytes).toPixelImage();
    final rgba = image.firstFrameBytes();

    expect(rgba.take(4), <int>[129, 129, 129, 255]);
    expect(
      [for (var i = 0; i < 4; i++) rgba[i * 4]],
      <int>[129, 128, 128, 127],
    );
    expect(
      [for (var i = 0; i < 4; i++) rgba[16 + i * 4]],
      <int>[129, 128, 128, 127],
    );
  });
}
