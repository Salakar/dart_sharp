import 'dart:typed_data';

import '../api/exceptions.dart';

/// Encodes GIF indices with a clear-code-heavy LZW stream.
Uint8List gifLzwEncode(List<int> indices, int minimumCodeSize) {
  final clear = 1 << minimumCodeSize;
  final end = clear + 1;
  final writer = _BitWriter();
  for (final index in indices) {
    writer.write(clear, minimumCodeSize + 1);
    writer.write(index, minimumCodeSize + 1);
  }
  writer.write(end, minimumCodeSize + 1);
  return writer.toBytes();
}

/// Decodes GIF LZW image data into palette indices.
List<int> gifLzwDecode(Uint8List data, int minimumCodeSize, int expected) {
  final reader = _BitReader(data);
  final clear = 1 << minimumCodeSize;
  final end = clear + 1;
  var codeSize = minimumCodeSize + 1;
  var nextCode = end + 1;
  var previous = <int>[];
  var dictionary = _initialDictionary(clear);
  final output = <int>[];
  while (output.length < expected) {
    final code = reader.read(codeSize);
    if (code == clear) {
      dictionary = _initialDictionary(clear);
      codeSize = minimumCodeSize + 1;
      nextCode = end + 1;
      previous = <int>[];
      continue;
    }
    if (code == end) {
      break;
    }
    final entry = code < dictionary.length && dictionary[code].isNotEmpty
        ? dictionary[code]
        : <int>[...previous, previous.first];
    output.addAll(entry);
    if (previous.isNotEmpty) {
      dictionary.add(<int>[...previous, entry.first]);
      nextCode += 1;
      if (nextCode == (1 << codeSize) && codeSize < 12) {
        codeSize += 1;
      }
    }
    previous = entry;
  }
  if (output.length < expected) {
    throw const InvalidImageException('Truncated GIF LZW data.');
  }
  return output.take(expected).toList(growable: false);
}

List<List<int>> _initialDictionary(int clear) {
  return <List<int>>[
    for (var i = 0; i < clear; i += 1) <int>[i],
    <int>[],
    <int>[],
  ];
}

final class _BitWriter {
  final List<int> _bytes = <int>[];
  var _current = 0;
  var _bits = 0;

  void write(int value, int count) {
    var remaining = count;
    var currentValue = value;
    while (remaining > 0) {
      _current |= (currentValue & 1) << _bits;
      currentValue >>= 1;
      _bits += 1;
      remaining -= 1;
      if (_bits == 8) {
        _bytes.add(_current);
        _current = 0;
        _bits = 0;
      }
    }
  }

  Uint8List toBytes() {
    if (_bits > 0) {
      _bytes.add(_current);
      _current = 0;
      _bits = 0;
    }
    return Uint8List.fromList(_bytes);
  }
}

final class _BitReader {
  _BitReader(this.bytes);

  final Uint8List bytes;
  var _byteOffset = 0;
  var _bitOffset = 0;

  int read(int count) {
    var value = 0;
    for (var bit = 0; bit < count; bit += 1) {
      if (_byteOffset >= bytes.length) {
        throw const InvalidImageException('Truncated GIF LZW code.');
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
