import 'dart:typed_data';

/// VP8 boolean arithmetic decoder.
final class Vp8BoolDecoder {
  /// Creates a decoder for one VP8 arithmetic-coded partition.
  Vp8BoolDecoder(Uint8List bytes) : _bytes = bytes {
    if (bytes.length >= 2) {
      _value = (bytes[0] << 8) | bytes[1];
      _offset = 2;
    }
  }

  final Uint8List _bytes;
  var _offset = 0;
  var _range = 255;
  var _value = 0;
  var _bitCount = 0;

  /// Reads a bool whose zero probability is [probability] / 256.
  int readBool(int probability) {
    final split = 1 + (((_range - 1) * probability) >> 8);
    final bigSplit = split << 8;
    var value = 0;
    if (_value >= bigSplit) {
      value = 1;
      _range -= split;
      _value -= bigSplit;
    } else {
      value = 0;
      _range = split;
    }
    while (_range < 128) {
      _value <<= 1;
      _range <<= 1;
      _bitCount += 1;
      if (_bitCount == 8) {
        _bitCount = 0;
        if (_offset < _bytes.length) {
          _value |= _bytes[_offset++];
        }
      }
    }
    return value;
  }

  /// Reads one equiprobable bit.
  int readBit() => readBool(128);

  /// Reads [bits] high-to-low equiprobable bits as an unsigned integer.
  int readLiteral(int bits) {
    var value = 0;
    for (var i = 0; i < bits; i += 1) {
      value = (value << 1) | readBit();
    }
    return value;
  }

  /// Reads a tree-coded value.
  int readTree(List<int> tree, List<int> probabilities) {
    var index = 0;
    while (true) {
      index = tree[index + readBool(probabilities[index >> 1])];
      if (index <= 0) {
        return -index;
      }
    }
  }
}
