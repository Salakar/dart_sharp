import '../codecs/image_format.dart';

/// Runtime capability information for the pure Dart implementation.
final class DsharpCapabilities {
  const DsharpCapabilities._(this._formats);

  /// Default capability table for the current package version.
  static const DsharpCapabilities current =
      DsharpCapabilities._(<ImageFormat, CodecSupport>{
        ImageFormat.raw: CodecSupport(
          format: ImageFormat.raw,
          input: CodecAvailability.supported,
          output: CodecAvailability.supported,
          metadata: CodecAvailability.unsupported,
        ),
        ImageFormat.png: CodecSupport(
          format: ImageFormat.png,
          input: CodecAvailability.supported,
          output: CodecAvailability.supported,
          metadata: CodecAvailability.supported,
        ),
        ImageFormat.jpeg: CodecSupport(
          format: ImageFormat.jpeg,
          input: CodecAvailability.supported,
          output: CodecAvailability.supported,
          metadata: CodecAvailability.supported,
        ),
        ImageFormat.gif: CodecSupport(
          format: ImageFormat.gif,
          input: CodecAvailability.supported,
          output: CodecAvailability.supported,
          animation: CodecAvailability.supported,
          metadata: CodecAvailability.supported,
        ),
        ImageFormat.tiff: CodecSupport(
          format: ImageFormat.tiff,
          input: CodecAvailability.supported,
          output: CodecAvailability.supported,
          metadata: CodecAvailability.supported,
        ),
        ImageFormat.webp: CodecSupport(
          format: ImageFormat.webp,
          input: CodecAvailability.supported,
          output: CodecAvailability.supported,
          animation: CodecAvailability.supported,
          metadata: CodecAvailability.supported,
        ),
        ImageFormat.ppm: CodecSupport(
          format: ImageFormat.ppm,
          input: CodecAvailability.supported,
          output: CodecAvailability.supported,
          metadata: CodecAvailability.unsupported,
        ),
        ImageFormat.avif: CodecSupport(
          format: ImageFormat.avif,
          input: CodecAvailability.unsupported,
          output: CodecAvailability.unsupported,
          reason: 'No pure Dart AVIF codec is wired yet.',
        ),
        ImageFormat.heif: CodecSupport(
          format: ImageFormat.heif,
          input: CodecAvailability.unsupported,
          output: CodecAvailability.unsupported,
          reason: 'No pure Dart HEIF codec is wired yet.',
        ),
        ImageFormat.jp2: CodecSupport(
          format: ImageFormat.jp2,
          input: CodecAvailability.unsupported,
          output: CodecAvailability.unsupported,
          reason: 'No pure Dart JPEG 2000 codec is wired yet.',
        ),
        ImageFormat.jxl: CodecSupport(
          format: ImageFormat.jxl,
          input: CodecAvailability.unsupported,
          output: CodecAvailability.unsupported,
          reason: 'No pure Dart JPEG XL codec is wired yet.',
        ),
        ImageFormat.svg: CodecSupport(
          format: ImageFormat.svg,
          input: CodecAvailability.unsupported,
          output: CodecAvailability.unsupported,
          reason: 'SVG rasterization needs a pure Dart renderer.',
        ),
        ImageFormat.pdf: CodecSupport(
          format: ImageFormat.pdf,
          input: CodecAvailability.unsupported,
          output: CodecAvailability.unsupported,
          reason: 'PDF rasterization is not available in the pure Dart core.',
        ),
        ImageFormat.openSlide: CodecSupport(
          format: ImageFormat.openSlide,
          input: CodecAvailability.unsupported,
          output: CodecAvailability.unsupported,
          reason: 'OpenSlide support depends on native libraries.',
        ),
        ImageFormat.magick: CodecSupport(
          format: ImageFormat.magick,
          input: CodecAvailability.unsupported,
          output: CodecAvailability.unsupported,
          reason: 'Magick-backed formats depend on native libraries.',
        ),
        ImageFormat.dcraw: CodecSupport(
          format: ImageFormat.dcraw,
          input: CodecAvailability.unsupported,
          output: CodecAvailability.unsupported,
          reason: 'Camera raw decoding is not implemented in pure Dart.',
        ),
        ImageFormat.fits: CodecSupport(
          format: ImageFormat.fits,
          input: CodecAvailability.supported,
          output: CodecAvailability.supported,
          metadata: CodecAvailability.unsupported,
        ),
        ImageFormat.rad: CodecSupport(
          format: ImageFormat.rad,
          input: CodecAvailability.supported,
          output: CodecAvailability.supported,
          metadata: CodecAvailability.unsupported,
        ),
        ImageFormat.vips: CodecSupport(
          format: ImageFormat.vips,
          input: CodecAvailability.unsupported,
          output: CodecAvailability.unsupported,
          reason: 'Native V image data is not part of the pure Dart core.',
        ),
        ImageFormat.deepZoom: CodecSupport(
          format: ImageFormat.deepZoom,
          input: CodecAvailability.unsupported,
          output: CodecAvailability.planned,
          reason: 'Tile output requires an in-house archive/container writer.',
        ),
      });

  final Map<ImageFormat, CodecSupport> _formats;

  /// All known format capability entries.
  Iterable<CodecSupport> get formats => _formats.values;

  /// Returns capability information for [format].
  CodecSupport supportFor(ImageFormat format) {
    return _formats[format] ??
        CodecSupport(
          format: format,
          input: CodecAvailability.unsupported,
          output: CodecAvailability.unsupported,
          reason: 'Unknown image format.',
        );
  }
}
