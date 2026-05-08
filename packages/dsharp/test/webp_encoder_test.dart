import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

void main() {
  test('encodes animated WebP as lossless VP8L frames', () async {
    final image = _animation(loopCount: 5);

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

  test('WebP animation options override loop count and frame delay', () async {
    final encoded = await ImagePipeline.fromPixelImage(_animation(loopCount: 2))
        .webp(
          const WebpEncoderOptions(
            loopCount: 3,
            frameDelays: <Duration>[
              Duration(milliseconds: 40),
              Duration(milliseconds: 60),
            ],
          ),
        )
        .toBytesWithInfo();
    final decoded = await ImagePipeline.fromBytes(encoded.bytes).toPixelImage();

    expect(encoded.info.loopCount, 3);
    expect(encoded.info.frameDelays, <Duration>[
      const Duration(milliseconds: 40),
      const Duration(milliseconds: 60),
    ]);
    expect(decoded.loopCount, 3);
    expect(decoded.frames[0].delay, const Duration(milliseconds: 40));
    expect(decoded.frames[1].delay, const Duration(milliseconds: 60));
  });

  test('WebP frameDelay repeats one delay across animation frames', () async {
    final decoded = await ImagePipeline.fromPixelImage(_animation())
        .webp(const WebpEncoderOptions(frameDelay: Duration(milliseconds: 50)))
        .toBytes()
        .then((bytes) => ImagePipeline.fromBytes(bytes).toPixelImage());

    expect(decoded.frames[0].delay, const Duration(milliseconds: 50));
    expect(decoded.frames[1].delay, const Duration(milliseconds: 50));
  });

  test('WebP loop and delay aliases map to animation metadata', () async {
    final decoded = await ImagePipeline.fromPixelImage(_animation())
        .webp(
          const WebpEncoderOptions(loop: 4, delay: Duration(milliseconds: 70)),
        )
        .toBytes()
        .then((bytes) => ImagePipeline.fromBytes(bytes).toPixelImage());

    expect(decoded.loopCount, 4);
    expect(decoded.frames[0].delay, const Duration(milliseconds: 70));
    expect(decoded.frames[1].delay, const Duration(milliseconds: 70));
  });

  test('WebP nearLossless preprocesses pixels before VP8L encoding', () async {
    final raw = _rgba(<int>[1, 10, 23, 77, 250, 251, 252, 128]);

    final decoded = await ImagePipeline.fromRawPixels(raw)
        .webp(
          const WebpEncoderOptions(
            lossless: false,
            nearLossless: true,
            quality: 60,
          ),
        )
        .toBytes()
        .then((bytes) => ImagePipeline.fromBytes(bytes).toPixelImage());

    expect(decoded.firstFrameBytes(), <int>[0, 11, 22, 77, 253, 253, 253, 128]);
  });

  test('WebP lossy encoder writes static VP8 with alpha', () async {
    final raw = _rgba(<int>[255, 0, 0, 255, 0, 0, 255, 128]);

    final encoded = await ImagePipeline.fromRawPixels(
      raw,
    ).webp(const WebpEncoderOptions(lossless: false, quality: 100)).toBytes();
    final metadata = await ImagePipeline.fromBytes(encoded).metadata();
    final decoded = await ImagePipeline.fromBytes(encoded).toPixelImage();
    final pixels = decoded.firstFrameBytes();

    expect(metadata.format, ImageFormat.webp);
    expect(metadata.hasAlpha, isTrue);
    expect(String.fromCharCodes(encoded.sublist(12, 16)), 'VP8X');
    expect(pixels[0], inInclusiveRange(120, 136));
    expect(pixels[1], inInclusiveRange(0, 8));
    expect(pixels[2], inInclusiveRange(120, 136));
    expect(pixels[3], 255);
    expect(pixels[4], inInclusiveRange(120, 136));
    expect(pixels[5], inInclusiveRange(0, 8));
    expect(pixels[6], inInclusiveRange(120, 136));
    expect(pixels[7], 128);
  });

  test('WebP encoder normalizes non-RGBA raw channel layouts', () async {
    final cases = <(RawPixels, List<int>)>[
      (
        _raw(<int>[7, 9], channels: ChannelCount.one),
        <int>[7, 7, 7, 255, 9, 9, 9, 255],
      ),
      (
        _raw(<int>[7, 11, 9, 13], channels: ChannelCount.two),
        <int>[7, 7, 7, 11, 9, 9, 9, 13],
      ),
      (
        _raw(<int>[1, 2, 3, 4, 5, 6], channels: ChannelCount.three),
        <int>[1, 2, 3, 255, 4, 5, 6, 255],
      ),
    ];

    for (final (raw, expected) in cases) {
      final decoded = await ImagePipeline.fromRawPixels(raw)
          .webp()
          .toBytes()
          .then((bytes) => ImagePipeline.fromBytes(bytes).toPixelImage());

      expect(decoded.firstFrameBytes(), expected);
    }
  });

  test(
    'WebP parity options validate and unsupported modes fail clearly',
    () async {
      final pipeline = ImagePipeline.fromPixelImage(_animation());

      await expectLater(
        pipeline
            .webp(
              const WebpEncoderOptions(
                alphaQuality: 0,
                smartSubsample: true,
                smartDeblock: true,
                preset: 'picture',
                effort: 0,
                minSize: true,
                mixed: true,
              ),
            )
            .toBytes(),
        completes,
      );
      expect(
        pipeline.webp(const WebpEncoderOptions(alphaQuality: -1)).toBytes(),
        throwsA(isA<OperationValidationException>()),
      );
      expect(
        pipeline.webp(const WebpEncoderOptions(alphaQuality: 101)).toBytes(),
        throwsA(isA<OperationValidationException>()),
      );
      expect(
        pipeline.webp(const WebpEncoderOptions(preset: 'fail')).toBytes(),
        throwsA(isA<OperationValidationException>()),
      );
      expect(
        pipeline.webp(const WebpEncoderOptions(lossless: false)).toBytes(),
        throwsA(isA<UnsupportedCodecException>()),
      );
    },
  );

  test('WebP animation option ranges are validated', () {
    expect(
      ImagePipeline.fromPixelImage(
        _animation(),
      ).webp(const WebpEncoderOptions(loopCount: -1)).toBytes(),
      throwsA(isA<OperationValidationException>()),
    );
    expect(
      ImagePipeline.fromPixelImage(_animation())
          .webp(
            const WebpEncoderOptions(
              frameDelay: Duration(milliseconds: 0x10000),
            ),
          )
          .toBytes(),
      throwsA(isA<OperationValidationException>()),
    );
    expect(
      ImagePipeline.fromPixelImage(_animation())
          .webp(
            const WebpEncoderOptions(
              frameDelays: <Duration>[Duration(milliseconds: 1)],
            ),
          )
          .toBytes(),
      throwsA(isA<OperationValidationException>()),
    );
  });
}

PixelImage _animation({int? loopCount}) {
  return PixelImage(
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
    loopCount: loopCount,
  );
}

RawPixels _rgba(List<int> bytes) {
  return _raw(bytes, channels: ChannelCount.four);
}

RawPixels _raw(List<int> bytes, {required ChannelCount channels}) {
  return RawPixels(
    bytes: Uint8List.fromList(bytes),
    width: 2,
    height: 1,
    channels: channels,
  );
}
