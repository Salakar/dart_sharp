import 'dart:typed_data';

import '../api/exceptions.dart';
import '../pixels/pixel_image.dart';
import 'binary_io.dart';
import 'codec_pixels.dart';

/// Encodes the first frame as a lossless VP8L WebP image.
Uint8List encodeWebpLossless(PixelImage image) {
  final raw = image.firstFrame.pixels;
  if (raw.width > 16384 || raw.height > 16384) {
    throw const OperationValidationException(
      'WebP dimensions must be at most 16384x16384.',
    );
  }
  final rgba = rawToRgba(raw);
  var hasAlpha = false;
  for (var i = 3; i < rgba.length; i += 4) {
    if (rgba[i] != 255) {
      hasAlpha = true;
      break;
    }
  }
  final bits = _Vp8lBitWriter()
    ..write(raw.width - 1, 14)
    ..write(raw.height - 1, 14)
    ..write(hasAlpha ? 1 : 0, 1)
    ..write(0, 3)
    ..write(0, 1)
    ..write(0, 1)
    ..write(0, 1);
  _writeBytePrefixCode(bits, 280);
  _writeBytePrefixCode(bits, 256);
  _writeBytePrefixCode(bits, 256);
  _writeBytePrefixCode(bits, 256);
  _writeSingleSymbolCode(bits, 0);
  for (var i = 0; i < rgba.length; i += 4) {
    bits
      ..write(_reverseBits(rgba[i + 1], 8), 8)
      ..write(_reverseBits(rgba[i + 3], 8), 8)
      ..write(_reverseBits(rgba[i], 8), 8)
      ..write(_reverseBits(rgba[i + 2], 8), 8);
  }
  return _webpContainer(Uint8List.fromList(<int>[0x2f, ...bits.finish()]));
}

void _writeBytePrefixCode(_Vp8lBitWriter bits, int alphabetSize) {
  bits.write(0, 1);
  _writeCodeLengthCode(bits);
  if (alphabetSize == 256) {
    bits.write(0, 1);
  } else {
    bits
      ..write(1, 1)
      ..write(3, 3)
      ..write(254, 8);
  }
  for (var i = 0; i < 256; i += 1) {
    bits.write(0, 1);
  }
}

void _writeCodeLengthCode(_Vp8lBitWriter bits) {
  const order = <int>[17, 18, 0, 1, 2, 3, 4, 5, 16, 6, 7, 8];
  bits.write(order.length - 4, 4);
  for (final symbol in order) {
    bits.write(symbol == 8 || symbol == 18 ? 1 : 0, 3);
  }
}

void _writeSingleSymbolCode(_Vp8lBitWriter bits, int symbol) {
  bits
    ..write(1, 1)
    ..write(0, 1);
  if (symbol < 2) {
    bits
      ..write(0, 1)
      ..write(symbol, 1);
  } else {
    bits
      ..write(1, 1)
      ..write(symbol, 8);
  }
}

Uint8List _webpContainer(Uint8List vp8l) {
  final writer = ByteWriter()
    ..writeAscii('RIFF')
    ..writeUint32Le(4 + 8 + vp8l.length + (vp8l.length.isOdd ? 1 : 0))
    ..writeAscii('WEBP')
    ..writeAscii('VP8L')
    ..writeUint32Le(vp8l.length)
    ..writeBytes(vp8l);
  if (vp8l.length.isOdd) {
    writer.writeByte(0);
  }
  return writer.toBytes();
}

final class _Vp8lBitWriter {
  final List<int> _bytes = <int>[];
  var _current = 0;
  var _bits = 0;

  void write(int value, int count) {
    for (var i = 0; i < count; i += 1) {
      _current |= ((value >> i) & 1) << _bits;
      _bits += 1;
      if (_bits == 8) {
        _bytes.add(_current);
        _current = 0;
        _bits = 0;
      }
    }
  }

  Uint8List finish() {
    if (_bits > 0) {
      _bytes.add(_current);
    }
    return Uint8List.fromList(_bytes);
  }
}

int _reverseBits(int value, int count) {
  var reversed = 0;
  for (var i = 0; i < count; i += 1) {
    reversed = (reversed << 1) | ((value >> i) & 1);
  }
  return reversed;
}
