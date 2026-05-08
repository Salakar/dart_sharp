import 'dart:typed_data';

import '../api/exceptions.dart';
import '../pixels/pixel_image.dart';
import '../source/raw_pixels.dart';
import 'binary_io.dart';
import 'webp_alpha.dart';
import 'webp_lossless.dart';
import 'webp_riff.dart';
import 'webp_vp8.dart';

/// Decodes animated WebP frames whose frame payloads are VP8L or VP8.
PixelImage decodeAnimatedWebp(Uint8List bytes) {
  final animation = _readAnimation(bytes);
  final canvas = Uint8List(animation.width * animation.height * 4);
  _fillRect(
    canvas,
    animation.width,
    0,
    0,
    animation.width,
    animation.height,
    animation.background,
  );
  final frames = <ImageFrame>[];
  _FrameRect? previousDispose;
  for (final frame in animation.frames) {
    final dispose = previousDispose;
    if (dispose != null) {
      _fillRect(
        canvas,
        animation.width,
        dispose.x,
        dispose.y,
        dispose.width,
        dispose.height,
        animation.background,
      );
    }
    final pixels = _decodeFramePixels(frame);
    if (pixels.width != frame.width || pixels.height != frame.height) {
      throw const InvalidImageException('Invalid WebP animation frame size.');
    }
    if (frame.x + frame.width > animation.width ||
        frame.y + frame.height > animation.height) {
      throw const InvalidImageException('WebP animation frame exceeds canvas.');
    }
    _drawFrame(canvas, animation.width, frame, pixels);
    frames.add(
      ImageFrame(
        pixels: RawPixels(
          bytes: Uint8List.fromList(canvas),
          width: animation.width,
          height: animation.height,
          channels: ChannelCount.four,
        ),
        delay: frame.duration,
      ),
    );
    previousDispose = frame.dispose
        ? _FrameRect(frame.x, frame.y, frame.width, frame.height)
        : null;
  }
  if (frames.isEmpty) {
    throw const InvalidImageException('WebP animation has no frames.');
  }
  return PixelImage(frames: frames, loopCount: animation.loopCount);
}

_Animation _readAnimation(Uint8List bytes) {
  if (bytes.length < 20 ||
      String.fromCharCodes(bytes.sublist(0, 4)) != 'RIFF' ||
      String.fromCharCodes(bytes.sublist(8, 12)) != 'WEBP') {
    throw const InvalidImageException('Invalid WebP signature.');
  }
  final riffEnd = webpRiffEnd(bytes);
  var offset = 12;
  int? width;
  int? height;
  var background = 0;
  var loopCount = 1;
  var hasAnimationHeader = false;
  final frames = <_AnimationFrame>[];
  while (offset + 8 <= riffEnd) {
    final type = String.fromCharCodes(bytes.sublist(offset, offset + 4));
    final length = readUint32Le(bytes, offset + 4);
    final start = offset + 8;
    final end = start + length;
    if (end > riffEnd) {
      throw const InvalidImageException('Truncated WebP chunk.');
    }
    final data = bytes.sublist(start, end);
    if (type == 'VP8X') {
      if (data.length != 10) {
        throw const InvalidImageException('Invalid VP8X header.');
      }
      if ((data[0] & 0x02) == 0) {
        throw const InvalidImageException('WebP animation flag is not set.');
      }
      width = _uint24Le(data, 4) + 1;
      height = _uint24Le(data, 7) + 1;
    } else if (type == 'ANIM') {
      if (data.length < 6) {
        throw const InvalidImageException('Invalid WebP animation header.');
      }
      hasAnimationHeader = true;
      background = _bgraToRgba(readUint32Le(data, 0));
      loopCount = readUint16Le(data, 4);
    } else if (type == 'ANMF') {
      frames.add(_readFrame(data));
    }
    offset = end + (length.isOdd ? 1 : 0);
  }
  if (offset != riffEnd) {
    throw const InvalidImageException('Truncated WebP chunk.');
  }
  final currentWidth = width;
  final currentHeight = height;
  if (currentWidth == null || currentHeight == null) {
    throw const InvalidImageException('WebP animation is missing VP8X.');
  }
  if (!hasAnimationHeader) {
    throw const InvalidImageException('WebP animation is missing ANIM.');
  }
  return _Animation(
    width: currentWidth,
    height: currentHeight,
    background: background,
    loopCount: loopCount,
    frames: frames,
  );
}

_AnimationFrame _readFrame(Uint8List data) {
  if (data.length < 16) {
    throw const InvalidImageException('Invalid WebP animation frame header.');
  }
  Uint8List? vp8l;
  Uint8List? vp8;
  Uint8List? alpha;
  var offset = 16;
  while (offset + 8 <= data.length) {
    final type = String.fromCharCodes(data.sublist(offset, offset + 4));
    final length = readUint32Le(data, offset + 4);
    final start = offset + 8;
    final end = start + length;
    if (end > data.length) {
      throw const InvalidImageException('Truncated WebP animation frame.');
    }
    if (type == 'VP8L') {
      if (vp8l != null || vp8 != null) {
        throw const InvalidImageException(
          'WebP animation frame has multiple image chunks.',
        );
      }
      vp8l = data.sublist(start, end);
    } else if (type == 'VP8 ') {
      if (vp8l != null || vp8 != null) {
        throw const InvalidImageException(
          'WebP animation frame has multiple image chunks.',
        );
      }
      vp8 = data.sublist(start, end);
    } else if (type == 'ALPH') {
      if (alpha != null) {
        throw const InvalidImageException(
          'WebP animation frame has multiple ALPH chunks.',
        );
      }
      alpha = data.sublist(start, end);
    }
    offset = end + (length.isOdd ? 1 : 0);
  }
  if (offset != data.length) {
    throw const InvalidImageException('Truncated WebP animation frame.');
  }
  if ((vp8l == null) == (vp8 == null)) {
    throw const InvalidImageException(
      'WebP animation frame has no image data.',
    );
  }
  if (vp8l != null && alpha != null) {
    throw const InvalidImageException('WebP VP8L animation frame has ALPH.');
  }
  final flags = data[15];
  return _AnimationFrame(
    x: _uint24Le(data, 0) * 2,
    y: _uint24Le(data, 3) * 2,
    width: _uint24Le(data, 6) + 1,
    height: _uint24Le(data, 9) + 1,
    duration: Duration(milliseconds: _uint24Le(data, 12)),
    blend: (flags & 0x02) == 0,
    dispose: (flags & 0x01) != 0,
    vp8l: vp8l,
    vp8: vp8,
    alpha: alpha,
  );
}

RawPixels _decodeFramePixels(_AnimationFrame frame) {
  final vp8l = frame.vp8l;
  if (vp8l != null) {
    return decodeWebpLosslessChunk(vp8l);
  }
  var pixels = decodeWebpVp8Chunk(frame.vp8!);
  final alpha = frame.alpha;
  if (alpha == null) {
    return pixels;
  }
  final values = decodeWebpAlphaChunk(
    alpha,
    width: pixels.width,
    height: pixels.height,
  );
  final rgba = pixels.bytes;
  for (var i = 0; i < values.length; i += 1) {
    rgba[i * 4 + 3] = values[i];
  }
  pixels = RawPixels(
    bytes: rgba,
    width: pixels.width,
    height: pixels.height,
    channels: ChannelCount.four,
  );
  return pixels;
}

void _drawFrame(
  Uint8List canvas,
  int canvasWidth,
  _AnimationFrame frame,
  RawPixels pixels,
) {
  final source = pixels.bytes;
  for (var y = 0; y < frame.height; y += 1) {
    for (var x = 0; x < frame.width; x += 1) {
      final sourceOffset = (y * frame.width + x) * 4;
      final destPixel = (frame.y + y) * canvasWidth + frame.x + x;
      final destOffset = destPixel * 4;
      if (frame.blend) {
        _blendPixel(canvas, destOffset, source, sourceOffset);
      } else {
        canvas.setRange(destOffset, destOffset + 4, source, sourceOffset);
      }
    }
  }
}

void _blendPixel(Uint8List dst, int dstOffset, Uint8List src, int srcOffset) {
  final srcAlpha = src[srcOffset + 3];
  if (srcAlpha == 255) {
    dst.setRange(dstOffset, dstOffset + 4, src, srcOffset);
    return;
  }
  if (srcAlpha == 0) {
    return;
  }
  final dstAlpha = dst[dstOffset + 3];
  final invAlpha = 255 - srcAlpha;
  final outAlpha = srcAlpha + ((dstAlpha * invAlpha + 127) ~/ 255);
  if (outAlpha == 0) {
    dst[dstOffset] = 0;
    dst[dstOffset + 1] = 0;
    dst[dstOffset + 2] = 0;
    dst[dstOffset + 3] = 0;
    return;
  }
  for (var channel = 0; channel < 3; channel += 1) {
    final premul =
        src[srcOffset + channel] * srcAlpha +
        ((dst[dstOffset + channel] * dstAlpha * invAlpha + 127) ~/ 255);
    dst[dstOffset + channel] = ((premul + outAlpha ~/ 2) ~/ outAlpha).clamp(
      0,
      255,
    );
  }
  dst[dstOffset + 3] = outAlpha;
}

void _fillRect(
  Uint8List canvas,
  int canvasWidth,
  int x,
  int y,
  int width,
  int height,
  int rgba,
) {
  final red = (rgba >> 24) & 0xff;
  final green = (rgba >> 16) & 0xff;
  final blue = (rgba >> 8) & 0xff;
  final alpha = rgba & 0xff;
  for (var row = 0; row < height; row += 1) {
    for (var column = 0; column < width; column += 1) {
      final offset = ((y + row) * canvasWidth + x + column) * 4;
      canvas[offset] = red;
      canvas[offset + 1] = green;
      canvas[offset + 2] = blue;
      canvas[offset + 3] = alpha;
    }
  }
}

int _bgraToRgba(int bgra) {
  final blue = bgra & 0xff;
  final green = (bgra >> 8) & 0xff;
  final red = (bgra >> 16) & 0xff;
  final alpha = (bgra >> 24) & 0xff;
  return (red << 24) | (green << 16) | (blue << 8) | alpha;
}

int _uint24Le(Uint8List bytes, int offset) {
  return bytes[offset] | (bytes[offset + 1] << 8) | (bytes[offset + 2] << 16);
}

final class _Animation {
  const _Animation({
    required this.width,
    required this.height,
    required this.background,
    required this.loopCount,
    required this.frames,
  });

  final int width;
  final int height;
  final int background;
  final int loopCount;
  final List<_AnimationFrame> frames;
}

final class _AnimationFrame {
  const _AnimationFrame({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.duration,
    required this.blend,
    required this.dispose,
    required this.vp8l,
    required this.vp8,
    required this.alpha,
  });

  final int x;
  final int y;
  final int width;
  final int height;
  final Duration duration;
  final bool blend;
  final bool dispose;
  final Uint8List? vp8l;
  final Uint8List? vp8;
  final Uint8List? alpha;
}

final class _FrameRect {
  const _FrameRect(this.x, this.y, this.width, this.height);

  final int x;
  final int y;
  final int width;
  final int height;
}
