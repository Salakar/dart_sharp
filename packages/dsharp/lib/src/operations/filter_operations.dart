import 'dart:typed_data';

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
  const MedianOperation();

  @override
  String get name => 'median';

  @override
  PixelImage apply(PixelImage image) => mapFrames(image, _median);
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
  const SharpenOperation();

  @override
  String get name => 'sharpen';

  @override
  PixelImage apply(PixelImage image) {
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
  const DilateOperation();

  @override
  String get name => 'dilate';

  @override
  PixelImage apply(PixelImage image) =>
      mapFrames(image, (raw) => _morph(raw, true));
}

/// Applies a min filter.
final class ErodeOperation implements PipelineOperation {
  /// Creates an erode operation.
  const ErodeOperation();

  @override
  String get name => 'erode';

  @override
  PixelImage apply(PixelImage image) =>
      mapFrames(image, (raw) => _morph(raw, false));
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

RawPixels _median(RawPixels raw) {
  final channels = raw.channels.value;
  final input = raw.bytes;
  final output = Uint8List(input.length);
  for (var y = 0; y < raw.height; y += 1) {
    for (var x = 0; x < raw.width; x += 1) {
      final target = ((y * raw.width) + x) * channels;
      for (var c = 0; c < channels; c += 1) {
        final values = <int>[];
        for (var yy = -1; yy <= 1; yy += 1) {
          for (var xx = -1; xx <= 1; xx += 1) {
            values.add(input[clampedOffset(raw, x + xx, y + yy) + c]);
          }
        }
        output[target + c] = medianByte(values);
      }
    }
  }
  return sameSizeRaw(raw, output, raw.channels);
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

RawPixels _morph(RawPixels raw, bool useMax) {
  final channels = raw.channels.value;
  final input = raw.bytes;
  final output = Uint8List(input.length);
  for (var y = 0; y < raw.height; y += 1) {
    for (var x = 0; x < raw.width; x += 1) {
      final target = ((y * raw.width) + x) * channels;
      for (var c = 0; c < channels; c += 1) {
        var value = useMax ? 0 : 255;
        for (var yy = -1; yy <= 1; yy += 1) {
          for (var xx = -1; xx <= 1; xx += 1) {
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
