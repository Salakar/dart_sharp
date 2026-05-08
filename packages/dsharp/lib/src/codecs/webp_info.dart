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
    required this.hasProfile,
    required this.hasExif,
    required this.hasXmp,
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

  /// Whether an ICC profile chunk is present or advertised.
  final bool hasProfile;

  /// Whether an EXIF chunk is present or advertised.
  final bool hasExif;

  /// Whether an XMP chunk is present or advertised.
  final bool hasXmp;

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
  var hasProfile = false;
  var hasExif = false;
  var hasXmp = false;
  var loopCount = 1;
  var hasAnimationHeader = false;
  var imageChunkCount = 0;
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
      imageChunkCount += 1;
      if (imageChunkCount > 1) {
        throw const InvalidImageException('WebP has multiple image chunks.');
      }
      info ??= _vp8Info(data);
    } else if (type == 'VP8L') {
      imageChunkCount += 1;
      if (imageChunkCount > 1) {
        throw const InvalidImageException('WebP has multiple image chunks.');
      }
      info ??= _vp8lInfo(data);
    } else if (type == 'VP8X') {
      info = _vp8xInfo(data);
      hasAlpha = info.hasAlpha;
      hasProfile = info.hasProfile;
      hasExif = info.hasExif;
      hasXmp = info.hasXmp;
    } else if (type == 'ALPH') {
      hasAlpha = true;
    } else if (type == 'ICCP') {
      hasProfile = true;
    } else if (type == 'EXIF') {
      hasExif = true;
    } else if (type == 'XMP ') {
      hasXmp = true;
    } else if (type == 'ANIM') {
      if (data.length < 6) {
        throw const InvalidImageException('Invalid WebP animation header.');
      }
      hasAnimationHeader = true;
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
  if (parsed.compression == WebpCompression.extended &&
      !parsed.isAnimated &&
      imageChunkCount != 1) {
    throw const InvalidImageException('WebP has no decodable image chunk.');
  }
  if (parsed.isAnimated) {
    if (!hasAnimationHeader) {
      throw const InvalidImageException('WebP animation is missing ANIM.');
    }
    if (frames.isEmpty) {
      throw const InvalidImageException('WebP animation has no frames.');
    }
  } else if (frames.isNotEmpty) {
    throw const InvalidImageException('WebP animation flag is not set.');
  }
  for (final frame in frames) {
    if (frame.x + frame.width > parsed.width ||
        frame.y + frame.height > parsed.height) {
      throw const InvalidImageException('WebP animation frame exceeds canvas.');
    }
  }
  return WebpImageInfo(
    width: parsed.width,
    height: parsed.height,
    compression: parsed.compression,
    hasAlpha:
        parsed.hasAlpha || hasAlpha || frames.any((frame) => frame.hasAlpha),
    hasProfile: parsed.hasProfile || hasProfile,
    hasExif: parsed.hasExif || hasExif,
    hasXmp: parsed.hasXmp || hasXmp,
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
    hasProfile: false,
    hasExif: false,
    hasXmp: false,
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
    hasProfile: false,
    hasExif: false,
    hasXmp: false,
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
    hasProfile: (flags & 0x20) != 0,
    hasExif: (flags & 0x08) != 0,
    hasXmp: (flags & 0x04) != 0,
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
    final dataStart = offset + 8;
    final dataEnd = dataStart + length;
    if (dataEnd > bytes.length) {
      throw const InvalidImageException('Truncated WebP animation frame.');
    }
    if (type == name) {
      return true;
    }
    offset = dataEnd + (length.isOdd ? 1 : 0);
  }
  return false;
}

int _uint24Le(Uint8List bytes, int offset) {
  return bytes[offset] | (bytes[offset + 1] << 8) | (bytes[offset + 2] << 16);
}
