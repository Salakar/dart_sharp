import '../pixels/pixel_image.dart';

/// Operation that transforms decoded pixels.
abstract interface class PipelineOperation {
  /// Human-readable operation name.
  String get name;

  /// Applies this operation.
  PixelImage apply(PixelImage image);
}
