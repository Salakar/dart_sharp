import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

import 'helpers/webp_lossy_fixture.dart';

void main() {
  test('applies VP8 key-frame display scale bits', () async {
    final bytes = solidVp8Webp(width: 4, height: 3);
    _setVp8Scale(bytes, horizontal: 1, vertical: 2);

    final metadata = await ImagePipeline.fromBytes(bytes).metadata();
    final image = await ImagePipeline.fromBytes(bytes).toPixelImage();

    expect(metadata.width, 5);
    expect(metadata.height, 5);
    expect(image.width, 5);
    expect(image.height, 5);
    expect(image.firstFrameBytes(), hasLength(5 * 5 * 4));
    for (var offset = 0; offset < image.firstFrameBytes().length; offset += 4) {
      expect(image.firstFrameBytes().sublist(offset, offset + 4), <int>[
        128,
        128,
        128,
        255,
      ]);
    }
  });
}

void _setVp8Scale(
  Uint8List webp, {
  required int horizontal,
  required int vertical,
}) {
  webp[27] = (webp[27] & 0x3f) | (horizontal << 6);
  webp[29] = (webp[29] & 0x3f) | (vertical << 6);
}
