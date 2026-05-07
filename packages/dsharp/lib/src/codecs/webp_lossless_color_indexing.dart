part of 'webp_lossless.dart';

final class _ColorIndexingTransform implements _LosslessTransform {
  _ColorIndexingTransform._(this._table, this._widthBits, this._outputWidth);

  factory _ColorIndexingTransform.read(_BitReader reader, int width) {
    final tableSize = reader.readBits(8) + 1;
    final widthBits = _packedWidthBits(tableSize);
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
    return _ColorIndexingTransform._(table, widthBits, width);
  }

  final Uint32List _table;
  final int _widthBits;
  final int _outputWidth;

  @override
  int get type => 3;

  @override
  int encodedWidth(int width) => _divRoundUp(width, 1 << _widthBits);

  @override
  _LosslessImage apply(_LosslessImage image) {
    final out = Uint8List(_outputWidth * image.height * 4);
    for (var y = 0; y < image.height; y += 1) {
      for (var x = 0; x < _outputWidth; x += 1) {
        final packedPixel = y * image.width + (x >> _widthBits);
        final packed = image.bytes[packedPixel * 4 + 1];
        final index =
            (packed >> ((x & ((1 << _widthBits) - 1)) << (3 - _widthBits))) &
            ((1 << (8 >> _widthBits)) - 1);
        _writeArgbToRgba(
          out,
          y * _outputWidth + x,
          index < _table.length ? _table[index] : 0,
        );
      }
    }
    return _LosslessImage(out, _outputWidth, image.height);
  }
}

int _packedWidthBits(int tableSize) {
  if (tableSize <= 2) {
    return 3;
  }
  if (tableSize <= 4) {
    return 2;
  }
  if (tableSize <= 16) {
    return 1;
  }
  return 0;
}
