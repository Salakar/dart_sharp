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

  /// Applies a threshold when enabled.
  ImagePipeline threshold([Object threshold = 128, Object grayscale = true]) {
    final options = _thresholdOptions(threshold, grayscale);
    return options == null ? this : _append(ThresholdOperation(options));
  }

  /// Applies linear channel adjustment.
  ImagePipeline linear([Object? a = const LinearOptions(), Object? b]) {
    return _append(LinearOperation(_linearOptions(a, b)));
  }

  /// Tints pixels toward [color].
  ImagePipeline tint(RgbaColor color) {
    return _append(TintOperation(color));
  }

  /// Applies gamma correction.
  ImagePipeline gamma([double gamma = 2.2]) {
    return _append(GammaOperation(gamma));
  }

  /// Normalizes channel values between lower and upper percentiles.
  ImagePipeline normalize([
    NormalizeOptions options = const NormalizeOptions(),
  ]) {
    options.validate();
    return _append(NormalizeOperation(options));
  }

  /// Normalises channel values between lower and upper percentiles.
  ImagePipeline normalise([
    NormalizeOptions options = const NormalizeOptions(),
  ]) => normalize(options);

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

  /// Applies a 3x3 or 4x4 recombination matrix.
  ImagePipeline recomb(Object matrix) {
    final parsed = _recombMatrix(matrix);
    return _append(RecombOperation(parsed.values, dimension: parsed.dimension));
  }

  /// Applies CLAHE approximation.
  ImagePipeline clahe([ClaheOptions options = const ClaheOptions()]) {
    return _append(ClaheOperation(options));
  }

  LinearOptions _linearOptions(Object? a, Object? b) {
    if (a is LinearOptions) {
      if (b != null) {
        throw const OperationValidationException(
          'Linear options cannot be combined with an offset argument.',
        );
      }
      return a;
    }
    if (a == null && b == null) {
      return const LinearOptions();
    }
    if (a == null && b is num) {
      return LinearOptions(offset: b);
    }
    if (a is num && b == null) {
      return LinearOptions(multiplier: a);
    }
    if (a is num && b is num) {
      return LinearOptions(multiplier: a, offset: b);
    }
    if (a is List<num> && b is List<num>) {
      if (a.isEmpty || b.isEmpty || a.length != b.length) {
        throw const OperationValidationException(
          'Linear multiplier and offset arrays must have the same length.',
        );
      }
      return LinearOptions(
        multipliers: List<num>.unmodifiable(a),
        offsets: List<num>.unmodifiable(b),
      );
    }
    throw const OperationValidationException(
      'Linear expects numbers, matching number arrays, or LinearOptions.',
    );
  }

  ({int dimension, List<num> values}) _recombMatrix(Object matrix) {
    if (matrix is List<num>) {
      return switch (matrix.length) {
        9 => (dimension: 3, values: List<num>.unmodifiable(matrix)),
        16 => (dimension: 4, values: List<num>.unmodifiable(matrix)),
        _ => throw const OperationValidationException(
          'Recombination matrix must be 3x3 or 4x4.',
        ),
      };
    }
    if (matrix is List<Object?>) {
      final rows = <List<num>>[];
      for (final row in matrix) {
        if (row is! List<Object?>) {
          throw const OperationValidationException(
            'Recombination matrix rows must contain numbers.',
          );
        }
        rows.add(<num>[
          for (final value in row)
            if (value is num)
              value
            else
              throw const OperationValidationException(
                'Recombination matrix rows must contain numbers.',
              ),
        ]);
      }
      final dimension = rows.length;
      if (dimension != 3 && dimension != 4) {
        throw const OperationValidationException(
          'Recombination matrix must be 3x3 or 4x4.',
        );
      }
      if (rows.any((row) => row.length != dimension)) {
        throw const OperationValidationException(
          'Recombination matrix must be square.',
        );
      }
      return (
        dimension: dimension,
        values: List<num>.unmodifiable(rows.expand((row) => row)),
      );
    }
    throw const OperationValidationException(
      'Recombination matrix must be a numeric 3x3 or 4x4 matrix.',
    );
  }

  ThresholdOptions? _thresholdOptions(Object threshold, Object grayscale) {
    if (threshold is bool && !threshold) {
      return null;
    }
    final thresholdValue = switch (threshold) {
      true => 128,
      final int value when value >= 0 && value <= 255 => value,
      _ => throw const OperationValidationException(
        'Threshold must be an integer between 0 and 255.',
      ),
    };
    if (grayscale is! bool) {
      throw const OperationValidationException(
        'Threshold grayscale option must be a boolean.',
      );
    }
    return ThresholdOptions(threshold: thresholdValue, grayscale: grayscale);
  }
}
