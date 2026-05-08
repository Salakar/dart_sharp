part of 'image_pipeline.dart';

/// Transform pipeline operations.
extension ImagePipelineTransform on ImagePipeline {
  /// Flips vertically when [flip] is true.
  ImagePipeline flip([bool flip = true]) {
    return flip
        ? _appendBefore(
            const FlipOperation(),
            (step) => step is RotateOperation,
          )
        : this;
  }

  /// Flops horizontally when [flop] is true.
  ImagePipeline flop([bool flop = true]) {
    return flop
        ? _appendBefore(
            const FlopOperation(),
            (step) => step is RotateOperation,
          )
        : this;
  }

  /// Rotates by [degrees], or auto-orients when no angle is provided.
  ImagePipeline rotate([Object? degrees, Object? options]) {
    if (degrees == null) {
      return autoOrient();
    }
    final angle = switch (degrees) {
      final num value => value,
      _ => throw const OperationValidationException(
        'Rotate angle must be numeric.',
      ),
    };
    final rotateOptions = switch (options) {
      null => const RotateOptions(),
      final RotateOptions value => value,
      _ => throw const OperationValidationException(
        'Rotate options must be RotateOptions.',
      ),
    };
    return _appendReplacing(
      RotateOperation(angle, rotateOptions),
      (step) => step is RotateOperation,
    );
  }

  /// Adds a metadata-driven auto-orient hook.
  ImagePipeline autoOrient() {
    return _append(const AutoOrientOperation());
  }

  /// Applies an affine transform.
  ImagePipeline affine(Object transform, [Object? options]) {
    return _append(AffineOperation(_affineOptions(transform, options)));
  }

  AffineOptions _affineOptions(Object transform, Object? options) {
    if (transform is AffineOptions) {
      if (options != null) {
        throw const OperationValidationException(
          'AffineOptions cannot be combined with transform options.',
        );
      }
      return transform;
    }
    final matrix = _affineMatrix(transform);
    final transformOptions = switch (options) {
      null => const AffineTransformOptions(),
      final AffineTransformOptions value => value,
      _ => throw const OperationValidationException(
        'Affine options must be AffineTransformOptions.',
      ),
    };
    return AffineOptions(
      a: matrix[0].toDouble(),
      b: matrix[1].toDouble(),
      c: matrix[2].toDouble(),
      d: matrix[3].toDouble(),
      background: transformOptions.background,
      idx: transformOptions.idx,
      idy: transformOptions.idy,
      odx: transformOptions.odx,
      ody: transformOptions.ody,
    );
  }

  List<num> _affineMatrix(Object matrix) {
    if (matrix is List<num>) {
      if (matrix.length == 4) {
        return List<num>.unmodifiable(matrix);
      }
      throw const OperationValidationException(
        'Affine matrix must be a 1x4 or 2x2 numeric array.',
      );
    }
    if (matrix is List<Object?>) {
      if (matrix.length != 2) {
        throw const OperationValidationException(
          'Affine matrix must be a 1x4 or 2x2 numeric array.',
        );
      }
      final values = <num>[];
      for (final row in matrix) {
        if (row is! List<Object?> || row.length != 2) {
          throw const OperationValidationException(
            'Affine matrix must be a 1x4 or 2x2 numeric array.',
          );
        }
        for (final value in row) {
          if (value is! num) {
            throw const OperationValidationException(
              'Affine matrix must be a 1x4 or 2x2 numeric array.',
            );
          }
          values.add(value);
        }
      }
      return List<num>.unmodifiable(values);
    }
    throw const OperationValidationException(
      'Affine matrix must be a 1x4 or 2x2 numeric array.',
    );
  }
}
