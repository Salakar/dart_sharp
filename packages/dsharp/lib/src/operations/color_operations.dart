import 'dart:math';
import 'dart:typed_data';

import '../api/exceptions.dart';
import '../pipeline/pipeline_operation.dart';
import '../pixels/color.dart';
import '../pixels/pixel_image.dart';
import '../source/raw_pixels.dart';
import 'operation_options.dart';
import 'pixel_helpers.dart';

/// Converts pixels to grayscale.
final class GrayscaleOperation implements PipelineOperation {
  /// Creates a grayscale operation.
  const GrayscaleOperation();

  @override
  String get name => 'grayscale';

  @override
  PixelImage apply(PixelImage image) {
    return mapFrames(image, (raw) {
      final input = raw.bytes;
      final channels = raw.channels.value;
      final output = Uint8List(raw.width * raw.height * channels);
      for (var i = 0; i < input.length; i += channels) {
        final color = readColor(input, i, channels);
        final gray = luminance(color);
        writeColor(
          output,
          i,
          channels,
          RgbaColor(red: gray, green: gray, blue: gray, alpha: color.alpha),
        );
      }
      return sameSizeRaw(raw, output, raw.channels);
    });
  }
}

/// Converts pixels to a supported output colourspace.
final class ColourspaceOperation implements PipelineOperation {
  /// Creates a colourspace conversion operation.
  const ColourspaceOperation(this.colourspace, {required this.name});

  /// Requested colourspace name.
  final String colourspace;

  @override
  final String name;

  @override
  PixelImage apply(PixelImage image) {
    return switch (_normalizeColourspace(colourspace)) {
      'rgb' || 'srgb' => image,
      'bw' => mapFrames(image, _toBlackAndWhite),
      _ => throw OperationValidationException(
        'Unsupported colourspace "$colourspace".',
      ),
    };
  }
}

/// Negates pixel channels.
final class NegateOperation implements PipelineOperation {
  /// Creates a negate operation.
  const NegateOperation({this.negateAlpha = true});

  /// Whether alpha should also be negated.
  final bool negateAlpha;

  @override
  String get name => 'negate';

  @override
  PixelImage apply(PixelImage image) => mapFrames(image, _negate);

  RawPixels _negate(RawPixels raw) {
    final output = raw.bytes;
    final channels = raw.channels.value;
    for (var i = 0; i < output.length; i += channels) {
      final limit = negateAlpha ? channels : colorChannelCount(channels);
      for (var c = 0; c < limit; c += 1) {
        output[i + c] = 255 - output[i + c];
      }
    }
    return sameSizeRaw(raw, output, raw.channels);
  }
}

String _normalizeColourspace(String colourspace) {
  final normalized = colourspace.toLowerCase().replaceAll('_', '-');
  return switch (normalized) {
    'b-w' ||
    'bw' ||
    'black-white' ||
    'grey' ||
    'gray' ||
    'greyscale' ||
    'grayscale' => 'bw',
    'rgb' || 'srgb' => normalized,
    _ => normalized,
  };
}

RawPixels _toBlackAndWhite(RawPixels raw) {
  if (raw.channels == ChannelCount.one) {
    return raw;
  }
  final input = raw.bytes;
  final channels = raw.channels.value;
  final output = Uint8List(raw.width * raw.height);
  for (var i = 0, o = 0; i < input.length; i += channels, o += 1) {
    output[o] = luminance(readColor(input, i, channels));
  }
  return sameSizeRaw(raw, output, ChannelCount.one);
}

/// Thresholds pixels.
final class ThresholdOperation implements PipelineOperation {
  /// Creates a threshold operation.
  const ThresholdOperation([this.options = const ThresholdOptions()]);

  /// Options.
  final ThresholdOptions options;

  @override
  String get name => 'threshold';

  @override
  PixelImage apply(PixelImage image) {
    options.validate();
    return mapFrames(image, (raw) {
      final output = raw.bytes;
      final channels = raw.channels.value;
      for (var i = 0; i < output.length; i += channels) {
        if (options.grayscale) {
          final value =
              luminance(readColor(output, i, channels)) >= options.threshold
              ? 255
              : 0;
          for (var c = 0; c < colorChannelCount(channels); c += 1) {
            output[i + c] = value;
          }
        } else {
          for (var c = 0; c < colorChannelCount(channels); c += 1) {
            output[i + c] = output[i + c] >= options.threshold ? 255 : 0;
          }
        }
      }
      return sameSizeRaw(raw, output, raw.channels);
    });
  }
}

/// Applies linear channel adjustment.
final class LinearOperation implements PipelineOperation {
  /// Creates a linear operation.
  const LinearOperation(this.options);

  /// Options.
  final LinearOptions options;

  @override
  String get name => 'linear';

  @override
  PixelImage apply(PixelImage image) {
    return mapFrames(image, (raw) {
      final output = raw.bytes;
      final channels = raw.channels.value;
      options.validate(channels);
      for (var i = 0; i < output.length; i += channels) {
        for (var c = 0; c < channels; c += 1) {
          final multiplier = options.hasChannelValues
              ? options.multipliers[c]
              : options.multiplier;
          final offset = options.hasChannelValues
              ? options.offsets[c]
              : options.offset;
          output[i + c] = byteClamp((output[i + c] * multiplier) + offset);
        }
      }
      return sameSizeRaw(raw, output, raw.channels);
    });
  }
}

/// Tints RGB channels toward [color].
final class TintOperation implements PipelineOperation {
  /// Creates a tint operation.
  const TintOperation(this.color);

  /// Tint color.
  final RgbaColor color;

  @override
  String get name => 'tint';

  @override
  PixelImage apply(PixelImage image) {
    return mapFrames(image, (raw) {
      final output = raw.bytes;
      final channels = raw.channels.value;
      for (var i = 0; i < output.length; i += channels) {
        output[i] = byteClamp((output[i] + color.red) / 2);
        if (channels > 2) {
          output[i + 1] = byteClamp((output[i + 1] + color.green) / 2);
          output[i + 2] = byteClamp((output[i + 2] + color.blue) / 2);
        }
      }
      return sameSizeRaw(raw, output, raw.channels);
    });
  }
}

/// Applies gamma correction.
final class GammaOperation implements PipelineOperation {
  /// Creates a gamma operation.
  const GammaOperation([this.gamma = 2.2, this.gammaOut]);

  /// Input gamma value.
  final num gamma;

  /// Output gamma value.
  final num? gammaOut;

  @override
  String get name => 'gamma';

  @override
  PixelImage apply(PixelImage image) {
    _validateGamma('Gamma', gamma);
    final outputGamma = gammaOut ?? gamma;
    _validateGamma('Gamma output', outputGamma);
    return mapFrames(image, (raw) {
      final output = raw.bytes;
      final channels = raw.channels.value;
      for (var i = 0; i < output.length; i += channels) {
        for (var c = 0; c < colorChannelCount(channels); c += 1) {
          output[i + c] = byteClamp(
            255 * pow(output[i + c] / 255, 1 / outputGamma),
          );
        }
      }
      return sameSizeRaw(raw, output, raw.channels);
    });
  }
}

void _validateGamma(String label, num value) {
  if (value < 1 || value > 3) {
    throw OperationValidationException('$label must be between 1.0 and 3.0.');
  }
}

/// Stretches byte values to full range.
final class NormalizeOperation implements PipelineOperation {
  /// Creates a normalize operation.
  const NormalizeOperation([this.options = const NormalizeOptions()]);

  /// Options.
  final NormalizeOptions options;

  @override
  String get name => 'normalize';

  @override
  PixelImage apply(PixelImage image) {
    options.validate();
    return mapFrames(image, (raw) {
      final output = raw.bytes;
      final channels = raw.channels.value;
      final samples = <int>[];
      for (var i = 0; i < output.length; i += channels) {
        for (var c = 0; c < colorChannelCount(channels); c += 1) {
          samples.add(output[i + c]);
        }
      }
      samples.sort();
      final minValue = _nearestPercentile(samples, options.lower);
      final maxValue = _nearestPercentile(samples, options.upper);
      if (minValue == maxValue) {
        return sameSizeRaw(raw, output, raw.channels);
      }
      for (var i = 0; i < output.length; i += channels) {
        for (var c = 0; c < colorChannelCount(channels); c += 1) {
          output[i + c] = byteClamp(
            (output[i + c] - minValue) * 255 / (maxValue - minValue),
          );
        }
      }
      return sameSizeRaw(raw, output, raw.channels);
    });
  }
}

int _nearestPercentile(List<int> sortedSamples, num percentile) {
  final position = (percentile / 100) * (sortedSamples.length - 1);
  return sortedSamples[position.round()];
}

/// Applies a simple RGB recombination matrix.
final class RecombOperation implements PipelineOperation {
  /// Creates a recombination operation.
  const RecombOperation(this.matrix, {this.dimension = 3});

  /// Row-major matrix values.
  final List<num> matrix;

  /// Matrix width and height.
  final int dimension;

  @override
  String get name => 'recomb';

  @override
  PixelImage apply(PixelImage image) {
    return mapFrames(image, (raw) {
      final channels = raw.channels.value;
      if (channels < dimension) {
        return raw;
      }
      final output = raw.bytes;
      for (var i = 0; i < output.length; i += channels) {
        final source = <int>[
          for (var c = 0; c < dimension; c += 1) output[i + c],
        ];
        for (var row = 0; row < dimension; row += 1) {
          var value = 0.0;
          for (var column = 0; column < dimension; column += 1) {
            value += source[column] * matrix[(row * dimension) + column];
          }
          output[i + row] = byteClamp(value);
        }
      }
      return sameSizeRaw(raw, output, raw.channels);
    });
  }
}
