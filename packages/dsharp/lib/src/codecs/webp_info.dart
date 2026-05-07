import 'dart:typed_data';

import '../api/exceptions.dart';
import 'binary_io.dart';

/// WebP compression payload kind.
enum WebpCompression {
  /// Lossy VP8 payload.
  vp8,

  /// Lossless VP8L payload.
  vp8l,

  /// Extended VP8X container.
  extended,
}

/// Parsed WebP frame metadata.
final class WebpFrameInfo {
  /// Creates frame metadata.
  const WebpFrameInfo({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.duration,
    required this.hasAlpha,
    required this.blend,
  });

  /// Frame x-offset.
  final int x;

  /// Frame y-offset.
  final int y;

  /// Frame width.
  final int width;

  /// Frame height.
  final int height;

  /// Frame display duration.
  final Duration duration;

  /// Whether the frame has an alpha payload.
  final bool hasAlpha;

  /// Whether the frame should blend with previous canvas contents.
  final bool blend;
}

/// Parsed WebP container metadata.
final class WebpImageInfo {
  /// Creates WebP metadata.
  const WebpImageInfo({
    required this.width,
    required this.height,
    required this.compression,
    required this.hasAlpha,
    required this.isAnimated,
    required this.loopCount,
    required this.frames,
  });

  /// Canvas or image width.
  final int width;

  /// Canvas or image height.
  final int height;

  /// Payload kind.
  final WebpCompression compression;

  /// Whether alpha is present or advertised.
  final bool hasAlpha;

  /// Whether ANIM/ANMF chunks are present.
  final bool isAnimated;

  /// Animation loop count, if present.
  final int? loopCount;

  /// Parsed frame metadata.
  final List<WebpFrameInfo> frames;
}

/// Parses a RIFF/WebP container and returns structural image metadata.
WebpImageInfo readWebpInfo(Uint8List bytes) {
  if (bytes.length < 20 ||
      String.fromCharCodes(bytes.sublist(0, 4)) != 'RIFF' ||
      String.fromCharCodes(bytes.sublist(8, 12)) != 'WEBP') {
    throw const InvalidImageException('Invalid WebP signature.');
  }
  var offset = 12;
  WebpImageInfo? info;
  var hasAlpha = false;
  var loopCount = 1;
  final frames = <WebpFrameInfo>[];
  while (offset + 8 <= bytes.length) {
    final type = String.fromCharCodes(bytes.sublist(offset, offset + 4));
    final length = readUint32Le(bytes, offset + 4);
    final start = offset + 8;
    final end = start + length;
    if (end > bytes.length) {
      throw const InvalidImageException('Truncated WebP chunk.');
    }
    final data = bytes.sublist(start, end);
    if (type == 'VP8 ') {
      info ??= _vp8Info(data);
    } else if (type == 'VP8L') {
      info ??= _vp8lInfo(data);
    } else if (type == 'VP8X') {
      info = _vp8xInfo(data);
      hasAlpha = info.hasAlpha;
    } else if (type == 'ALPH') {
      hasAlpha = true;
    } else if (type == 'ANIM') {
      loopCount = readUint16Le(data, 4);
    } else if (type == 'ANMF') {
      frames.add(_frameInfo(data));
    }
    offset = end + (length.isOdd ? 1 : 0);
  }
  final parsed = info;
  if (parsed == null) {
    throw const InvalidImageException('WebP has no decodable image chunk.');
  }
  return WebpImageInfo(
    width: parsed.width,
    height: parsed.height,
    compression: parsed.compression,
    hasAlpha:
        parsed.hasAlpha || hasAlpha || frames.any((frame) => frame.hasAlpha),
    isAnimated: parsed.isAnimated || frames.isNotEmpty,
    loopCount: frames.isEmpty ? parsed.loopCount : loopCount,
    frames: List<WebpFrameInfo>.unmodifiable(frames),
  );
}

WebpImageInfo _vp8Info(Uint8List data) {
  if (data.length < 10 ||
      data[3] != 0x9d ||
      data[4] != 0x01 ||
      data[5] != 0x2a) {
    throw const InvalidImageException('Invalid VP8 key-frame header.');
  }
  return WebpImageInfo(
    width: readUint16Le(data, 6) & 0x3fff,
    height: readUint16Le(data, 8) & 0x3fff,
    compression: WebpCompression.vp8,
    hasAlpha: false,
    isAnimated: false,
    loopCount: null,
    frames: const <WebpFrameInfo>[],
  );
}

WebpImageInfo _vp8lInfo(Uint8List data) {
  if (data.length < 5 || data[0] != 0x2f) {
    throw const InvalidImageException('Invalid VP8L header.');
  }
  final bits = readUint32Le(data, 1);
  return WebpImageInfo(
    width: (bits & 0x3fff) + 1,
    height: ((bits >> 14) & 0x3fff) + 1,
    compression: WebpCompression.vp8l,
    hasAlpha: ((bits >> 28) & 1) == 1,
    isAnimated: false,
    loopCount: null,
    frames: const <WebpFrameInfo>[],
  );
}

WebpImageInfo _vp8xInfo(Uint8List data) {
  if (data.length != 10) {
    throw const InvalidImageException('Invalid VP8X header.');
  }
  final flags = data[0];
  return WebpImageInfo(
    width: _uint24Le(data, 4) + 1,
    height: _uint24Le(data, 7) + 1,
    compression: WebpCompression.extended,
    hasAlpha: (flags & 0x10) != 0,
    isAnimated: (flags & 0x02) != 0,
    loopCount: null,
    frames: const <WebpFrameInfo>[],
  );
}

WebpFrameInfo _frameInfo(Uint8List data) {
  if (data.length < 16) {
    throw const InvalidImageException('Invalid WebP animation frame header.');
  }
  final flags = data[15];
  return WebpFrameInfo(
    x: _uint24Le(data, 0) * 2,
    y: _uint24Le(data, 3) * 2,
    width: _uint24Le(data, 6) + 1,
    height: _uint24Le(data, 9) + 1,
    duration: Duration(milliseconds: _uint24Le(data, 12)),
    hasAlpha: _containsChunk(data, 'ALPH', start: 16),
    blend: (flags & 0x02) == 0,
  );
}

bool _containsChunk(Uint8List bytes, String name, {required int start}) {
  var offset = start;
  while (offset + 8 <= bytes.length) {
    final type = String.fromCharCodes(bytes.sublist(offset, offset + 4));
    final length = readUint32Le(bytes, offset + 4);
    if (type == name) {
      return true;
    }
    offset += 8 + length + (length.isOdd ? 1 : 0);
  }
  return false;
}

int _uint24Le(Uint8List bytes, int offset) {
  return bytes[offset] | (bytes[offset + 1] << 8) | (bytes[offset + 2] << 16);
}
