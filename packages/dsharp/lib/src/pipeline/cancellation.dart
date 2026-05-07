import '../api/exceptions.dart';

/// Cooperative cancellation token for pipeline execution.
final class CancellationToken {
  /// Creates a token.
  CancellationToken();

  var _isCancelled = false;

  /// Whether cancellation was requested.
  bool get isCancelled => _isCancelled;

  /// Requests cancellation.
  void cancel() {
    _isCancelled = true;
  }

  /// Throws if cancellation was requested.
  void throwIfCancelled() {
    if (_isCancelled) {
      throw const ImageCancellationException('Image pipeline was cancelled.');
    }
  }
}
