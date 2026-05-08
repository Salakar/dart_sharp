import 'dart:typed_data';

import '../api/exceptions.dart';
import 'binary_io.dart';
import 'webp_riff.dart';

const _vp8xReservedFeatureFlags = 0xc1;
const _animationFrameReservedFlags = 0xfc;

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
  final riffEnd = webpRiffEnd(bytes);
  var offset = 12;
  WebpImageInfo? info;
  WebpImageInfo? payloadInfo;
  WebpCompression? imageCompression;
  var hasVp8x = false;
  var hasAlphaChunk = false;
  var hasProfileChunk = false;
  var hasExifChunk = false;
  var hasXmpChunk = false;
  var loopCount = 1;
  var hasAnimationHeader = false;
  var imageChunkCount = 0;
  final frames = <WebpFrameInfo>[];
  while (offset + 8 <= riffEnd) {
    final type = String.fromCharCodes(bytes.sublist(offset, offset + 4));
    final length = readUint32Le(bytes, offset + 4);
    final start = offset + 8;
    final end = start + length;
    if (end > riffEnd) {
      throw const InvalidImageException('Truncated WebP chunk.');
    }
    final data = bytes.sublist(start, end);
    if (type == 'VP8 ') {
      imageChunkCount += 1;
      if (imageChunkCount > 1) {
        throw const InvalidImageException('WebP has multiple image chunks.');
      }
      imageCompression = WebpCompression.vp8;
      payloadInfo = _vp8Info(data);
      info ??= payloadInfo;
    } else if (type == 'VP8L') {
      imageChunkCount += 1;
      if (imageChunkCount > 1) {
        throw const InvalidImageException('WebP has multiple image chunks.');
      }
      imageCompression = WebpCompression.vp8l;
      payloadInfo = _vp8lInfo(data);
      info ??= payloadInfo;
    } else if (type == 'VP8X') {
      if (hasVp8x) {
        throw const InvalidImageException('WebP has multiple VP8X chunks.');
      }
      if (offset != 12) {
        throw const InvalidImageException('WebP VP8X chunk must be first.');
      }
      hasVp8x = true;
      info = _vp8xInfo(data);
    } else if (type == 'ALPH') {
      if (hasAlphaChunk) {
        throw const InvalidImageException('WebP has multiple ALPH chunks.');
      }
      if (imageChunkCount > 0) {
        throw const InvalidImageException(
          'WebP ALPH chunk follows image data.',
        );
      }
      hasAlphaChunk = true;
    } else if (type == 'ICCP') {
      if (hasProfileChunk) {
        throw const InvalidImageException('WebP has multiple ICCP chunks.');
      }
      hasProfileChunk = true;
    } else if (type == 'EXIF') {
      if (hasExifChunk) {
        throw const InvalidImageException('WebP has multiple EXIF chunks.');
      }
      hasExifChunk = true;
    } else if (type == 'XMP ') {
      if (hasXmpChunk) {
        throw const InvalidImageException('WebP has multiple XMP chunks.');
      }
      hasXmpChunk = true;
    } else if (type == 'ANIM') {
      if (hasAnimationHeader) {
        throw const InvalidImageException(
          'WebP animation has multiple ANIM chunks.',
        );
      }
      if (data.length != 6) {
        throw const InvalidImageException('Invalid WebP animation header.');
      }
      hasAnimationHeader = true;
      loopCount = readUint16Le(data, 4);
    } else if (type == 'ANMF') {
      if (!hasAnimationHeader) {
        throw const InvalidImageException(
          'WebP animation frame precedes ANIM.',
        );
      }
      frames.add(_frameInfo(data));
    }
    offset = end + (length.isOdd ? 1 : 0);
  }
  if (offset != riffEnd) {
    throw const InvalidImageException('Truncated WebP chunk.');
  }
  final parsed = info;
  if (parsed == null) {
    throw const InvalidImageException('WebP has no decodable image chunk.');
  }
  if (!hasVp8x && (hasProfileChunk || hasExifChunk || hasXmpChunk)) {
    throw const InvalidImageException('WebP metadata chunks require VP8X.');
  }
  if (parsed.compression == WebpCompression.extended &&
      !parsed.isAnimated &&
      imageChunkCount != 1) {
    throw const InvalidImageException('WebP has no decodable image chunk.');
  }
  final embeddedPayload = payloadInfo;
  if (parsed.compression == WebpCompression.extended &&
      !parsed.isAnimated &&
      embeddedPayload != null &&
      (embeddedPayload.width != parsed.width ||
          embeddedPayload.height != parsed.height)) {
    throw const InvalidImageException(
      'WebP VP8X dimensions do not match image payload.',
    );
  }
  if (parsed.isAnimated) {
    if (imageChunkCount != 0) {
      throw const InvalidImageException(
        'WebP animation has top-level image chunks.',
      );
    }
    if (hasAlphaChunk) {
      throw const InvalidImageException(
        'WebP animation has top-level ALPH chunks.',
      );
    }
    if (!hasAnimationHeader) {
      throw const InvalidImageException('WebP animation is missing ANIM.');
    }
    if (frames.isEmpty) {
      throw const InvalidImageException('WebP animation has no frames.');
    }
  } else if (hasAnimationHeader || frames.isNotEmpty) {
    throw const InvalidImageException('WebP animation flag is not set.');
  }
  if (hasAlphaChunk &&
      (parsed.compression != WebpCompression.extended ||
          imageCompression != WebpCompression.vp8)) {
    throw const InvalidImageException(
      'WebP ALPH chunk requires an extended VP8 image.',
    );
  }
  if (parsed.compression == WebpCompression.extended &&
      !parsed.isAnimated &&
      imageCompression == WebpCompression.vp8 &&
      parsed.hasAlpha != hasAlphaChunk) {
    throw const InvalidImageException(
      'WebP VP8 alpha flag does not match ALPH chunk.',
    );
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
        parsed.hasAlpha ||
        hasAlphaChunk ||
        frames.any((frame) => frame.hasAlpha),
    hasProfile: parsed.hasProfile || hasProfileChunk,
    hasExif: parsed.hasExif || hasExifChunk,
    hasXmp: parsed.hasXmp || hasXmpChunk,
    isAnimated: parsed.isAnimated || frames.isNotEmpty,
    loopCount: frames.isEmpty ? parsed.loopCount : loopCount,
    frames: List<WebpFrameInfo>.unmodifiable(frames),
  );
}

WebpImageInfo _vp8Info(Uint8List data) {
  if (data.length < 10) {
    throw const InvalidImageException('Invalid VP8 key-frame header.');
  }
  final tag = data[0] | (data[1] << 8) | (data[2] << 16);
  if ((tag & 1) != 0) {
    throw const UnsupportedCodecException(
      'Only VP8 key frames are supported for WebP still images.',
    );
  }
  if (((tag >> 4) & 1) == 0) {
    throw const InvalidImageException('VP8 key frame is not displayable.');
  }
  final firstPartSize = (tag >> 5) & 0x7ffff;
  if (data[3] != 0x9d ||
      data[4] != 0x01 ||
      data[5] != 0x2a ||
      10 + firstPartSize > data.length) {
    throw const InvalidImageException('Invalid VP8 key-frame header.');
  }
  final width = readUint16Le(data, 6) & 0x3fff;
  final height = readUint16Le(data, 8) & 0x3fff;
  if (width == 0 || height == 0) {
    throw const InvalidImageException('Invalid VP8 dimensions.');
  }
  return WebpImageInfo(
    width: width,
    height: height,
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
  if ((flags & _vp8xReservedFeatureFlags) != 0) {
    throw const InvalidImageException('Invalid VP8X feature flags.');
  }
  if (data[1] != 0 || data[2] != 0 || data[3] != 0) {
    throw const InvalidImageException('Invalid VP8X reserved fields.');
  }
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
  if ((flags & _animationFrameReservedFlags) != 0) {
    throw const InvalidImageException('Invalid WebP animation frame flags.');
  }
  final payload = _framePayloadInfo(data, start: 16);
  if (payload.hasVp8l == payload.hasVp8) {
    throw const InvalidImageException(
      'WebP animation frame has no image data.',
    );
  }
  if (payload.hasVp8l && payload.hasAlpha) {
    throw const InvalidImageException('WebP VP8L animation frame has ALPH.');
  }
  final width = _uint24Le(data, 6) + 1;
  final height = _uint24Le(data, 9) + 1;
  if (payload.width != width || payload.height != height) {
    throw const InvalidImageException('Invalid WebP animation frame size.');
  }
  return WebpFrameInfo(
    x: _uint24Le(data, 0) * 2,
    y: _uint24Le(data, 3) * 2,
    width: width,
    height: height,
    duration: Duration(milliseconds: _uint24Le(data, 12)),
    hasAlpha: payload.hasAlpha,
    blend: (flags & 0x02) == 0,
  );
}

({bool hasAlpha, bool hasVp8l, bool hasVp8, int? width, int? height})
_framePayloadInfo(Uint8List bytes, {required int start}) {
  var offset = start;
  var hasAlpha = false;
  var hasVp8l = false;
  var hasVp8 = false;
  int? width;
  int? height;
  var imageChunkCount = 0;
  while (offset + 8 <= bytes.length) {
    final type = String.fromCharCodes(bytes.sublist(offset, offset + 4));
    final length = readUint32Le(bytes, offset + 4);
    final dataStart = offset + 8;
    final dataEnd = dataStart + length;
    if (dataEnd > bytes.length) {
      throw const InvalidImageException('Truncated WebP animation frame.');
    }
    if (type == 'ALPH') {
      if (hasAlpha) {
        throw const InvalidImageException(
          'WebP animation frame has multiple ALPH chunks.',
        );
      }
      if (imageChunkCount > 0) {
        throw const InvalidImageException(
          'WebP animation frame ALPH chunk follows image data.',
        );
      }
      hasAlpha = true;
    } else if (type == 'VP8L') {
      imageChunkCount += 1;
      if (imageChunkCount > 1) {
        throw const InvalidImageException(
          'WebP animation frame has multiple image chunks.',
        );
      }
      final info = _vp8lInfo(bytes.sublist(dataStart, dataEnd));
      width = info.width;
      height = info.height;
      hasVp8l = true;
    } else if (type == 'VP8 ') {
      imageChunkCount += 1;
      if (imageChunkCount > 1) {
        throw const InvalidImageException(
          'WebP animation frame has multiple image chunks.',
        );
      }
      final info = _vp8Info(bytes.sublist(dataStart, dataEnd));
      width = info.width;
      height = info.height;
      hasVp8 = true;
    }
    offset = dataEnd + (length.isOdd ? 1 : 0);
  }
  if (offset != bytes.length) {
    throw const InvalidImageException('Truncated WebP animation frame.');
  }
  return (
    hasAlpha: hasAlpha,
    hasVp8l: hasVp8l,
    hasVp8: hasVp8,
    width: width,
    height: height,
  );
}

int _uint24Le(Uint8List bytes, int offset) {
  return bytes[offset] | (bytes[offset + 1] << 8) | (bytes[offset + 2] << 16);
}
