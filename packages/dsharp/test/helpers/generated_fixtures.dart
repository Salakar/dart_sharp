import 'dart:math';
import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';

/// Deterministic generated fixtures for tests and benchmarks.
final class GeneratedFixtures {
  const GeneratedFixtures._();

  /// 2x2 alpha grid with red channel identifiers.
  static RawPixels alphaGrid() {
    return RawPixels(
      bytes: Uint8List.fromList(<int>[
        10,
        0,
        0,
        0,
        20,
        0,
        0,
        85,
        30,
        0,
        0,
        170,
        40,
        0,
        0,
        255,
      ]),
      width: 2,
      height: 2,
      channels: ChannelCount.four,
    );
  }

  /// RGBA gradient.
  static RawPixels gradient({int width = 4, int height = 4}) {
    final bytes = <int>[];
    for (var y = 0; y < height; y += 1) {
      for (var x = 0; x < width; x += 1) {
        bytes
          ..add(_scale(x, width))
          ..add(_scale(y, height))
          ..add(_scale(x + y, width + height - 1))
          ..add(255);
      }
    }
    return RawPixels(
      bytes: Uint8List.fromList(bytes),
      width: width,
      height: height,
      channels: ChannelCount.four,
    );
  }

  /// Small two-frame animation.
  static PixelImage animation() {
    return PixelImage(
      frames: <ImageFrame>[
        ImageFrame(
          pixels: alphaGrid(),
          delay: const Duration(milliseconds: 10),
        ),
        ImageFrame(
          pixels: gradient(width: 2, height: 2),
          delay: const Duration(milliseconds: 20),
        ),
      ],
      loopCount: 2,
    );
  }

  /// Deterministic raw byte buffer.
  static Uint8List rawBuffer(int length, {int seed = 1}) {
    final random = Random(seed);
    return Uint8List.fromList(<int>[
      for (var i = 0; i < length; i += 1) random.nextInt(256),
    ]);
  }

  /// Malformed encoded byte sequences.
  static List<Uint8List> malformedBytes() {
    return <Uint8List>[
      Uint8List(0),
      Uint8List.fromList(<int>[0x89, 0x50, 0x4e, 0x47]),
      Uint8List.fromList(<int>[0xff, 0xd8, 0xff]),
      rawBuffer(32, seed: 99),
    ];
  }

  static int _scale(int value, int length) {
    if (length <= 1) {
      return 0;
    }
    return (value * 255 / (length - 1)).round().clamp(0, 255);
  }
}
