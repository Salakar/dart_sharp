import 'dart:math';
import 'dart:typed_data';

import '../api/exceptions.dart';
import '../geometry/geometry.dart';
import '../geometry/resize_geometry.dart';
import '../pipeline/pipeline_operation.dart';
import '../pixels/color.dart';
import '../pixels/pixel_image.dart';
import '../resize/crop_strategy.dart';
import '../resize/kernels.dart';
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
    if (options.strategy != null && options.fit != ResizeFit.cover) {
      throw const OperationValidationException(
        'Resize strategy is supported only for cover fit.',
      );
    }
    if (options.strategy != null && image.isAnimated) {
      throw const UnsupportedCodecException(
        'Resize strategy is not supported for multi-frame images.',
      );
    }
    final resolved = resolveResize(
      sourceWidth: image.width,
      sourceHeight: image.height,
      options: options,
    );
    return _mapFrames(image, (raw) => _resize(raw, resolved, options));
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
    if (options.threshold < 0) {
      throw OperationValidationException(
        'Trim threshold must be non-negative.',
      );
    }
    return _mapFrames(image, (raw) => _trim(raw, options));
  }
}

PixelImage _mapFrames(PixelImage image, RawPixels Function(RawPixels) apply) {
  return PixelImage(
    frames: image.frames.map((frame) {
      return ImageFrame(pixels: apply(frame.pixels), delay: frame.delay);
    }),
    loopCount: image.loopCount,
  );
}

RawPixels _resize(
  RawPixels raw,
  ResolvedResize resolved,
  ResizeOptions options,
) {
  if (options.fit == ResizeFit.cover &&
      options.width != null &&
      options.height != null) {
    return _resizeCover(raw, resolved.width, resolved.height, options);
  }
  if (options.fit == ResizeFit.contain &&
      options.width != null &&
      options.height != null) {
    return _resizeContain(raw, resolved.width, resolved.height, options);
  }
  return _resizeRaw(raw, resolved.width, resolved.height, options.kernel);
}

RawPixels _resizeCover(
  RawPixels raw,
  int width,
  int height,
  ResizeOptions options,
) {
  final widthRatio = width / raw.width;
  final heightRatio = height / raw.height;
  final scale = max(widthRatio, heightRatio);
  final scaledWidth = max(1, (raw.width * scale).round());
  final scaledHeight = max(1, (raw.height * scale).round());
  final scaled = _resizeRaw(raw, scaledWidth, scaledHeight, options.kernel);
  if (scaled.width == width && scaled.height == height) {
    return scaled;
  }
  final offset = options.strategy == null
      ? _gravityOffset(
          outerWidth: scaled.width,
          outerHeight: scaled.height,
          innerWidth: width,
          innerHeight: height,
          gravity: options.gravity,
        )
      : _strategyOffset(scaled, width, height, options.strategy!);
  return _crop(
    scaled,
    Region(left: offset.x, top: offset.y, width: width, height: height),
  );
}

RawPixels _resizeContain(
  RawPixels raw,
  int width,
  int height,
  ResizeOptions options,
) {
  final widthRatio = width / raw.width;
  final heightRatio = height / raw.height;
  final scale = min(widthRatio, heightRatio);
  final scaledWidth = max(1, (raw.width * scale).round());
  final scaledHeight = max(1, (raw.height * scale).round());
  final scaled = _resizeRaw(raw, scaledWidth, scaledHeight, options.kernel);
  if (scaled.width == width && scaled.height == height) {
    return scaled;
  }
  final offset = _gravityOffset(
    outerWidth: width,
    outerHeight: height,
    innerWidth: scaled.width,
    innerHeight: scaled.height,
    gravity: options.gravity,
  );
  return _embed(
    scaled,
    width: width,
    height: height,
    left: offset.x,
    top: offset.y,
    background: options.background,
  );
}

({int x, int y}) _gravityOffset({
  required int outerWidth,
  required int outerHeight,
  required int innerWidth,
  required int innerHeight,
  required Gravity gravity,
}) {
  final extraX = max(0, outerWidth - innerWidth);
  final extraY = max(0, outerHeight - innerHeight);
  final centerX = extraX ~/ 2;
  final centerY = extraY ~/ 2;
  return switch (gravity) {
    Gravity.north => (x: centerX, y: 0),
    Gravity.east => (x: extraX, y: centerY),
    Gravity.south => (x: centerX, y: extraY),
    Gravity.west => (x: 0, y: centerY),
    Gravity.northeast => (x: extraX, y: 0),
    Gravity.southeast => (x: extraX, y: extraY),
    Gravity.southwest => (x: 0, y: extraY),
    Gravity.northwest => (x: 0, y: 0),
    Gravity.center => (x: centerX, y: centerY),
  };
}

({int x, int y}) _strategyOffset(
  RawPixels raw,
  int cropWidth,
  int cropHeight,
  CropStrategy strategy,
) {
  final maxX = max(0, raw.width - cropWidth);
  final maxY = max(0, raw.height - cropHeight);
  var bestX = 0;
  var bestY = 0;
  var bestScore = double.negativeInfinity;
  for (var y = 0; y <= maxY; y += 1) {
    for (var x = 0; x <= maxX; x += 1) {
      final candidate = _crop(
        raw,
        Region(left: x, top: y, width: cropWidth, height: cropHeight),
      );
      final score = strategy.score(PixelImage.fromRawPixels(candidate));
      if (score > bestScore) {
        bestScore = score;
        bestX = x;
        bestY = y;
      }
    }
  }
  return (x: bestX, y: bestY);
}

RawPixels _resizeRaw(
  RawPixels raw,
  int width,
  int height,
  ResizeKernel kernel,
) {
  if (raw.width == width && raw.height == height) {
    return raw;
  }
  if (kernel == ResizeKernel.nearest) {
    return _resizeNearest(raw, width, height);
  }
  return _resizeKernel(raw, width, height, kernel);
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

RawPixels _resizeKernel(
  RawPixels raw,
  int width,
  int height,
  ResizeKernel kernel,
) {
  final channels = raw.channels.value;
  final input = raw.bytes;
  final horizontal = Float64List(width * raw.height * channels);
  final scaleX = raw.width / width;
  final kernelX = _resamplingKernel(kernel, scaleX);
  final filterScaleX = max(1.0, scaleX);
  final radiusX = kernelRadius(kernelX) * filterScaleX;
  for (var y = 0; y < raw.height; y += 1) {
    for (var x = 0; x < width; x += 1) {
      final sourceX = ((x + 0.5) * scaleX) - 0.5;
      final start = (sourceX - radiusX).floor();
      final end = (sourceX + radiusX).ceil();
      final target = ((y * width) + x) * channels;
      _accumulateSamples(
        start: start,
        end: end,
        center: sourceX,
        filterScale: filterScaleX,
        kernel: kernelX,
        channels: channels,
        sampleOffset: (sample) => ((y * raw.width) + sample) * channels,
        maxSample: raw.width - 1,
        read: (offset) => input[offset].toDouble(),
        write: (channel, value) => horizontal[target + channel] = value,
      );
    }
  }

  final output = Uint8List(width * height * channels);
  final scaleY = raw.height / height;
  final kernelY = _resamplingKernel(kernel, scaleY);
  final filterScaleY = max(1.0, scaleY);
  final radiusY = kernelRadius(kernelY) * filterScaleY;
  for (var y = 0; y < height; y += 1) {
    final sourceY = ((y + 0.5) * scaleY) - 0.5;
    final start = (sourceY - radiusY).floor();
    final end = (sourceY + radiusY).ceil();
    for (var x = 0; x < width; x += 1) {
      final target = ((y * width) + x) * channels;
      _accumulateSamples(
        start: start,
        end: end,
        center: sourceY,
        filterScale: filterScaleY,
        kernel: kernelY,
        channels: channels,
        sampleOffset: (sample) => ((sample * width) + x) * channels,
        maxSample: raw.height - 1,
        read: (offset) => horizontal[offset],
        write: (channel, value) {
          output[target + channel] = value.round().clamp(0, 255);
        },
      );
    }
  }
  return RawPixels(
    bytes: output,
    width: width,
    height: height,
    channels: raw.channels,
  );
}

ResizeKernel _resamplingKernel(ResizeKernel kernel, double scale) {
  if (scale >= 1) {
    return kernel;
  }
  return switch (kernel) {
    ResizeKernel.nearest || ResizeKernel.linear || ResizeKernel.cubic => kernel,
    ResizeKernel.mitchell ||
    ResizeKernel.lanczos2 ||
    ResizeKernel.lanczos3 ||
    ResizeKernel.mks2013 ||
    ResizeKernel.mks2021 => ResizeKernel.cubic,
  };
}

void _accumulateSamples({
  required int start,
  required int end,
  required double center,
  required double filterScale,
  required ResizeKernel kernel,
  required int channels,
  required int Function(int sample) sampleOffset,
  required int maxSample,
  required double Function(int offset) read,
  required void Function(int channel, double value) write,
}) {
  final sums = Float64List(channels);
  var weightSum = 0.0;
  for (var sample = start; sample <= end; sample += 1) {
    final distance = (sample - center) / filterScale;
    final weight = kernelWeight(kernel, distance);
    if (weight == 0) {
      continue;
    }
    final offset = sampleOffset(sample.clamp(0, maxSample));
    for (var c = 0; c < channels; c += 1) {
      sums[c] += read(offset + c) * weight;
    }
    weightSum += weight;
  }
  if (weightSum == 0) {
    final offset = sampleOffset(center.round().clamp(0, maxSample));
    for (var c = 0; c < channels; c += 1) {
      write(c, read(offset + c));
    }
    return;
  }
  for (var c = 0; c < channels; c += 1) {
    write(c, sums[c] / weightSum);
  }
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

RawPixels _embed(
  RawPixels raw, {
  required int width,
  required int height,
  required int left,
  required int top,
  required RgbaColor background,
}) {
  final channels = raw.channels.value;
  final input = raw.bytes;
  final output = Uint8List(width * height * channels);
  for (var y = 0; y < height; y += 1) {
    for (var x = 0; x < width; x += 1) {
      _writeColor(output, ((y * width) + x) * channels, channels, background);
    }
  }
  for (var y = 0; y < raw.height; y += 1) {
    for (var x = 0; x < raw.width; x += 1) {
      _copyPixel(
        input,
        output,
        ((y * raw.width) + x) * channels,
        (((top + y) * width) + left + x) * channels,
        channels,
      );
    }
  }
  return RawPixels(
    bytes: output,
    width: width,
    height: height,
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
