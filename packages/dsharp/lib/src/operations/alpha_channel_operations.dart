import 'dart:typed_data';

import '../api/exceptions.dart';
import '../pipeline/pipeline_operation.dart';
import '../pixels/color.dart';
import '../pixels/pixel_image.dart';
import '../source/raw_pixels.dart';
import 'operation_options.dart';
import 'pixel_helpers.dart';

/// Ensures an alpha channel exists.
final class EnsureAlphaOperation implements PipelineOperation {
  /// Creates an ensure-alpha operation.
  const EnsureAlphaOperation([this.alpha = 255]);

  /// Alpha byte for newly added samples.
  final int alpha;

  @override
  String get name => 'ensureAlpha';

  @override
  PixelImage apply(PixelImage image) => mapFrames(image, _ensure);

  RawPixels _ensure(RawPixels raw) {
    if (raw.channels == ChannelCount.two || raw.channels == ChannelCount.four) {
      return raw;
    }
    final input = raw.bytes;
    final inChannels = raw.channels.value;
    final output = Uint8List(raw.width * raw.height * 4);
    for (var i = 0, o = 0; i < input.length; i += inChannels, o += 4) {
      output[o] = input[i];
      output[o + 1] = inChannels > 1 ? input[i + 1] : input[i];
      output[o + 2] = inChannels > 2 ? input[i + 2] : input[i];
      output[o + 3] = alpha;
    }
    return sameSizeRaw(raw, output, ChannelCount.four);
  }
}

/// Removes alpha from pixels.
final class RemoveAlphaOperation implements PipelineOperation {
  /// Creates a remove-alpha operation.
  const RemoveAlphaOperation();

  @override
  String get name => 'removeAlpha';

  @override
  PixelImage apply(PixelImage image) => mapFrames(image, _remove);

  RawPixels _remove(RawPixels raw) {
    if (raw.channels == ChannelCount.two) {
      final input = raw.bytes;
      final output = Uint8List(raw.width * raw.height);
      for (var i = 0, o = 0; i < input.length; i += 2, o += 1) {
        output[o] = input[i];
      }
      return sameSizeRaw(raw, output, ChannelCount.one);
    }
    if (raw.channels != ChannelCount.four) {
      return raw;
    }
    final input = raw.bytes;
    final output = Uint8List(raw.width * raw.height * 3);
    for (var i = 0, o = 0; i < input.length; i += 4, o += 3) {
      output[o] = input[i];
      output[o + 1] = input[i + 1];
      output[o + 2] = input[i + 2];
    }
    return sameSizeRaw(raw, output, ChannelCount.three);
  }
}

/// Flattens alpha against a background.
final class FlattenOperation implements PipelineOperation {
  /// Creates a flatten operation.
  const FlattenOperation([this.background = RgbaColor.black]);

  /// Background color.
  final RgbaColor background;

  @override
  String get name => 'flatten';

  @override
  PixelImage apply(PixelImage image) => mapFrames(image, _flatten);

  RawPixels _flatten(RawPixels raw) {
    if (raw.channels == ChannelCount.two) {
      final input = raw.bytes;
      final output = Uint8List(raw.width * raw.height * 3);
      for (var i = 0, o = 0; i < input.length; i += 2, o += 3) {
        final gray = input[i];
        final alpha = input[i + 1] / 255;
        output[o] = _flattenSample(gray, background.red, alpha);
        output[o + 1] = _flattenSample(gray, background.green, alpha);
        output[o + 2] = _flattenSample(gray, background.blue, alpha);
      }
      return sameSizeRaw(raw, output, ChannelCount.three);
    }
    if (raw.channels != ChannelCount.four) {
      return raw;
    }
    final input = raw.bytes;
    final output = Uint8List(raw.width * raw.height * 3);
    for (var i = 0, o = 0; i < input.length; i += 4, o += 3) {
      final alpha = input[i + 3] / 255;
      output[o] = _flattenSample(input[i], background.red, alpha);
      output[o + 1] = _flattenSample(input[i + 1], background.green, alpha);
      output[o + 2] = _flattenSample(input[i + 2], background.blue, alpha);
    }
    return sameSizeRaw(raw, output, ChannelCount.three);
  }
}

/// Extracts one channel as grayscale pixels.
final class ExtractChannelOperation implements PipelineOperation {
  /// Creates an extract-channel operation.
  const ExtractChannelOperation(this.channel);

  /// Zero-based channel index, [ImageChannel], or channel name.
  final Object channel;

  @override
  String get name => 'extractChannel';

  @override
  PixelImage apply(PixelImage image) {
    return mapFrames(image, (raw) {
      final index = ImageChannel.resolve(channel);
      if (index < 0 || index >= raw.channels.value) {
        throw RangeError.range(index, 0, raw.channels.value - 1, 'channel');
      }
      final input = raw.bytes;
      final output = Uint8List(raw.width * raw.height);
      for (
        var i = index, o = 0;
        i < input.length;
        i += raw.channels.value, o += 1
      ) {
        output[o] = input[i];
      }
      return sameSizeRaw(raw, output, ChannelCount.one);
    });
  }
}

/// Joins a one-channel image as an additional channel.
final class JoinChannelOperation implements PipelineOperation {
  /// Creates a join-channel operation.
  const JoinChannelOperation(this.channel);

  /// Channel image.
  final PixelImage channel;

  @override
  String get name => 'joinChannel';

  @override
  PixelImage apply(PixelImage image) {
    final extra = channel.firstFrame.pixels;
    return mapFrames(image, (raw) {
      if (raw.width != extra.width || raw.height != extra.height) {
        throw const InvalidImageException(
          'Joined channel must match image dimensions.',
        );
      }
      if (extra.channels != ChannelCount.one) {
        throw const InvalidImageException(
          'Joined channel image must contain exactly one channel.',
        );
      }
      if (raw.channels == ChannelCount.four) {
        throw const OperationValidationException(
          'Cannot join channels beyond four channels.',
        );
      }
      final input = raw.bytes;
      final extraBytes = extra.bytes;
      final inChannels = raw.channels.value;
      final outChannels = inChannels + 1;
      final output = Uint8List(raw.width * raw.height * outChannels);
      for (
        var i = 0, o = 0, e = 0;
        i < input.length;
        i += inChannels, o += outChannels, e += extra.channels.value
      ) {
        for (var c = 0; c < inChannels; c += 1) {
          output[o + c] = input[i + c];
        }
        output[o + inChannels] = extraBytes[e];
      }
      return sameSizeRaw(raw, output, ChannelCount.fromInt(outChannels));
    });
  }
}

/// Makes white pixels transparent.
final class UnflattenOperation implements PipelineOperation {
  /// Creates an unflatten operation.
  const UnflattenOperation();

  @override
  String get name => 'unflatten';

  @override
  PixelImage apply(PixelImage image) {
    final withAlpha = const EnsureAlphaOperation().apply(image);
    return mapFrames(withAlpha, (raw) {
      final output = raw.bytes;
      for (var i = 0; i < output.length; i += 4) {
        if (output[i] == 255 && output[i + 1] == 255 && output[i + 2] == 255) {
          output[i + 3] = 0;
        }
      }
      return sameSizeRaw(raw, output, ChannelCount.four);
    });
  }
}

/// Premultiplies RGB samples by alpha.
final class PremultiplyAlphaOperation implements PipelineOperation {
  /// Creates a premultiply-alpha operation.
  const PremultiplyAlphaOperation();

  @override
  String get name => 'premultiplyAlpha';

  @override
  PixelImage apply(PixelImage image) => mapFrames(image, premultiplyAlpha);
}

/// Converts premultiplied RGB samples back to straight alpha.
final class UnpremultiplyAlphaOperation implements PipelineOperation {
  /// Creates an unpremultiply-alpha operation.
  const UnpremultiplyAlphaOperation();

  @override
  String get name => 'unpremultiplyAlpha';

  @override
  PixelImage apply(PixelImage image) => mapFrames(image, unpremultiplyAlpha);
}

/// Premultiplies RGB channels by alpha.
RawPixels premultiplyAlpha(RawPixels raw) {
  if (!_hasAlphaChannel(raw.channels) ||
      raw.premultiplication == Premultiplication.premultiplied) {
    return raw;
  }
  final input = raw.bytes;
  final output = Uint8List(input.length);
  final channels = raw.channels.value;
  final alphaOffset = channels - 1;
  for (var i = 0; i < input.length; i += channels) {
    final alpha = input[i + alphaOffset] / 255;
    for (var channel = 0; channel < alphaOffset; channel += 1) {
      output[i + channel] = byteClamp(input[i + channel] * alpha);
    }
    output[i + alphaOffset] = input[i + alphaOffset];
  }
  return RawPixels(
    bytes: output,
    width: raw.width,
    height: raw.height,
    channels: raw.channels,
    depth: raw.depth,
    premultiplication: Premultiplication.premultiplied,
    pageHeight: raw.pageHeight,
  );
}

/// Converts premultiplied RGB channels back to straight alpha.
RawPixels unpremultiplyAlpha(RawPixels raw) {
  if (!_hasAlphaChannel(raw.channels) ||
      raw.premultiplication == Premultiplication.none) {
    return raw;
  }
  final input = raw.bytes;
  final output = Uint8List(input.length);
  final channels = raw.channels.value;
  final alphaOffset = channels - 1;
  for (var i = 0; i < input.length; i += channels) {
    final alpha = input[i + alphaOffset];
    if (alpha == 0) {
      for (var channel = 0; channel < alphaOffset; channel += 1) {
        output[i + channel] = 0;
      }
    } else {
      final scale = 255 / alpha;
      for (var channel = 0; channel < alphaOffset; channel += 1) {
        output[i + channel] = byteClamp(input[i + channel] * scale);
      }
    }
    output[i + alphaOffset] = alpha;
  }
  return RawPixels(
    bytes: output,
    width: raw.width,
    height: raw.height,
    channels: raw.channels,
    depth: raw.depth,
    premultiplication: Premultiplication.none,
    pageHeight: raw.pageHeight,
  );
}

int _flattenSample(int foreground, int background, double alpha) {
  return byteClamp((foreground * alpha) + (background * (1 - alpha)));
}

bool _hasAlphaChannel(ChannelCount channels) {
  return channels == ChannelCount.two || channels == ChannelCount.four;
}
