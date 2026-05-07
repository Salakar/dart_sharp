import 'dart:math';
import 'dart:typed_data';

import '../pipeline/pipeline_operation.dart';
import '../pixels/pixel_image.dart';
import '../source/raw_pixels.dart';
import 'operation_options.dart';
import 'pixel_helpers.dart';

/// Applies contrast-limited adaptive histogram equalization.
final class ClaheOperation implements PipelineOperation {
  /// Creates a CLAHE operation.
  const ClaheOperation([this.options = const ClaheOptions()]);

  /// Options.
  final ClaheOptions options;

  @override
  String get name => 'clahe';

  @override
  PixelImage apply(PixelImage image) {
    options.validate();
    return mapFrames(image, _clahe);
  }

  RawPixels _clahe(RawPixels raw) {
    final input = raw.bytes;
    final output = Uint8List.fromList(input);
    for (var top = 0; top < raw.height; top += options.height) {
      final bottom = min(raw.height, top + options.height);
      for (var left = 0; left < raw.width; left += options.width) {
        final right = min(raw.width, left + options.width);
        final map = _tileMap(raw, input, left, top, right, bottom, options);
        _applyTileMap(raw, input, output, left, top, right, bottom, map);
      }
    }
    return sameSizeRaw(raw, output, raw.channels);
  }
}

Uint8List _tileMap(
  RawPixels raw,
  Uint8List input,
  int left,
  int top,
  int right,
  int bottom,
  ClaheOptions options,
) {
  final histogram = List<int>.filled(256, 0);
  final channels = raw.channels.value;
  for (var y = top; y < bottom; y += 1) {
    for (var x = left; x < right; x += 1) {
      final offset = ((y * raw.width) + x) * channels;
      histogram[luminance(readColor(input, offset, channels))] += 1;
    }
  }
  final unique = histogram.where((count) => count > 0).length;
  if (unique <= 1) {
    return Uint8List.fromList(List<int>.generate(256, (index) => index));
  }
  _clipHistogram(histogram, (right - left) * (bottom - top), options.maxSlope);
  final map = Uint8List(256);
  var cumulative = 0;
  final total = histogram.reduce((a, b) => a + b);
  for (var i = 0; i < histogram.length; i += 1) {
    cumulative += histogram[i];
    map[i] = byteClamp(cumulative * 255 / total);
  }
  return map;
}

void _clipHistogram(List<int> histogram, int tilePixels, num maxSlope) {
  if (maxSlope == 0) {
    return;
  }
  final limit = max(1, (tilePixels * maxSlope / 256).round());
  var excess = 0;
  for (var i = 0; i < histogram.length; i += 1) {
    if (histogram[i] > limit) {
      excess += histogram[i] - limit;
      histogram[i] = limit;
    }
  }
  final addEach = excess ~/ histogram.length;
  final remainder = excess % histogram.length;
  for (var i = 0; i < histogram.length; i += 1) {
    histogram[i] += addEach + (i < remainder ? 1 : 0);
  }
}

void _applyTileMap(
  RawPixels raw,
  Uint8List input,
  Uint8List output,
  int left,
  int top,
  int right,
  int bottom,
  Uint8List map,
) {
  final channels = raw.channels.value;
  for (var y = top; y < bottom; y += 1) {
    for (var x = left; x < right; x += 1) {
      final offset = ((y * raw.width) + x) * channels;
      final color = readColor(input, offset, channels);
      final original = luminance(color);
      final equalized = map[original];
      if (channels == 1 || original == 0) {
        output[offset] = equalized;
      } else {
        final scale = equalized / original;
        output[offset] = byteClamp(color.red * scale);
        if (channels > 1) {
          output[offset + 1] = byteClamp(color.green * scale);
        }
        if (channels > 2) {
          output[offset + 2] = byteClamp(color.blue * scale);
        }
      }
    }
  }
}
