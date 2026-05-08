part of 'image_pipeline.dart';

/// Bitwise boolean pipeline operations.
extension ImagePipelineBoolean on ImagePipeline {
  /// Applies a bitwise boolean operation against [operand].
  ImagePipeline boolean({
    required PixelImage operand,
    required BooleanOperator operator,
  }) {
    return _append(BooleanImageOperation(operand: operand, operator: operator));
  }

  /// Reduces bands with a bitwise operator.
  ImagePipeline bandBool(BooleanOperator operator) {
    return _append(BandBoolOperation(operator));
  }

  /// Reduces bands with a bitwise operator using sharp's method spelling.
  ImagePipeline bandbool(BooleanOperator operator) => bandBool(operator);
}
