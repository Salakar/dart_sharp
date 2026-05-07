import 'dart:math';

import '../pipeline/pipeline_operation.dart';
import '../pixels/color.dart';
import '../pixels/pixel_image.dart';
import 'operation_options.dart';
import 'pixel_helpers.dart';

/// Applies brightness, saturation, hue, and lightness modulation.
final class ModulateOperation implements PipelineOperation {
  /// Creates a modulate operation.
  const ModulateOperation([this.options = const ModulateOptions()]);

  /// Options.
  final ModulateOptions options;

  @override
  String get name => 'modulate';

  @override
  PixelImage apply(PixelImage image) {
    return mapFrames(image, (raw) {
      final output = raw.bytes;
      final channels = raw.channels.value;
      for (var i = 0; i < output.length; i += channels) {
        final color = readColor(output, i, channels);
        num red = color.red * options.brightness;
        num green = color.green * options.brightness;
        num blue = color.blue * options.brightness;
        if (options.saturation != 1) {
          final gray = luminance(color);
          red = gray + ((red - gray) * options.saturation);
          green = gray + ((green - gray) * options.saturation);
          blue = gray + ((blue - gray) * options.saturation);
        }
        if (options.hue % 360 != 0) {
          final rotated = _rotateHue(red, green, blue, options.hue);
          red = rotated.red;
          green = rotated.green;
          blue = rotated.blue;
        }
        final lightnessOffset = options.lightness * 255 / 100;
        output[i] = byteClamp(red + lightnessOffset);
        if (channels > 1) {
          output[i + 1] = byteClamp(green + lightnessOffset);
        }
        if (channels > 2) {
          output[i + 2] = byteClamp(blue + lightnessOffset);
        }
      }
      return sameSizeRaw(raw, output, raw.channels);
    });
  }
}

RgbaColor _rotateHue(num red, num green, num blue, double degrees) {
  final angle = degrees * pi / 180;
  final cosAngle = cos(angle);
  final sinAngle = sin(angle);
  final y = (0.299 * red) + (0.587 * green) + (0.114 * blue);
  final i = (0.596 * red) - (0.274 * green) - (0.322 * blue);
  final q = (0.211 * red) - (0.523 * green) + (0.312 * blue);
  final rotatedI = (i * cosAngle) - (q * sinAngle);
  final rotatedQ = (i * sinAngle) + (q * cosAngle);
  return RgbaColor(
    red: byteClamp(y + (0.956 * rotatedI) + (0.621 * rotatedQ)),
    green: byteClamp(y - (0.272 * rotatedI) - (0.647 * rotatedQ)),
    blue: byteClamp(y - (1.106 * rotatedI) + (1.703 * rotatedQ)),
  );
}
