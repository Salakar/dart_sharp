import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

void main() {
  test('WebP lossy encoder preserves horizontal chroma detail', () async {
    final bytes = <int>[
      for (var row = 0; row < 8; row += 1)
        for (var col = 0; col < 8; col += 1)
          if (col < 4) ...<int>[255, 0, 0, 255] else ...<int>[0, 0, 255, 255],
    ];
    final raw = RawPixels(
      bytes: Uint8List.fromList(bytes),
      width: 8,
      height: 8,
      channels: ChannelCount.four,
    );

    final decoded = await ImagePipeline.fromRawPixels(raw)
        .webp(const WebpEncoderOptions(lossless: false, quality: 100))
        .toBytes()
        .then((bytes) => ImagePipeline.fromBytes(bytes).toPixelImage());
    final pixels = decoded.firstFrameBytes();

    expect(pixels[0], greaterThan(150));
    expect(pixels[2], lessThan(120));
    expect(pixels[7 * 4], lessThan(120));
    expect(pixels[7 * 4 + 2], greaterThan(150));
  });

  test('WebP lossy encoder preserves vertical chroma detail', () async {
    final bytes = <int>[
      for (var row = 0; row < 8; row += 1)
        for (var col = 0; col < 8; col += 1)
          if (row < 4) ...<int>[255, 0, 0, 255] else ...<int>[0, 0, 255, 255],
    ];
    final raw = RawPixels(
      bytes: Uint8List.fromList(bytes),
      width: 8,
      height: 8,
      channels: ChannelCount.four,
    );

    final decoded = await ImagePipeline.fromRawPixels(raw)
        .webp(const WebpEncoderOptions(lossless: false, quality: 100))
        .toBytes()
        .then((bytes) => ImagePipeline.fromBytes(bytes).toPixelImage());
    final pixels = decoded.firstFrameBytes();

    expect(pixels[0], greaterThan(150));
    expect(pixels[2], lessThan(120));
    expect(pixels[(7 * 8) * 4], lessThan(120));
    expect(pixels[(7 * 8) * 4 + 2], greaterThan(150));
  });

  test('WebP lossy encoder preserves second vertical chroma detail', () async {
    final bytes = <int>[
      for (var row = 0; row < 8; row += 1)
        for (var col = 0; col < 8; col += 1)
          if (row < 2 || row >= 6) ...<int>[255, 0, 0, 255] else ...<int>[
            0,
            0,
            255,
            255,
          ],
    ];
    final raw = RawPixels(
      bytes: Uint8List.fromList(bytes),
      width: 8,
      height: 8,
      channels: ChannelCount.four,
    );

    final decoded = await ImagePipeline.fromRawPixels(raw)
        .webp(const WebpEncoderOptions(lossless: false, quality: 100))
        .toBytes()
        .then((bytes) => ImagePipeline.fromBytes(bytes).toPixelImage());
    final pixels = decoded.firstFrameBytes();

    expect(pixels[0], greaterThan(150));
    expect(pixels[2], lessThan(120));
    expect(pixels[(3 * 8) * 4], lessThan(120));
    expect(pixels[(3 * 8) * 4 + 2], greaterThan(150));
    expect(pixels[(7 * 8) * 4], greaterThan(150));
    expect(pixels[(7 * 8) * 4 + 2], lessThan(120));
  });

  test('WebP lossy encoder preserves diagonal chroma detail', () async {
    final bytes = <int>[
      for (var row = 0; row < 8; row += 1)
        for (var col = 0; col < 8; col += 1)
          if ((row < 4) == (col < 4)) ...<int>[255, 0, 0, 255] else ...<int>[
            0,
            0,
            255,
            255,
          ],
    ];
    final raw = RawPixels(
      bytes: Uint8List.fromList(bytes),
      width: 8,
      height: 8,
      channels: ChannelCount.four,
    );

    final decoded = await ImagePipeline.fromRawPixels(raw)
        .webp(const WebpEncoderOptions(lossless: false, quality: 100))
        .toBytes()
        .then((bytes) => ImagePipeline.fromBytes(bytes).toPixelImage());
    final pixels = decoded.firstFrameBytes();

    expect(pixels[0], greaterThan(150));
    expect(pixels[2], lessThan(120));
    expect(pixels[7 * 4], lessThan(120));
    expect(pixels[7 * 4 + 2], greaterThan(150));
    expect(pixels[(7 * 8) * 4], lessThan(120));
    expect(pixels[(7 * 8) * 4 + 2], greaterThan(150));
    expect(pixels[(7 * 8 + 7) * 4], greaterThan(150));
    expect(pixels[(7 * 8 + 7) * 4 + 2], lessThan(120));
  });

  test(
    'WebP lossy encoder preserves second horizontal chroma detail',
    () async {
      final bytes = <int>[
        for (var row = 0; row < 8; row += 1)
          for (var col = 0; col < 8; col += 1)
            if (col < 2 || col >= 6) ...<int>[255, 0, 0, 255] else ...<int>[
              0,
              0,
              255,
              255,
            ],
      ];
      final raw = RawPixels(
        bytes: Uint8List.fromList(bytes),
        width: 8,
        height: 8,
        channels: ChannelCount.four,
      );

      final decoded = await ImagePipeline.fromRawPixels(raw)
          .webp(const WebpEncoderOptions(lossless: false, quality: 100))
          .toBytes()
          .then((bytes) => ImagePipeline.fromBytes(bytes).toPixelImage());
      final pixels = decoded.firstFrameBytes();

      expect(pixels[0], greaterThan(150));
      expect(pixels[2], lessThan(120));
      expect(pixels[3 * 4], lessThan(120));
      expect(pixels[3 * 4 + 2], greaterThan(150));
      expect(pixels[7 * 4], greaterThan(150));
      expect(pixels[7 * 4 + 2], lessThan(120));
    },
  );
}
