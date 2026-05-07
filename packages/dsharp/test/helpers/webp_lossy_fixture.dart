import 'dart:convert' as convert;
import 'dart:typed_data';

part 'webp_lossy_residual_fixture.dart';

/// Builds a minimal lossy VP8 WebP with skipped macroblocks.
Uint8List solidVp8Webp({
  required int width,
  required int height,
  int yMode = 0,
}) {
  return _simpleWebp(
    _solidVp8Payload(width: width, height: height, yMode: yMode),
  );
}

/// Builds an extended lossy VP8 WebP without alpha.
Uint8List extendedSolidVp8Webp({required int width, required int height}) {
  final vp8 = _solidVp8Payload(width: width, height: height, yMode: 0);
  final chunks = _ByteWriter()
    ..ascii('VP8X')
    ..u32(10)
    ..byte(0)
    ..byte(0)
    ..byte(0)
    ..byte(0)
    ..u24(width - 1)
    ..u24(height - 1);
  _writeChunk(chunks, 'VP8 ', vp8);
  return _riffWebp(chunks.finish());
}

Uint8List _solidVp8Payload({
  required int width,
  required int height,
  required int yMode,
}) {
  final mbCols = (width + 15) >> 4;
  final mbRows = (height + 15) >> 4;
  final first = _BoolWriter()
    ..bit(false)
    ..bit(false)
    ..bit(false)
    ..bit(false)
    ..literal(0, 6)
    ..literal(0, 3)
    ..bit(false)
    ..literal(0, 2)
    ..literal(0, 7);
  for (var i = 0; i < 5; i += 1) {
    first.bit(false);
  }
  first.bit(false);
  for (var i = 0; i < 4 * 8 * 3 * 11; i += 1) {
    first.bit(false);
  }
  first
    ..bit(true)
    ..literal(128, 8);
  for (var i = 0; i < mbCols * mbRows; i += 1) {
    first.prob(128, true);
    _writeYMode(first, yMode);
    first.prob(142, false);
  }
  final firstPartition = first.finish();
  final vp8 = _ByteWriter()
    ..u24((1 << 4) | (firstPartition.length << 5))
    ..byte(0x9d)
    ..byte(0x01)
    ..byte(0x2a)
    ..u16(width)
    ..u16(height)
    ..bytes(firstPartition)
    ..byte(0)
    ..byte(0);
  return vp8.finish();
}

Uint8List _simpleWebp(Uint8List vp8) {
  final out = _ByteWriter()
    ..ascii('RIFF')
    ..u32(4 + 8 + vp8.length + (vp8.length.isOdd ? 1 : 0))
    ..ascii('WEBP')
    ..ascii('VP8 ')
    ..u32(vp8.length)
    ..bytes(vp8);
  if (vp8.length.isOdd) {
    out.byte(0);
  }
  return out.finish();
}

Uint8List _riffWebp(Uint8List payload) =>
    (_ByteWriter()
          ..ascii('RIFF')
          ..u32(4 + payload.length)
          ..ascii('WEBP')
          ..bytes(payload))
        .finish();

void _writeChunk(_ByteWriter out, String type, Uint8List payload) {
  out
    ..ascii(type)
    ..u32(payload.length)
    ..bytes(payload);
  if (payload.length.isOdd) {
    out.byte(0);
  }
}

void _writeYMode(_BoolWriter out, int mode) {
  out.prob(145, true);
  switch (mode) {
    case 0:
      out
        ..prob(156, false)
        ..prob(163, false);
    case 1:
      out
        ..prob(156, false)
        ..prob(163, true);
    case 2:
      out
        ..prob(156, true)
        ..prob(128, false);
    case 3:
      out
        ..prob(156, true)
        ..prob(128, true);
    default:
      throw ArgumentError.value(mode, 'mode');
  }
}

final class _BoolWriter {
  final _bytes = <int>[];
  var _range = 255;
  var _bottom = 0;
  var _bitCount = 24;

  void bit(bool value) => prob(128, value);

  void literal(int value, int bits) {
    for (var bit = bits - 1; bit >= 0; bit -= 1) {
      prob(128, ((value >> bit) & 1) == 1);
    }
  }

  void prob(int probability, bool value) {
    final split = 1 + (((_range - 1) * probability) >> 8);
    if (value) {
      _bottom = (_bottom + split) & 0xffffffff;
      _range -= split;
    } else {
      _range = split;
    }
    while (_range < 128) {
      _range <<= 1;
      if ((_bottom & 0x80000000) != 0) {
        _addOneToOutput();
      }
      _bottom = (_bottom << 1) & 0xffffffff;
      _bitCount -= 1;
      if (_bitCount == 0) {
        _bytes.add((_bottom >> 24) & 0xff);
        _bottom &= 0x00ffffff;
        _bitCount = 8;
      }
    }
  }

  Uint8List finish() {
    var c = _bitCount;
    var value = _bottom;
    if ((value & (1 << (32 - c))) != 0) {
      _addOneToOutput();
    }
    value = (value << (c & 7)) & 0xffffffff;
    c >>= 3;
    while (true) {
      c -= 1;
      if (c < 0) {
        break;
      }
      value = (value << 8) & 0xffffffff;
    }
    for (var i = 0; i < 4; i += 1) {
      _bytes.add((value >> 24) & 0xff);
      value = (value << 8) & 0xffffffff;
    }
    return Uint8List.fromList(_bytes);
  }

  void _addOneToOutput() {
    var index = _bytes.length - 1;
    while (index >= 0 && _bytes[index] == 255) {
      _bytes[index] = 0;
      index -= 1;
    }
    if (index >= 0) {
      _bytes[index] += 1;
    }
  }
}

final class _ByteWriter {
  final _bytes = <int>[];

  void ascii(String value) => _bytes.addAll(convert.ascii.encode(value));

  void byte(int value) => _bytes.add(value & 0xff);

  void bytes(Iterable<int> values) {
    for (final value in values) {
      byte(value);
    }
  }

  void u16(int value) {
    byte(value);
    byte(value >> 8);
  }

  void u24(int value) {
    byte(value);
    byte(value >> 8);
    byte(value >> 16);
  }

  void u32(int value) {
    byte(value);
    byte(value >> 8);
    byte(value >> 16);
    byte(value >> 24);
  }

  Uint8List finish() => Uint8List.fromList(_bytes);
}
