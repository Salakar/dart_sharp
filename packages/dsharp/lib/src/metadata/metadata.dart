import 'dart:typed_data';

import '../codecs/image_format.dart';
import '../pixels/pixel_image.dart';
import 'xmp_metadata.dart';

/// Basic metadata for an image or decoded pixel buffer.
final class ImageMetadata {
  /// Creates image metadata.
  const ImageMetadata({
    required this.format,
    required this.width,
    required this.height,
    required this.channels,
    required this.hasAlpha,
    this.size,
    this.frames = 1,
    this.pageHeight,
    this.loopCount,
    this.density,
    bool hasProfile = false,
    bool hasExif = false,
    bool hasXmp = false,
    Uint8List? iccProfile,
    Uint8List? exif,
    this.xmp,
    this.bitDepth,
    this.orientation,
    this.isProgressive = false,
  }) : _iccProfile = iccProfile,
       _exif = exif,
       hasProfile = hasProfile || iccProfile != null,
       hasExif = hasExif || exif != null,
       hasXmp = hasXmp || xmp != null;

  /// Encoded or source format.
  final ImageFormat format;

  /// Encoded byte size when known.
  final int? size;

  /// Pixel width.
  final int width;

  /// Pixel height.
  final int height;

  /// Channel count.
  final int channels;

  /// Whether an alpha channel is present.
  final bool hasAlpha;

  /// Number of frames.
  final int frames;

  /// Optional page height for stacked frames.
  final int? pageHeight;

  /// Optional animation loop count.
  final int? loopCount;

  /// Optional pixel density in DPI.
  final double? density;

  /// Whether an ICC or similar color profile is present.
  final bool hasProfile;

  final Uint8List? _iccProfile;

  /// Embedded ICC profile bytes when present and parsed.
  Uint8List? get iccProfile => _copyBytes(_iccProfile);

  /// Whether EXIF metadata is present.
  final bool hasExif;

  final Uint8List? _exif;

  /// Embedded EXIF bytes when present and parsed.
  Uint8List? get exif => _copyBytes(_exif);

  /// Whether XMP metadata is present.
  final bool hasXmp;

  /// Embedded XMP metadata when present and parsed.
  final XmpMetadata? xmp;

  /// Embedded XMP metadata as text when present and parsed.
  String? get xmpAsString => xmp?.xmlText;

  /// Encoded bits per sample when known.
  final int? bitDepth;

  /// EXIF orientation value when present.
  final int? orientation;

  /// Whether the encoded image uses progressive/interlaced storage.
  final bool isProgressive;

  /// Creates metadata from decoded pixels.
  factory ImageMetadata.fromPixelImage({
    required PixelImage image,
    required ImageFormat format,
    int? size,
  }) {
    return ImageMetadata(
      format: format,
      size: size,
      width: image.width,
      height: image.height,
      channels: image.channels.value,
      hasAlpha: image.channels.value == 2 || image.channels.value == 4,
      frames: image.frames.length,
      pageHeight: image.firstFrame.pixels.pageHeight,
      loopCount: image.loopCount,
      bitDepth: 8,
    );
  }
}

Uint8List? _copyBytes(Uint8List? bytes) {
  return bytes == null ? null : Uint8List.fromList(bytes);
}
