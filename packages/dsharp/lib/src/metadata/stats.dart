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
    this.minX = 0,
    this.minY = 0,
    this.maxX = 0,
    this.maxY = 0,
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

  /// X-coordinate of a pixel containing [min].
  final int minX;

  /// Y-coordinate of a pixel containing [min].
  final int minY;

  /// X-coordinate of a pixel containing [max].
  final int maxX;

  /// Y-coordinate of a pixel containing [max].
  final int maxY;
}

/// Image-wide statistics.
final class ImageStats {
  /// Creates image statistics.
  const ImageStats({
    required this.channels,
    required this.isOpaque,
    required this.entropy,
    this.sharpness = 0,
    required this.dominant,
  });

  /// Per-channel stats.
  final List<ChannelStats> channels;

  /// Whether all alpha samples are fully opaque.
  final bool isOpaque;

  /// Histogram-based greyscale entropy.
  final double entropy;

  /// Greyscale sharpness estimated from a Laplacian convolution.
  final double sharpness;

  /// Dominant sRGB color approximated with a 4096-bin histogram.
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
      var minX = 0;
      var minY = 0;
      var maxX = 0;
      var maxY = 0;
      var sum = 0;
      var squares = 0;
      for (var pixel = 0; pixel < pixelCount; pixel += 1) {
        final value = bytes[pixel * channelCount + channel];
        final x = pixel % raw.width;
        final y = pixel ~/ raw.width;
        if (value < minValue) {
          minValue = value;
          minX = x;
          minY = y;
        }
        if (value > maxValue) {
          maxValue = value;
          maxX = x;
          maxY = y;
        }
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
          minX: minX,
          minY: minY,
          maxX: maxX,
          maxY: maxY,
        ),
      );
    }
    return ImageStats(
      channels: List<ChannelStats>.unmodifiable(stats),
      isOpaque: _isOpaque(bytes, channelCount),
      entropy: _entropy(bytes, channelCount, pixelCount),
      sharpness: _sharpness(raw.width, raw.height, bytes, channelCount),
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
    histogram[_luminance(bytes, i, channelCount)] += 1;
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
  final counts = List<int>.filled(4096, 0);
  final redSums = List<int>.filled(4096, 0);
  final greenSums = List<int>.filled(4096, 0);
  final blueSums = List<int>.filled(4096, 0);
  var bestBin = 0;
  for (var i = 0; i < bytes.length; i += channelCount) {
    final (red, green, blue) = _rgb(bytes, i, channelCount);
    final bin = (red >> 4) << 8 | (green >> 4) << 4 | (blue >> 4);
    counts[bin] += 1;
    redSums[bin] += red;
    greenSums[bin] += green;
    blueSums[bin] += blue;
    if (counts[bin] > counts[bestBin]) {
      bestBin = bin;
    }
  }
  final count = counts[bestBin];
  return RgbaColor(
    red: (redSums[bestBin] / count).round(),
    green: (greenSums[bestBin] / count).round(),
    blue: (blueSums[bestBin] / count).round(),
  );
}

double _sharpness(int width, int height, List<int> bytes, int channelCount) {
  if (width < 3 || height < 3) {
    return 0;
  }
  final samples = (width - 2) * (height - 2);
  var sum = 0.0;
  var squares = 0.0;
  for (var y = 1; y < height - 1; y += 1) {
    for (var x = 1; x < width - 1; x += 1) {
      final center = (y * width + x) * channelCount;
      final value =
          _luminance(bytes, center - channelCount, channelCount) +
          _luminance(bytes, center + channelCount, channelCount) +
          _luminance(bytes, center - width * channelCount, channelCount) +
          _luminance(bytes, center + width * channelCount, channelCount) -
          4 * _luminance(bytes, center, channelCount);
      sum += value;
      squares += value * value;
    }
  }
  final mean = sum / samples;
  return sqrt(max(0, squares / samples - mean * mean));
}

int _luminance(List<int> bytes, int offset, int channelCount) {
  final (red, green, blue) = _rgb(bytes, offset, channelCount);
  return (red * 299 + green * 587 + blue * 114 + 500) ~/ 1000;
}

(int, int, int) _rgb(List<int> bytes, int offset, int channelCount) {
  final red = bytes[offset];
  final green = channelCount == 2
      ? red
      : channelCount > 1
      ? bytes[offset + 1]
      : red;
  final blue = channelCount > 2 ? bytes[offset + 2] : red;
  return (red, green, blue);
}
