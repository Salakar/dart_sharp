part of 'image_pipeline.dart';

/// Geometry pipeline operations.
extension ImagePipelineGeometry on ImagePipeline {
  /// Adds a resize operation.
  ImagePipeline resize(ResizeOptions options) {
    return _appendReplacing(
      ResizeOperation(options),
      (step) => step is ResizeOperation,
    );
  }

  /// Adds an extract operation.
  ImagePipeline extract(Region region) {
    return _append(ExtractOperation(region));
  }

  /// Adds an extend operation.
  ImagePipeline extend(ExtendOptions options) {
    return _append(ExtendOperation(options));
  }

  /// Adds a trim operation.
  ImagePipeline trim([TrimOptions options = const TrimOptions()]) {
    return _append(TrimOperation(options));
  }
}
