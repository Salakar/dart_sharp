part of 'image_pipeline.dart';

/// Color math pipeline operations.
extension ImagePipelineColor on ImagePipeline {
  /// Converts pixels to grayscale.
  ImagePipeline grayscale() {
    return _append(const GrayscaleOperation());
  }

  /// Converts pixels to greyscale.
  ImagePipeline greyscale() => grayscale();

  /// Negates pixel channels.
  ImagePipeline negate({bool alpha = false}) {
    return _append(NegateOperation(negateAlpha: alpha));
  }

  /// Applies a threshold.
  ImagePipeline threshold([int threshold = 128, bool grayscale = true]) {
    return _append(
      ThresholdOperation(
        ThresholdOptions(threshold: threshold, grayscale: grayscale),
      ),
    );
  }

  /// Applies linear channel adjustment.
  ImagePipeline linear([LinearOptions options = const LinearOptions()]) {
    return _append(LinearOperation(options));
  }

  /// Tints pixels toward [color].
  ImagePipeline tint(RgbaColor color) {
    return _append(TintOperation(color));
  }

  /// Applies gamma correction.
  ImagePipeline gamma([double gamma = 2.2]) {
    return _append(GammaOperation(gamma));
  }

  /// Normalizes channel values.
  ImagePipeline normalize() {
    return _append(const NormalizeOperation());
  }

  /// Normalises channel values.
  ImagePipeline normalise() => normalize();

  /// Applies brightness modulation.
  ImagePipeline modulate({
    double brightness = 1,
    double saturation = 1,
    double hue = 0,
    double lightness = 0,
  }) {
    return _append(
      ModulateOperation(
        ModulateOptions(
          brightness: brightness,
          saturation: saturation,
          hue: hue,
          lightness: lightness,
        ),
      ),
    );
  }

  /// Applies a 3x3 recombination matrix.
  ImagePipeline recomb(List<num> matrix) {
    return _append(RecombOperation(matrix));
  }

  /// Applies CLAHE approximation.
  ImagePipeline clahe([ClaheOptions options = const ClaheOptions()]) {
    return _append(ClaheOperation(options));
  }
}
