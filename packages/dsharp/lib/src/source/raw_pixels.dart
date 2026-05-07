import 'dart:typed_data';

import '../api/exceptions.dart';

/// Number of channels in a raw pixel buffer.
enum ChannelCount {
  /// One channel.
  one(1),

  /// Two channels.
  two(2),

  /// Three channels.
  three(3),

  /// Four channels.
  four(4);

  const ChannelCount(this.value);

  /// Numeric channel count.
  final int value;

  /// Creates a channel count from an integer.
  static ChannelCount fromInt(int value) {
    for (final count in ChannelCount.values) {
      if (count.value == value) {
        return count;
      }
    }
    throw OperationValidationException(
      'Expected channel count between 1 and 4.',
    );
  }
}

/// Pixel sample depth used by a raw pixel buffer.
enum PixelDepth {
  /// Unsigned 8-bit samples.
  uint8(1),

  /// Unsigned 16-bit samples.
  uint16(2),

  /// 32-bit floating-point samples.
  float32(4),

  /// 64-bit floating-point samples.
  float64(8);

  const PixelDepth(this.bytesPerSample);

  /// Bytes per channel sample.
  final int bytesPerSample;
}

/// Whether RGB samples are premultiplied by alpha.
enum Premultiplication {
  /// Samples are not premultiplied.
  none,

  /// Color samples are premultiplied by alpha.
  premultiplied,
}

/// Raw interleaved pixel bytes and their dimensions.
final class RawPixels {
  /// Creates a raw pixel buffer after validating dimensions and length.
  RawPixels({
    required Uint8List bytes,
    required this.width,
    required this.height,
    required this.channels,
    this.depth = PixelDepth.uint8,
    this.premultiplication = Premultiplication.none,
    this.pageHeight,
  }) : _bytes = Uint8List.fromList(bytes) {
    _validate();
  }

  final Uint8List _bytes;

  /// Pixel width.
  final int width;

  /// Pixel height.
  final int height;

  /// Channel count.
  final ChannelCount channels;

  /// Sample depth.
  final PixelDepth depth;

  /// Premultiplication state.
  final Premultiplication premultiplication;

  /// Optional per-frame page height for vertically stacked frames.
  final int? pageHeight;

  /// Defensive copy of the raw bytes.
  Uint8List get bytes => Uint8List.fromList(_bytes);

  /// Expected byte length for this raw layout.
  int get expectedLength {
    return width * height * channels.value * depth.bytesPerSample;
  }

  void _validate() {
    if (width <= 0) {
      throw OperationValidationException('Expected width to be positive.');
    }
    if (height <= 0) {
      throw OperationValidationException('Expected height to be positive.');
    }
    final actualLength = _bytes.length;
    if (actualLength != expectedLength) {
      throw InvalidImageException(
        'Expected $expectedLength raw bytes but received $actualLength.',
      );
    }
    final currentPageHeight = pageHeight;
    if (currentPageHeight != null) {
      if (currentPageHeight <= 0 || currentPageHeight > height) {
        throw OperationValidationException(
          'Expected pageHeight to be between 1 and height.',
        );
      }
      if (height % currentPageHeight != 0) {
        throw OperationValidationException(
          'Expected height to be a multiple of pageHeight.',
        );
      }
    }
  }
}
