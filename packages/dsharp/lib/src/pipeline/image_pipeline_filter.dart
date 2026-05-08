part of 'image_pipeline.dart';

/// Filter and convolution pipeline operations.
extension ImagePipelineFilter on ImagePipeline {
  /// Applies a blur when [blur] is true.
  ImagePipeline blur([bool blur = true]) {
    return blur ? _append(const BlurOperation()) : this;
  }

  /// Applies a sharpen filter.
  ImagePipeline sharpen() {
    return _append(const SharpenOperation());
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
}
