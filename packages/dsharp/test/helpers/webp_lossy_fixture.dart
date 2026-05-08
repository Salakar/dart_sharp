import 'dart:convert' as convert;
import 'dart:typed_data';

part 'webp_lossy_residual_fixture.dart';
part 'webp_lossy_luma_fixture.dart';

/// Builds a minimal lossy VP8 WebP with skipped macroblocks.
Uint8List solidVp8Webp({
  required int width,
  required int height,
  int yMode = 0,
  int loopFilterLevel = 0,
  bool loopFilterAdjustmentEnabled = false,
  bool unsupportedColorSpace = false,
  List<int?>? loopFilterRefDeltas,
  List<int?>? loopFilterModeDeltas,
}) {
  return _simpleWebp(
    _solidVp8Payload(
      width: width,
      height: height,
      yMode: yMode,
      loopFilterLevel: loopFilterLevel,
      loopFilterAdjustmentEnabled: loopFilterAdjustmentEnabled,
      unsupportedColorSpace: unsupportedColorSpace,
      loopFilterRefDeltas: loopFilterRefDeltas,
      loopFilterModeDeltas: loopFilterModeDeltas,
    ),
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

/// Builds an extended lossy WebP with reserved VP8X feature bits set.
Uint8List reservedFlagVp8xWebp({
  required int width,
  required int height,
  required int reservedFlags,
}) {
  final vp8 = _solidVp8Payload(width: width, height: height, yMode: 0);
  final chunks = _ByteWriter()
    ..ascii('VP8X')
    ..u32(10)
    ..byte(reservedFlags)
    ..byte(0)
    ..byte(0)
    ..byte(0)
    ..u24(width - 1)
    ..u24(height - 1);
  _writeChunk(chunks, 'VP8 ', vp8);
  return _riffWebp(chunks.finish());
}

/// Builds an extended lossy WebP with duplicate top-level ALPH chunks.
Uint8List duplicateAlphaVp8Webp({required int width, required int height}) {
  final vp8 = _solidVp8Payload(width: width, height: height, yMode: 0);
  final alpha = Uint8List.fromList(<int>[
    0,
    for (var i = 0; i < width * height; i += 1) 255,
  ]);
  final chunks = _ByteWriter()
    ..ascii('VP8X')
    ..u32(10)
    ..byte(0x10)
    ..byte(0)
    ..byte(0)
    ..byte(0)
    ..u24(width - 1)
    ..u24(height - 1);
  _writeChunk(chunks, 'ALPH', alpha);
  _writeChunk(chunks, 'ALPH', alpha);
  _writeChunk(chunks, 'VP8 ', vp8);
  return _riffWebp(chunks.finish());
}

/// Builds an extended lossy VP8 WebP with an uncompressed ALPH chunk.
Uint8List alphaSolidVp8Webp({
  required int width,
  required int height,
  required List<int> alpha,
  int alphaFilter = 0,
}) {
  if (alpha.length != width * height) {
    throw ArgumentError.value(alpha.length, 'alpha.length');
  }
  final vp8 = _solidVp8Payload(width: width, height: height, yMode: 0);
  final chunks = _ByteWriter()
    ..ascii('VP8X')
    ..u32(10)
    ..byte(0x10)
    ..byte(0)
    ..byte(0)
    ..byte(0)
    ..u24(width - 1)
    ..u24(height - 1);
  _writeChunk(
    chunks,
    'ALPH',
    Uint8List.fromList(<int>[
      (alphaFilter & 0x03) << 2,
      ..._filteredAlphaValues(alpha, width, height, alphaFilter),
    ]),
  );
  _writeChunk(chunks, 'VP8 ', vp8);
  return _riffWebp(chunks.finish());
}

/// Builds an extended lossy VP8 WebP with a compressed ALPH chunk.
Uint8List compressedAlphaVp8Webp({
  required int width,
  required int height,
  required List<int> alpha,
  int alphaFilter = 0,
}) {
  if (alpha.length != width * height) {
    throw ArgumentError.value(alpha.length, 'alpha.length');
  }
  final vp8 = _solidVp8Payload(width: width, height: height, yMode: 0);
  final chunks = _ByteWriter()
    ..ascii('VP8X')
    ..u32(10)
    ..byte(0x10)
    ..byte(0)
    ..byte(0)
    ..byte(0)
    ..u24(width - 1)
    ..u24(height - 1);
  _writeChunk(
    chunks,
    'ALPH',
    Uint8List.fromList(<int>[
      1 | ((alphaFilter & 0x03) << 2),
      ..._compressedAlphaPayload(
        _filteredAlphaValues(alpha, width, height, alphaFilter),
      ),
    ]),
  );
  _writeChunk(chunks, 'VP8 ', vp8);
  return _riffWebp(chunks.finish());
}

/// Builds an extended lossy VP8 WebP with a truncated compressed ALPH chunk.
Uint8List truncatedCompressedAlphaVp8Webp({
  required int width,
  required int height,
}) {
  final vp8 = _solidVp8Payload(width: width, height: height, yMode: 0);
  final chunks = _ByteWriter()
    ..ascii('VP8X')
    ..u32(10)
    ..byte(0x10)
    ..byte(0)
    ..byte(0)
    ..byte(0)
    ..u24(width - 1)
    ..u24(height - 1);
  _writeChunk(chunks, 'ALPH', Uint8List.fromList(<int>[1]));
  _writeChunk(chunks, 'VP8 ', vp8);
  return _riffWebp(chunks.finish());
}

/// Builds a VP8 WebP with an ALPH chunk appended outside declared RIFF bytes.
Uint8List alphaOutsideRiffVp8Webp({
  required int width,
  required int height,
  required List<int> alpha,
}) {
  if (alpha.length != width * height) {
    throw ArgumentError.value(alpha.length, 'alpha.length');
  }
  final vp8 = _solidVp8Payload(width: width, height: height, yMode: 0);
  final declared = _ByteWriter()
    ..ascii('VP8X')
    ..u32(10)
    ..byte(0x10)
    ..byte(0)
    ..byte(0)
    ..byte(0)
    ..u24(width - 1)
    ..u24(height - 1);
  _writeChunk(declared, 'VP8 ', vp8);

  final declaredPayload = declared.finish();
  final payload = _ByteWriter()..bytes(declaredPayload);
  _writeChunk(payload, 'ALPH', Uint8List.fromList(<int>[0, ...alpha]));
  return (_ByteWriter()
        ..ascii('RIFF')
        ..u32(4 + declaredPayload.length)
        ..ascii('WEBP')
        ..bytes(payload.finish()))
      .finish();
}

/// Builds an animated WebP with one lossy VP8 frame and optional ALPH data.
Uint8List animatedVp8Webp({
  required int width,
  required int height,
  List<int>? alpha,
  bool unsupportedColorSpace = false,
}) {
  if (alpha != null && alpha.length != width * height) {
    throw ArgumentError.value(alpha.length, 'alpha.length');
  }
  final vp8 = _solidVp8Payload(
    width: width,
    height: height,
    yMode: 0,
    unsupportedColorSpace: unsupportedColorSpace,
  );
  final chunks = _ByteWriter()
    ..ascii('VP8X')
    ..u32(10)
    ..byte(alpha == null ? 0x02 : 0x12)
    ..byte(0)
    ..byte(0)
    ..byte(0)
    ..u24(width - 1)
    ..u24(height - 1);
  _writeChunk(
    chunks,
    'ANIM',
    (_ByteWriter()
          ..u32(0)
          ..u16(1))
        .finish(),
  );
  _writeChunk(
    chunks,
    'ANMF',
    _lossyAnimationFramePayload(
      width: width,
      height: height,
      durationMs: 15,
      vp8: vp8,
      alpha: alpha,
    ),
  );
  return _riffWebp(chunks.finish());
}

/// Builds an invalid animated VP8 WebP with duplicate frame ALPH chunks.
Uint8List animatedVp8WebpWithDuplicateAlphaChunks({
  required int width,
  required int height,
  required List<int> alpha,
}) {
  if (alpha.length != width * height) {
    throw ArgumentError.value(alpha.length, 'alpha.length');
  }
  final vp8 = _solidVp8Payload(width: width, height: height, yMode: 0);
  final frame = _ByteWriter()
    ..u24(0)
    ..u24(0)
    ..u24(width - 1)
    ..u24(height - 1)
    ..u24(15)
    ..byte(2);
  final alphaPayload = Uint8List.fromList(<int>[0, ...alpha]);
  _writeChunk(frame, 'ALPH', alphaPayload);
  _writeChunk(frame, 'ALPH', alphaPayload);
  _writeChunk(frame, 'VP8 ', vp8);

  final chunks = _ByteWriter()
    ..ascii('VP8X')
    ..u32(10)
    ..byte(0x12)
    ..byte(0)
    ..byte(0)
    ..byte(0)
    ..u24(width - 1)
    ..u24(height - 1);
  _writeChunk(
    chunks,
    'ANIM',
    (_ByteWriter()
          ..u32(0)
          ..u16(1))
        .finish(),
  );
  _writeChunk(chunks, 'ANMF', frame.finish());
  return _riffWebp(chunks.finish());
}

Uint8List _lossyAnimationFramePayload({
  required int width,
  required int height,
  required int durationMs,
  required Uint8List vp8,
  required List<int>? alpha,
}) {
  final out = _ByteWriter()
    ..u24(0)
    ..u24(0)
    ..u24(width - 1)
    ..u24(height - 1)
    ..u24(durationMs)
    ..byte(2);
  final alphaValues = alpha;
  if (alphaValues != null) {
    _writeChunk(out, 'ALPH', Uint8List.fromList(<int>[0, ...alphaValues]));
  }
  _writeChunk(out, 'VP8 ', vp8);
  return out.finish();
}

Uint8List _compressedAlphaPayload(List<int> values) {
  final symbols = <int>[];
  for (final value in values) {
    if (!symbols.contains(value)) {
      symbols.add(value);
    }
  }
  if (symbols.length > 2) {
    throw ArgumentError.value(symbols.length, 'alpha symbol count');
  }
  final bits = _AlphaBitWriter()
    ..write(0, 1)
    ..write(0, 1)
    ..write(0, 1);
  if (symbols.length == 1) {
    _writeAlphaSingleSymbolCode(bits, symbols.single);
  } else {
    _writeAlphaTwoSymbolCode(bits, symbols[0], symbols[1]);
  }
  _writeAlphaSingleSymbolCode(bits, 11);
  _writeAlphaSingleSymbolCode(bits, 22);
  _writeAlphaSingleSymbolCode(bits, 33);
  _writeAlphaSingleSymbolCode(bits, 0);
  if (symbols.length == 2) {
    for (final value in values) {
      bits.write(value == symbols[0] ? 0 : 1, 1);
    }
  }
  return bits.finish();
}

void _writeAlphaSingleSymbolCode(_AlphaBitWriter bits, int symbol) {
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

void _writeAlphaTwoSymbolCode(_AlphaBitWriter bits, int first, int second) {
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

List<int> _filteredAlphaValues(
  List<int> alpha,
  int width,
  int height,
  int filter,
) {
  final out = List<int>.filled(alpha.length, 0);
  for (var y = 0; y < height; y += 1) {
    for (var x = 0; x < width; x += 1) {
      final index = y * width + x;
      final predictor = _alphaPredictor(alpha, width, x, y, filter);
      out[index] = (alpha[index] - predictor) & 0xff;
    }
  }
  return out;
}

int _alphaPredictor(List<int> alpha, int width, int x, int y, int filter) {
  if (x == 0 && y == 0) {
    return 0;
  }
  final hasLeft = x > 0;
  final hasAbove = y > 0;
  final left = hasLeft ? alpha[y * width + x - 1] : 0;
  final above = hasAbove ? alpha[(y - 1) * width + x] : 0;
  return switch (filter) {
    0 => 0,
    1 => hasLeft ? left : above,
    2 => hasAbove ? above : left,
    3 => _gradientAlphaPredictor(alpha, width, x, y, left, above),
    _ => throw ArgumentError.value(filter, 'filter'),
  };
}

int _gradientAlphaPredictor(
  List<int> alpha,
  int width,
  int x,
  int y,
  int left,
  int above,
) {
  if (x == 0) {
    return above;
  }
  if (y == 0) {
    return left;
  }
  final upperLeft = alpha[(y - 1) * width + x - 1];
  final predictor = left + above - upperLeft;
  return predictor < 0 ? 0 : (predictor > 255 ? 255 : predictor);
}

Uint8List _solidVp8Payload({
  required int width,
  required int height,
  required int yMode,
  int loopFilterLevel = 0,
  bool loopFilterAdjustmentEnabled = false,
  bool unsupportedColorSpace = false,
  List<int?>? loopFilterRefDeltas,
  List<int?>? loopFilterModeDeltas,
}) {
  final mbCols = (width + 15) >> 4;
  final mbRows = (height + 15) >> 4;
  final first = _BoolWriter()
    ..bit(unsupportedColorSpace)
    ..bit(false)
    ..bit(false);
  _writeLoopFilterHeader(
    first,
    level: loopFilterLevel,
    adjustmentEnabled: loopFilterAdjustmentEnabled,
    referenceDeltas: loopFilterRefDeltas,
    modeDeltas: loopFilterModeDeltas,
  );
  first
    ..literal(0, 2)
    ..literal(0, 7);
  for (var i = 0; i < 5; i += 1) {
    first.bit(false);
  }
  first.bit(false);
  for (var i = 0; i < 4 * 8 * 3 * 11; i += 1) {
    first.prob(_fixtureCoefficientUpdateProbabilityByIndex(i), false);
  }
  first
    ..bit(true)
    ..literal(128, 8);
  for (var i = 0; i < mbCols * mbRows; i += 1) {
    first.prob(128, true);
    _writeYMode(first, yMode);
    if (yMode == 4) {
      _writeBdcSubblockModes(first);
    }
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

void _writeLoopFilterHeader(
  _BoolWriter out, {
  required int level,
  bool adjustmentEnabled = false,
  List<int?>? referenceDeltas,
  List<int?>? modeDeltas,
}) {
  final refs = referenceDeltas;
  final modes = modeDeltas;
  if (level < 0 || level > 63) {
    throw ArgumentError.value(level, 'level');
  }
  if (refs != null && refs.length != 4) {
    throw ArgumentError.value(refs.length, 'referenceDeltas');
  }
  if (modes != null && modes.length != 4) {
    throw ArgumentError.value(modes.length, 'modeDeltas');
  }
  final hasUpdates = refs != null || modes != null;
  out
    ..bit(false)
    ..literal(level, 6)
    ..literal(0, 3)
    ..bit(adjustmentEnabled || hasUpdates);
  if (adjustmentEnabled || hasUpdates) {
    out.bit(hasUpdates);
    if (hasUpdates) {
      for (var i = 0; i < 4; i += 1) {
        _writeLoopFilterDelta(out, refs == null ? null : refs[i]);
      }
      for (var i = 0; i < 4; i += 1) {
        _writeLoopFilterDelta(out, modes == null ? null : modes[i]);
      }
    }
  }
}

void _writeLoopFilterDelta(_BoolWriter out, int? value) {
  out.bit(value != null);
  if (value == null) {
    return;
  }
  final magnitude = value.abs();
  if (magnitude > 63) {
    throw ArgumentError.value(value, 'value');
  }
  out
    ..literal(magnitude, 6)
    ..bit(value < 0);
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
  if (mode == 4) {
    out.prob(145, false);
    return;
  }
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

void _writeBdcSubblockModes(_BoolWriter out) {
  for (var block = 0; block < 16; block += 1) {
    out.prob(231, false);
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

final class _AlphaBitWriter {
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
