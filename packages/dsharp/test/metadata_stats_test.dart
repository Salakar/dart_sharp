import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

void main() {
  test('metadata is derived from raw pixel source', () async {
    final metadata = await ImagePipeline.fromRawPixels(
      RawPixels(
        bytes: Uint8List.fromList(<int>[1, 2, 3, 255]),
        width: 1,
        height: 1,
        channels: ChannelCount.four,
      ),
    ).metadata();

    expect(metadata.format, ImageFormat.raw);
    expect(metadata.width, 1);
    expect(metadata.height, 1);
    expect(metadata.channels, 4);
    expect(metadata.hasAlpha, isTrue);
  });

  test('metadata includes encoded source size and sniffed format', () async {
    final encoded = await ImagePipeline.create(
      const CreateImage(
        width: 1,
        height: 1,
        channels: 4,
        background: RgbaColor.white,
      ),
    ).toBytes(format: ImageFormat.png);

    final metadata = await ImagePipeline.fromBytes(encoded).metadata();

    expect(metadata.format, ImageFormat.png);
    expect(metadata.size, encoded.length);
    expect(metadata.width, 1);
    expect(metadata.height, 1);
  });

  test('metadata includes decoded animation delays', () async {
    RawPixels pixel(int red) {
      return RawPixels(
        bytes: Uint8List.fromList(<int>[red, 0, 0, 255]),
        width: 1,
        height: 1,
        channels: ChannelCount.four,
      );
    }

    final metadata = await ImagePipeline.fromPixelImage(
      PixelImage(
        frames: <ImageFrame>[
          ImageFrame(pixels: pixel(1), delay: const Duration(milliseconds: 10)),
          ImageFrame(pixels: pixel(2), delay: const Duration(milliseconds: 20)),
        ],
        loopCount: 4,
      ),
    ).metadata();

    expect(metadata.frames, 2);
    expect(metadata.loopCount, 4);
    expect(metadata.frameDelays, <Duration>[
      Duration(milliseconds: 10),
      Duration(milliseconds: 20),
    ]);
    expect(metadata.delay, <int>[10, 20]);
  });

  test('stats compute per-channel values and opacity', () async {
    final stats = await ImagePipeline.fromRawPixels(
      RawPixels(
        bytes: Uint8List.fromList(<int>[0, 10, 20, 255, 100, 110, 120, 255]),
        width: 2,
        height: 1,
        channels: ChannelCount.four,
      ),
    ).stats();

    expect(stats.channels.first.min, 0);
    expect(stats.channels.first.max, 100);
    expect(stats.channels.first.sum, 100);
    expect(stats.channels.first.mean, 50);
    expect(stats.channels.first.minX, 0);
    expect(stats.channels.first.minY, 0);
    expect(stats.channels.first.maxX, 1);
    expect(stats.channels.first.maxY, 0);
    expect(stats.isOpaque, isTrue);
    expect(stats.entropy, 1);
    expect(stats.sharpness, 0);
    expect(stats.dominant.red, 0);
  });

  test('stats estimate sharpness and dominant color', () async {
    final sharpStats = await ImagePipeline.fromRawPixels(
      RawPixels(
        bytes: Uint8List.fromList(<int>[
          for (var y = 0; y < 4; y += 1)
            for (var x = 0; x < 4; x += 1) ...[
              if (x < 2) ...[0, 0, 0, 255] else ...[255, 255, 255, 255],
            ],
        ]),
        width: 4,
        height: 4,
        channels: ChannelCount.four,
      ),
    ).stats();

    final dominantStats = await ImagePipeline.fromRawPixels(
      RawPixels(
        bytes: Uint8List.fromList(<int>[
          240,
          10,
          20,
          255,
          241,
          11,
          21,
          255,
          242,
          12,
          22,
          128,
          10,
          200,
          230,
          255,
        ]),
        width: 4,
        height: 1,
        channels: ChannelCount.four,
      ),
    ).stats();

    expect(sharpStats.sharpness, closeTo(255, 0.001));
    expect(dominantStats.dominant.red, 241);
    expect(dominantStats.dominant.green, 11);
    expect(dominantStats.dominant.blue, 21);
    expect(dominantStats.dominant.alpha, 255);
  });

  test('safety limits reject oversized inputs', () {
    const limits = InputSafetyLimits(maxBytes: 2, maxPixels: 4);

    expect(() => limits.checkBytes(3), throwsA(isA<ImageLimitException>()));
    expect(
      () => limits.checkImage(width: 3, height: 2, frames: 1),
      throwsA(isA<ImageLimitException>()),
    );
  });

  test('xmp metadata validates XML syntax', () {
    final metadata = XmpMetadata.parse('<xmp><title>Test</title></xmp>');

    expect(metadata.xmlText, contains('title'));
    expect(
      () => XmpMetadata.parse('<xmp>'),
      throwsA(isA<InvalidImageException>()),
    );
  });

  test('decode failure policies expose expected options', () {
    expect(DecodeFailurePolicy.values, contains(DecodeFailurePolicy.warning));
    expect(DecodeFailurePolicy.values, contains(DecodeFailurePolicy.truncated));
  });
}
