part of 'webp_lossless.dart';

abstract interface class _LosslessTransform {
  int get type;

  void apply(Uint8List bytes, int width, int height);

  static _LosslessTransform read(_BitReader reader, int width, int height) {
    final type = reader.readBits(2);
    return switch (type) {
      1 => _ColorTransform.read(reader, width, height),
      2 => const _SubtractGreenTransform(),
      _ => throw const UnsupportedCodecException(
        'Only VP8L color and subtract-green transforms are implemented so far.',
      ),
    };
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

int _signed8(int value) => value < 128 ? value : value - 256;

int _divRoundUp(int value, int divisor) => (value + divisor - 1) ~/ divisor;
