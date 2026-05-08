import 'dart:typed_data';

import '../api/exceptions.dart';
import 'binary_io.dart';
import 'deflate_tables.dart';

/// Encodes [data] as a zlib stream using uncompressed deflate blocks.
Uint8List zlibEncodeStored(Uint8List data) {
  final writer = ByteWriter()
    ..writeByte(0x78)
    ..writeByte(0x01);
  var offset = 0;
  while (offset < data.length || data.isEmpty && offset == 0) {
    final remaining = data.length - offset;
    final length = remaining > 65535 ? 65535 : remaining;
    final isFinal = offset + length >= data.length;
    writer
      ..writeByte(isFinal ? 1 : 0)
      ..writeUint16Le(length)
      ..writeUint16Le(length ^ 0xffff)
      ..writeBytes(data.sublist(offset, offset + length));
    offset += length;
    if (data.isEmpty) {
      break;
    }
  }
  writer.writeUint32Be(adler32(data));
  return writer.toBytes();
}

/// Encodes [data] as a zlib stream using fixed Huffman literal deflate blocks.
Uint8List zlibEncodeFixed(Uint8List data) {
  final bits = _DeflateBitWriter()
    ..writeBits(1, 1)
    ..writeBits(1, 2);
  for (final byte in data) {
    _writeFixedSymbol(bits, byte);
  }
  _writeFixedSymbol(bits, 256);
  return (ByteWriter()
        ..writeByte(0x78)
        ..writeByte(0x9c)
        ..writeBytes(bits.finish())
        ..writeUint32Be(adler32(data)))
      .toBytes();
}

/// Decodes a zlib-wrapped deflate stream.
Uint8List zlibDecode(Uint8List bytes) {
  if (bytes.length < 6) {
    throw const InvalidImageException('Invalid zlib stream.');
  }
  if ((readUint16Be(bytes, 0) % 31) != 0) {
    throw const InvalidImageException('Invalid zlib header checksum.');
  }
  final compressed = byteSlice(bytes, 2, bytes.length - 4);
  final output = _DeflateReader(compressed).decode();
  final expected = readUint32Be(bytes, bytes.length - 4);
  if (adler32(output) != expected) {
    throw const InvalidImageException('Invalid zlib Adler-32 checksum.');
  }
  return output;
}

final class _DeflateReader {
  _DeflateReader(this.bytes);

  final Uint8List bytes;
  var _byteOffset = 0;
  var _bitOffset = 0;

  Uint8List decode() {
    final output = <int>[];
    var isFinal = false;
    while (!isFinal) {
      isFinal = _readBits(1) == 1;
      final type = _readBits(2);
      switch (type) {
        case 0:
          _decodeStored(output);
        case 1:
          _decodeCompressed(output, _fixedLitLenTree, _fixedDistanceTree);
        case 2:
          final trees = _dynamicTrees();
          _decodeCompressed(output, trees.$1, trees.$2);
        default:
          throw const InvalidImageException('Invalid deflate block type.');
      }
    }
    return Uint8List.fromList(output);
  }

  void _decodeStored(List<int> output) {
    if (_bitOffset != 0) {
      _bitOffset = 0;
      _byteOffset += 1;
    }
    if (_byteOffset + 4 > bytes.length) {
      throw const InvalidImageException('Truncated stored deflate block.');
    }
    final length = readUint16Le(bytes, _byteOffset);
    final nlength = readUint16Le(bytes, _byteOffset + 2);
    _byteOffset += 4;
    if ((length ^ 0xffff) != nlength) {
      throw const InvalidImageException('Invalid stored deflate length.');
    }
    if (_byteOffset + length > bytes.length) {
      throw const InvalidImageException('Truncated stored deflate payload.');
    }
    output.addAll(bytes.sublist(_byteOffset, _byteOffset + length));
    _byteOffset += length;
  }

  void _decodeCompressed(
    List<int> output,
    _HuffmanTree litLen,
    _HuffmanTree distance,
  ) {
    while (true) {
      final symbol = litLen.read(this);
      if (symbol < 256) {
        output.add(symbol);
      } else if (symbol == 256) {
        return;
      } else if (symbol <= 285) {
        final length =
            lengthBase[symbol - 257] + _readBits(lengthExtra[symbol - 257]);
        final distSymbol = distance.read(this);
        final copyDistance =
            distanceBase[distSymbol] + _readBits(distanceExtra[distSymbol]);
        if (copyDistance <= 0 || copyDistance > output.length) {
          throw const InvalidImageException('Invalid deflate distance.');
        }
        for (var i = 0; i < length; i += 1) {
          output.add(output[output.length - copyDistance]);
        }
      } else {
        throw const InvalidImageException('Invalid deflate length symbol.');
      }
    }
  }

  (_HuffmanTree, _HuffmanTree) _dynamicTrees() {
    final litLenCount = _readBits(5) + 257;
    final distanceCount = _readBits(5) + 1;
    final codeLengthCount = _readBits(4) + 4;
    final codeLengths = List<int>.filled(19, 0);
    for (var i = 0; i < codeLengthCount; i += 1) {
      codeLengths[codeLengthOrder[i]] = _readBits(3);
    }
    final codeTree = _HuffmanTree(codeLengths);
    final lengths = <int>[];
    while (lengths.length < litLenCount + distanceCount) {
      final symbol = codeTree.read(this);
      if (symbol < 16) {
        lengths.add(symbol);
      } else if (symbol == 16) {
        if (lengths.isEmpty) {
          throw const InvalidImageException('Invalid deflate repeat code.');
        }
        lengths.addAll(List<int>.filled(_readBits(2) + 3, lengths.last));
      } else if (symbol == 17) {
        lengths.addAll(List<int>.filled(_readBits(3) + 3, 0));
      } else if (symbol == 18) {
        lengths.addAll(List<int>.filled(_readBits(7) + 11, 0));
      } else {
        throw const InvalidImageException('Invalid deflate code length.');
      }
    }
    return (
      _HuffmanTree(lengths.sublist(0, litLenCount)),
      _HuffmanTree(lengths.sublist(litLenCount)),
    );
  }

  int _readBits(int count) {
    var value = 0;
    for (var bit = 0; bit < count; bit += 1) {
      if (_byteOffset >= bytes.length) {
        throw const InvalidImageException('Unexpected end of deflate stream.');
      }
      value |= ((bytes[_byteOffset] >> _bitOffset) & 1) << bit;
      _bitOffset += 1;
      if (_bitOffset == 8) {
        _bitOffset = 0;
        _byteOffset += 1;
      }
    }
    return value;
  }
}

final class _HuffmanTree {
  _HuffmanTree(List<int> lengths) {
    var code = 0;
    final counts = List<int>.filled(16, 0);
    for (final length in lengths) {
      if (length > 0) {
        counts[length] += 1;
      }
    }
    for (var bits = 1; bits <= 15; bits += 1) {
      code = (code + counts[bits - 1]) << 1;
      var nextCode = code;
      for (var symbol = 0; symbol < lengths.length; symbol += 1) {
        if (lengths[symbol] == bits) {
          _symbols[(bits << 16) | _reverseBits(nextCode, bits)] = symbol;
          nextCode += 1;
        }
      }
    }
  }

  final Map<int, int> _symbols = <int, int>{};

  int read(_DeflateReader reader) {
    var code = 0;
    for (var bits = 1; bits <= 15; bits += 1) {
      code |= reader._readBits(1) << (bits - 1);
      final symbol = _symbols[(bits << 16) | code];
      if (symbol != null) {
        return symbol;
      }
    }
    throw const InvalidImageException('Invalid deflate Huffman code.');
  }
}

int _reverseBits(int value, int length) {
  var reversed = 0;
  for (var i = 0; i < length; i += 1) {
    reversed = (reversed << 1) | ((value >> i) & 1);
  }
  return reversed;
}

void _writeFixedSymbol(_DeflateBitWriter bits, int symbol) {
  final code = _fixedLitLenCodes[symbol];
  bits.writeBits(code.code, code.length);
}

List<({int code, int length})> _canonicalCodeTable(List<int> lengths) {
  var code = 0;
  final counts = List<int>.filled(16, 0);
  for (final length in lengths) {
    if (length > 0) {
      counts[length] += 1;
    }
  }
  final table = List<({int code, int length})>.filled(lengths.length, (
    code: 0,
    length: 0,
  ));
  for (var bits = 1; bits <= 15; bits += 1) {
    code = (code + counts[bits - 1]) << 1;
    var nextCode = code;
    for (var symbol = 0; symbol < lengths.length; symbol += 1) {
      if (lengths[symbol] == bits) {
        table[symbol] = (code: _reverseBits(nextCode, bits), length: bits);
        nextCode += 1;
      }
    }
  }
  return table;
}

final class _DeflateBitWriter {
  final _bytes = <int>[];
  var _current = 0;
  var _bits = 0;

  void writeBits(int value, int count) {
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

final _fixedLitLenTree = _HuffmanTree(<int>[
  ...List<int>.filled(144, 8),
  ...List<int>.filled(112, 9),
  ...List<int>.filled(24, 7),
  ...List<int>.filled(8, 8),
]);
final _fixedDistanceTree = _HuffmanTree(List<int>.filled(32, 5));
final _fixedLitLenCodes = _canonicalCodeTable(<int>[
  ...List<int>.filled(144, 8),
  ...List<int>.filled(112, 9),
  ...List<int>.filled(24, 7),
  ...List<int>.filled(8, 8),
]);
