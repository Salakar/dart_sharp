/// Horizontal alignment for generated text images.
enum TextAlign {
  /// Align text to the left edge.
  left,

  /// Align text to the center.
  center,

  /// Align text to the right edge.
  right,
}

/// Word wrapping behavior for generated text images.
enum TextWrap {
  /// Wrap on word boundaries.
  word,

  /// Wrap on character boundaries.
  character,

  /// Prefer word wrapping and fall back to character wrapping.
  wordCharacter,

  /// Do not wrap.
  none,
}

/// Descriptor for a future pure Dart text image renderer.
final class TextImageRequest {
  /// Creates a text image descriptor.
  const TextImageRequest({
    required this.text,
    this.font,
    this.width,
    this.height,
    this.align = TextAlign.left,
    this.wrap = TextWrap.word,
    this.dpi = 72,
    this.hasRgba = false,
  }) : assert(dpi > 0),
       assert(width == null || width > 0),
       assert(height == null || height > 0);

  /// UTF-8 text to render.
  final String text;

  /// Optional font family or implementation-specific font identifier.
  final String? font;

  /// Optional maximum pixel width.
  final int? width;

  /// Optional maximum pixel height.
  final int? height;

  /// Horizontal alignment.
  final TextAlign align;

  /// Wrapping behavior.
  final TextWrap wrap;

  /// Dots per inch.
  final int dpi;

  /// Whether the requested output should include alpha.
  final bool hasRgba;
}
