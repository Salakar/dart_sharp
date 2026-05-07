/// Base exception for image processing failures.
base class ImageProcessingException implements Exception {
  /// Creates an image processing exception.
  const ImageProcessingException(this.message, {this.cause});

  /// Human-readable failure message.
  final String message;

  /// Optional underlying failure.
  final Object? cause;

  @override
  String toString() => cause == null
      ? 'ImageProcessingException: $message'
      : 'ImageProcessingException: $message ($cause)';
}

/// Thrown when input bytes or pixel data cannot be decoded safely.
final class InvalidImageException extends ImageProcessingException {
  /// Creates an invalid image exception.
  const InvalidImageException(super.message, {super.cause});
}

/// Thrown when a requested codec is not available in the pure Dart core.
final class UnsupportedCodecException extends ImageProcessingException {
  /// Creates an unsupported codec exception.
  const UnsupportedCodecException(super.message, {super.cause});
}

/// Thrown when input safety limits would be exceeded.
final class ImageLimitException extends ImageProcessingException {
  /// Creates an image limit exception.
  const ImageLimitException(super.message, {super.cause});
}

/// Thrown when an operation receives invalid parameters.
final class OperationValidationException extends ImageProcessingException {
  /// Creates an operation validation exception.
  const OperationValidationException(super.message, {super.cause});
}

/// Thrown when processing is cancelled.
final class ImageCancellationException extends ImageProcessingException {
  /// Creates an image cancellation exception.
  const ImageCancellationException(super.message, {super.cause});
}
