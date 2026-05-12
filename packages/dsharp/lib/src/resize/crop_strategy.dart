import 'dart:math';

import '../pixels/pixel_image.dart';

/// Crop strategy contract.
abstract interface class CropStrategy {
  /// Strategy name.
  String get name;

  /// Scores [image] for deterministic crop selection.
  double score(PixelImage image);
}

/// Entropy-based crop strategy.
final class EntropyCropStrategy implements CropStrategy {
  /// Creates an entropy strategy.
  const EntropyCropStrategy();

  @override
  String get name => 'entropy';

  @override
  double score(PixelImage image) {
    final raw = image.firstFrame.pixels;
    final bytes = raw.bytes;
    final channels = raw.channels.value;
    final pixelCount = raw.width * raw.height;
    if (pixelCount == 0) {
      return 0;
    }
    final histogram = List<int>.filled(256, 0);
    for (var offset = 0; offset < bytes.length; offset += channels) {
      histogram[_luminance(bytes, offset, channels)] += 1;
    }
    var entropy = 0.0;
    for (final count in histogram) {
      if (count == 0) {
        continue;
      }
      final probability = count / pixelCount;
      entropy -= probability * (log(probability) / ln2);
    }
    return entropy / 8;
  }
}

/// Attention-based crop strategy.
final class AttentionCropStrategy implements CropStrategy {
  /// Creates an attention strategy.
  const AttentionCropStrategy();

  @override
  String get name => 'attention';

  @override
  double score(PixelImage image) {
    final raw = image.firstFrame.pixels;
    final bytes = raw.bytes;
    final channels = raw.channels.value;
    final pixelCount = raw.width * raw.height;
    if (pixelCount == 0) {
      return 0;
    }

    var colorScore = 0.0;
    var edgeScore = 0.0;
    var edgeCount = 0;
    for (var y = 0; y < raw.height; y += 1) {
      for (var x = 0; x < raw.width; x += 1) {
        final offset = ((y * raw.width) + x) * channels;
        final (red, green, blue) = _rgb(bytes, offset, channels);
        final maxChannel = max(red, max(green, blue));
        final minChannel = min(red, min(green, blue));
        final saturation = (maxChannel - minChannel) / 255;
        colorScore += saturation;
        if (_isSkinTone(red, green, blue)) {
          colorScore += 0.5;
        }

        final luminance = _luminance(bytes, offset, channels);
        if (x + 1 < raw.width) {
          final right = offset + channels;
          edgeScore += (luminance - _luminance(bytes, right, channels)).abs();
          edgeCount += 1;
        }
        if (y + 1 < raw.height) {
          final below = offset + (raw.width * channels);
          edgeScore += (luminance - _luminance(bytes, below, channels)).abs();
          edgeCount += 1;
        }
      }
    }

    final normalizedColor = colorScore / pixelCount;
    final normalizedEdges = edgeCount == 0 ? 0 : edgeScore / (edgeCount * 255);
    return normalizedEdges + normalizedColor;
  }
}

int _luminance(List<int> bytes, int offset, int channels) {
  final (red, green, blue) = _rgb(bytes, offset, channels);
  return ((0.2126 * red) + (0.7152 * green) + (0.0722 * blue)).round();
}

(int, int, int) _rgb(List<int> bytes, int offset, int channels) {
  final red = bytes[offset];
  final green = channels == 2
      ? red
      : channels > 1
      ? bytes[offset + 1]
      : red;
  final blue = channels > 2 ? bytes[offset + 2] : red;
  return (red, green, blue);
}

bool _isSkinTone(int red, int green, int blue) {
  final maxChannel = max(red, max(green, blue));
  final minChannel = min(red, min(green, blue));
  return red > 95 &&
      green > 40 &&
      blue > 20 &&
      maxChannel - minChannel > 15 &&
      (red - green).abs() > 15 &&
      red > green &&
      red > blue;
}
