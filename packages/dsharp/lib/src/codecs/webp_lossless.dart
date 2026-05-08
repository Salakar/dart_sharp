import 'dart:typed_data';

import '../api/exceptions.dart';
import '../source/raw_pixels.dart';
import 'binary_io.dart';
import 'webp_riff.dart';

part 'webp_lossless_bits.dart';
part 'webp_lossless_color_cache.dart';
part 'webp_lossless_color_indexing.dart';
part 'webp_lossless_distance.dart';
part 'webp_lossless_prefix.dart';
part 'webp_lossless_transform.dart';

/// Decodes the supported VP8L subset of WebP lossless images.
RawPixels decodeWebpLossless(Uint8List bytes) {
  final chunk = _findVp8lChunk(bytes);
  return decodeWebpLosslessChunk(chunk);
}

/// Decodes a raw VP8L chunk payload.
RawPixels decodeWebpLosslessChunk(Uint8List chunk) {
  final reader = _BitReader(chunk, byteOffset: 1);
  if (chunk.isEmpty || chunk[0] != 0x2f) {
    throw const InvalidImageException('Invalid VP8L signature.');
  }
  final width = reader.readBits(14) + 1;
  final height = reader.readBits(14) + 1;
  reader.readBits(1);
  if (reader.readBits(3) != 0) {
    throw const InvalidImageException('Unsupported VP8L version.');
  }
  final image = _decodeWebpLosslessImage(reader, width, height);
  return RawPixels(
    bytes: image.bytes,
    width: width,
    height: height,
    channels: ChannelCount.four,
  );
}

/// Decodes a headerless VP8L image stream and returns its green channel.
Uint8List decodeHeaderlessWebpLosslessGreen(
  Uint8List chunk, {
  required int width,
  required int height,
}) {
  final image = _decodeWebpLosslessImage(
    _BitReader(chunk, byteOffset: 0),
    width,
    height,
  );
  final green = Uint8List(width * height);
  for (var i = 0; i < green.length; i += 1) {
    green[i] = image.bytes[i * 4 + 1];
  }
  return green;
}

_LosslessImage _decodeWebpLosslessImage(
  _BitReader reader,
  int width,
  int height,
) {
  final transforms = <_LosslessTransform>[];
  var dataWidth = width;
  while (reader.readBits(1) == 1) {
    final transform = _LosslessTransform.read(reader, dataWidth, height);
    if (transforms.any((item) => item.type == transform.type)) {
      throw const InvalidImageException('Duplicate VP8L transform.');
    }
    transforms.add(transform);
    dataWidth = transform.encodedWidth(dataWidth);
  }
  var image = _LosslessImage(
    _decodeImageData(reader, dataWidth, height, readMetaPrefix: true),
    dataWidth,
    height,
  );
  for (final transform in transforms.reversed) {
    image = transform.apply(image);
  }
  if (image.width != width || image.height != height) {
    throw const InvalidImageException('Invalid VP8L transform dimensions.');
  }
  return image;
}

Uint8List _decodeImageData(
  _BitReader reader,
  int width,
  int height, {
  required bool readMetaPrefix,
}) {
  final colorCache = _ColorCache.read(reader);
  final metaPrefix = readMetaPrefix
      ? _MetaPrefixCodes.read(reader, width, height)
      : _MetaPrefixCodes.single();
  final groups = <_PrefixCodeGroup>[
    for (var i = 0; i < metaPrefix.groupCount; i += 1)
      _PrefixCodeGroup.read(reader, colorCache.size),
  ];
  final out = Uint8List(width * height * 4);
  var pixel = 0;
  while (pixel < width * height) {
    final group = groups[metaPrefix.groupFor(pixel % width, pixel ~/ width)];
    final g = group.green.decode(reader);
    if (g >= 280) {
      final argb = colorCache[g - 280];
      _writeArgbToRgba(out, pixel, argb);
      colorCache.insert(argb);
      pixel += 1;
      continue;
    }
    if (g >= 256) {
      final length = _prefixValue(g - 256, reader);
      final dist = _distanceToPixels(
        _prefixValue(group.distance.decode(reader), reader),
        width,
      );
      if (dist <= 0 || dist > pixel || pixel + length > width * height) {
        throw InvalidImageException(
          'Invalid VP8L backward reference at pixel $pixel '
          '(distance $dist, length $length).',
        );
      }
      for (var i = 0; i < length; i += 1) {
        out.setRange(
          (pixel + i) * 4,
          (pixel + i + 1) * 4,
          out,
          (pixel + i - dist) * 4,
        );
        colorCache.insert(_argbFromRgba(out, pixel + i));
      }
      pixel += length;
      continue;
    }
    final red = group.red.decode(reader);
    final blue = group.blue.decode(reader);
    final alpha = group.alpha.decode(reader);
    final argb = _argb(alpha, red, g, blue);
    _writeArgbToRgba(out, pixel, argb);
    colorCache.insert(argb);
    pixel += 1;
  }
  return out;
}

final class _MetaPrefixCodes {
  const _MetaPrefixCodes._(
    this._prefixBits,
    this._width,
    this._codes,
    this.groupCount,
  );

  factory _MetaPrefixCodes.single() {
    return _MetaPrefixCodes._(0, 0, Uint16List(0), 1);
  }

  factory _MetaPrefixCodes.read(_BitReader reader, int width, int height) {
    if (reader.readBits(1) == 0) {
      return _MetaPrefixCodes.single();
    }
    final prefixBits = reader.readBits(3) + 2;
    final prefixWidth = _divRoundUp(width, 1 << prefixBits);
    final prefixHeight = _divRoundUp(height, 1 << prefixBits);
    final image = _decodeImageData(
      reader,
      prefixWidth,
      prefixHeight,
      readMetaPrefix: false,
    );
    final codes = Uint16List(prefixWidth * prefixHeight);
    var maxCode = 0;
    for (var i = 0; i < codes.length; i += 1) {
      final code = (_argbFromRgba(image, i) >> 8) & 0xffff;
      codes[i] = code;
      if (code > maxCode) {
        maxCode = code;
      }
    }
    return _MetaPrefixCodes._(prefixBits, prefixWidth, codes, maxCode + 1);
  }

  final int _prefixBits;
  final int _width;
  final Uint16List _codes;
  final int groupCount;

  int groupFor(int x, int y) {
    if (_codes.isEmpty) {
      return 0;
    }
    return _codes[(y >> _prefixBits) * _width + (x >> _prefixBits)];
  }
}

Uint8List _findVp8lChunk(Uint8List bytes) {
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
    if (type == 'VP8L') {
      return bytes.sublist(start, end);
    }
    offset = end + (length.isOdd ? 1 : 0);
  }
  if (offset != riffEnd) {
    throw const InvalidImageException('Truncated WebP chunk.');
  }
  throw const UnsupportedCodecException(
    'Only VP8L lossless WebP pixel decoding is implemented so far.',
  );
}
