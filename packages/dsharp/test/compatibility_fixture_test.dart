import 'dart:io';

import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

void main() {
  test(
    'optional upstream fixture harness reads ignored fixtures when present',
    () async {
      final fixture = File('../../sharp_clone/test/fixtures/2x2_fdcce6.png');
      if (!fixture.existsSync()) {
        markTestSkipped('sharp_clone fixtures are not present.');
        return;
      }

      final bytes = await fixture.readAsBytes();
      final metadata = await ImagePipeline.fromBytes(bytes).metadata();
      final image = await ImagePipeline.fromBytes(bytes).toPixelImage();

      expect(metadata.format, ImageFormat.png);
      expect(metadata.width, 2);
      expect(metadata.height, 2);
      expect(image.width, 2);
      expect(image.height, 2);
      expect(image.firstFrameBytes().length, 16);
    },
  );
}
