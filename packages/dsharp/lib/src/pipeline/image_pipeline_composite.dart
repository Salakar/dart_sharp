part of 'image_pipeline.dart';

/// Compositing pipeline operations.
extension ImagePipelineComposite on ImagePipeline {
  /// Applies ordered overlays.
  ImagePipeline composite(List<CompositeLayer> layers) {
    return _append(
      CompositeOperation(List<CompositeLayer>.unmodifiable(layers)),
    );
  }
}
