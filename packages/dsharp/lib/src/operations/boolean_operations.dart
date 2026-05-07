import 'dart:typed_data';

import '../api/exceptions.dart';
import '../pipeline/pipeline_operation.dart';
import '../pixels/pixel_image.dart';
import '../source/raw_pixels.dart';
import 'operation_options.dart';
import 'pixel_helpers.dart';

/// Applies a bitwise operation against another image.
final class BooleanImageOperation implements PipelineOperation {
  /// Creates a boolean operation.
  const BooleanImageOperation({required this.operand, required this.operator});

  /// Operand image.
  final PixelImage operand;

  /// Operator.
  final BooleanOperator operator;

  @override
  String get name => 'boolean';

  @override
  PixelImage apply(PixelImage image) {
    requireSingleFrame(image, name);
    requireSingleFrame(operand, '$name operand');
    final left = image.firstFrame.pixels;
    final right = operand.firstFrame.pixels;
    if (left.width != right.width ||
        left.height != right.height ||
        left.channels != right.channels) {
      throw const OperationValidationException(
        'Boolean operands must have matching dimensions and channels.',
      );
    }
    final a = left.bytes;
    final b = right.bytes;
    final output = Uint8List(a.length);
    for (var i = 0; i < a.length; i += 1) {
      output[i] = _apply(a[i], b[i], operator);
    }
    return PixelImage.fromRawPixels(sameSizeRaw(left, output, left.channels));
  }
}

/// Reduces channels with a bitwise operator.
final class BandBoolOperation implements PipelineOperation {
  /// Creates a band boolean operation.
  const BandBoolOperation(this.operator);

  /// Operator.
  final BooleanOperator operator;

  @override
  String get name => 'bandBool';

  @override
  PixelImage apply(PixelImage image) {
    return mapFrames(image, (raw) {
      final input = raw.bytes;
      final channels = raw.channels.value;
      final output = Uint8List(raw.width * raw.height);
      for (var i = 0, o = 0; i < input.length; i += channels, o += 1) {
        var value = input[i];
        for (var c = 1; c < channels; c += 1) {
          value = _apply(value, input[i + c], operator);
        }
        output[o] = value;
      }
      return sameSizeRaw(raw, output, ChannelCount.one);
    });
  }
}

int _apply(int left, int right, BooleanOperator operator) {
  return switch (operator) {
    BooleanOperator.and => left & right,
    BooleanOperator.or => left | right,
    BooleanOperator.eor => left ^ right,
  };
}
