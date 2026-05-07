import 'dart:math';
import 'dart:typed_data';

import '../geometry/geometry.dart';
import '../geometry/resize_geometry.dart';
import '../pipeline/pipeline_operation.dart';
import '../pixels/color.dart';
import '../pixels/pixel_image.dart';
import '../source/raw_pixels.dart';

/// Resize operation.
final class ResizeOperation implements PipelineOperation {
  /// Creates a resize operation.
  const ResizeOperation(this.options);

  /// Resize options.
  final ResizeOptions options;

  @override
  String get name => 'resize';

  @override
  PixelImage apply(PixelImage image) {
    final resolved = resolveResize(
      sourceWidth: image.width,
      sourceHeight: image.height,
      options: options,
    );
    return _mapFrames(
      image,
      (raw) => _resizeNearest(raw, resolved.width, resolved.height),
    );
  }
}

/// Extract operation.
final class ExtractOperation implements PipelineOperation {
  /// Creates an extract operation.
  const ExtractOperation(this.region);

  /// Region to extract.
  final Region region;

  @override
  String get name => 'extract';

  @override
  PixelImage apply(PixelImage image) {
    region.validate(imageWidth: image.width, imageHeight: image.height);
    return _mapFrames(image, (raw) => _crop(raw, region));
  }
}

/// Extend operation.
final class ExtendOperation implements PipelineOperation {
  /// Creates an extend operation.
  const ExtendOperation(this.options);

  /// Extend options.
  final ExtendOptions options;

  @override
  String get name => 'extend';

  @override
  PixelImage apply(PixelImage image) {
    options.insets.validate();
    return _mapFrames(image, (raw) => _extend(raw, options));
  }
}

/// Trim operation.
final class TrimOperation implements PipelineOperation {
  /// Creates a trim operation.
  const TrimOperation(this.options);

  /// Trim options.
  final TrimOptions options;

  @override
  String get name => 'trim';

  @override
  PixelImage apply(PixelImage image) {
    return _mapFrames(image, (raw) => _trim(raw, options));
  }
}

PixelImage _mapFrames(PixelImage image, RawPixels Function(RawPixels) apply) {
  return PixelImage(
    frames: image.frames.map((frame) {
      return ImageFrame(pixels: apply(frame.pixels), delay: frame.delay);
    }),
  );
}

RawPixels _resizeNearest(RawPixels raw, int width, int height) {
  final channels = raw.channels.value;
  final input = raw.bytes;
  final output = Uint8List(width * height * channels);
  for (var y = 0; y < height; y += 1) {
    final sourceY = min(raw.height - 1, (y * raw.height / height).floor());
    for (var x = 0; x < width; x += 1) {
      final sourceX = min(raw.width - 1, (x * raw.width / width).floor());
      final source = ((sourceY * raw.width) + sourceX) * channels;
      final target = ((y * width) + x) * channels;
      for (var c = 0; c < channels; c += 1) {
        output[target + c] = input[source + c];
      }
    }
  }
  return RawPixels(
    bytes: output,
    width: width,
    height: height,
    channels: raw.channels,
  );
}

RawPixels _crop(RawPixels raw, Region region) {
  final channels = raw.channels.value;
  final input = raw.bytes;
  final output = Uint8List(region.width * region.height * channels);
  for (var y = 0; y < region.height; y += 1) {
    for (var x = 0; x < region.width; x += 1) {
      final source =
          (((region.top + y) * raw.width) + region.left + x) * channels;
      final target = ((y * region.width) + x) * channels;
      for (var c = 0; c < channels; c += 1) {
        output[target + c] = input[source + c];
      }
    }
  }
  return RawPixels(
    bytes: output,
    width: region.width,
    height: region.height,
    channels: raw.channels,
  );
}

RawPixels _extend(RawPixels raw, ExtendOptions options) {
  final channels = raw.channels.value;
  final outputWidth = raw.width + options.insets.left + options.insets.right;
  final outputHeight = raw.height + options.insets.top + options.insets.bottom;
  final input = raw.bytes;
  final output = Uint8List(outputWidth * outputHeight * channels);
  for (var y = 0; y < outputHeight; y += 1) {
    for (var x = 0; x < outputWidth; x += 1) {
      final sourceX = x - options.insets.left;
      final sourceY = y - options.insets.top;
      final target = ((y * outputWidth) + x) * channels;
      if (sourceX >= 0 &&
          sourceY >= 0 &&
          sourceX < raw.width &&
          sourceY < raw.height) {
        _copyPixel(
          input,
          output,
          ((sourceY * raw.width) + sourceX) * channels,
          target,
          channels,
        );
      } else if (options.mode == ExtendMode.background) {
        _writeColor(output, target, channels, options.background);
      } else {
        final mappedX = _mapExtended(sourceX, raw.width, options.mode);
        final mappedY = _mapExtended(sourceY, raw.height, options.mode);
        _copyPixel(
          input,
          output,
          ((mappedY * raw.width) + mappedX) * channels,
          target,
          channels,
        );
      }
    }
  }
  return RawPixels(
    bytes: output,
    width: outputWidth,
    height: outputHeight,
    channels: raw.channels,
  );
}

RawPixels _trim(RawPixels raw, TrimOptions options) {
  final channels = raw.channels.value;
  final bytes = raw.bytes;
  final background = options.background ?? _readColor(bytes, 0, channels);
  var left = raw.width;
  var top = raw.height;
  var right = -1;
  var bottom = -1;
  for (var y = 0; y < raw.height; y += 1) {
    for (var x = 0; x < raw.width; x += 1) {
      final offset = ((y * raw.width) + x) * channels;
      if (!_matches(bytes, offset, channels, background, options.threshold)) {
        left = min(left, x);
        top = min(top, y);
        right = max(right, x);
        bottom = max(bottom, y);
      }
    }
  }
  if (right == -1) {
    return raw;
  }
  return _crop(
    raw,
    Region(
      left: left,
      top: top,
      width: right - left + 1,
      height: bottom - top + 1,
    ),
  );
}

int _mapExtended(int coordinate, int size, ExtendMode mode) {
  return switch (mode) {
    ExtendMode.copy => coordinate.clamp(0, size - 1),
    ExtendMode.repeat => coordinate % size,
    ExtendMode.mirror => (coordinate.abs()) % size,
    ExtendMode.background => coordinate.clamp(0, size - 1),
  };
}

void _copyPixel(
  Uint8List input,
  Uint8List output,
  int source,
  int target,
  int channels,
) {
  for (var c = 0; c < channels; c += 1) {
    output[target + c] = input[source + c];
  }
}

void _writeColor(Uint8List output, int target, int channels, RgbaColor color) {
  output[target] = color.red;
  if (channels > 1) {
    output[target + 1] = color.green;
  }
  if (channels > 2) {
    output[target + 2] = color.blue;
  }
  if (channels > 3) {
    output[target + 3] = color.alpha;
  }
}

RgbaColor _readColor(Uint8List bytes, int offset, int channels) {
  final red = bytes[offset];
  return RgbaColor(
    red: red,
    green: channels > 1 ? bytes[offset + 1] : red,
    blue: channels > 2 ? bytes[offset + 2] : red,
    alpha: channels > 3 ? bytes[offset + 3] : 255,
  );
}

bool _matches(
  Uint8List bytes,
  int offset,
  int channels,
  RgbaColor color,
  int threshold,
) {
  final pixel = _readColor(bytes, offset, channels);
  return (pixel.red - color.red).abs() <= threshold &&
      (pixel.green - color.green).abs() <= threshold &&
      (pixel.blue - color.blue).abs() <= threshold &&
      (pixel.alpha - color.alpha).abs() <= threshold;
}
