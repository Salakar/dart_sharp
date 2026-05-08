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

    final bytes = await fixture.readAsBytes();
    final image = await ImagePipeline.fromBytes(bytes).toPixelImage();
    final rgba = image.firstFrameBytes();

    expect(image.width, 320);
    expect(image.height, 240);
    expect(rgba.length, 320 * 240 * 4);
    expect(rgba.sublist(0, 4), <int>[66, 62, 63, 255]);
    expect(rgba.sublist(319 * 4, 320 * 4), <int>[42, 40, 41, 255]);
    expect(rgba.sublist(76799 * 4, 76800 * 4), <int>[17, 15, 16, 255]);
  });

  test('optional upstream restart JPEG fixture decodes pixels', () async {
    final fixture = File('../../sharp_clone/test/fixtures/Landscape_9.jpg');
    if (!fixture.existsSync()) {
      markTestSkipped('sharp_clone fixtures are not present.');
      return;
    }

    final bytes = await fixture.readAsBytes();
    final image = await ImagePipeline.fromBytes(bytes).toPixelImage();
    final rgba = image.firstFrameBytes();

    expect(_jpegMarkerCount(bytes, 0xdd), greaterThan(0));
    expect(_jpegRestartMarkerCount(bytes), greaterThan(0));
    expect(image.width, 480);
    expect(image.height, 369);
    expect(rgba.length, 480 * 369 * 4);
    expect(rgba.sublist(0, 4), <int>[125, 172, 200, 255]);
    expect(rgba.sublist(479 * 4, 480 * 4), <int>[119, 168, 198, 255]);
    expect(rgba.sublist(177119 * 4, 177120 * 4), <int>[40, 91, 108, 255]);
  });

  test('optional upstream Adobe YCCK JPEG fixture decodes pixels', () async {
    final fixture = File(
      '../../sharp_clone/test/fixtures/'
      'Channel_digital_image_CMYK_color_no_profile.jpg',
    );
    if (!fixture.existsSync()) {
      markTestSkipped('sharp_clone fixtures are not present.');
      return;
    }

    final bytes = await fixture.readAsBytes();
    final image = await ImagePipeline.fromBytes(bytes).toPixelImage();
    final rgba = image.firstFrameBytes();

    expect(_jpegAdobeTransform(bytes), 2);
    expect(image.width, 500);
    expect(image.height, 333);
    expect(rgba.length, 500 * 333 * 4);
    expect(rgba.sublist(0, 4), <int>[200, 228, 255, 255]);
    expect(rgba.sublist(499 * 4, 500 * 4), <int>[53, 77, 77, 255]);
    expect(rgba.sublist(166499 * 4, 166500 * 4), <int>[35, 55, 15, 255]);
  });

  test('optional upstream CIELab TIFF fixture decodes pixels', () async {
    final fixture = File('../../sharp_clone/test/fixtures/cielab-dagams.tiff');
    if (!fixture.existsSync()) {
      markTestSkipped('sharp_clone fixtures are not present.');
      return;
    }

    final bytes = await fixture.readAsBytes();
    final metadata = await ImagePipeline.fromBytes(bytes).metadata();
    final image = await ImagePipeline.fromBytes(bytes).toPixelImage();

    expect(metadata.format, ImageFormat.tiff);
    expect(metadata.width, 400);
    expect(metadata.height, 266);
    expect(image.width, 400);
    expect(image.height, 266);
    expect(image.firstFrameBytes().length, 400 * 266 * 4);
  });

  test('optional upstream JPEG-compressed CMYK TIFF fixture decodes', () async {
    final fixture = File(
      '../../sharp_clone/test/fixtures/fogra-0-100-100-0.tif',
    );
    if (!fixture.existsSync()) {
      markTestSkipped('sharp_clone fixtures are not present.');
      return;
    }

    final image = await ImagePipeline.fromBytes(
      await fixture.readAsBytes(),
    ).toPixelImage();

    expect(image.width, 1000);
    expect(image.height, 1000);
    expect(image.firstFrameBytes().length, 1000 * 1000 * 4);
    expect(image.firstFrameBytes().sublist(0, 4), <int>[255, 0, 0, 255]);
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
    _expectPixelNear(rgba, image.width, 150, 150, <int>[
      0,
      0,
      0,
      51,
    ], tolerance: 24);
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
      expect(metadata.loopCount, 3);
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
    expect(image.loopCount, 3);
    expect(image.frames.first.pixels.bytes.length, 370 * 285 * 4);
  });

  test(
    'optional upstream offset alpha WebP animation decodes frames',
    () async {
      final fixture = File(
        '../../sharp_clone/test/fixtures/rotating-squares.webp',
      );
      if (!fixture.existsSync()) {
        markTestSkipped('sharp_clone fixtures are not present.');
        return;
      }

      final bytes = await fixture.readAsBytes();
      final metadata = await ImagePipeline.fromBytes(bytes).metadata();
      final image = await ImagePipeline.fromBytes(bytes).toPixelImage();
      final rgba = image.firstFrameBytes();

      expect(metadata.format, ImageFormat.webp);
      expect(metadata.width, 80);
      expect(metadata.height, 80);
      expect(metadata.hasAlpha, isTrue);
      expect(metadata.frames, greaterThan(1));
      expect(image.isAnimated, isTrue);
      expect(image.frames.length, metadata.frames);
      expect(rgba.length, 80 * 80 * 4);
      expect(
        [
          for (var i = 3; i < rgba.length; i += 4) rgba[i],
        ].any((alpha) => alpha < 255),
        isTrue,
      );
    },
  );

  test('optional upstream tall WebP animation decodes frames', () async {
    final fixture = File('../../sharp_clone/test/fixtures/big-height.webp');
    if (!fixture.existsSync()) {
      markTestSkipped('sharp_clone fixtures are not present.');
      return;
    }

    final bytes = await fixture.readAsBytes();
    final metadata = await ImagePipeline.fromBytes(bytes).metadata();
    final image = await ImagePipeline.fromBytes(bytes).toPixelImage();

    expect(metadata.format, ImageFormat.webp);
    expect(metadata.width, 13);
    expect(metadata.height, 169);
    expect(metadata.frames, greaterThan(0));
    expect(image.width, 13);
    expect(image.height, 169);
    expect(image.isAnimated, isTrue);
    expect(image.frames.length, metadata.frames);
    expect(image.frames.first.pixels.bytes.length, 13 * 169 * 4);
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
    _expectPixelNear(image.firstFrameBytes(), image.width, 0, 0, <int>[
      27,
      125,
      192,
      255,
    ]);
    _expectPixelNear(image.firstFrameBytes(), image.width, 512, 386, <int>[
      82,
      173,
      231,
      255,
    ]);
    _expectPixelNear(image.firstFrameBytes(), image.width, 1023, 771, <int>[
      18,
      21,
      0,
      255,
    ]);
  });
}

void _expectPixelNear(
  List<int> rgba,
  int width,
  int x,
  int y,
  List<int> expected, {
  int tolerance = 20,
}) {
  final offset = (y * width + x) * 4;
  final actual = rgba.sublist(offset, offset + 4);
  for (var channel = 0; channel < 4; channel += 1) {
    final channelTolerance = channel == 3 ? 0 : tolerance;
    expect(
      actual[channel],
      inInclusiveRange(
        expected[channel] - channelTolerance,
        expected[channel] + channelTolerance,
      ),
      reason: 'pixel ($x,$y) channel $channel was $actual',
    );
  }
}

int _jpegMarkerCount(List<int> bytes, int marker) {
  var count = 0;
  for (var i = 0; i + 1 < bytes.length; i += 1) {
    if (bytes[i] == 0xff && bytes[i + 1] == marker) {
      count += 1;
    }
  }
  return count;
}

int _jpegRestartMarkerCount(List<int> bytes) {
  var count = 0;
  for (var marker = 0xd0; marker <= 0xd7; marker += 1) {
    count += _jpegMarkerCount(bytes, marker);
  }
  return count;
}

int? _jpegAdobeTransform(List<int> bytes) {
  for (var i = 0; i + 11 < bytes.length; i += 1) {
    if (bytes[i] == 0x41 &&
        bytes[i + 1] == 0x64 &&
        bytes[i + 2] == 0x6f &&
        bytes[i + 3] == 0x62 &&
        bytes[i + 4] == 0x65) {
      return bytes[i + 11];
    }
  }
  return null;
}
