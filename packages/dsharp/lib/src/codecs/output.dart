import 'dart:typed_data';

import 'image_format.dart';

/// Encoded image bytes and basic output information.
final class EncodedImage {
  /// Creates encoded image output.
  EncodedImage({required Uint8List bytes, required this.info})
    : _bytes = Uint8List.fromList(bytes);

  final Uint8List _bytes;

  /// Defensive copy of encoded bytes.
  Uint8List get bytes => Uint8List.fromList(_bytes);

  /// Output metadata.
  final OutputInfo info;
}

/// Basic output metadata for an encoded image.
final class OutputInfo {
  /// Creates output metadata.
  OutputInfo({
    required this.format,
    required this.size,
    required this.width,
    required this.height,
    required this.channels,
    this.premultiplied = false,
    this.cropOffsetLeft,
    this.cropOffsetTop,
    this.trimOffsetLeft,
    this.trimOffsetTop,
    this.frames = 1,
    this.pageHeight,
    this.loopCount,
    List<Duration> frameDelays = const <Duration>[],
    this.textAutofitDpi,
  }) : frameDelays = List<Duration>.unmodifiable(frameDelays);

  /// Encoded format.
  final ImageFormat format;

  /// Encoded byte size.
  final int size;

  /// Output pixel width.
  final int width;

  /// Output pixel height.
  final int height;

  /// Output channel count.
  final int channels;

  /// Whether output pixels were premultiplied.
  final bool premultiplied;

  /// Optional crop left offset.
  final int? cropOffsetLeft;

  /// Optional crop top offset.
  final int? cropOffsetTop;

  /// Optional trim left offset.
  final int? trimOffsetLeft;

  /// Optional trim top offset.
  final int? trimOffsetTop;

  /// Number of animation frames.
  final int frames;

  /// Optional page height for stacked animation frames.
  final int? pageHeight;

  /// Optional animation loop count.
  final int? loopCount;

  /// Animation frame delays.
  final List<Duration> frameDelays;

  /// Text rendering DPI selected by autofit, when text output is implemented.
  final int? textAutofitDpi;
}

/// Bytes result with output metadata.
final class ImageBytesResult {
  /// Creates a bytes result.
  ImageBytesResult({required Uint8List bytes, required this.info})
    : _bytes = Uint8List.fromList(bytes);

  final Uint8List _bytes;

  /// Defensive copy of bytes.
  Uint8List get bytes => Uint8List.fromList(_bytes);

  /// Output metadata.
  final OutputInfo info;
}
