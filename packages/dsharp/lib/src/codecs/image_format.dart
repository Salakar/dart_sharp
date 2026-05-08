/// Known encoded image formats.
enum ImageFormat {
  /// JPEG/JFIF/Exif image data.
  jpeg('jpeg', aliases: ['jpg', 'jpe']),

  /// Portable Network Graphics image data.
  png('png'),

  /// WebP image data.
  webp('webp'),

  /// Graphics Interchange Format image data.
  gif('gif'),

  /// Tagged Image File Format image data.
  tiff('tiff', aliases: ['tif']),

  /// Raw pixel bytes with caller-supplied dimensions.
  raw('raw'),

  /// Netpbm portable pixmap/graymap/bitmap image data.
  ppm('ppm', aliases: ['pnm', 'pgm', 'pbm']),

  /// AV1 Image File Format.
  avif('avif'),

  /// High Efficiency Image File Format.
  heif('heif', aliases: ['heic']),

  /// JPEG 2000 image data.
  jp2('jp2', aliases: ['jpx', 'j2k', 'j2c']),

  /// JPEG XL image data.
  jxl('jxl'),

  /// Scalable Vector Graphics input.
  svg('svg'),

  /// PDF raster input.
  pdf('pdf'),

  /// OpenSlide whole-slide image input.
  openSlide('openslide'),

  /// ImageMagick-backed input.
  magick('magick'),

  /// Digital camera raw input.
  dcraw('dcraw'),

  /// Flexible Image Transport System input.
  fits('fits'),

  /// Radiance HDR RGBE image data.
  rad('rad', aliases: ['hdr', 'rgbe']),

  /// Native V image data.
  vips('v'),

  /// Deep zoom tile output.
  deepZoom('dz', aliases: ['deepzoom', 'tile']),

  /// Unknown or unsupported-by-name image format.
  unknown('unknown');

  const ImageFormat(this.id, {this.aliases = const <String>[]});

  /// Stable lower-case identifier.
  final String id;

  /// Alternate lower-case identifiers accepted for this format.
  final List<String> aliases;

  /// Finds a known format by identifier or alias.
  static ImageFormat fromId(String id) {
    final normalized = id.trim().toLowerCase();
    for (final format in ImageFormat.values) {
      if (format.id == normalized || format.aliases.contains(normalized)) {
        return format;
      }
    }
    return ImageFormat.unknown;
  }
}

/// Whether a codec direction is available.
enum CodecAvailability {
  /// The feature is implemented and expected to work.
  supported,

  /// The feature is intentionally unavailable.
  unsupported,

  /// The feature is planned but not yet implemented.
  planned,
}

/// Pure Dart support metadata for an image format.
final class CodecSupport {
  /// Creates support metadata for one image format.
  const CodecSupport({
    required this.format,
    required this.input,
    required this.output,
    this.animation = CodecAvailability.unsupported,
    this.metadata = CodecAvailability.planned,
    this.reason,
  });

  /// Format this support entry describes.
  final ImageFormat format;

  /// Decode support.
  final CodecAvailability input;

  /// Encode support.
  final CodecAvailability output;

  /// Animated or multi-frame support.
  final CodecAvailability animation;

  /// Metadata read/write support.
  final CodecAvailability metadata;

  /// Optional reason for unsupported or planned state.
  final String? reason;

  /// Whether decoding is currently available.
  bool get canDecode => input == CodecAvailability.supported;

  /// Whether encoding is currently available.
  bool get canEncode => output == CodecAvailability.supported;
}
