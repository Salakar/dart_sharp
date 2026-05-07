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
    expect(stats.isOpaque, isTrue);
    expect(stats.entropy, 1);
    expect(stats.dominant.red, 0);
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
