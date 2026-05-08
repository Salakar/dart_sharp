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

  /// Applies a median filter.
  ImagePipeline median() {
    return _append(const MedianOperation());
  }

  /// Applies dilation.
  ImagePipeline dilate() {
    return _append(const DilateOperation());
  }

  /// Applies erosion.
  ImagePipeline erode() {
    return _append(const ErodeOperation());
  }

  /// Applies a convolution.
  ImagePipeline convolve(ConvolutionKernel kernel) {
    return _append(ConvolveOperation(kernel));
  }
}
