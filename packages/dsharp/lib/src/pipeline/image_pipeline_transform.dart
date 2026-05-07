part of 'image_pipeline.dart';

/// Transform pipeline operations.
extension ImagePipelineTransform on ImagePipeline {
  /// Flips vertically.
  ImagePipeline flip() {
    return _append(const FlipOperation());
  }

  /// Flops horizontally.
  ImagePipeline flop() {
    return _append(const FlopOperation());
  }

  /// Rotates by a multiple of 90 degrees.
  ImagePipeline rotate(int degrees) {
    return _append(RotateOperation(degrees));
  }

  /// Adds a metadata-driven auto-orient hook.
  ImagePipeline autoOrient() {
    return _append(const AutoOrientOperation());
  }

  /// Applies affine transform options.
  ImagePipeline affine(AffineOptions options) {
    return _append(AffineOperation(options));
  }
}
