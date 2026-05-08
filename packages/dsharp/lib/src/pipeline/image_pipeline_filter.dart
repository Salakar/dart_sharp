part of 'image_pipeline.dart';

/// Filter and convolution pipeline operations.
extension ImagePipelineFilter on ImagePipeline {
  /// Applies a blur when [blur] is true.
  ImagePipeline blur([bool blur = true]) {
    return blur ? _append(const BlurOperation()) : this;
  }

  /// Applies a sharpen filter.
  ImagePipeline sharpen([Object? options, num? flat, num? jagged]) {
    if (options == null) {
      return _append(const SharpenOperation());
    }
    if (options is bool) {
      return options ? _append(const SharpenOperation()) : this;
    }
    if (options is SharpenOptions) {
      if (flat != null || jagged != null) {
        throw const OperationValidationException(
          'Sharpen options cannot be combined with flat or jagged arguments.',
        );
      }
      options.validate();
      return _append(SharpenOperation(options));
    }
    if (options is num) {
      _validateRange('Sharpen sigma', options, 0.01, 10000);
      if (flat != null) {
        _validateRange('Sharpen flat', flat, 0, 10000);
      }
      if (jagged != null) {
        _validateRange('Sharpen jagged', jagged, 0, 10000);
      }
      return _append(
        SharpenOperation(
          SharpenOptions(sigma: options, m1: flat ?? 1, m2: jagged ?? 2),
          true,
        ),
      );
    }
    throw const OperationValidationException(
      'Sharpen expects a boolean, number, or SharpenOptions.',
    );
  }

  /// Applies a median filter with a square mask [size].
  ImagePipeline median([int size = 3]) {
    _validateFilterSize('Median size', size, max: 1000);
    return _append(MedianOperation(size));
  }

  /// Applies dilation with [width] pixels of expansion.
  ImagePipeline dilate([int width = 1]) {
    _validateFilterSize('Dilate width', width);
    return _append(DilateOperation(width));
  }

  /// Applies erosion with [width] pixels of contraction.
  ImagePipeline erode([int width = 1]) {
    _validateFilterSize('Erode width', width);
    return _append(ErodeOperation(width));
  }

  /// Applies a convolution.
  ImagePipeline convolve(ConvolutionKernel kernel) {
    return _append(ConvolveOperation(kernel));
  }

  void _validateFilterSize(String label, int value, {int? max}) {
    if (value <= 0 || (max != null && value > max)) {
      throw OperationValidationException(
        max == null
            ? '$label must be a positive integer.'
            : '$label must be an integer between 1 and $max.',
      );
    }
  }

  void _validateRange(String label, num value, num min, num max) {
    if (value < min || value > max) {
      throw OperationValidationException(
        '$label must be between $min and $max.',
      );
    }
  }
}
