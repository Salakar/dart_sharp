part of 'webp_lossless.dart';

final class _PrefixCode {
  const _PrefixCode._(this.symbol, [this.secondSymbol]) : tree = null;

  final int symbol;
  final int? secondSymbol;

  static _PrefixCode read(_BitReader reader, int alphabetSize) {
    if (reader.readBits(1) == 0) {
      return _PrefixCode._fromLengths(
        _readNormalCodeLengths(reader, alphabetSize),
      );
    }
    final numSymbols = reader.readBits(1) + 1;
    final isFirst8Bits = reader.readBits(1);
    final symbol = reader.readBits(1 + 7 * isFirst8Bits);
    if (symbol >= alphabetSize) {
      throw const InvalidImageException('Invalid VP8L prefix symbol.');
    }
    if (numSymbols == 2) {
      final second = reader.readBits(8);
      if (second >= alphabetSize) {
        throw const InvalidImageException('Invalid VP8L prefix symbol.');
      }
      return _PrefixCode._(symbol, second);
    }
    return _PrefixCode._(symbol);
  }

  factory _PrefixCode._fromLengths(List<int> lengths) {
    final symbols = <int>[];
    for (var i = 0; i < lengths.length; i += 1) {
      if (lengths[i] > 0) {
        symbols.add(i);
      }
    }
    if (symbols.length == 1) {
      return _PrefixCode._(symbols.single);
    }
    if (symbols.isEmpty) {
      throw const InvalidImageException('Invalid empty VP8L prefix code.');
    }
    return _PrefixCode._withTree(_CanonicalCode(lengths));
  }

  const _PrefixCode._withTree(this.tree) : symbol = -1, secondSymbol = null;

  final _CanonicalCode? tree;

  int decode(_BitReader reader) {
    final currentTree = tree;
    if (currentTree != null) {
      return currentTree.decode(reader);
    }
    final second = secondSymbol;
    if (second == null) {
      return symbol;
    }
    return reader.readBits(1) == 0 ? symbol : second;
  }
}

List<int> _readNormalCodeLengths(_BitReader reader, int alphabetSize) {
  const order = <int>[
    17,
    18,
    0,
    1,
    2,
    3,
    4,
    5,
    16,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15,
  ];
  final codeLengthLengths = List<int>.filled(19, 0);
  final numCodeLengths = 4 + reader.readBits(4);
  for (var i = 0; i < numCodeLengths; i += 1) {
    codeLengthLengths[order[i]] = reader.readBits(3);
  }
  final codeLengthCode = _CanonicalCode(codeLengthLengths);
  final maxSymbol = reader.readBits(1) == 0
      ? alphabetSize
      : 2 + reader.readBits(2 + 2 * reader.readBits(3));
  if (maxSymbol > alphabetSize) {
    throw const InvalidImageException('Invalid VP8L prefix symbol count.');
  }
  final lengths = List<int>.filled(maxSymbol, 0);
  var index = 0;
  var previous = 8;
  while (index < maxSymbol) {
    final symbol = codeLengthCode.decode(reader);
    if (symbol < 16) {
      lengths[index++] = symbol;
      if (symbol > 0) {
        previous = symbol;
      }
    } else {
      final repeat = switch (symbol) {
        16 => 3 + reader.readBits(2),
        17 => 3 + reader.readBits(3),
        18 => 11 + reader.readBits(7),
        _ => throw const InvalidImageException('Invalid VP8L code length.'),
      };
      if (index + repeat > maxSymbol) {
        throw const InvalidImageException('Invalid VP8L code length repeat.');
      }
      final value = symbol == 16 ? previous : 0;
      for (var i = 0; i < repeat; i += 1) {
        lengths[index++] = value;
      }
    }
  }
  return lengths;
}

final class _CanonicalCode {
  _CanonicalCode(List<int> lengths) {
    var code = 0;
    for (var bits = 1; bits <= 15; bits += 1) {
      for (var symbol = 0; symbol < lengths.length; symbol += 1) {
        if (lengths[symbol] == bits) {
          _symbols[(bits << 16) | _reverseBits(code, bits)] = symbol;
          code += 1;
        }
      }
      code <<= 1;
    }
  }

  final Map<int, int> _symbols = <int, int>{};

  int decode(_BitReader reader) {
    var code = 0;
    for (var bits = 1; bits <= 15; bits += 1) {
      code |= reader.readBits(1) << (bits - 1);
      final symbol = _symbols[(bits << 16) | code];
      if (symbol != null) {
        return symbol;
      }
    }
    throw const InvalidImageException('Invalid VP8L prefix code.');
  }
}

int _reverseBits(int value, int count) {
  var reversed = 0;
  for (var i = 0; i < count; i += 1) {
    reversed = (reversed << 1) | ((value >> i) & 1);
  }
  return reversed;
}

int _prefixValue(int prefix, _BitReader reader) {
  if (prefix < 4) {
    return prefix + 1;
  }
  final extraBits = (prefix - 2) >> 1;
  final offset = (2 + (prefix & 1)) << extraBits;
  return offset + reader.readBits(extraBits) + 1;
}
