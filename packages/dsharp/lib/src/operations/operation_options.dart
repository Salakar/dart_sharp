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

/// Options for linear channel adjustment.
final class LinearOptions {
  /// Creates linear options.
  const LinearOptions({this.multiplier = 1, this.offset = 0});

  /// Multiplier.
  final num multiplier;

  /// Offset.
  final num offset;
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
