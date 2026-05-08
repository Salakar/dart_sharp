part of 'image_pipeline.dart';

/// Output, cancellation, and metadata pipeline options.
extension ImagePipelineOutput on ImagePipeline {
  /// Selects an output format.
  ImagePipeline toFormat(Object format, {EncoderOptions? options}) {
    final resolved = _resolveFormatArgument(format);
    if (options != null && options.format != resolved) {
      throw const OperationValidationException(
        'Encoder options must match the requested output format.',
      );
    }
    return _copyPipelineWith(
      this,
      outputFormat: resolved,
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

  /// Selects unsupported JPEG 2000 output.
  ImagePipeline jp2([
    UnsupportedEncoderOptions options = const UnsupportedEncoderOptions(
      format: ImageFormat.jp2,
    ),
  ]) {
    return toFormat(ImageFormat.jp2, options: options);
  }

  /// Selects unsupported AVIF output.
  ImagePipeline avif([
    UnsupportedEncoderOptions options = const UnsupportedEncoderOptions(
      format: ImageFormat.avif,
    ),
  ]) {
    return toFormat(ImageFormat.avif, options: options);
  }

  /// Selects unsupported HEIF output.
  ImagePipeline heif([
    UnsupportedEncoderOptions options = const UnsupportedEncoderOptions(
      format: ImageFormat.heif,
    ),
  ]) {
    return toFormat(ImageFormat.heif, options: options);
  }

  /// Selects unsupported JPEG XL output.
  ImagePipeline jxl([
    UnsupportedEncoderOptions options = const UnsupportedEncoderOptions(
      format: ImageFormat.jxl,
    ),
  ]) {
    return toFormat(ImageFormat.jxl, options: options);
  }

  /// Selects raw output.
  ImagePipeline raw([RawEncoderOptions options = const RawEncoderOptions()]) {
    return toFormat(ImageFormat.raw, options: options);
  }

  /// Selects unsupported deep zoom tile output.
  ImagePipeline tile([
    UnsupportedEncoderOptions options = const UnsupportedEncoderOptions(
      format: ImageFormat.deepZoom,
    ),
  ]) {
    return toFormat(ImageFormat.deepZoom, options: options);
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

  /// Requests broad metadata preservation.
  ImagePipeline keepMetadata() => withMetadata();

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

  /// Requests EXIF metadata writing.
  ImagePipeline withExifMetadata(Uint8List exif) {
    return _copyPipelineWith(
      this,
      metadataWrites: _metadataWrites.copyWith(exif: Uint8List.fromList(exif)),
    );
  }

  /// Requests EXIF metadata writing.
  ImagePipeline withExif(Uint8List exif) => withExifMetadata(exif);

  /// Requests ICC profile writing.
  ImagePipeline withIccProfile(Uint8List iccProfile) {
    return _copyPipelineWith(
      this,
      metadataWrites: _metadataWrites.copyWith(
        iccProfile: Uint8List.fromList(iccProfile),
      ),
    );
  }

  /// Requests XMP metadata writing.
  ImagePipeline withXmpMetadata(XmpMetadata xmp) {
    return _copyPipelineWith(
      this,
      metadataWrites: _metadataWrites.copyWith(xmp: xmp),
    );
  }

  /// Requests XMP metadata writing from an XML string.
  ImagePipeline withXmp(String xmp) {
    return withXmpMetadata(XmpMetadata.parse(xmp));
  }
}

ImageFormat _resolveFormatArgument(Object format) {
  if (format is ImageFormat) {
    return format;
  }
  if (format is CodecSupport) {
    return format.format;
  }
  if (format is String) {
    return _resolveFormatId(format);
  }
  if (format is Map<Object?, Object?>) {
    final id = format['id'];
    if (id is String) {
      return _resolveFormatId(id);
    }
  }
  throw const OperationValidationException(
    'Output format must be an ImageFormat, format id string, '
    'CodecSupport, or map with an id string.',
  );
}

ImageFormat _resolveFormatId(String id) {
  final format = ImageFormat.fromId(id);
  if (format != ImageFormat.unknown) {
    return format;
  }
  throw OperationValidationException('Unsupported output format "$id".');
}
