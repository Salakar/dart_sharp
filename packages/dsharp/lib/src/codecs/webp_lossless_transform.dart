part of 'webp_lossless.dart';

abstract interface class _LosslessTransform {
  int get type;

  void apply(Uint8List bytes, int width, int height);

  static _LosslessTransform read(_BitReader reader, int width, int height) {
    final type = reader.readBits(2);
    return switch (type) {
      0 => _PredictorTransform.read(reader, width, height),
      1 => _ColorTransform.read(reader, width, height),
      2 => const _SubtractGreenTransform(),
      3 => _ColorIndexingTransform.read(reader),
      _ => throw const UnsupportedCodecException(
        'Unsupported VP8L transform type.',
      ),
    };
  }
}

final class _ColorIndexingTransform implements _LosslessTransform {
  _ColorIndexingTransform._(this._table);

  factory _ColorIndexingTransform.read(_BitReader reader) {
    final tableSize = reader.readBits(8) + 1;
    if (tableSize <= 16) {
      throw const UnsupportedCodecException(
        'VP8L packed color-indexing transforms are not implemented yet.',
      );
    }
    final deltas = _decodeImageData(
      reader,
      tableSize,
      1,
      readMetaPrefix: false,
    );
    final table = Uint32List(tableSize);
    var alpha = 0;
    var red = 0;
    var green = 0;
    var blue = 0;
    for (var i = 0; i < tableSize; i += 1) {
      final offset = i * 4;
      red = (red + deltas[offset]) & 0xff;
      green = (green + deltas[offset + 1]) & 0xff;
      blue = (blue + deltas[offset + 2]) & 0xff;
      alpha = (alpha + deltas[offset + 3]) & 0xff;
      table[i] = _argb(alpha, red, green, blue);
    }
    return _ColorIndexingTransform._(table);
  }

  final Uint32List _table;

  @override
  int get type => 3;

  @override
  void apply(Uint8List bytes, int width, int height) {
    final pixels = width * height;
    for (var pixel = 0; pixel < pixels; pixel += 1) {
      final index = bytes[pixel * 4 + 1];
      _writeArgbToRgba(bytes, pixel, index < _table.length ? _table[index] : 0);
    }
  }
}

final class _PredictorTransform implements _LosslessTransform {
  _PredictorTransform._(this._sizeBits, this._blocks, this._blocksWide);

  factory _PredictorTransform.read(_BitReader reader, int width, int height) {
    final sizeBits = reader.readBits(3) + 2;
    final blockSize = 1 << sizeBits;
    final blocksWide = _divRoundUp(width, blockSize);
    final blocksHigh = _divRoundUp(height, blockSize);
    return _PredictorTransform._(
      sizeBits,
      _decodeImageData(reader, blocksWide, blocksHigh, readMetaPrefix: false),
      blocksWide,
    );
  }

  final int _sizeBits;
  final Uint8List _blocks;
  final int _blocksWide;

  @override
  int get type => 0;

  @override
  void apply(Uint8List bytes, int width, int height) {
    for (var y = 0; y < height; y += 1) {
      final blockRow = (y >> _sizeBits) * _blocksWide;
      for (var x = 0; x < width; x += 1) {
        final pixel = y * width + x;
        final mode = _blocks[(blockRow + (x >> _sizeBits)) * 4 + 1];
        final pred = _predictor(bytes, width, x, y, mode);
        final residual = _argbFromRgba(bytes, pixel);
        _writeArgbToRgba(bytes, pixel, _addArgb(residual, pred));
      }
    }
  }
}

final class _ColorTransform implements _LosslessTransform {
  _ColorTransform._(this._sizeBits, this._blocks, this._blocksWide);

  factory _ColorTransform.read(_BitReader reader, int width, int height) {
    final sizeBits = reader.readBits(3) + 2;
    final blockSize = 1 << sizeBits;
    final blocksWide = _divRoundUp(width, blockSize);
    final blocksHigh = _divRoundUp(height, blockSize);
    return _ColorTransform._(
      sizeBits,
      _decodeImageData(reader, blocksWide, blocksHigh, readMetaPrefix: false),
      blocksWide,
    );
  }

  final int _sizeBits;
  final Uint8List _blocks;
  final int _blocksWide;

  @override
  int get type => 1;

  @override
  void apply(Uint8List bytes, int width, int height) {
    for (var y = 0; y < height; y += 1) {
      final blockRow = (y >> _sizeBits) * _blocksWide;
      for (var x = 0; x < width; x += 1) {
        final blockOffset = (blockRow + (x >> _sizeBits)) * 4;
        final redToBlue = _blocks[blockOffset];
        final greenToBlue = _blocks[blockOffset + 1];
        final greenToRed = _blocks[blockOffset + 2];
        final offset = (y * width + x) * 4;
        final green = bytes[offset + 1];
        final red = (bytes[offset] + _colorDelta(greenToRed, green)) & 0xff;
        final blue =
            (bytes[offset + 2] +
                _colorDelta(greenToBlue, green) +
                _colorDelta(redToBlue, red)) &
            0xff;
        bytes[offset] = red;
        bytes[offset + 2] = blue;
      }
    }
  }
}

final class _SubtractGreenTransform implements _LosslessTransform {
  const _SubtractGreenTransform();

  @override
  int get type => 2;

  @override
  void apply(Uint8List bytes, int width, int height) {
    final pixels = width * height;
    for (var pixel = 0; pixel < pixels; pixel += 1) {
      final offset = pixel * 4;
      final green = bytes[offset + 1];
      bytes[offset] = (bytes[offset] + green) & 0xff;
      bytes[offset + 2] = (bytes[offset + 2] + green) & 0xff;
    }
  }
}

int _colorDelta(int transform, int channel) {
  return (_signed8(transform) * _signed8(channel)) >> 5;
}

int _predictor(Uint8List bytes, int width, int x, int y, int mode) {
  final pixel = y * width + x;
  if (x == 0 && y == 0) {
    return 0xff000000;
  }
  if (y == 0) {
    return _argbFromRgba(bytes, pixel - 1);
  }
  if (x == 0) {
    return _argbFromRgba(bytes, pixel - width);
  }
  final left = _argbFromRgba(bytes, pixel - 1);
  final top = _argbFromRgba(bytes, pixel - width);
  final topLeft = _argbFromRgba(bytes, pixel - width - 1);
  final topRight = x == width - 1
      ? _argbFromRgba(bytes, y * width)
      : _argbFromRgba(bytes, pixel - width + 1);
  return switch (mode) {
    0 => 0xff000000,
    1 => left,
    2 => top,
    3 => topRight,
    4 => topLeft,
    5 => _avgArgb(_avgArgb(left, topRight), top),
    6 => _avgArgb(left, topLeft),
    7 => _avgArgb(left, top),
    8 => _avgArgb(topLeft, top),
    9 => _avgArgb(top, topRight),
    10 => _avgArgb(_avgArgb(left, topLeft), _avgArgb(top, topRight)),
    11 => _selectArgb(left, top, topLeft),
    12 => _clampAddSubtractFull(left, top, topLeft),
    13 => _clampAddSubtractHalf(_avgArgb(left, top), topLeft),
    _ => throw const InvalidImageException('Invalid VP8L predictor mode.'),
  };
}

int _addArgb(int residual, int pred) {
  return _argb(
    (_alpha(residual) + _alpha(pred)) & 0xff,
    (_red(residual) + _red(pred)) & 0xff,
    (_green(residual) + _green(pred)) & 0xff,
    (_blue(residual) + _blue(pred)) & 0xff,
  );
}

int _avgArgb(int a, int b) {
  return _argb(
    (_alpha(a) + _alpha(b)) >> 1,
    (_red(a) + _red(b)) >> 1,
    (_green(a) + _green(b)) >> 1,
    (_blue(a) + _blue(b)) >> 1,
  );
}

int _selectArgb(int left, int top, int topLeft) {
  final predAlpha = _alpha(left) + _alpha(top) - _alpha(topLeft);
  final predRed = _red(left) + _red(top) - _red(topLeft);
  final predGreen = _green(left) + _green(top) - _green(topLeft);
  final predBlue = _blue(left) + _blue(top) - _blue(topLeft);
  final leftScore =
      (predAlpha - _alpha(left)).abs() +
      (predRed - _red(left)).abs() +
      (predGreen - _green(left)).abs() +
      (predBlue - _blue(left)).abs();
  final topScore =
      (predAlpha - _alpha(top)).abs() +
      (predRed - _red(top)).abs() +
      (predGreen - _green(top)).abs() +
      (predBlue - _blue(top)).abs();
  return leftScore < topScore ? left : top;
}

int _clampAddSubtractFull(int a, int b, int c) {
  return _argb(
    _clamp8(_alpha(a) + _alpha(b) - _alpha(c)),
    _clamp8(_red(a) + _red(b) - _red(c)),
    _clamp8(_green(a) + _green(b) - _green(c)),
    _clamp8(_blue(a) + _blue(b) - _blue(c)),
  );
}

int _clampAddSubtractHalf(int a, int b) {
  return _argb(
    _clamp8(_alpha(a) + ((_alpha(a) - _alpha(b)) ~/ 2)),
    _clamp8(_red(a) + ((_red(a) - _red(b)) ~/ 2)),
    _clamp8(_green(a) + ((_green(a) - _green(b)) ~/ 2)),
    _clamp8(_blue(a) + ((_blue(a) - _blue(b)) ~/ 2)),
  );
}

int _alpha(int argb) => (argb >> 24) & 0xff;
int _red(int argb) => (argb >> 16) & 0xff;
int _green(int argb) => (argb >> 8) & 0xff;
int _blue(int argb) => argb & 0xff;

int _clamp8(int value) => value < 0 ? 0 : (value > 255 ? 255 : value);

int _signed8(int value) => value < 128 ? value : value - 256;

int _divRoundUp(int value, int divisor) => (value + divisor - 1) ~/ divisor;
