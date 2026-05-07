part of 'image_pipeline.dart';

/// Metadata helpers.
extension ImagePipelineMetadata on ImagePipeline {
  /// Reads image metadata.
  Future<ImageMetadata> metadata({CodecRegistry? registry}) async {
    if (source case BytesImageSource(
      :final bytes,
    ) when sniffImageFormat(bytes) == ImageFormat.webp) {
      final info = readWebpInfo(bytes);
      return ImageMetadata(
        format: ImageFormat.webp,
        size: bytes.length,
        width: info.width,
        height: info.height,
        channels: info.hasAlpha ? 4 : 3,
        hasAlpha: info.hasAlpha,
        frames: info.frames.isEmpty ? 1 : info.frames.length,
        loopCount: info.isAnimated ? info.loopCount : null,
      );
    }
    final image = await toPixelImage(registry: registry);
    return ImageMetadata.fromPixelImage(
      image: image,
      format: _sourceFormat(),
      size: _sourceSize(),
    );
  }
}
