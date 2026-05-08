import 'dart:math';
import 'dart:typed_data';

import '../api/exceptions.dart';
import '../pipeline/pipeline_operation.dart';
import '../pixels/pixel_image.dart';
import '../source/raw_pixels.dart';
import 'operation_options.dart';
import 'pixel_helpers.dart';

/// Applies a box blur.
final class BlurOperation implements PipelineOperation {
  /// Creates a blur operation.
  const BlurOperation();

  @override
  String get name => 'blur';

  @override
  PixelImage apply(PixelImage image) => mapFrames(image, _blur);
}

/// Applies a median filter.
final class MedianOperation implements PipelineOperation {
  /// Creates a median operation.
  const MedianOperation([this.size = 3]);

  /// Square mask size.
  final int size;

  @override
  String get name => 'median';

  @override
  PixelImage apply(PixelImage image) {
    _validateSize('Median size', size, max: 1000);
    return mapFrames(image, (raw) => _median(raw, size));
  }
}

/// Applies a convolution kernel.
final class ConvolveOperation implements PipelineOperation {
  /// Creates a convolution operation.
  const ConvolveOperation(this.kernel);

  /// Kernel.
  final ConvolutionKernel kernel;

  @override
  String get name => 'convolve';

  @override
  PixelImage apply(PixelImage image) {
    kernel.validate();
    return mapFrames(image, (raw) => _convolve(raw, kernel));
  }
}

/// Applies a mild sharpen kernel.
final class SharpenOperation implements PipelineOperation {
  /// Creates a sharpen operation.
  const SharpenOperation([this.options, this.legacySigmaRange = false]);

  /// Sigma-based options, or null for mild sharpen.
  final SharpenOptions? options;

  /// Whether to validate legacy positional sigma ranges.
  final bool legacySigmaRange;

  @override
  String get name => 'sharpen';

  @override
  PixelImage apply(PixelImage image) {
    final options = this.options;
    if (options != null) {
      options.validate(legacySigmaRange: legacySigmaRange);
      return mapFrames(image, (raw) => _unsharp(raw, options));
    }
    return const ConvolveOperation(
      ConvolutionKernel(
        width: 3,
        height: 3,
        values: <num>[0, -1, 0, -1, 5, -1, 0, -1, 0],
      ),
    ).apply(image);
  }
}

/// Applies a max filter.
final class DilateOperation implements PipelineOperation {
  /// Creates a dilate operation.
  const DilateOperation([this.width = 1]);

  /// Expansion width in pixels.
  final int width;

  @override
  String get name => 'dilate';

  @override
  PixelImage apply(PixelImage image) {
    _validateSize('Dilate width', width);
    return mapFrames(image, (raw) => _morph(raw, true, width));
  }
}

/// Applies a min filter.
final class ErodeOperation implements PipelineOperation {
  /// Creates an erode operation.
  const ErodeOperation([this.width = 1]);

  /// Contraction width in pixels.
  final int width;

  @override
  String get name => 'erode';

  @override
  PixelImage apply(PixelImage image) {
    _validateSize('Erode width', width);
    return mapFrames(image, (raw) => _morph(raw, false, width));
  }
}

RawPixels _blur(RawPixels raw) {
  return _convolve(
    raw,
    const ConvolutionKernel(
      width: 3,
      height: 3,
      values: <num>[1, 1, 1, 1, 1, 1, 1, 1, 1],
      scale: 9,
    ),
  );
}

RawPixels _median(RawPixels raw, int size) {
  final channels = raw.channels.value;
  final input = raw.bytes;
  final output = Uint8List(input.length);
  final before = size ~/ 2;
  final after = size - before - 1;
  for (var y = 0; y < raw.height; y += 1) {
    for (var x = 0; x < raw.width; x += 1) {
      final target = ((y * raw.width) + x) * channels;
      for (var c = 0; c < channels; c += 1) {
        final values = <int>[];
        for (var yy = -before; yy <= after; yy += 1) {
          for (var xx = -before; xx <= after; xx += 1) {
            values.add(input[clampedOffset(raw, x + xx, y + yy) + c]);
          }
        }
        output[target + c] = medianByte(values);
      }
    }
  }
  return sameSizeRaw(raw, output, raw.channels);
}

RawPixels _unsharp(RawPixels raw, SharpenOptions options) {
  final sigma = min(10.0, options.sigma.toDouble());
  final blurred = _gaussianBlur(raw, _gaussianKernel(sigma));
  final channels = raw.channels.value;
  final input = raw.bytes;
  final output = Uint8List(input.length);
  final colorChannels = min(3, channels);
  for (var i = 0; i < input.length; i += channels) {
    for (var c = 0; c < colorChannels; c += 1) {
      final delta = input[i + c] - blurred[i + c];
      final magnitude = delta.abs();
      final amount = magnitude <= options.x1 ? options.m1 : options.m2;
      final limit = delta >= 0 ? options.y2 : options.y3;
      final adjustment = min(magnitude * amount, limit).toDouble();
      output[i + c] = byteClamp(
        input[i + c] + (delta >= 0 ? adjustment : -adjustment),
      );
    }
    for (var c = colorChannels; c < channels; c += 1) {
      output[i + c] = input[i + c];
    }
  }
  return sameSizeRaw(raw, output, raw.channels);
}

Uint8List _gaussianBlur(RawPixels raw, List<double> kernel) {
  final channels = raw.channels.value;
  final input = raw.bytes;
  final radius = kernel.length ~/ 2;
  final temp = List<double>.filled(input.length, 0);
  final output = Uint8List(input.length);
  for (var y = 0; y < raw.height; y += 1) {
    for (var x = 0; x < raw.width; x += 1) {
      final target = clampedOffset(raw, x, y);
      for (var c = 0; c < channels; c += 1) {
        var sum = 0.0;
        for (var k = -radius; k <= radius; k += 1) {
          sum += input[clampedOffset(raw, x + k, y) + c] * kernel[k + radius];
        }
        temp[target + c] = sum;
      }
    }
  }
  for (var y = 0; y < raw.height; y += 1) {
    for (var x = 0; x < raw.width; x += 1) {
      final target = clampedOffset(raw, x, y);
      for (var c = 0; c < channels; c += 1) {
        var sum = 0.0;
        for (var k = -radius; k <= radius; k += 1) {
          sum += temp[clampedOffset(raw, x, y + k) + c] * kernel[k + radius];
        }
        output[target + c] = byteClamp(sum);
      }
    }
  }
  return output;
}

List<double> _gaussianKernel(double sigma) {
  final radius = max(1, (sigma * 3).ceil());
  final values = <double>[];
  var total = 0.0;
  for (var i = -radius; i <= radius; i += 1) {
    final value = exp(-(i * i) / (2 * sigma * sigma));
    values.add(value);
    total += value;
  }
  return <double>[for (final value in values) value / total];
}

RawPixels _convolve(RawPixels raw, ConvolutionKernel kernel) {
  final channels = raw.channels.value;
  final input = raw.bytes;
  final output = Uint8List(input.length);
  final halfWidth = kernel.width ~/ 2;
  final halfHeight = kernel.height ~/ 2;
  for (var y = 0; y < raw.height; y += 1) {
    for (var x = 0; x < raw.width; x += 1) {
      final target = ((y * raw.width) + x) * channels;
      for (var c = 0; c < channels; c += 1) {
        var sum = 0.0;
        for (var ky = 0; ky < kernel.height; ky += 1) {
          for (var kx = 0; kx < kernel.width; kx += 1) {
            final source = clampedOffset(
              raw,
              x + kx - halfWidth,
              y + ky - halfHeight,
            );
            sum += input[source + c] * kernel.values[(ky * kernel.width) + kx];
          }
        }
        output[target + c] = byteClamp((sum / kernel.scale) + kernel.offset);
      }
    }
  }
  return sameSizeRaw(raw, output, raw.channels);
}

RawPixels _morph(RawPixels raw, bool useMax, int width) {
  final channels = raw.channels.value;
  final input = raw.bytes;
  final output = Uint8List(input.length);
  for (var y = 0; y < raw.height; y += 1) {
    for (var x = 0; x < raw.width; x += 1) {
      final target = ((y * raw.width) + x) * channels;
      for (var c = 0; c < channels; c += 1) {
        var value = useMax ? 0 : 255;
        for (var yy = -width; yy <= width; yy += 1) {
          for (var xx = -width; xx <= width; xx += 1) {
            final sample = input[clampedOffset(raw, x + xx, y + yy) + c];
            value = useMax
                ? sample > value
                      ? sample
                      : value
                : sample < value
                ? sample
                : value;
          }
        }
        output[target + c] = value;
      }
    }
  }
  return sameSizeRaw(raw, output, raw.channels);
}

void _validateSize(String label, int value, {int? max}) {
  if (value <= 0 || (max != null && value > max)) {
    throw OperationValidationException(
      max == null
          ? '$label must be a positive integer.'
          : '$label must be an integer between 1 and $max.',
    );
  }
}
