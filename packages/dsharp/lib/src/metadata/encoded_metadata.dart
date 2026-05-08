import 'dart:typed_data';

import '../api/exceptions.dart';
import '../codecs/binary_io.dart';
import '../codecs/image_format.dart';
import '../codecs/webp_info.dart';
import '../source/input_options.dart';
import 'encoded_metadata_payloads.dart';
import 'metadata.dart';

/// Reads container metadata without decoding pixels when that is safe.
ImageMetadata? readEncodedImageMetadata(Uint8List bytes, ImageFormat format) {
  return switch (format) {
    ImageFormat.png => _pngMetadata(bytes),
    ImageFormat.jpeg => _jpegMetadata(bytes),
    ImageFormat.gif => _gifMetadata(bytes),
    ImageFormat.webp => _webpMetadata(bytes),
    ImageFormat.tiff => _tiffMetadata(bytes),
    _ => null,
  };
}

ImageMetadata _pngMetadata(Uint8List bytes) {
  if (bytes.length < 33 ||
      bytes[0] != 0x89 ||
      bytes[1] != 0x50 ||
      bytes[2] != 0x4e ||
      bytes[3] != 0x47 ||
      bytes[4] != 0x0d ||
      bytes[5] != 0x0a ||
      bytes[6] != 0x1a ||
      bytes[7] != 0x0a) {
    throw const InvalidImageException('Invalid PNG signature.');
  }
  var offset = 8;
  int? width;
  int? height;
  var bitDepth = 0;
  var colorType = 0;
  var interlace = 0;
  var hasTransparency = false;
  var hasProfile = false;
  var hasExif = false;
  var hasXmp = false;
  double? density;
  int? orientation;
  while (offset + 12 <= bytes.length) {
    final length = readUint32Be(bytes, offset);
    final type = String.fromCharCodes(bytes.sublist(offset + 4, offset + 8));
    final dataStart = offset + 8;
    final dataEnd = dataStart + length;
    if (dataEnd + 4 > bytes.length) {
      throw const InvalidImageException('Truncated PNG chunk.');
    }
    final data = bytes.sublist(dataStart, dataEnd);
    if (type == 'IHDR') {
      if (length != 13) {
        throw const InvalidImageException('Invalid PNG IHDR chunk.');
      }
      width = readUint32Be(data, 0);
      height = readUint32Be(data, 4);
      bitDepth = data[8];
      colorType = data[9];
      interlace = data[12];
      if (data[10] != 0 || data[11] != 0 || interlace > 1) {
        throw const UnsupportedCodecException(
          'Only standard PNG compression, filtering, and interlace are supported.',
        );
      }
    } else if (type == 'tRNS') {
      hasTransparency = true;
    } else if (type == 'iCCP') {
      hasProfile = true;
    } else if (type == 'eXIf') {
      hasExif = true;
      orientation ??= _exifOrientation(data);
    } else if (type == 'iTXt' && _isPngXmpChunk(data)) {
      hasXmp = true;
    } else if (type == 'pHYs' && length == 9 && data[8] == 1) {
      density = readUint32Be(data, 0) * 0.0254;
    } else if (type == 'IEND') {
      break;
    }
    offset = dataEnd + 4;
  }
  final parsedWidth = width;
  final parsedHeight = height;
  if (parsedWidth == null || parsedHeight == null) {
    throw const InvalidImageException('Invalid PNG dimensions.');
  }
  _checkMetadataLimits(parsedWidth, parsedHeight);
  if (!_supportsPngMetadataBitDepth(colorType, bitDepth)) {
    throw const UnsupportedCodecException(
      'Unsupported PNG colour type or bit depth.',
    );
  }
  final payloads = readEncodedMetadataPayloads(bytes, ImageFormat.png);
  final channels = switch (colorType) {
    0 => 1,
    2 || 3 => hasTransparency ? 4 : 3,
    4 => 2,
    6 => 4,
    _ => throw const UnsupportedCodecException(
      'Unsupported PNG colour type or bit depth.',
    ),
  };
  return ImageMetadata(
    format: ImageFormat.png,
    size: bytes.length,
    width: parsedWidth,
    height: parsedHeight,
    channels: channels,
    hasAlpha: hasTransparency || colorType == 4 || colorType == 6,
    density: density,
    hasProfile: hasProfile,
    hasExif: hasExif,
    hasXmp: hasXmp,
    iccProfile: payloads.iccProfile,
    exif: payloads.exif,
    xmp: payloads.xmp,
    bitDepth: bitDepth,
    orientation: orientation,
    isProgressive: interlace == 1,
    isPalette: colorType == 3,
  );
}

bool _isPngXmpChunk(Uint8List data) {
  const keyword = 'XML:com.adobe.xmp';
  if (data.length <= keyword.length || data[keyword.length] != 0) {
    return false;
  }
  for (var i = 0; i < keyword.length; i += 1) {
    if (data[i] != keyword.codeUnitAt(i)) {
      return false;
    }
  }
  return true;
}

bool _supportsPngMetadataBitDepth(int colorType, int bitDepth) {
  final lowBit = bitDepth == 1 || bitDepth == 2 || bitDepth == 4;
  return switch (colorType) {
    0 => lowBit || bitDepth == 8 || bitDepth == 16,
    3 => lowBit || bitDepth == 8,
    2 || 4 || 6 => bitDepth == 8 || bitDepth == 16,
    _ => false,
  };
}

ImageMetadata _jpegMetadata(Uint8List bytes) {
  if (bytes.length < 4 || bytes[0] != 0xff || bytes[1] != 0xd8) {
    throw const InvalidImageException('Invalid JPEG signature.');
  }
  var offset = 2;
  _JpegFrameInfo? frame;
  double? density;
  var hasProfile = false;
  var hasExif = false;
  var hasXmp = false;
  int? orientation;
  while (offset < bytes.length) {
    if (bytes[offset] != 0xff) {
      throw const InvalidImageException('Invalid JPEG marker.');
    }
    while (offset < bytes.length && bytes[offset] == 0xff) {
      offset += 1;
    }
    if (offset >= bytes.length) {
      break;
    }
    final marker = bytes[offset];
    offset += 1;
    if (marker == 0xd9 || marker == 0xda) {
      break;
    }
    if (_jpegStandaloneMarker(marker)) {
      continue;
    }
    if (offset + 2 > bytes.length) {
      throw const InvalidImageException('Truncated JPEG marker.');
    }
    final length = readUint16Be(bytes, offset);
    if (length < 2 || offset + length > bytes.length) {
      throw const InvalidImageException('Invalid JPEG marker length.');
    }
    final dataStart = offset + 2;
    final dataEnd = offset + length;
    final data = bytes.sublist(dataStart, dataEnd);
    if (marker == 0xe0) {
      density ??= _jfifDensity(data);
    } else if (marker == 0xe1) {
      if (_startsWithAscii(data, 'http://ns.adobe.com/xap/1.0/')) {
        hasXmp = true;
      } else {
        hasExif = hasExif || _startsWithAscii(data, 'Exif');
        orientation ??= _exifOrientation(data);
        hasExif = hasExif || orientation != null;
      }
    } else if (marker == 0xe2 && _startsWithAscii(data, 'ICC_PROFILE')) {
      hasProfile = true;
    } else if (_jpegSofMarker(marker)) {
      frame = _jpegFrameInfo(marker, data);
    }
    offset = dataEnd;
  }
  final parsed = frame;
  if (parsed == null) {
    throw const InvalidImageException('JPEG missing frame header.');
  }
  _checkMetadataLimits(parsed.width, parsed.height);
  final payloads = readEncodedMetadataPayloads(bytes, ImageFormat.jpeg);
  return ImageMetadata(
    format: ImageFormat.jpeg,
    size: bytes.length,
    width: parsed.width,
    height: parsed.height,
    channels: parsed.components,
    hasAlpha: false,
    density: density,
    hasProfile: hasProfile,
    hasExif: hasExif,
    hasXmp: hasXmp,
    iccProfile: payloads.iccProfile,
    exif: payloads.exif,
    xmp: payloads.xmp,
    bitDepth: parsed.precision,
    orientation: orientation,
    isProgressive: parsed.progressive,
  );
}

ImageMetadata _gifMetadata(Uint8List bytes) {
  if (bytes.length < 13 ||
      (!_startsWithAscii(bytes, 'GIF87a') &&
          !_startsWithAscii(bytes, 'GIF89a'))) {
    throw const InvalidImageException('Invalid GIF signature.');
  }
  final width = readUint16Le(bytes, 6);
  final height = readUint16Le(bytes, 8);
  _checkMetadataLimits(width, height);
  final packed = bytes[10];
  var offset = 13;
  if ((packed & 0x80) != 0) {
    offset += 3 * (1 << ((packed & 0x07) + 1));
  }
  var frames = 0;
  var hasAlpha = false;
  int? loopCount;
  var progressive = false;
  var pendingDelay = Duration.zero;
  final frameDelays = <Duration>[];
  while (offset < bytes.length) {
    final marker = bytes[offset];
    offset += 1;
    if (marker == 0x3b) {
      break;
    }
    if (marker == 0x2c) {
      if (offset + 9 > bytes.length) {
        throw const InvalidImageException('Truncated GIF image descriptor.');
      }
      final imagePacked = bytes[offset + 8];
      progressive = progressive || (imagePacked & 0x40) != 0;
      frameDelays.add(pendingDelay);
      pendingDelay = Duration.zero;
      offset += 9;
      if ((imagePacked & 0x80) != 0) {
        offset += 3 * (1 << ((imagePacked & 0x07) + 1));
      }
      if (offset >= bytes.length) {
        throw const InvalidImageException('Truncated GIF image data.');
      }
      offset = _skipGifSubBlocks(bytes, offset + 1);
      frames += 1;
    } else if (marker == 0x21) {
      if (offset >= bytes.length) {
        throw const InvalidImageException('Truncated GIF extension.');
      }
      final label = bytes[offset];
      offset += 1;
      if (label == 0xf9) {
        if (offset + 6 > bytes.length || bytes[offset] != 4) {
          throw const InvalidImageException('Invalid GIF graphics extension.');
        }
        hasAlpha = hasAlpha || (bytes[offset + 1] & 0x01) != 0;
        pendingDelay = Duration(
          milliseconds: readUint16Le(bytes, offset + 2) * 10,
        );
        offset += 6;
      } else if (label == 0xff) {
        if (offset >= bytes.length) {
          throw const InvalidImageException('Truncated GIF app extension.');
        }
        final blockSize = bytes[offset];
        offset += 1;
        if (offset + blockSize > bytes.length) {
          throw const InvalidImageException('Truncated GIF app extension.');
        }
        final name = String.fromCharCodes(
          bytes.sublist(offset, offset + blockSize),
        );
        offset += blockSize;
        final subBlocks = _readGifSubBlocks(bytes, offset);
        offset = subBlocks.offset;
        if (name == 'NETSCAPE2.0' &&
            subBlocks.bytes.length >= 3 &&
            subBlocks.bytes[0] == 1) {
          loopCount = subBlocks.bytes[1] | (subBlocks.bytes[2] << 8);
        }
      } else {
        offset = _skipGifSubBlocks(bytes, offset);
      }
    } else {
      throw const InvalidImageException('Invalid GIF block marker.');
    }
  }
  _checkMetadataLimits(width, height, frames: frames == 0 ? 1 : frames);
  return ImageMetadata(
    format: ImageFormat.gif,
    size: bytes.length,
    width: width,
    height: height,
    channels: hasAlpha ? 4 : 3,
    hasAlpha: hasAlpha,
    frames: frames == 0 ? 1 : frames,
    loopCount: loopCount,
    frameDelays: frameDelays,
    bitDepth: (packed & 0x07) + 1,
    isProgressive: progressive,
    isPalette: true,
  );
}

ImageMetadata _webpMetadata(Uint8List bytes) {
  final info = readWebpInfo(bytes);
  final frames = info.frames.isEmpty ? 1 : info.frames.length;
  _checkMetadataLimits(info.width, info.height, frames: frames);
  final payloads = readEncodedMetadataPayloads(bytes, ImageFormat.webp);
  return ImageMetadata(
    format: ImageFormat.webp,
    size: bytes.length,
    width: info.width,
    height: info.height,
    channels: info.hasAlpha ? 4 : 3,
    hasAlpha: info.hasAlpha,
    frames: frames,
    loopCount: info.isAnimated ? info.loopCount : null,
    frameDelays: <Duration>[for (final frame in info.frames) frame.duration],
    hasProfile: info.hasProfile,
    hasExif: info.hasExif,
    hasXmp: info.hasXmp,
    iccProfile: payloads.iccProfile,
    exif: payloads.exif,
    xmp: payloads.xmp,
    bitDepth: 8,
    orientation: payloads.exif == null
        ? null
        : _exifOrientation(payloads.exif!),
  );
}

ImageMetadata _tiffMetadata(Uint8List bytes) {
  if (bytes.length < 8) {
    throw const InvalidImageException('Invalid TIFF header.');
  }
  final little = bytes[0] == 0x49 && bytes[1] == 0x49;
  final big = bytes[0] == 0x4d && bytes[1] == 0x4d;
  if (!little && !big || _tiffRead16(bytes, 2, little) != 42) {
    throw const InvalidImageException('Invalid TIFF header.');
  }
  var ifdOffset = _tiffRead32(bytes, 4, little);
  final seen = <int>{};
  var frames = 0;
  int? width;
  int? height;
  var channels = 0;
  var bitDepth = 0;
  var hasAlpha = false;
  var hasProfile = false;
  var isPalette = false;
  double? density;
  while (ifdOffset != 0) {
    if (ifdOffset < 8 ||
        ifdOffset + 2 > bytes.length ||
        seen.contains(ifdOffset)) {
      throw const InvalidImageException('Invalid TIFF IFD offset.');
    }
    seen.add(ifdOffset);
    final count = _tiffRead16(bytes, ifdOffset, little);
    final entriesStart = ifdOffset + 2;
    final entriesEnd = entriesStart + count * 12;
    if (entriesEnd + 4 > bytes.length) {
      throw const InvalidImageException('Truncated TIFF IFD.');
    }
    final tags = <int, _TiffTag>{};
    for (var i = 0; i < count; i += 1) {
      final entry = entriesStart + i * 12;
      final tag = _tiffRead16(bytes, entry, little);
      final type = _tiffRead16(bytes, entry + 2, little);
      final valueCount = _tiffRead32(bytes, entry + 4, little);
      tags[tag] = _TiffTag(type, valueCount, entry + 8);
    }
    width ??= _tiffFirstInt(bytes, tags[256], little);
    height ??= _tiffFirstInt(bytes, tags[257], little);
    bitDepth = _tiffFirstInt(bytes, tags[258], little) ?? bitDepth;
    final samples = _tiffFirstInt(bytes, tags[277], little);
    final photometric = _tiffFirstInt(bytes, tags[262], little);
    isPalette = isPalette || photometric == 3;
    channels = channels == 0
        ? samples ?? _tiffPhotometricChannels(photometric)
        : channels;
    hasAlpha = hasAlpha || _tiffHasExtraSamples(bytes, tags[338], little);
    hasProfile = hasProfile || tags.containsKey(34675);
    density ??= _tiffDensity(bytes, tags, little);
    frames += 1;
    ifdOffset = _tiffRead32(bytes, entriesEnd, little);
  }
  final parsedWidth = width;
  final parsedHeight = height;
  if (frames == 0 || parsedWidth == null || parsedHeight == null) {
    throw const InvalidImageException('TIFF contains no image frames.');
  }
  _checkMetadataLimits(parsedWidth, parsedHeight, frames: frames);
  return ImageMetadata(
    format: ImageFormat.tiff,
    size: bytes.length,
    width: parsedWidth,
    height: parsedHeight,
    channels: channels == 0 ? 4 : channels,
    hasAlpha: hasAlpha,
    frames: frames,
    pageHeight: frames > 1 ? parsedHeight : null,
    density: density,
    hasProfile: hasProfile,
    bitDepth: bitDepth == 0 ? null : bitDepth,
    isPalette: isPalette,
  );
}

bool _jpegStandaloneMarker(int marker) {
  return marker == 0x01 || marker >= 0xd0 && marker <= 0xd9;
}

bool _jpegSofMarker(int marker) {
  return marker >= 0xc0 &&
      marker <= 0xcf &&
      marker != 0xc4 &&
      marker != 0xc8 &&
      marker != 0xcc;
}

_JpegFrameInfo _jpegFrameInfo(int marker, Uint8List data) {
  if (data.length < 6) {
    throw const InvalidImageException('Truncated JPEG frame header.');
  }
  return _JpegFrameInfo(
    width: readUint16Be(data, 3),
    height: readUint16Be(data, 1),
    components: data[5],
    precision: data[0],
    progressive: marker == 0xc2,
  );
}

double? _jfifDensity(Uint8List data) {
  if (data.length < 12 || !_startsWithAscii(data, 'JFIF')) {
    return null;
  }
  final units = data[7];
  final xDensity = readUint16Be(data, 8);
  if (xDensity == 0) {
    return null;
  }
  return switch (units) {
    1 => xDensity.toDouble(),
    2 => xDensity * 2.54,
    _ => null,
  };
}

int? _exifOrientation(Uint8List data) {
  if (data.length < 8) {
    return null;
  }
  var tiff = 0;
  if (_startsWithAscii(data, 'Exif')) {
    if (data.length < 14) {
      return null;
    }
    tiff = 6;
  }
  final little = data[tiff] == 0x49 && data[tiff + 1] == 0x49;
  final big = data[tiff] == 0x4d && data[tiff + 1] == 0x4d;
  if (!little && !big || _tiffRead16(data, tiff + 2, little) != 42) {
    return null;
  }
  final ifd = tiff + _tiffRead32(data, tiff + 4, little);
  if (ifd + 2 > data.length) {
    return null;
  }
  final count = _tiffRead16(data, ifd, little);
  final entriesStart = ifd + 2;
  final entriesEnd = entriesStart + count * 12;
  if (entriesEnd > data.length) {
    return null;
  }
  for (var i = 0; i < count; i += 1) {
    final entry = entriesStart + i * 12;
    if (_tiffRead16(data, entry, little) == 0x0112) {
      return _tiffRead16(data, entry + 8, little);
    }
  }
  return null;
}

int _skipGifSubBlocks(Uint8List bytes, int offset) {
  var current = offset;
  while (current < bytes.length) {
    final length = bytes[current];
    current += 1;
    if (length == 0) {
      return current;
    }
    current += length;
    if (current > bytes.length) {
      throw const InvalidImageException('Truncated GIF data block.');
    }
  }
  throw const InvalidImageException('Truncated GIF data block.');
}

_GifSubBlocks _readGifSubBlocks(Uint8List bytes, int offset) {
  var current = offset;
  final data = <int>[];
  while (current < bytes.length) {
    final length = bytes[current];
    current += 1;
    if (length == 0) {
      return _GifSubBlocks(Uint8List.fromList(data), current);
    }
    if (current + length > bytes.length) {
      throw const InvalidImageException('Truncated GIF data block.');
    }
    data.addAll(bytes.sublist(current, current + length));
    current += length;
  }
  throw const InvalidImageException('Truncated GIF data block.');
}

int? _tiffFirstInt(Uint8List bytes, _TiffTag? tag, bool little) {
  if (tag == null || tag.count <= 0) {
    return null;
  }
  final offset = _tiffValueOffset(bytes, tag, little);
  return switch (tag.type) {
    1 => bytes[offset],
    3 => _tiffRead16(bytes, offset, little),
    4 => _tiffRead32(bytes, offset, little),
    _ => null,
  };
}

bool _tiffHasExtraSamples(Uint8List bytes, _TiffTag? tag, bool little) {
  if (tag == null || tag.count <= 0) {
    return false;
  }
  final offset = _tiffValueOffset(bytes, tag, little);
  final values = tag.count > 4 ? 4 : tag.count;
  for (var i = 0; i < values; i += 1) {
    final value = switch (tag.type) {
      1 => bytes[offset + i],
      3 => _tiffRead16(bytes, offset + i * 2, little),
      _ => 0,
    };
    if (value == 1 || value == 2) {
      return true;
    }
  }
  return false;
}

double? _tiffDensity(Uint8List bytes, Map<int, _TiffTag> tags, bool little) {
  final x = _tiffRational(bytes, tags[282], little);
  if (x == null || x == 0) {
    return null;
  }
  final unit = _tiffFirstInt(bytes, tags[296], little) ?? 2;
  return switch (unit) {
    2 => x,
    3 => x * 2.54,
    _ => null,
  };
}

double? _tiffRational(Uint8List bytes, _TiffTag? tag, bool little) {
  if (tag == null || tag.type != 5 || tag.count <= 0) {
    return null;
  }
  final offset = _tiffValueOffset(bytes, tag, little);
  if (offset + 8 > bytes.length) {
    throw const InvalidImageException('Invalid TIFF tag offset.');
  }
  final denominator = _tiffRead32(bytes, offset + 4, little);
  if (denominator == 0) {
    return null;
  }
  return _tiffRead32(bytes, offset, little) / denominator;
}

int _tiffValueOffset(Uint8List bytes, _TiffTag tag, bool little) {
  final typeSize = switch (tag.type) {
    1 || 2 || 7 => 1,
    3 => 2,
    4 || 9 => 4,
    5 || 10 => 8,
    _ => throw const UnsupportedCodecException('Unsupported TIFF tag type.'),
  };
  final total = tag.count * typeSize;
  final offset = total <= 4
      ? tag.valueOffset
      : _tiffRead32(bytes, tag.valueOffset, little);
  if (offset < 0 || offset + total > bytes.length) {
    throw const InvalidImageException('Invalid TIFF tag offset.');
  }
  return offset;
}

int _tiffPhotometricChannels(int? photometric) {
  return switch (photometric) {
    0 || 1 => 1,
    2 || 3 || 8 => 3,
    5 => 4,
    _ => 4,
  };
}

int _tiffRead16(Uint8List bytes, int offset, bool little) {
  return little ? readUint16Le(bytes, offset) : readUint16Be(bytes, offset);
}

int _tiffRead32(Uint8List bytes, int offset, bool little) {
  return little ? readUint32Le(bytes, offset) : readUint32Be(bytes, offset);
}

bool _startsWithAscii(Uint8List bytes, String text) {
  if (bytes.length < text.length) {
    return false;
  }
  for (var i = 0; i < text.length; i += 1) {
    if (bytes[i] != text.codeUnitAt(i)) {
      return false;
    }
  }
  return true;
}

void _checkMetadataLimits(int width, int height, {int frames = 1}) {
  const InputSafetyLimits().checkImage(
    width: width,
    height: height,
    frames: frames,
  );
}

final class _JpegFrameInfo {
  const _JpegFrameInfo({
    required this.width,
    required this.height,
    required this.components,
    required this.precision,
    required this.progressive,
  });

  final int width;
  final int height;
  final int components;
  final int precision;
  final bool progressive;
}

final class _GifSubBlocks {
  const _GifSubBlocks(this.bytes, this.offset);

  final Uint8List bytes;
  final int offset;
}

final class _TiffTag {
  const _TiffTag(this.type, this.count, this.valueOffset);

  final int type;
  final int count;
  final int valueOffset;
}
