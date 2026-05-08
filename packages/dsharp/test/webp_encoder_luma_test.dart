import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

void main() {
  test(
    'WebP lossy encoder preserves third horizontal vertical luma detail',
    () async {
      final bytes = <int>[
        for (var row = 0; row < 4; row += 1)
          for (var col = 0; col < 4; col += 1)
            if (col.isEven == (row < 2)) ...<int>[
              255,
              255,
              255,
              255,
            ] else ...<int>[0, 0, 0, 255],
      ];
      final raw = RawPixels(
        bytes: Uint8List.fromList(bytes),
        width: 4,
        height: 4,
        channels: ChannelCount.four,
      );

      final decoded = await ImagePipeline.fromRawPixels(raw)
          .webp(const WebpEncoderOptions(lossless: false, quality: 100))
          .toBytes()
          .then((bytes) => ImagePipeline.fromBytes(bytes).toPixelImage());
      final pixels = decoded.firstFrameBytes();

      expect(pixels[0], greaterThan(180));
      expect(pixels[1 * 4], lessThan(80));
      expect(pixels[2 * 4], greaterThan(180));
      expect(pixels[3 * 4], lessThan(80));
      expect(pixels[(2 * 4 + 0) * 4], lessThan(80));
      expect(pixels[(2 * 4 + 1) * 4], greaterThan(180));
      expect(pixels[(2 * 4 + 2) * 4], lessThan(80));
      expect(pixels[(2 * 4 + 3) * 4], greaterThan(180));
    },
  );

  test(
    'WebP lossy encoder preserves third horizontal second vertical luma detail',
    () async {
      final bytes = <int>[
        for (var row = 0; row < 4; row += 1)
          for (var col = 0; col < 4; col += 1)
            if (col.isEven == (row == 0 || row == 3)) ...<int>[
              255,
              255,
              255,
              255,
            ] else ...<int>[0, 0, 0, 255],
      ];
      final raw = RawPixels(
        bytes: Uint8List.fromList(bytes),
        width: 4,
        height: 4,
        channels: ChannelCount.four,
      );

      final decoded = await ImagePipeline.fromRawPixels(raw)
          .webp(const WebpEncoderOptions(lossless: false, quality: 100))
          .toBytes()
          .then((bytes) => ImagePipeline.fromBytes(bytes).toPixelImage());
      final pixels = decoded.firstFrameBytes();

      expect(pixels[0], greaterThan(180));
      expect(pixels[1 * 4], lessThan(80));
      expect(pixels[2 * 4], greaterThan(180));
      expect(pixels[3 * 4], lessThan(80));
      expect(pixels[(1 * 4 + 0) * 4], lessThan(80));
      expect(pixels[(1 * 4 + 1) * 4], greaterThan(180));
      expect(pixels[(1 * 4 + 2) * 4], lessThan(80));
      expect(pixels[(1 * 4 + 3) * 4], greaterThan(180));
    },
  );
}
