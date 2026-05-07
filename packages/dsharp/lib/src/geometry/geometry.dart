import '../api/exceptions.dart';
import '../pixels/color.dart';

/// Rectangular pixel region.
final class Region {
  /// Creates a rectangular region.
  const Region({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  /// Left offset.
  final int left;

  /// Top offset.
  final int top;

  /// Region width.
  final int width;

  /// Region height.
  final int height;

  /// Validates this region against [imageWidth] and [imageHeight].
  void validate({required int imageWidth, required int imageHeight}) {
    if (left < 0 || top < 0 || width <= 0 || height <= 0) {
      throw const OperationValidationException(
        'Region offsets must be non-negative and dimensions positive.',
      );
    }
    if (left + width > imageWidth || top + height > imageHeight) {
      throw const OperationValidationException('Region exceeds image bounds.');
    }
  }
}

/// Insets used to extend image edges.
final class Insets {
  /// Creates edge insets.
  const Insets({this.top = 0, this.right = 0, this.bottom = 0, this.left = 0});

  /// Creates equal insets for every edge.
  const Insets.all(int value)
    : top = value,
      right = value,
      bottom = value,
      left = value;

  /// Top inset.
  final int top;

  /// Right inset.
  final int right;

  /// Bottom inset.
  final int bottom;

  /// Left inset.
  final int left;

  /// Validates that no edge is negative.
  void validate() {
    if (top < 0 || right < 0 || bottom < 0 || left < 0) {
      throw const OperationValidationException('Insets must be non-negative.');
    }
  }
}

/// How an image should fit requested dimensions.
enum ResizeFit {
  /// Crop to cover both dimensions.
  cover,

  /// Contain inside both dimensions.
  contain,

  /// Stretch to exact dimensions.
  fill,

  /// Preserve aspect ratio inside requested bounds.
  inside,

  /// Preserve aspect ratio outside requested bounds.
  outside,
}

/// Placement gravity for crops or embedded images.
enum Gravity {
  /// Center placement.
  center,

  /// North edge.
  north,

  /// East edge.
  east,

  /// South edge.
  south,

  /// West edge.
  west,

  /// North-east corner.
  northeast,

  /// South-east corner.
  southeast,

  /// South-west corner.
  southwest,

  /// North-west corner.
  northwest,
}

/// Resize kernel identifier.
enum ResizeKernel {
  /// Nearest-neighbor sampling.
  nearest,

  /// Linear sampling.
  linear,

  /// Cubic sampling.
  cubic,

  /// Mitchell-Netravali sampling.
  mitchell,

  /// Lanczos sampling with radius 2.
  lanczos2,

  /// Lanczos sampling with radius 3.
  lanczos3,

  /// Magic Kernel Sharp 2013.
  mks2013,

  /// Magic Kernel Sharp 2021.
  mks2021,
}

/// How new pixels are filled when extending an image.
enum ExtendMode {
  /// Fill with a background color.
  background,

  /// Copy edge pixels.
  copy,

  /// Repeat the image.
  repeat,

  /// Mirror the image.
  mirror,
}

/// Extend options.
final class ExtendOptions {
  /// Creates extend options.
  const ExtendOptions({
    required this.insets,
    this.mode = ExtendMode.background,
    this.background = RgbaColor.black,
  });

  /// Edge insets.
  final Insets insets;

  /// Fill mode.
  final ExtendMode mode;

  /// Background used in [ExtendMode.background].
  final RgbaColor background;
}

/// Trim options.
final class TrimOptions {
  /// Creates trim options.
  const TrimOptions({this.background, this.threshold = 0});

  /// Optional explicit background color. Defaults to the top-left pixel.
  final RgbaColor? background;

  /// Per-channel threshold.
  final int threshold;
}

/// Resize options.
final class ResizeOptions {
  /// Creates resize options.
  const ResizeOptions({
    this.width,
    this.height,
    this.fit = ResizeFit.cover,
    this.gravity = Gravity.center,
    this.kernel = ResizeKernel.lanczos3,
    this.background = RgbaColor.black,
    this.withoutEnlargement = false,
    this.withoutReduction = false,
  });

  /// Target width.
  final int? width;

  /// Target height.
  final int? height;

  /// Fit mode.
  final ResizeFit fit;

  /// Placement gravity.
  final Gravity gravity;

  /// Sampling kernel.
  final ResizeKernel kernel;

  /// Background used for contain mode.
  final RgbaColor background;

  /// Prevent upscaling.
  final bool withoutEnlargement;

  /// Prevent downscaling.
  final bool withoutReduction;
}
