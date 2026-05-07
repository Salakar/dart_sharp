import 'dart:typed_data';

import '../api/exceptions.dart';
import '../source/raw_pixels.dart';
import 'binary_io.dart';

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
  if (reader.readBits(1) == 1) {
    throw const UnsupportedCodecException(
      'VP8L transforms are not implemented yet.',
    );
  }
  if (reader.readBits(1) == 1) {
    throw const UnsupportedCodecException(
      'VP8L color cache is not implemented yet.',
    );
  }
  if (reader.readBits(1) == 1) {
    throw const UnsupportedCodecException(
      'VP8L meta prefix codes are not implemented yet.',
    );
  }
  final green = _PrefixCode.read(reader, 280);
  final red = _PrefixCode.read(reader, 256);
  final blue = _PrefixCode.read(reader, 256);
  final alpha = _PrefixCode.read(reader, 256);
  _PrefixCode.read(reader, 40);
  final out = Uint8List(width * height * 4);
  for (var pixel = 0; pixel < width * height; pixel += 1) {
    final g = green.decode(reader);
    if (g >= 256) {
      throw const UnsupportedCodecException(
        'VP8L LZ77 and color cache symbols are not implemented yet.',
      );
    }
    final offset = pixel * 4;
    out[offset] = red.decode(reader);
    out[offset + 1] = g;
    out[offset + 2] = blue.decode(reader);
    out[offset + 3] = alpha.decode(reader);
  }
  return RawPixels(
    bytes: out,
    width: width,
    height: height,
    channels: ChannelCount.four,
  );
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

final class _PrefixCode {
  const _PrefixCode._(this.symbol, [this.secondSymbol]);

  final int symbol;
  final int? secondSymbol;

  static _PrefixCode read(_BitReader reader, int alphabetSize) {
    if (reader.readBits(1) != 1) {
      throw const UnsupportedCodecException(
        'Normal VP8L prefix codes are not implemented yet.',
      );
    }
    final numSymbols = reader.readBits(1) + 1;
    final isFirst8Bits = reader.readBits(1);
    final symbol = reader.readBits(1 + 7 * isFirst8Bits);
    if (symbol >= alphabetSize) {
      throw const InvalidImageException('Invalid VP8L prefix symbol.');
    }
    if (numSymbols == 2) {
      final second = reader.readBits(8);
      if (second >= alphabetSize) {
        throw const InvalidImageException('Invalid VP8L prefix symbol.');
      }
      return _PrefixCode._(symbol, second);
    }
    return _PrefixCode._(symbol);
  }

  int decode(_BitReader reader) {
    final second = secondSymbol;
    if (second == null) {
      return symbol;
    }
    return reader.readBits(1) == 0 ? symbol : second;
  }
}

final class _BitReader {
  _BitReader(this.bytes, {required this.byteOffset});

  final Uint8List bytes;
  int byteOffset;
  var bitOffset = 0;

  int readBits(int count) {
    var value = 0;
    for (var i = 0; i < count; i += 1) {
      if (byteOffset >= bytes.length) {
        throw const InvalidImageException('Truncated VP8L bitstream.');
      }
      value |= ((bytes[byteOffset] >> bitOffset) & 1) << i;
      bitOffset += 1;
      if (bitOffset == 8) {
        bitOffset = 0;
        byteOffset += 1;
      }
    }
    return value;
  }
}
