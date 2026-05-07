import 'dart:convert';
import 'dart:typed_data';

/// Builds a minimal valid VP8L WebP with one repeated RGBA colour.
Uint8List solidVp8lWebp({
  required int width,
  required int height,
  required int red,
  required int green,
  required int blue,
  required int alpha,
}) {
  final bits = _BitWriter()
    ..write(width - 1, 14)
    ..write(height - 1, 14)
    ..write(alpha == 255 ? 0 : 1, 1)
    ..write(0, 3)
    ..write(0, 1)
    ..write(0, 1)
    ..write(0, 1);
  _writeSingleSymbolCode(bits, green);
  _writeSingleSymbolCode(bits, red);
  _writeSingleSymbolCode(bits, blue);
  _writeSingleSymbolCode(bits, alpha);
  _writeSingleSymbolCode(bits, 0);
  final vp8l = Uint8List.fromList(<int>[0x2f, ...bits.finish()]);
  final out = _ByteWriter()
    ..ascii('RIFF')
    ..u32(4 + 8 + vp8l.length + (vp8l.length.isOdd ? 1 : 0))
    ..ascii('WEBP')
    ..ascii('VP8L')
    ..u32(vp8l.length)
    ..bytes(vp8l);
  if (vp8l.length.isOdd) {
    out.byte(0);
  }
  return out.finish();
}

/// Builds a minimal VP8L WebP where only green alternates between two symbols.
Uint8List twoGreenVp8lWebp({
  required int width,
  required int height,
  required int red,
  required int firstGreen,
  required int secondGreen,
  required int blue,
  required int alpha,
}) {
  final bits = _BitWriter()
    ..write(width - 1, 14)
    ..write(height - 1, 14)
    ..write(alpha == 255 ? 0 : 1, 1)
    ..write(0, 3)
    ..write(0, 1)
    ..write(0, 1)
    ..write(0, 1);
  _writeTwoSymbolCode(bits, firstGreen, secondGreen);
  _writeSingleSymbolCode(bits, red);
  _writeSingleSymbolCode(bits, blue);
  _writeSingleSymbolCode(bits, alpha);
  _writeSingleSymbolCode(bits, 0);
  for (var i = 0; i < width * height; i += 1) {
    bits.write(i.isEven ? 0 : 1, 1);
  }
  return _webpContainer(Uint8List.fromList(<int>[0x2f, ...bits.finish()]));
}

void _writeSingleSymbolCode(_BitWriter bits, int symbol) {
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

void _writeTwoSymbolCode(_BitWriter bits, int first, int second) {
  bits
    ..write(1, 1)
    ..write(1, 1);
  if (first < 2) {
    bits
      ..write(0, 1)
      ..write(first, 1);
  } else {
    bits
      ..write(1, 1)
      ..write(first, 8);
  }
  bits.write(second, 8);
}

Uint8List _webpContainer(Uint8List vp8l) {
  final out = _ByteWriter()
    ..ascii('RIFF')
    ..u32(4 + 8 + vp8l.length + (vp8l.length.isOdd ? 1 : 0))
    ..ascii('WEBP')
    ..ascii('VP8L')
    ..u32(vp8l.length)
    ..bytes(vp8l);
  if (vp8l.length.isOdd) {
    out.byte(0);
  }
  return out.finish();
}

final class _BitWriter {
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

final class _ByteWriter {
  final List<int> _bytes = <int>[];

  void ascii(String value) => _bytes.addAll(utf8.encode(value));

  void u32(int value) {
    _bytes
      ..add(value & 0xff)
      ..add((value >> 8) & 0xff)
      ..add((value >> 16) & 0xff)
      ..add((value >> 24) & 0xff);
  }

  void bytes(Iterable<int> values) => _bytes.addAll(values);

  void byte(int value) => _bytes.add(value & 0xff);

  Uint8List finish() => Uint8List.fromList(_bytes);
}
