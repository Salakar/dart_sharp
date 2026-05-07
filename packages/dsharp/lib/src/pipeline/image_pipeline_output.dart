part of 'image_pipeline.dart';

/// Output, cancellation, and metadata pipeline options.
extension ImagePipelineOutput on ImagePipeline {
  /// Selects an output format.
  ImagePipeline toFormat(ImageFormat format, {EncoderOptions? options}) {
    if (options != null && options.format != format) {
      throw const OperationValidationException(
        'Encoder options must match the requested output format.',
      );
    }
    return _copyPipelineWith(
      this,
      outputFormat: format,
      encoderOptions: options,
    );
  }

  /// Selects JPEG output.
  ImagePipeline jpeg([
    JpegEncoderOptions options = const JpegEncoderOptions(),
  ]) {
    return toFormat(ImageFormat.jpeg, options: options);
  }

  /// Selects PNG output.
  ImagePipeline png([PngEncoderOptions options = const PngEncoderOptions()]) {
    return toFormat(ImageFormat.png, options: options);
  }

  /// Selects GIF output.
  ImagePipeline gif([GifEncoderOptions options = const GifEncoderOptions()]) {
    return toFormat(ImageFormat.gif, options: options);
  }

  /// Selects TIFF output.
  ImagePipeline tiff([
    TiffEncoderOptions options = const TiffEncoderOptions(),
  ]) {
    return toFormat(ImageFormat.tiff, options: options);
  }

  /// Selects WebP output.
  ImagePipeline webp([
    WebpEncoderOptions options = const WebpEncoderOptions(),
  ]) {
    return toFormat(ImageFormat.webp, options: options);
  }

  /// Selects raw output.
  ImagePipeline raw([RawEncoderOptions options = const RawEncoderOptions()]) {
    return toFormat(ImageFormat.raw, options: options);
  }

  /// Adds a cooperative cancellation token.
  ImagePipeline withCancellationToken(CancellationToken token) {
    return _copyPipelineWith(this, cancellationToken: token);
  }

  /// Adds a timeout for byte output.
  ImagePipeline timeout(Duration duration) {
    return _copyPipelineWith(this, timeout: duration);
  }

  /// Requests broad metadata preservation.
  ImagePipeline withMetadata() {
    return _copyPipelineWith(
      this,
      metadataWrites: _metadataWrites.copyWith(withMetadata: true),
    );
  }

  /// Requests EXIF preservation.
  ImagePipeline keepExif() {
    return _copyPipelineWith(
      this,
      metadataWrites: _metadataWrites.copyWith(keepExif: true),
    );
  }

  /// Requests ICC profile preservation.
  ImagePipeline keepIccProfile() {
    return _copyPipelineWith(
      this,
      metadataWrites: _metadataWrites.copyWith(keepIcc: true),
    );
  }

  /// Requests XMP preservation.
  ImagePipeline keepXmp() {
    return _copyPipelineWith(
      this,
      metadataWrites: _metadataWrites.copyWith(keepXmp: true),
    );
  }

  /// Requests XMP metadata writing.
  ImagePipeline withXmpMetadata(XmpMetadata xmp) {
    return _copyPipelineWith(
      this,
      metadataWrites: _metadataWrites.copyWith(xmp: xmp),
    );
  }
}
