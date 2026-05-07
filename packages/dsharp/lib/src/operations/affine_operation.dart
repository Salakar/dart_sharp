import 'dart:math';
import 'dart:typed_data';

import '../api/exceptions.dart';
import '../pipeline/pipeline_operation.dart';
import '../pixels/color.dart';
import '../pixels/pixel_image.dart';
import '../source/raw_pixels.dart';
import 'operation_options.dart';
import 'pixel_helpers.dart';

/// Applies a nearest-neighbor affine transform.
final class AffineOperation implements PipelineOperation {
  /// Creates an affine operation.
  const AffineOperation(this.options);

  /// Options.
  final AffineOptions options;

  @override
  String get name => 'affine';

  @override
  PixelImage apply(PixelImage image) {
    final determinant = (options.a * options.d) - (options.b * options.c);
    if (determinant == 0) {
      throw const OperationValidationException(
        'Affine matrix must be invertible.',
      );
    }
    return mapFrames(image, (raw) => _affine(raw, determinant, options));
  }
}

RawPixels _affine(RawPixels raw, double determinant, AffineOptions options) {
  final bounds = _affineBounds(raw, options);
  final outWidth = max(1, (bounds.maxX - bounds.minX).ceil());
  final outHeight = max(1, (bounds.maxY - bounds.minY).ceil());
  final input = raw.bytes;
  final output = Uint8List(outWidth * outHeight * raw.channels.value);
  for (var y = 0; y < outHeight; y += 1) {
    for (var x = 0; x < outWidth; x += 1) {
      final targetX = x + bounds.minX;
      final targetY = y + bounds.minY;
      final inverseX =
          ((options.d * (targetX - options.odx)) -
              (options.b * (targetY - options.ody))) /
          determinant;
      final inverseY =
          ((-options.c * (targetX - options.odx)) +
              (options.a * (targetY - options.ody))) /
          determinant;
      _copySample(
        raw,
        input,
        output,
        outWidth,
        x,
        y,
        (inverseX - options.idx).round(),
        (inverseY - options.idy).round(),
        options.background,
      );
    }
  }
  return RawPixels(
    bytes: output,
    width: outWidth,
    height: outHeight,
    channels: raw.channels,
    depth: raw.depth,
    premultiplication: raw.premultiplication,
  );
}

void _copySample(
  RawPixels raw,
  Uint8List input,
  Uint8List output,
  int outputWidth,
  int targetX,
  int targetY,
  int sourceX,
  int sourceY,
  RgbaColor background,
) {
  final channels = raw.channels.value;
  final target = ((targetY * outputWidth) + targetX) * channels;
  if (sourceX < 0 ||
      sourceY < 0 ||
      sourceX >= raw.width ||
      sourceY >= raw.height) {
    writeColor(output, target, channels, background);
    return;
  }
  final source = ((sourceY * raw.width) + sourceX) * channels;
  for (var c = 0; c < channels; c += 1) {
    output[target + c] = input[source + c];
  }
}

_AffineBounds _affineBounds(RawPixels raw, AffineOptions options) {
  final xs = <double>[];
  final ys = <double>[];
  for (final corner in <(double, double)>[
    (0, 0),
    (raw.width.toDouble(), 0),
    (0, raw.height.toDouble()),
    (raw.width.toDouble(), raw.height.toDouble()),
  ]) {
    xs.add(
      (options.a * (corner.$1 + options.idx)) +
          (options.b * (corner.$2 + options.idy)) +
          options.odx,
    );
    ys.add(
      (options.c * (corner.$1 + options.idx)) +
          (options.d * (corner.$2 + options.idy)) +
          options.ody,
    );
  }
  return _AffineBounds(
    minX: xs.reduce(min).floorToDouble(),
    minY: ys.reduce(min).floorToDouble(),
    maxX: xs.reduce(max).ceilToDouble(),
    maxY: ys.reduce(max).ceilToDouble(),
  );
}

final class _AffineBounds {
  const _AffineBounds({
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
  });

  final double minX;
  final double minY;
  final double maxX;
  final double maxY;
}
