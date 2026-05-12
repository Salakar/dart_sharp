import 'dart:math';
import 'dart:typed_data';

import '../api/exceptions.dart';
import '../pixels/color.dart';
import '../pixels/pixel_image.dart';
import '../source/raw_pixels.dart';

/// Applies [convert] to every frame.
PixelImage mapFrames(PixelImage image, RawPixels Function(RawPixels) convert) {
  return PixelImage(
    frames: image.frames.map((frame) {
      return ImageFrame(pixels: convert(frame.pixels), delay: frame.delay);
    }),
    loopCount: image.loopCount,
  );
}

/// Rejects animated input for operations that currently work on one frame.
void requireSingleFrame(PixelImage image, String operation) {
  if (image.isAnimated) {
    throw OperationValidationException(
      '$operation is not supported for animated images yet.',
    );
  }
}

/// Creates raw pixels with the same dimensions as [source].
RawPixels sameSizeRaw(
  RawPixels source,
  Uint8List bytes,
  ChannelCount channels,
) {
  final premultiplication = hasAlphaChannel(channels.value)
      ? source.premultiplication
      : Premultiplication.none;
  return RawPixels(
    bytes: bytes,
    width: source.width,
    height: source.height,
    channels: channels,
    depth: source.depth,
    premultiplication: premultiplication,
    pageHeight: source.pageHeight,
  );
}

/// Clamps [value] to an 8-bit channel.
int byteClamp(num value) => value.round().clamp(0, 255);

/// Reads a pixel as an RGBA color.
RgbaColor readColor(Uint8List bytes, int offset, int channels) {
  final red = bytes[offset];
  if (channels == 2) {
    return RgbaColor(red: red, green: red, blue: red, alpha: bytes[offset + 1]);
  }
  return RgbaColor(
    red: red,
    green: channels > 1 ? bytes[offset + 1] : red,
    blue: channels > 2 ? bytes[offset + 2] : red,
    alpha: channels > 3 ? bytes[offset + 3] : 255,
  );
}

/// Writes [color] into [bytes].
void writeColor(Uint8List bytes, int offset, int channels, RgbaColor color) {
  bytes[offset] = color.red;
  if (channels == 2) {
    bytes[offset + 1] = color.alpha;
    return;
  }
  if (channels > 1) {
    bytes[offset + 1] = color.green;
  }
  if (channels > 2) {
    bytes[offset + 2] = color.blue;
  }
  if (channels > 3) {
    bytes[offset + 3] = color.alpha;
  }
}

/// Number of non-alpha color channels in a raw layout.
int colorChannelCount(int channels) => channels == 2 ? 1 : min(3, channels);

/// Whether a raw layout has an alpha channel.
bool hasAlphaChannel(int channels) => channels == 2 || channels == 4;

/// Returns the luminance approximation of [color].
int luminance(RgbaColor color) {
  return byteClamp(
    (0.299 * color.red) + (0.587 * color.green) + (0.114 * color.blue),
  );
}

/// Returns the median byte from [values].
int medianByte(List<int> values) {
  values.sort();
  return values[values.length ~/ 2];
}

/// Returns a source pixel offset with clamped coordinates.
int clampedOffset(RawPixels raw, int x, int y) {
  final cx = min(raw.width - 1, max(0, x));
  final cy = min(raw.height - 1, max(0, y));
  return ((cy * raw.width) + cx) * raw.channels.value;
}
