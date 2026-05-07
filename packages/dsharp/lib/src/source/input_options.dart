import '../api/exceptions.dart';

/// Policy for invalid or truncated encoded image data.
enum DecodeFailurePolicy {
  /// Attempt best-effort decoding where the backend supports it.
  none,

  /// Fail on truncated data.
  truncated,

  /// Fail on decoding errors.
  error,

  /// Fail on warnings and errors.
  warning,
}

/// Safety limits applied before or during image decoding.
final class InputSafetyLimits {
  /// Creates input safety limits.
  const InputSafetyLimits({
    this.maxBytes = 256 * 1024 * 1024,
    this.maxPixels = 0x3fff * 0x3fff,
    this.maxWidth = 0x3fff,
    this.maxHeight = 0x3fff,
    this.maxFrames = 100000,
    this.maxMetadataBytes = 16 * 1024 * 1024,
  });

  /// Maximum encoded bytes to buffer.
  final int maxBytes;

  /// Maximum decoded pixels per frame.
  final int maxPixels;

  /// Maximum decoded width.
  final int maxWidth;

  /// Maximum decoded height.
  final int maxHeight;

  /// Maximum frame count.
  final int maxFrames;

  /// Maximum metadata payload bytes.
  final int maxMetadataBytes;

  /// Validates byte length.
  void checkBytes(int length) {
    if (length > maxBytes) {
      throw ImageLimitException('Input exceeds $maxBytes bytes.');
    }
  }

  /// Validates decoded dimensions and frame count.
  void checkImage({
    required int width,
    required int height,
    required int frames,
  }) {
    if (width > maxWidth || height > maxHeight) {
      throw ImageLimitException('Image dimensions exceed configured limits.');
    }
    if (frames > maxFrames) {
      throw ImageLimitException('Image frame count exceeds $maxFrames.');
    }
    if (width * height > maxPixels) {
      throw ImageLimitException('Image exceeds $maxPixels pixels.');
    }
  }
}
