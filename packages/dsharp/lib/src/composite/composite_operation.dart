import 'dart:typed_data';

import '../geometry/geometry.dart';
import '../operations/pixel_helpers.dart';
import '../pipeline/pipeline_operation.dart';
import '../pixels/pixel_image.dart';
import '../source/raw_pixels.dart';
import 'blend_math.dart';
import 'composite_layer.dart';

/// Applies ordered composite layers.
final class CompositeOperation implements PipelineOperation {
  /// Creates a composite operation.
  const CompositeOperation(this.layers);

  /// Layers applied in order.
  final List<CompositeLayer> layers;

  @override
  String get name => 'composite';

  @override
  PixelImage apply(PixelImage image) {
    for (final layer in layers) {
      layer.validate();
    }
    return PixelImage(
      frames: <ImageFrame>[
        for (var i = 0; i < image.frames.length; i += 1)
          ImageFrame(
            pixels: _applyFrame(image.frames[i].pixels, i),
            delay: image.frames[i].delay,
          ),
      ],
      loopCount: image.loopCount,
    );
  }

  RawPixels _applyFrame(RawPixels base, int frameIndex) {
    final output = _toRgbaBytes(base);
    for (final layer in layers) {
      _applyLayer(output, base.width, base.height, layer, frameIndex);
    }
    return RawPixels(
      bytes: output,
      width: base.width,
      height: base.height,
      channels: ChannelCount.four,
      pageHeight: base.pageHeight,
    );
  }
}

void _applyLayer(
  Uint8List output,
  int width,
  int height,
  CompositeLayer layer,
  int frameIndex,
) {
  final overlay = _overlayFrame(layer.image, frameIndex);
  final placement = _placement(width, height, overlay, layer);
  if (layer.tile) {
    for (var y = 0; y < height; y += 1) {
      for (var x = 0; x < width; x += 1) {
        final ox = _positiveMod(x - placement.left, overlay.width);
        final oy = _positiveMod(y - placement.top, overlay.height);
        _blendAt(output, width, x, y, overlay, ox, oy, layer);
      }
    }
    return;
  }
  for (var oy = 0; oy < overlay.height; oy += 1) {
    final y = placement.top + oy;
    if (y < 0 || y >= height) {
      continue;
    }
    for (var ox = 0; ox < overlay.width; ox += 1) {
      final x = placement.left + ox;
      if (x < 0 || x >= width) {
        continue;
      }
      _blendAt(output, width, x, y, overlay, ox, oy, layer);
    }
  }
}

void _blendAt(
  Uint8List output,
  int width,
  int x,
  int y,
  RawPixels overlay,
  int overlayX,
  int overlayY,
  CompositeLayer layer,
) {
  final target = ((y * width) + x) * 4;
  final source =
      ((overlayY * overlay.width) + overlayX) * overlay.channels.value;
  final result = blendPixel(
    readColor(output, target, 4),
    readColor(overlay.bytes, source, overlay.channels.value),
    layer.blendMode,
    sourcePremultiplied: layer.premultiplied,
  );
  output[target] = result.red;
  output[target + 1] = result.green;
  output[target + 2] = result.blue;
  output[target + 3] = result.alpha;
}

Uint8List _toRgbaBytes(RawPixels raw) {
  final input = raw.bytes;
  final output = Uint8List(raw.width * raw.height * 4);
  for (var i = 0, o = 0; i < input.length; i += raw.channels.value, o += 4) {
    final color = readColor(input, i, raw.channels.value);
    output[o] = color.red;
    output[o + 1] = color.green;
    output[o + 2] = color.blue;
    output[o + 3] = color.alpha;
  }
  return output;
}

RawPixels _overlayFrame(PixelImage image, int frameIndex) {
  if (image.isAnimated && frameIndex < image.frames.length) {
    return image.frames[frameIndex].pixels;
  }
  return image.firstFrame.pixels;
}

({int left, int top}) _placement(
  int width,
  int height,
  RawPixels overlay,
  CompositeLayer layer,
) {
  final left = layer.left;
  final top = layer.top;
  if (left != null && top != null) {
    return (left: left, top: top);
  }
  return switch (layer.gravity) {
    Gravity.north => (left: (width - overlay.width) ~/ 2, top: 0),
    Gravity.east => (
      left: width - overlay.width,
      top: (height - overlay.height) ~/ 2,
    ),
    Gravity.south => (
      left: (width - overlay.width) ~/ 2,
      top: height - overlay.height,
    ),
    Gravity.west => (left: 0, top: (height - overlay.height) ~/ 2),
    Gravity.northeast => (left: width - overlay.width, top: 0),
    Gravity.southeast => (
      left: width - overlay.width,
      top: height - overlay.height,
    ),
    Gravity.southwest => (left: 0, top: height - overlay.height),
    Gravity.northwest => (left: 0, top: 0),
    Gravity.center => (
      left: (width - overlay.width) ~/ 2,
      top: (height - overlay.height) ~/ 2,
    ),
  };
}

int _positiveMod(int value, int divisor) {
  return ((value % divisor) + divisor) % divisor;
}
