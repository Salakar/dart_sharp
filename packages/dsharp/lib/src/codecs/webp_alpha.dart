import 'dart:typed_data';

import '../api/exceptions.dart';
import '../source/raw_pixels.dart';
import 'binary_io.dart';
import 'webp_lossless.dart';
import 'webp_riff.dart';

/// Applies a static extended WebP ALPH chunk to decoded VP8 pixels.
RawPixels applyWebpAlpha(Uint8List bytes, RawPixels pixels) {
  final alphaChunk = _findWebpChunk(bytes, 'ALPH');
  if (alphaChunk == null) {
    return pixels;
  }
  if (pixels.channels != ChannelCount.four) {
    throw const InvalidImageException('WebP alpha requires RGBA pixels.');
  }
  final alpha = decodeWebpAlphaChunk(
    alphaChunk,
    width: pixels.width,
    height: pixels.height,
  );
  final rgba = pixels.bytes;
  for (var i = 0; i < alpha.length; i += 1) {
    rgba[i * 4 + 3] = alpha[i];
  }
  return RawPixels(
    bytes: rgba,
    width: pixels.width,
    height: pixels.height,
    channels: ChannelCount.four,
  );
}

/// Decodes the payload of a WebP ALPH chunk into one alpha byte per pixel.
Uint8List decodeWebpAlphaChunk(
  Uint8List chunk, {
  required int width,
  required int height,
}) {
  if (chunk.isEmpty) {
    throw const InvalidImageException('Invalid WebP ALPH chunk.');
  }
  final flags = chunk[0];
  final compression = flags & 0x03;
  final filter = (flags >> 2) & 0x03;
  final expectedLength = width * height;
  final data = chunk.sublist(1);
  if (compression == 1) {
    return _unfilterAlpha(
      decodeHeaderlessWebpLosslessGreen(data, width: width, height: height),
      width,
      height,
      filter,
    );
  }
  if (compression != 0) {
    throw const InvalidImageException('Invalid WebP ALPH compression method.');
  }
  if (data.length != expectedLength) {
    throw const InvalidImageException('Invalid WebP ALPH payload length.');
  }
  return _unfilterAlpha(data, width, height, filter);
}

Uint8List _unfilterAlpha(Uint8List data, int width, int height, int filter) {
  final alpha = Uint8List(data.length);
  for (var y = 0; y < height; y += 1) {
    for (var x = 0; x < width; x += 1) {
      final index = y * width + x;
      alpha[index] =
          (data[index] + _alphaPredictor(alpha, width, x, y, filter)) & 0xff;
    }
  }
  return alpha;
}

int _alphaPredictor(Uint8List alpha, int width, int x, int y, int filter) {
  if (x == 0 && y == 0) {
    return 0;
  }
  final hasLeft = x > 0;
  final hasAbove = y > 0;
  final left = hasLeft ? alpha[y * width + x - 1] : 0;
  final above = hasAbove ? alpha[(y - 1) * width + x] : 0;
  return switch (filter) {
    0 => 0,
    1 => hasLeft ? left : above,
    2 => hasAbove ? above : left,
    3 => _gradientAlphaPredictor(alpha, width, x, y, left, above),
    _ => throw const InvalidImageException('Invalid WebP ALPH filter method.'),
  };
}

int _gradientAlphaPredictor(
  Uint8List alpha,
  int width,
  int x,
  int y,
  int left,
  int above,
) {
  if (x == 0) {
    return above;
  }
  if (y == 0) {
    return left;
  }
  final upperLeft = alpha[(y - 1) * width + x - 1];
  final predictor = left + above - upperLeft;
  return predictor < 0 ? 0 : (predictor > 255 ? 255 : predictor);
}

Uint8List? _findWebpChunk(Uint8List bytes, String target) {
  final riffEnd = webpRiffEnd(bytes);
  var offset = 12;
  while (offset + 8 <= riffEnd) {
    final type = String.fromCharCodes(bytes.sublist(offset, offset + 4));
    final length = readUint32Le(bytes, offset + 4);
    final start = offset + 8;
    final end = start + length;
    if (end > riffEnd) {
      throw const InvalidImageException('Truncated WebP chunk.');
    }
    if (type == target) {
      return bytes.sublist(start, end);
    }
    offset = end + (length.isOdd ? 1 : 0);
  }
  if (offset != riffEnd) {
    throw const InvalidImageException('Truncated WebP chunk.');
  }
  return null;
}
