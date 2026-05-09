import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

void main() {
  test('WebP mixed animation keeps the smaller frame candidates', () async {
    final image = _patternAnimation();

    final lossy = await ImagePipeline.fromPixelImage(image)
        .webp(const WebpEncoderOptions(lossless: false, quality: 100))
        .toBytesWithInfo();
    final mixed = await ImagePipeline.fromPixelImage(image)
        .webp(
          const WebpEncoderOptions(lossless: false, mixed: true, quality: 100),
        )
        .toBytesWithInfo();
    final minSize = await ImagePipeline.fromPixelImage(image)
        .webp(
          const WebpEncoderOptions(
            lossless: false,
            minSize: true,
            quality: 100,
          ),
        )
        .toBytesWithInfo();
    final mixedMinSize = await ImagePipeline.fromPixelImage(image)
        .webp(
          const WebpEncoderOptions(
            lossless: false,
            minSize: true,
            mixed: true,
            quality: 100,
          ),
        )
        .toBytesWithInfo();
    final decoded = await ImagePipeline.fromBytes(
      mixedMinSize.bytes,
    ).toPixelImage();

    expect(mixed.info.size, lessThanOrEqualTo(lossy.info.size));
    expect(mixedMinSize.info.size, lessThanOrEqualTo(minSize.info.size));
    expect(mixed.info.frames, 3);
    expect(mixedMinSize.info.frames, 3);
    expect(decoded.frames.length, 3);
    expect(decoded.loopCount, 2);
    expect(decoded.frames[1].delay, const Duration(milliseconds: 20));
    expect(decoded.frames[2].delay, const Duration(milliseconds: 30));
  });
}

PixelImage _patternAnimation() {
  return PixelImage(
    frames: <ImageFrame>[
      ImageFrame(pixels: _pattern(1), delay: const Duration(milliseconds: 10)),
      ImageFrame(pixels: _pattern(17), delay: const Duration(milliseconds: 20)),
      ImageFrame(pixels: _pattern(33), delay: const Duration(milliseconds: 30)),
    ],
    loopCount: 2,
  );
}

RawPixels _pattern(int seed) {
  const width = 16;
  const height = 16;
  final bytes = Uint8List(width * height * 4);
  for (var y = 0; y < height; y += 1) {
    for (var x = 0; x < width; x += 1) {
      final offset = (y * width + x) * 4;
      bytes[offset] = (x * 37 + y * 19 + seed) & 0xff;
      bytes[offset + 1] = (x * 17 + y * 43 + seed * 3) & 0xff;
      bytes[offset + 2] = (x * 71 + y * 11 + seed * 5) & 0xff;
      bytes[offset + 3] = 255;
    }
  }
  return RawPixels(
    bytes: bytes,
    width: width,
    height: height,
    channels: ChannelCount.four,
  );
}
