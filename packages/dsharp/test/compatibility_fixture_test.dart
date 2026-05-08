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

  test('optional upstream JPEG fixture decodes when present', () async {
    final fixture = File('../../sharp_clone/test/fixtures/320x240.jpg');
    if (!fixture.existsSync()) {
      markTestSkipped('sharp_clone fixtures are not present.');
      return;
    }

    final image = await ImagePipeline.fromBytes(
      await fixture.readAsBytes(),
    ).toPixelImage();

    expect(image.width, 320);
    expect(image.height, 240);
    expect(image.firstFrameBytes().length, 320 * 240 * 4);
  });

  test('optional upstream WebP fixture exposes metadata', () async {
    final fixture = File('../../sharp_clone/test/fixtures/4.webp');
    if (!fixture.existsSync()) {
      markTestSkipped('sharp_clone fixtures are not present.');
      return;
    }

    final metadata = await ImagePipeline.fromBytes(
      await fixture.readAsBytes(),
    ).metadata();

    expect(metadata.format, ImageFormat.webp);
    expect(metadata.width, 1024);
    expect(metadata.height, 772);
    expect(metadata.hasAlpha, isFalse);
  });

  test('optional upstream alpha WebP fixture exposes alpha metadata', () async {
    final fixture = File('../../sharp_clone/test/fixtures/5_webp_a.webp');
    if (!fixture.existsSync()) {
      markTestSkipped('sharp_clone fixtures are not present.');
      return;
    }

    final metadata = await ImagePipeline.fromBytes(
      await fixture.readAsBytes(),
    ).metadata();

    expect(metadata.format, ImageFormat.webp);
    expect(metadata.width, 300);
    expect(metadata.height, 300);
    expect(metadata.hasAlpha, isTrue);
  });

  test('optional upstream alpha WebP fixture decodes pixels', () async {
    final fixture = File('../../sharp_clone/test/fixtures/5_webp_a.webp');
    if (!fixture.existsSync()) {
      markTestSkipped('sharp_clone fixtures are not present.');
      return;
    }

    final image = await ImagePipeline.fromBytes(
      await fixture.readAsBytes(),
    ).toPixelImage();
    final rgba = image.firstFrameBytes();

    expect(image.width, 300);
    expect(image.height, 300);
    expect(rgba.length, 300 * 300 * 4);
    expect(
      [
        for (var i = 3; i < rgba.length; i += 4) rgba[i],
      ].any((alpha) => alpha < 255),
      isTrue,
    );
  });

  test(
    'optional upstream animated WebP fixture exposes frame metadata',
    () async {
      final fixture = File(
        '../../sharp_clone/test/fixtures/animated-loop-3.webp',
      );
      if (!fixture.existsSync()) {
        markTestSkipped('sharp_clone fixtures are not present.');
        return;
      }

      final metadata = await ImagePipeline.fromBytes(
        await fixture.readAsBytes(),
      ).metadata();

      expect(metadata.format, ImageFormat.webp);
      expect(metadata.width, 370);
      expect(metadata.height, 285);
      expect(metadata.frames, greaterThan(1));
    },
  );

  test('optional upstream animated WebP fixture decodes frames', () async {
    final fixture = File(
      '../../sharp_clone/test/fixtures/animated-loop-3.webp',
    );
    if (!fixture.existsSync()) {
      markTestSkipped('sharp_clone fixtures are not present.');
      return;
    }

    final image = await ImagePipeline.fromBytes(
      await fixture.readAsBytes(),
    ).toPixelImage();

    expect(image.width, 370);
    expect(image.height, 285);
    expect(image.isAnimated, isTrue);
    expect(image.frames.length, greaterThan(1));
    expect(image.frames.first.pixels.bytes.length, 370 * 285 * 4);
  });

  test('optional upstream WebP fixture decodes pixels when present', () async {
    final fixture = File('../../sharp_clone/test/fixtures/4.webp');
    if (!fixture.existsSync()) {
      markTestSkipped('sharp_clone fixtures are not present.');
      return;
    }

    final image = await ImagePipeline.fromBytes(
      await fixture.readAsBytes(),
    ).toPixelImage();

    expect(image.width, 1024);
    expect(image.height, 772);
    expect(image.firstFrameBytes().length, 1024 * 772 * 4);
  });
}
