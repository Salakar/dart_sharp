import 'dart:typed_data';

import '../api/exceptions.dart';

/// JPEG entropy bit reader.
final class JpegBitReader {
  /// Creates a reader for de-stuffed entropy bytes.
  JpegBitReader(this.bytes);

  /// Entropy bytes.
  final Uint8List bytes;
  int _offset = 0;
  int _buffer = 0;
  int _bits = 0;

  /// Reads [count] bits.
  int readBits(int count) {
    while (_bits < count) {
      if (_offset >= bytes.length) {
        throw const InvalidImageException('Truncated JPEG entropy stream.');
      }
      _buffer = (_buffer << 8) | bytes[_offset++];
      _bits += 8;
    }
    _bits -= count;
    return (_buffer >> _bits) & ((1 << count) - 1);
  }
}

/// Canonical JPEG Huffman decode tree.
final class JpegHuffmanTree {
  /// Builds a Huffman tree from per-length counts and symbols.
  JpegHuffmanTree(List<int> counts, List<int> symbols) {
    var code = 0;
    var symbolOffset = 0;
    for (var length = 1; length <= 16; length += 1) {
      for (var i = 0; i < counts[length - 1]; i += 1) {
        _codes[(length << 16) | code] = symbols[symbolOffset++];
        code += 1;
      }
      code <<= 1;
    }
  }

  final Map<int, int> _codes = <int, int>{};

  /// Reads one Huffman symbol.
  int read(JpegBitReader reader) {
    var code = 0;
    for (var length = 1; length <= 16; length += 1) {
      code = (code << 1) | reader.readBits(1);
      final symbol = _codes[(length << 16) | code];
      if (symbol != null) {
        return symbol;
      }
    }
    throw const InvalidImageException('Invalid JPEG Huffman code.');
  }
}

/// JPEG entropy bit writer with byte stuffing.
final class JpegBitWriter {
  final List<int> _bytes = <int>[];
  int _buffer = 0;
  int _bits = 0;

  /// Writes [count] most-significant bits from [value].
  void writeBits(int value, int count) {
    for (var bit = count - 1; bit >= 0; bit -= 1) {
      _buffer = (_buffer << 1) | ((value >> bit) & 1);
      _bits += 1;
      if (_bits == 8) {
        _writeByte(_buffer);
        _buffer = 0;
        _bits = 0;
      }
    }
  }

  /// Writes one symbol using the encoder's fixed 8-bit table.
  void writeSymbol(int symbol) => writeBits(symbol, 8);

  /// Flushes the final byte with one-fill padding.
  Uint8List finish() {
    if (_bits > 0) {
      _writeByte((_buffer << (8 - _bits)) | ((1 << (8 - _bits)) - 1));
      _buffer = 0;
      _bits = 0;
    }
    return Uint8List.fromList(_bytes);
  }

  void _writeByte(int value) {
    _bytes.add(value & 0xff);
    if ((value & 0xff) == 0xff) {
      _bytes.add(0);
    }
  }
}

/// Converts a decoded JPEG additional-bit field to a signed value.
int jpegExtend(int bits, int size) {
  if (size == 0) {
    return 0;
  }
  final threshold = 1 << (size - 1);
  return bits < threshold ? bits - ((1 << size) - 1) : bits;
}

/// Returns the JPEG category for [value].
int jpegCategory(int value) => value == 0 ? 0 : value.abs().bitLength;

/// Encodes a signed coefficient as JPEG additional bits.
int jpegAdditionalBits(int value, int size) {
  if (size == 0) {
    return 0;
  }
  return value >= 0 ? value : value + ((1 << size) - 1);
}
