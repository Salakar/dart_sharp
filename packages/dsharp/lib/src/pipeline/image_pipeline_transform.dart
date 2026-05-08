part of 'image_pipeline.dart';

/// Transform pipeline operations.
extension ImagePipelineTransform on ImagePipeline {
  /// Flips vertically when [flip] is true.
  ImagePipeline flip([bool flip = true]) {
    return flip ? _append(const FlipOperation()) : this;
  }

  /// Flops horizontally when [flop] is true.
  ImagePipeline flop([bool flop = true]) {
    return flop ? _append(const FlopOperation()) : this;
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
