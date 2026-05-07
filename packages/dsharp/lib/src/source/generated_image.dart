import '../pixels/color.dart';

/// Description of an image generated from a solid background.
final class CreateImage {
  /// Creates a generated image descriptor.
  const CreateImage({
    required this.width,
    required this.height,
    required this.channels,
    required this.background,
    this.pageHeight,
  }) : assert(width > 0),
       assert(height > 0);

  /// Pixel width.
  final int width;

  /// Pixel height.
  final int height;

  /// Channel count, usually 3 or 4.
  final int channels;

  /// Fill background.
  final RgbaColor background;

  /// Optional page height for vertically stacked frames.
  final int? pageHeight;
}
