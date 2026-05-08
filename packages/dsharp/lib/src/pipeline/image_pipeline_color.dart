part of 'image_pipeline.dart';

/// Color math pipeline operations.
extension ImagePipelineColor on ImagePipeline {
  /// Converts pixels to grayscale when [grayscale] is true.
  ImagePipeline grayscale([bool grayscale = true]) {
    return grayscale ? _append(const GrayscaleOperation()) : this;
  }

  /// Converts pixels to greyscale when [greyscale] is true.
  ImagePipeline greyscale([bool greyscale = true]) => grayscale(greyscale);

  /// Sets the pipeline colourspace for supported pure Dart colourspaces.
  ImagePipeline pipelineColourspace([String colourspace = 'srgb']) {
    return _append(
      ColourspaceOperation(colourspace, name: 'pipelineColourspace'),
    );
  }

  /// Sets the pipeline colorspace for supported pure Dart colorspaces.
  ImagePipeline pipelineColorspace([String colorspace = 'srgb']) {
    return pipelineColourspace(colorspace);
  }

  /// Converts output to a supported pure Dart colourspace.
  ImagePipeline toColourspace([String colourspace = 'srgb']) {
    return _append(ColourspaceOperation(colourspace, name: 'toColourspace'));
  }

  /// Converts output to a supported pure Dart colorspace.
  ImagePipeline toColorspace([String colorspace = 'srgb']) {
    return toColourspace(colorspace);
  }

  /// Negates pixel channels when [enabled] is true.
  ImagePipeline negate({bool alpha = false, bool enabled = true}) {
    return enabled ? _append(NegateOperation(negateAlpha: alpha)) : this;
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
