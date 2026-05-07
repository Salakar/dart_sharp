import 'dart:math';
import 'dart:typed_data';

import '../pipeline/pipeline_operation.dart';
import '../pixels/color.dart';
import '../pixels/pixel_image.dart';
import '../source/raw_pixels.dart';
import 'pixel_helpers.dart';

/// Flips image vertically.
final class FlipOperation implements PipelineOperation {
  /// Creates a flip operation.
  const FlipOperation();

  @override
  String get name => 'flip';

  @override
  PixelImage apply(PixelImage image) => mapFrames(image, _flip);

  RawPixels _flip(RawPixels raw) {
    final channels = raw.channels.value;
    final input = raw.bytes;
    final output = Uint8List(input.length);
    for (var y = 0; y < raw.height; y += 1) {
      final targetY = raw.height - 1 - y;
      _copyRow(input, output, raw.width, channels, y, targetY);
    }
    return sameSizeRaw(raw, output, raw.channels);
  }
}

/// Flops image horizontally.
final class FlopOperation implements PipelineOperation {
  /// Creates a flop operation.
  const FlopOperation();

  @override
  String get name => 'flop';

  @override
  PixelImage apply(PixelImage image) {
    return mapFrames(image, (raw) {
      final channels = raw.channels.value;
      final input = raw.bytes;
      final output = Uint8List(input.length);
      for (var y = 0; y < raw.height; y += 1) {
        for (var x = 0; x < raw.width; x += 1) {
          final source = ((y * raw.width) + x) * channels;
          final target = ((y * raw.width) + (raw.width - 1 - x)) * channels;
          for (var c = 0; c < channels; c += 1) {
            output[target + c] = input[source + c];
          }
        }
      }
      return sameSizeRaw(raw, output, raw.channels);
    });
  }
}

/// Rotates by a multiple of 90 degrees.
final class RotateOperation implements PipelineOperation {
  /// Creates a rotate operation.
  const RotateOperation(this.degrees);

  /// Degrees clockwise.
  final int degrees;

  @override
  String get name => 'rotate';

  @override
  PixelImage apply(PixelImage image) {
    final normalized = ((degrees % 360) + 360) % 360;
    if (normalized == 0) {
      return image;
    }
    if (normalized % 90 == 0) {
      return mapFrames(image, (raw) => _rotate(raw, normalized));
    }
    return mapFrames(image, (raw) => _rotateArbitrary(raw, normalized));
  }
}

/// Auto-orient hook for metadata-driven orientation.
final class AutoOrientOperation implements PipelineOperation {
  /// Creates an auto-orient operation.
  const AutoOrientOperation();

  @override
  String get name => 'autoOrient';

  @override
  PixelImage apply(PixelImage image) => image;
}

RawPixels _rotate(RawPixels raw, int degrees) {
  if (degrees == 180) {
    return const FlipOperation()._flip(_flopRaw(raw));
  }
  final channels = raw.channels.value;
  final input = raw.bytes;
  final output = Uint8List(input.length);
  final outWidth = raw.height;
  final outHeight = raw.width;
  for (var y = 0; y < raw.height; y += 1) {
    for (var x = 0; x < raw.width; x += 1) {
      final source = ((y * raw.width) + x) * channels;
      final targetX = degrees == 90 ? raw.height - 1 - y : y;
      final targetY = degrees == 90 ? x : raw.width - 1 - x;
      final target = ((targetY * outWidth) + targetX) * channels;
      for (var c = 0; c < channels; c += 1) {
        output[target + c] = input[source + c];
      }
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

RawPixels _rotateArbitrary(RawPixels raw, int degrees) {
  final radians = degrees * pi / 180;
  final cosAngle = cos(radians);
  final sinAngle = sin(radians);
  final outWidth = max(
    1,
    ((raw.width * cosAngle.abs()) + (raw.height * sinAngle.abs())).ceil(),
  );
  final outHeight = max(
    1,
    ((raw.width * sinAngle.abs()) + (raw.height * cosAngle.abs())).ceil(),
  );
  final input = raw.bytes;
  final output = Uint8List(outWidth * outHeight * raw.channels.value);
  final inputCenterX = (raw.width - 1) / 2;
  final inputCenterY = (raw.height - 1) / 2;
  final outputCenterX = (outWidth - 1) / 2;
  final outputCenterY = (outHeight - 1) / 2;
  for (var y = 0; y < outHeight; y += 1) {
    for (var x = 0; x < outWidth; x += 1) {
      final dx = x - outputCenterX;
      final dy = y - outputCenterY;
      final sourceX = (cosAngle * dx) + (sinAngle * dy) + inputCenterX;
      final sourceY = (-sinAngle * dx) + (cosAngle * dy) + inputCenterY;
      _copySample(
        raw,
        input,
        output,
        outWidth,
        x,
        y,
        sourceX.round(),
        sourceY.round(),
        RgbaColor.black,
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

RawPixels _flopRaw(RawPixels raw) {
  return (FlopOperation().apply(
    PixelImage.fromRawPixels(raw),
  )).firstFrame.pixels;
}

void _copyRow(
  Uint8List input,
  Uint8List output,
  int width,
  int channels,
  int sourceY,
  int targetY,
) {
  final source = sourceY * width * channels;
  final target = targetY * width * channels;
  output.setRange(target, target + (width * channels), input, source);
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
