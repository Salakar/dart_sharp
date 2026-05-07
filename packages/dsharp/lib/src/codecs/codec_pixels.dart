import 'dart:typed_data';

import '../source/raw_pixels.dart';

/// Converts any 8-bit raw layout to RGBA bytes.
Uint8List rawToRgba(RawPixels raw) {
  final source = raw.bytes;
  final output = Uint8List(raw.width * raw.height * 4);
  final channels = raw.channels.value;
  for (var pixel = 0; pixel < raw.width * raw.height; pixel += 1) {
    final sourceOffset = pixel * channels;
    final targetOffset = pixel * 4;
    switch (raw.channels) {
      case ChannelCount.one:
        final gray = source[sourceOffset];
        output[targetOffset] = gray;
        output[targetOffset + 1] = gray;
        output[targetOffset + 2] = gray;
        output[targetOffset + 3] = 255;
      case ChannelCount.two:
        final gray = source[sourceOffset];
        output[targetOffset] = gray;
        output[targetOffset + 1] = gray;
        output[targetOffset + 2] = gray;
        output[targetOffset + 3] = source[sourceOffset + 1];
      case ChannelCount.three:
        output[targetOffset] = source[sourceOffset];
        output[targetOffset + 1] = source[sourceOffset + 1];
        output[targetOffset + 2] = source[sourceOffset + 2];
        output[targetOffset + 3] = 255;
      case ChannelCount.four:
        output[targetOffset] = source[sourceOffset];
        output[targetOffset + 1] = source[sourceOffset + 1];
        output[targetOffset + 2] = source[sourceOffset + 2];
        output[targetOffset + 3] = source[sourceOffset + 3];
    }
  }
  return output;
}

/// Returns RGB bytes from any 8-bit raw layout.
Uint8List rawToRgb(RawPixels raw) {
  final rgba = rawToRgba(raw);
  final output = Uint8List(raw.width * raw.height * 3);
  for (var pixel = 0; pixel < raw.width * raw.height; pixel += 1) {
    output[pixel * 3] = rgba[pixel * 4];
    output[pixel * 3 + 1] = rgba[pixel * 4 + 1];
    output[pixel * 3 + 2] = rgba[pixel * 4 + 2];
  }
  return output;
}
