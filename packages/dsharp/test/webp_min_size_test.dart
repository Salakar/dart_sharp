import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

void main() {
  test(
    'WebP minSize stores lossy animation frames as changed regions',
    () async {
      final image = _mostlyStaticAnimation();

      final full = await ImagePipeline.fromPixelImage(image)
          .webp(const WebpEncoderOptions(lossless: false, quality: 100))
          .toBytesWithInfo();
      final minimized = await ImagePipeline.fromPixelImage(image)
          .webp(
            const WebpEncoderOptions(
              lossless: false,
              minSize: true,
              quality: 100,
            ),
          )
          .toBytesWithInfo();
      final decoded = await ImagePipeline.fromBytes(
        minimized.bytes,
      ).toPixelImage();

      expect(minimized.info.size, lessThan(full.info.size));
      expect(minimized.info.frames, 3);
      expect(minimized.info.loopCount, 7);
      expect(minimized.info.frameDelays, <Duration>[
        const Duration(milliseconds: 10),
        const Duration(milliseconds: 20),
        const Duration(milliseconds: 30),
      ]);
      expect(decoded.frames.length, 3);
      expect(decoded.loopCount, 7);
      expect(
        decoded.frames[1].pixels.bytes[_offset(2, 2) + 2],
        greaterThan(120),
      );
      expect(
        decoded.frames[2].pixels.bytes[_offset(4, 2) + 1],
        greaterThan(120),
      );
    },
  );
}

PixelImage _mostlyStaticAnimation() {
  final red = _solidFrame(255, 0, 0, delayMs: 10);
  final bluePatch = _withPixel(red.pixels, 2, 2, 0, 0, 255, 255);
  final greenPatch = _withPixel(bluePatch, 4, 2, 0, 255, 0, 255);
  return PixelImage(
    frames: <ImageFrame>[
      red,
      ImageFrame(pixels: bluePatch, delay: const Duration(milliseconds: 20)),
      ImageFrame(pixels: greenPatch, delay: const Duration(milliseconds: 30)),
    ],
    loopCount: 7,
  );
}

ImageFrame _solidFrame(int red, int green, int blue, {required int delayMs}) {
  final bytes = Uint8List(32 * 16 * 4);
  for (var offset = 0; offset < bytes.length; offset += 4) {
    bytes[offset] = red;
    bytes[offset + 1] = green;
    bytes[offset + 2] = blue;
    bytes[offset + 3] = 255;
  }
  return ImageFrame(
    pixels: RawPixels(
      bytes: bytes,
      width: 32,
      height: 16,
      channels: ChannelCount.four,
    ),
    delay: Duration(milliseconds: delayMs),
  );
}

RawPixels _withPixel(
  RawPixels source,
  int x,
  int y,
  int red,
  int green,
  int blue,
  int alpha,
) {
  final bytes = source.bytes;
  final offset = _offset(x, y);
  bytes[offset] = red;
  bytes[offset + 1] = green;
  bytes[offset + 2] = blue;
  bytes[offset + 3] = alpha;
  return RawPixels(
    bytes: bytes,
    width: source.width,
    height: source.height,
    channels: source.channels,
  );
}

int _offset(int x, int y) {
  return (y * 32 + x) * 4;
}
