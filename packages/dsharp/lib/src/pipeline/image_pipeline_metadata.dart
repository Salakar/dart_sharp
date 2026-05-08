part of 'image_pipeline.dart';

/// Metadata helpers.
extension ImagePipelineMetadata on ImagePipeline {
  /// Reads image metadata.
  Future<ImageMetadata> metadata({CodecRegistry? registry}) async {
    if (_steps.isEmpty) {
      if (source case BytesImageSource(:final bytes)) {
        final metadata = readEncodedImageMetadata(
          bytes,
          sniffImageFormat(bytes),
        );
        if (metadata != null) {
          return metadata;
        }
      }
    }
    final image = await toPixelImage(registry: registry);
    return ImageMetadata.fromPixelImage(
      image: image,
      format: _sourceFormat(),
      size: _sourceSize(),
    );
  }
}
