part of 'image_pipeline.dart';

/// Bitwise boolean pipeline operations.
extension ImagePipelineBoolean on ImagePipeline {
  /// Applies a bitwise boolean operation against [operand].
  ImagePipeline boolean({
    required PixelImage operand,
    required Object operator,
  }) {
    return _append(
      BooleanImageOperation(
        operand: operand,
        operator: _resolveBooleanOperator(operator),
      ),
    );
  }

  /// Reduces bands with a bitwise operator.
  ImagePipeline bandBool(Object operator) {
    return _append(BandBoolOperation(_resolveBooleanOperator(operator)));
  }

  /// Reduces bands with a bitwise operator using sharp's method spelling.
  ImagePipeline bandbool(Object operator) => bandBool(operator);
}

BooleanOperator _resolveBooleanOperator(Object operator) {
  if (operator is BooleanOperator) {
    return operator;
  }
  if (operator is String) {
    return switch (operator.trim().toLowerCase()) {
      'and' => BooleanOperator.and,
      'or' => BooleanOperator.or,
      'eor' => BooleanOperator.eor,
      _ => throw const OperationValidationException(
        'Boolean operator must be one of and, or, or eor.',
      ),
    };
  }
  throw const OperationValidationException(
    'Boolean operator must be one of and, or, or eor.',
  );
}
