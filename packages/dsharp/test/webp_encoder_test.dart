import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

void main() {
  test('encodes animated WebP as lossless VP8L frames', () async {
    final image = PixelImage(
      frames: <ImageFrame>[
        ImageFrame(
          pixels: _rgba(<int>[255, 0, 0, 255, 0, 255, 0, 255]),
          delay: const Duration(milliseconds: 10),
        ),
        ImageFrame(
          pixels: _rgba(<int>[0, 0, 255, 0, 5, 6, 7, 128]),
          delay: const Duration(milliseconds: 20),
        ),
      ],
      loopCount: 5,
    );

    final encoded = await ImagePipeline.fromPixelImage(
      image,
    ).webp().toBytesWithInfo();
    final metadata = await ImagePipeline.fromBytes(encoded.bytes).metadata();
    final decoded = await ImagePipeline.fromBytes(encoded.bytes).toPixelImage();

    expect(encoded.info.format, ImageFormat.webp);
    expect(encoded.info.frames, 2);
    expect(encoded.info.loopCount, 5);
    expect(encoded.info.frameDelays, <Duration>[
      const Duration(milliseconds: 10),
      const Duration(milliseconds: 20),
    ]);
    expect(metadata.format, ImageFormat.webp);
    expect(metadata.width, 2);
    expect(metadata.height, 1);
    expect(metadata.frames, 2);
    expect(metadata.loopCount, 5);
    expect(metadata.hasAlpha, isTrue);
    expect(decoded.isAnimated, isTrue);
    expect(decoded.loopCount, 5);
    expect(decoded.frames[0].delay, const Duration(milliseconds: 10));
    expect(decoded.frames[1].delay, const Duration(milliseconds: 20));
    expect(decoded.frames[0].pixels.bytes, image.frames[0].pixels.bytes);
    expect(decoded.frames[1].pixels.bytes, image.frames[1].pixels.bytes);
  });
}

RawPixels _rgba(List<int> bytes) {
  return RawPixels(
    bytes: Uint8List.fromList(bytes),
    width: 2,
    height: 1,
    channels: ChannelCount.four,
  );
}
