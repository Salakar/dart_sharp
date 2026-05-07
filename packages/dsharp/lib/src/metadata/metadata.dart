import '../codecs/image_format.dart';
import '../pixels/pixel_image.dart';

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
    this.hasProfile = false,
  });

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
    );
  }
}
