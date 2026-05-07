import 'dart:typed_data';

import '../api/exceptions.dart';
import '../source/raw_pixels.dart';
import 'binary_io.dart';

part 'webp_lossless_bits.dart';
part 'webp_lossless_color_cache.dart';
part 'webp_lossless_color_indexing.dart';
part 'webp_lossless_distance.dart';
part 'webp_lossless_prefix.dart';
part 'webp_lossless_transform.dart';

/// Decodes the supported VP8L subset of WebP lossless images.
RawPixels decodeWebpLossless(Uint8List bytes) {
  final chunk = _findVp8lChunk(bytes);
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
  return RawPixels(
    bytes: image.bytes,
    width: width,
    height: height,
    channels: ChannelCount.four,
  );
}

Uint8List _decodeImageData(
  _BitReader reader,
  int width,
  int height, {
  required bool readMetaPrefix,
}) {
  final colorCache = _ColorCache.read(reader);
  if (readMetaPrefix && reader.readBits(1) == 1) {
    throw const UnsupportedCodecException(
      'VP8L meta prefix codes are not implemented yet.',
    );
  }
  final green = _PrefixCode.read(reader, 280 + colorCache.size);
  final red = _PrefixCode.read(reader, 256);
  final blue = _PrefixCode.read(reader, 256);
  final alpha = _PrefixCode.read(reader, 256);
  final distance = _PrefixCode.read(reader, 40);
  final out = Uint8List(width * height * 4);
  var pixel = 0;
  while (pixel < width * height) {
    final g = green.decode(reader);
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
        _prefixValue(distance.decode(reader), reader),
        width,
      );
      if (dist <= 0 || dist > pixel || pixel + length > width * height) {
        throw const InvalidImageException('Invalid VP8L backward reference.');
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
    final argb = _argb(
      alpha.decode(reader),
      red.decode(reader),
      g,
      blue.decode(reader),
    );
    _writeArgbToRgba(out, pixel, argb);
    colorCache.insert(argb);
    pixel += 1;
  }
  return out;
}

Uint8List _findVp8lChunk(Uint8List bytes) {
  if (bytes.length < 20 ||
      String.fromCharCodes(bytes.sublist(0, 4)) != 'RIFF' ||
      String.fromCharCodes(bytes.sublist(8, 12)) != 'WEBP') {
    throw const InvalidImageException('Invalid WebP signature.');
  }
  var offset = 12;
  while (offset + 8 <= bytes.length) {
    final type = String.fromCharCodes(bytes.sublist(offset, offset + 4));
    final length = readUint32Le(bytes, offset + 4);
    final start = offset + 8;
    final end = start + length;
    if (end > bytes.length) {
      throw const InvalidImageException('Truncated WebP chunk.');
    }
    if (type == 'VP8L') {
      return bytes.sublist(start, end);
    }
    offset = end + (length.isOdd ? 1 : 0);
  }
  throw const UnsupportedCodecException(
    'Only VP8L lossless WebP pixel decoding is implemented so far.',
  );
}
