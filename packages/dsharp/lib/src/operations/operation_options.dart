import '../api/exceptions.dart';
import '../pixels/color.dart';

/// Bitwise boolean operator.
enum BooleanOperator {
  /// Bitwise and.
  and,

  /// Bitwise or.
  or,

  /// Bitwise exclusive-or.
  eor,
}

/// Blur precision hint.
enum BlurPrecision {
  /// Integer precision.
  integer,

  /// Floating-point precision.
  float,

  /// Approximate precision.
  approximate,
}

/// Named channel selector.
enum ImageChannel {
  /// Red channel.
  red(0),

  /// Green channel.
  green(1),

  /// Blue channel.
  blue(2),

  /// Alpha channel.
  alpha(3);

  const ImageChannel(this.channelIndex);

  /// Zero-based channel index.
  final int channelIndex;

  /// Resolves an integer, enum, or channel name to a zero-based index.
  static int resolve(Object channel) {
    if (channel is int) {
      return channel;
    }
    if (channel is ImageChannel) {
      return channel.channelIndex;
    }
    if (channel is String) {
      for (final value in ImageChannel.values) {
        if (value.name == channel) {
          return value.index;
        }
      }
    }
    throw OperationValidationException(
      'Expected channel to be an integer or one of: red, green, blue, alpha.',
    );
  }
}

/// Matrix used by convolution.
final class ConvolutionKernel {
  /// Creates a convolution kernel.
  const ConvolutionKernel({
    required this.width,
    required this.height,
    required this.values,
    this.scale = 1,
    this.offset = 0,
  });

  /// Kernel width.
  final int width;

  /// Kernel height.
  final int height;

  /// Row-major kernel values.
  final List<num> values;

  /// Scale applied after summing.
  final num scale;

  /// Offset applied after scaling.
  final num offset;

  /// Validates kernel shape and scale.
  void validate() {
    if (width <= 0 || height <= 0 || width.isEven || height.isEven) {
      throw const OperationValidationException(
        'Convolution kernel dimensions must be positive odd numbers.',
      );
    }
    if (values.length != width * height) {
      throw const OperationValidationException(
        'Convolution kernel values must match width * height.',
      );
    }
    if (scale == 0) {
      throw const OperationValidationException(
        'Convolution kernel scale must not be zero.',
      );
    }
  }
}

/// Options for sigma-based sharpening.
final class SharpenOptions {
  /// Creates sharpen options.
  const SharpenOptions({
    required this.sigma,
    this.m1 = 1,
    this.m2 = 2,
    this.x1 = 2,
    this.y2 = 10,
    this.y3 = 20,
  });

  /// Gaussian mask sigma.
  final num sigma;

  /// Sharpening amount for flat areas.
  final num m1;

  /// Sharpening amount for jagged areas.
  final num m2;

  /// Threshold between flat and jagged areas.
  final num x1;

  /// Maximum brightening amount.
  final num y2;

  /// Maximum darkening amount.
  final num y3;

  /// Validates sharpen options.
  void validate({bool legacySigmaRange = false}) {
    final minSigma = legacySigmaRange ? 0.01 : 0.000001;
    final maxSigma = legacySigmaRange ? 10000 : 10;
    if (sigma < minSigma || sigma > maxSigma) {
      throw OperationValidationException(
        'Sharpen sigma must be between $minSigma and $maxSigma.',
      );
    }
    _validateRange('Sharpen m1', m1, 0, 1000000);
    _validateRange('Sharpen m2', m2, 0, 1000000);
    _validateRange('Sharpen x1', x1, 0, 1000000);
    _validateRange('Sharpen y2', y2, 0, 1000000);
    _validateRange('Sharpen y3', y3, 0, 1000000);
  }
}

/// Options for sigma-based Gaussian blur.
final class BlurOptions {
  /// Creates blur options.
  const BlurOptions({
    required this.sigma,
    this.precision = BlurPrecision.integer,
    this.minAmplitude = 0.2,
  });

  /// Gaussian mask sigma.
  final num sigma;

  /// Precision hint.
  final BlurPrecision precision;

  /// Minimum amplitude used to size the Gaussian mask.
  final num minAmplitude;

  /// Validates blur options.
  void validate() {
    _validateRange('Blur sigma', sigma, 0.3, 1000);
    _validateRange('Blur minAmplitude', minAmplitude, 0.001, 1);
  }
}

/// Options for affine transforms.
final class AffineOptions {
  /// Creates affine options.
  const AffineOptions({
    required this.a,
    required this.b,
    required this.c,
    required this.d,
    this.background = RgbaColor.black,
    this.idx = 0,
    this.idy = 0,
    this.odx = 0,
    this.ody = 0,
  });

  /// Matrix value.
  final double a;

  /// Matrix value.
  final double b;

  /// Matrix value.
  final double c;

  /// Matrix value.
  final double d;

  /// Background color.
  final RgbaColor background;

  /// Input horizontal offset.
  final double idx;

  /// Input vertical offset.
  final double idy;

  /// Output horizontal offset.
  final double odx;

  /// Output vertical offset.
  final double ody;
}

void _validateRange(String label, num value, num min, num max) {
  if (value < min || value > max) {
    throw OperationValidationException('$label must be between $min and $max.');
  }
}

/// Options for linear channel adjustment.
final class LinearOptions {
  /// Creates linear options.
  const LinearOptions({
    this.multiplier = 1,
    this.offset = 0,
    this.multipliers = const <num>[],
    this.offsets = const <num>[],
  });

  /// Scalar multiplier.
  final num multiplier;

  /// Scalar offset.
  final num offset;

  /// Per-channel multipliers.
  final List<num> multipliers;

  /// Per-channel offsets.
  final List<num> offsets;

  /// Whether per-channel values are used.
  bool get hasChannelValues => multipliers.isNotEmpty || offsets.isNotEmpty;

  /// Validates per-channel values against [channels].
  void validate(int channels) {
    if (!hasChannelValues) {
      return;
    }
    if (multipliers.length != offsets.length) {
      throw const OperationValidationException(
        'Linear multiplier and offset arrays must have the same length.',
      );
    }
    if (multipliers.length != channels) {
      throw const OperationValidationException(
        'Linear arrays must match the image channel count.',
      );
    }
  }
}

/// Options for thresholding.
final class ThresholdOptions {
  /// Creates threshold options.
  const ThresholdOptions({this.threshold = 128, this.grayscale = true});

  /// Threshold byte.
  final int threshold;

  /// Whether to threshold by luminance instead of per-channel.
  final bool grayscale;

  /// Validates threshold range.
  void validate() {
    if (threshold < 0 || threshold > 255) {
      throw const OperationValidationException(
        'Threshold must be between 0 and 255.',
      );
    }
  }
}

/// Options for negating image channels.
final class NegateOptions {
  /// Creates negate options.
  const NegateOptions({this.alpha = true});

  /// Whether alpha channels should be negated.
  final bool alpha;
}

/// Options for flattening alpha against a background.
final class FlattenOptions {
  /// Creates flatten options.
  const FlattenOptions({required this.background});

  /// Background color.
  final RgbaColor background;
}

/// Options for percentile-based normalization.
final class NormalizeOptions {
  /// Creates normalize options.
  const NormalizeOptions({this.lower = 1, this.upper = 99});

  /// Lower percentile to clip before stretching.
  final num lower;

  /// Upper percentile to clip before stretching.
  final num upper;

  /// Validates percentile bounds.
  void validate() {
    if (lower < 0 || lower > 99) {
      throw const OperationValidationException(
        'Normalize lower must be between 0 and 99.',
      );
    }
    if (upper < 1 || upper > 100) {
      throw const OperationValidationException(
        'Normalize upper must be between 1 and 100.',
      );
    }
    if (lower >= upper) {
      throw const OperationValidationException(
        'Normalize lower must be less than upper.',
      );
    }
  }
}

/// Options for brightness, saturation, hue, and lightness modulation.
final class ModulateOptions {
  /// Creates modulate options.
  const ModulateOptions({
    this.brightness = 1,
    this.saturation = 1,
    this.hue = 0,
    this.lightness = 0,
  });

  /// Brightness multiplier.
  final double brightness;

  /// Saturation multiplier.
  final double saturation;

  /// Hue rotation in degrees.
  final double hue;

  /// Lightness offset in percentage points.
  final double lightness;
}

/// Options for contrast-limited adaptive histogram equalization.
final class ClaheOptions {
  /// Creates CLAHE options.
  const ClaheOptions({this.width = 8, this.height = 8, this.maxSlope = 3});

  /// Tile width.
  final int width;

  /// Tile height.
  final int height;

  /// Histogram clip slope. Zero disables clipping.
  final num maxSlope;

  /// Validates CLAHE options.
  void validate() {
    if (width <= 0 || height <= 0) {
      throw const OperationValidationException(
        'CLAHE tile width and height must be positive.',
      );
    }
    if (maxSlope < 0 || maxSlope > 100) {
      throw const OperationValidationException(
        'CLAHE maxSlope must be between 0 and 100.',
      );
    }
  }
}
