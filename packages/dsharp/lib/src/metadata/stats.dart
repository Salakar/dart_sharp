import 'dart:math';

import '../pixels/color.dart';
import '../pixels/pixel_image.dart';

/// Per-channel image statistics.
final class ChannelStats {
  /// Creates channel statistics.
  const ChannelStats({
    required this.min,
    required this.max,
    required this.sum,
    required this.squaresSum,
    required this.mean,
    required this.stdev,
  });

  /// Minimum sample.
  final int min;

  /// Maximum sample.
  final int max;

  /// Sum of samples.
  final int sum;

  /// Sum of squared samples.
  final int squaresSum;

  /// Mean sample.
  final double mean;

  /// Standard deviation.
  final double stdev;
}

/// Image-wide statistics.
final class ImageStats {
  /// Creates image statistics.
  const ImageStats({
    required this.channels,
    required this.isOpaque,
    required this.entropy,
    required this.dominant,
  });

  /// Per-channel stats.
  final List<ChannelStats> channels;

  /// Whether all alpha samples are fully opaque.
  final bool isOpaque;

  /// Shannon entropy over first-channel byte values.
  final double entropy;

  /// Dominant color approximation.
  final RgbaColor dominant;

  /// Computes statistics for the first frame of [image].
  factory ImageStats.fromPixelImage(PixelImage image) {
    final raw = image.firstFrame.pixels;
    final bytes = raw.bytes;
    final channelCount = raw.channels.value;
    final pixelCount = raw.width * raw.height;
    final stats = <ChannelStats>[];
    for (var channel = 0; channel < channelCount; channel += 1) {
      var minValue = 255;
      var maxValue = 0;
      var sum = 0;
      var squares = 0;
      for (var i = channel; i < bytes.length; i += channelCount) {
        final value = bytes[i];
        minValue = min(minValue, value);
        maxValue = max(maxValue, value);
        sum += value;
        squares += value * value;
      }
      final mean = sum / pixelCount;
      final variance = max(0, (squares / pixelCount) - (mean * mean));
      stats.add(
        ChannelStats(
          min: minValue,
          max: maxValue,
          sum: sum,
          squaresSum: squares,
          mean: mean,
          stdev: sqrt(variance),
        ),
      );
    }
    return ImageStats(
      channels: List<ChannelStats>.unmodifiable(stats),
      isOpaque: _isOpaque(bytes, channelCount),
      entropy: _entropy(bytes, channelCount, pixelCount),
      dominant: _dominant(bytes, channelCount),
    );
  }
}

bool _isOpaque(List<int> bytes, int channelCount) {
  if (channelCount != 2 && channelCount != 4) {
    return true;
  }
  final alphaChannel = channelCount - 1;
  for (var i = alphaChannel; i < bytes.length; i += channelCount) {
    if (bytes[i] != 255) {
      return false;
    }
  }
  return true;
}

double _entropy(List<int> bytes, int channelCount, int pixelCount) {
  final histogram = List<int>.filled(256, 0);
  for (var i = 0; i < bytes.length; i += channelCount) {
    histogram[bytes[i]] += 1;
  }
  var entropy = 0.0;
  for (final count in histogram) {
    if (count == 0) {
      continue;
    }
    final probability = count / pixelCount;
    entropy -= probability * (log(probability) / ln2);
  }
  return entropy;
}

RgbaColor _dominant(List<int> bytes, int channelCount) {
  if (bytes.isEmpty) {
    return RgbaColor.transparent;
  }
  final red = bytes[0];
  final green = channelCount > 1 ? bytes[1] : red;
  final blue = channelCount > 2 ? bytes[2] : red;
  final alpha = channelCount > 3 ? bytes[3] : 255;
  return RgbaColor(red: red, green: green, blue: blue, alpha: alpha);
}
