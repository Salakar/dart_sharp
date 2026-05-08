part of 'tiff_codec.dart';

const _faxEol = -1;

Uint8List _decodeGroup3FaxTiff(
  Uint8List bytes,
  _Ifd tags,
  int width,
  int height,
) {
  final options = tags.value(292, fallback: 0);
  if ((options & 1) != 0) {
    throw const UnsupportedCodecException(
      'TIFF Group 3 two-dimensional coding is not supported.',
    );
  }
  if ((options & 2) != 0) {
    throw const UnsupportedCodecException(
      'TIFF Group 3 uncompressed mode is not supported.',
    );
  }
  final fillOrder = tags.value(266, fallback: 1);
  if (fillOrder != 1 && fillOrder != 2) {
    throw UnsupportedCodecException('Unsupported TIFF fill order $fillOrder.');
  }
  final offsets = tags.values(273);
  final byteCounts = tags.values(279);
  if (offsets.isEmpty || offsets.length != byteCounts.length) {
    throw const InvalidImageException('Invalid TIFF strip layout.');
  }
  final rowsPerStrip = tags.value(278, fallback: height);
  final rowBytes = (width + 7) >> 3;
  final output = Uint8List(rowBytes * height);
  var row = 0;
  for (var stripIndex = 0; stripIndex < offsets.length; stripIndex += 1) {
    final offset = offsets[stripIndex];
    final byteCount = byteCounts[stripIndex];
    if (offset + byteCount > bytes.length) {
      throw const InvalidImageException('Truncated TIFF strip.');
    }
    final reader = _FaxBitReader(
      Uint8List.sublistView(bytes, offset, offset + byteCount),
      lsbFirst: fillOrder == 2,
    );
    final stripRows = math.min(rowsPerStrip, height - row);
    for (var stripRow = 0; stripRow < stripRows; stripRow += 1) {
      _decodeGroup3Row(reader, output, rowBytes, row, width);
      row += 1;
    }
  }
  if (row < height) {
    throw const InvalidImageException('Missing TIFF fax rows.');
  }
  return output;
}

void _decodeGroup3Row(
  _FaxBitReader reader,
  Uint8List output,
  int rowBytes,
  int row,
  int width,
) {
  reader.tryConsumeEol();
  var x = 0;
  var white = true;
  while (x < width) {
    final run = _readFaxRun(reader, white);
    if (run == _faxEol) {
      if (x == 0) {
        continue;
      }
      throw const InvalidImageException('Short TIFF Group 3 row.');
    }
    if (!white) {
      _setFaxBlackRun(output, row * rowBytes, x, math.min(run, width - x));
    }
    x += run;
    white = !white;
  }
  reader.tryConsumeEol();
}

int _readFaxRun(_FaxBitReader reader, bool white) {
  final table = white ? _whiteFaxCodes : _blackFaxCodes;
  var run = 0;
  while (true) {
    final code = _readFaxCode(reader, table);
    if (code == _faxEol) {
      return run == 0 ? _faxEol : run;
    }
    run += code;
    if (code < 64) {
      return run;
    }
  }
}

int _readFaxCode(_FaxBitReader reader, Map<int, int> table) {
  var bits = 0;
  for (var length = 1; length <= 13; length += 1) {
    final bit = reader.readBit();
    if (bit == null) {
      throw const InvalidImageException('Truncated TIFF Group 3 data.');
    }
    bits = (bits << 1) | bit;
    if (length == 12 && bits == 1) {
      return _faxEol;
    }
    final value = table[(length << 16) | bits];
    if (value != null) {
      return value;
    }
  }
  throw const InvalidImageException('Invalid TIFF Group 3 code.');
}

void _setFaxBlackRun(Uint8List output, int rowOffset, int x, int length) {
  for (var i = 0; i < length; i += 1) {
    final pixel = x + i;
    output[rowOffset + (pixel >> 3)] |= 0x80 >> (pixel & 7);
  }
}

final class _FaxBitReader {
  _FaxBitReader(this.bytes, {required this.lsbFirst});

  final Uint8List bytes;
  final bool lsbFirst;
  int _bitOffset = 0;

  int? readBit() {
    if (_bitOffset >= bytes.length * 8) {
      return null;
    }
    final byte = bytes[_bitOffset >> 3];
    final bit = lsbFirst ? _bitOffset & 7 : 7 - (_bitOffset & 7);
    _bitOffset += 1;
    return (byte >> bit) & 1;
  }

  bool tryConsumeEol() {
    final start = _bitOffset;
    var zeroes = 0;
    while (_bitOffset < bytes.length * 8) {
      final bit = readBit();
      if (bit == 0) {
        zeroes += 1;
        continue;
      }
      if (zeroes >= 11) {
        return true;
      }
      _bitOffset = start;
      return false;
    }
    _bitOffset = start;
    return false;
  }
}

Map<int, int> _buildFaxCodes(List<_FaxCode> codes) {
  return <int, int>{
    for (final code in codes) (code.length << 16) | code.bits: code.run,
  };
}

final class _FaxCode {
  const _FaxCode(this.run, this.length, this.bits);

  final int run;
  final int length;
  final int bits;
}

final _whiteFaxCodes = _buildFaxCodes(const <_FaxCode>[
  _FaxCode(0, 8, 0x35),
  _FaxCode(1, 6, 0x07),
  _FaxCode(2, 4, 0x07),
  _FaxCode(3, 4, 0x08),
  _FaxCode(4, 4, 0x0b),
  _FaxCode(5, 4, 0x0c),
  _FaxCode(6, 4, 0x0e),
  _FaxCode(7, 4, 0x0f),
  _FaxCode(8, 5, 0x13),
  _FaxCode(9, 5, 0x14),
  _FaxCode(10, 5, 0x07),
  _FaxCode(11, 5, 0x08),
  _FaxCode(12, 6, 0x08),
  _FaxCode(13, 6, 0x03),
  _FaxCode(14, 6, 0x34),
  _FaxCode(15, 6, 0x35),
  _FaxCode(16, 6, 0x2a),
  _FaxCode(17, 6, 0x2b),
  _FaxCode(18, 7, 0x27),
  _FaxCode(19, 7, 0x0c),
  _FaxCode(20, 7, 0x08),
  _FaxCode(21, 7, 0x17),
  _FaxCode(22, 7, 0x03),
  _FaxCode(23, 7, 0x04),
  _FaxCode(24, 7, 0x28),
  _FaxCode(25, 7, 0x2b),
  _FaxCode(26, 7, 0x13),
  _FaxCode(27, 7, 0x24),
  _FaxCode(28, 7, 0x18),
  _FaxCode(29, 8, 0x02),
  _FaxCode(30, 8, 0x03),
  _FaxCode(31, 8, 0x1a),
  _FaxCode(32, 8, 0x1b),
  _FaxCode(33, 8, 0x12),
  _FaxCode(34, 8, 0x13),
  _FaxCode(35, 8, 0x14),
  _FaxCode(36, 8, 0x15),
  _FaxCode(37, 8, 0x16),
  _FaxCode(38, 8, 0x17),
  _FaxCode(39, 8, 0x28),
  _FaxCode(40, 8, 0x29),
  _FaxCode(41, 8, 0x2a),
  _FaxCode(42, 8, 0x2b),
  _FaxCode(43, 8, 0x2c),
  _FaxCode(44, 8, 0x2d),
  _FaxCode(45, 8, 0x04),
  _FaxCode(46, 8, 0x05),
  _FaxCode(47, 8, 0x0a),
  _FaxCode(48, 8, 0x0b),
  _FaxCode(49, 8, 0x52),
  _FaxCode(50, 8, 0x53),
  _FaxCode(51, 8, 0x54),
  _FaxCode(52, 8, 0x55),
  _FaxCode(53, 8, 0x24),
  _FaxCode(54, 8, 0x25),
  _FaxCode(55, 8, 0x58),
  _FaxCode(56, 8, 0x59),
  _FaxCode(57, 8, 0x5a),
  _FaxCode(58, 8, 0x5b),
  _FaxCode(59, 8, 0x4a),
  _FaxCode(60, 8, 0x4b),
  _FaxCode(61, 8, 0x32),
  _FaxCode(62, 8, 0x33),
  _FaxCode(63, 8, 0x34),
  _FaxCode(64, 5, 0x1b),
  _FaxCode(128, 5, 0x12),
  _FaxCode(192, 6, 0x17),
  _FaxCode(256, 7, 0x37),
  _FaxCode(320, 8, 0x36),
  _FaxCode(384, 8, 0x37),
  _FaxCode(448, 8, 0x64),
  _FaxCode(512, 8, 0x65),
  _FaxCode(576, 8, 0x68),
  _FaxCode(640, 8, 0x67),
  _FaxCode(704, 9, 0xcc),
  _FaxCode(768, 9, 0xcd),
  _FaxCode(832, 9, 0xd2),
  _FaxCode(896, 9, 0xd3),
  _FaxCode(960, 9, 0xd4),
  _FaxCode(1024, 9, 0xd5),
  _FaxCode(1088, 9, 0xd6),
  _FaxCode(1152, 9, 0xd7),
  _FaxCode(1216, 9, 0xd8),
  _FaxCode(1280, 9, 0xd9),
  _FaxCode(1344, 9, 0xda),
  _FaxCode(1408, 9, 0xdb),
  _FaxCode(1472, 9, 0x98),
  _FaxCode(1536, 9, 0x99),
  _FaxCode(1600, 9, 0x9a),
  _FaxCode(1664, 6, 0x18),
  _FaxCode(1728, 9, 0x9b),
  ..._longFaxMakeupCodes,
]);

final _blackFaxCodes = _buildFaxCodes(const <_FaxCode>[
  _FaxCode(0, 10, 0x37),
  _FaxCode(1, 3, 0x02),
  _FaxCode(2, 2, 0x03),
  _FaxCode(3, 2, 0x02),
  _FaxCode(4, 3, 0x03),
  _FaxCode(5, 4, 0x03),
  _FaxCode(6, 4, 0x02),
  _FaxCode(7, 5, 0x03),
  _FaxCode(8, 6, 0x05),
  _FaxCode(9, 6, 0x04),
  _FaxCode(10, 7, 0x04),
  _FaxCode(11, 7, 0x05),
  _FaxCode(12, 7, 0x07),
  _FaxCode(13, 8, 0x04),
  _FaxCode(14, 8, 0x07),
  _FaxCode(15, 9, 0x18),
  _FaxCode(16, 10, 0x17),
  _FaxCode(17, 10, 0x18),
  _FaxCode(18, 10, 0x08),
  _FaxCode(19, 11, 0x67),
  _FaxCode(20, 11, 0x68),
  _FaxCode(21, 11, 0x6c),
  _FaxCode(22, 11, 0x37),
  _FaxCode(23, 11, 0x28),
  _FaxCode(24, 11, 0x17),
  _FaxCode(25, 11, 0x18),
  _FaxCode(26, 12, 0xca),
  _FaxCode(27, 12, 0xcb),
  _FaxCode(28, 12, 0xcc),
  _FaxCode(29, 12, 0xcd),
  _FaxCode(30, 12, 0x68),
  _FaxCode(31, 12, 0x69),
  _FaxCode(32, 12, 0x6a),
  _FaxCode(33, 12, 0x6b),
  _FaxCode(34, 12, 0xd2),
  _FaxCode(35, 12, 0xd3),
  _FaxCode(36, 12, 0xd4),
  _FaxCode(37, 12, 0xd5),
  _FaxCode(38, 12, 0xd6),
  _FaxCode(39, 12, 0xd7),
  _FaxCode(40, 12, 0x6c),
  _FaxCode(41, 12, 0x6d),
  _FaxCode(42, 12, 0xda),
  _FaxCode(43, 12, 0xdb),
  _FaxCode(44, 12, 0x54),
  _FaxCode(45, 12, 0x55),
  _FaxCode(46, 12, 0x56),
  _FaxCode(47, 12, 0x57),
  _FaxCode(48, 12, 0x64),
  _FaxCode(49, 12, 0x65),
  _FaxCode(50, 12, 0x52),
  _FaxCode(51, 12, 0x53),
  _FaxCode(52, 12, 0x24),
  _FaxCode(53, 12, 0x37),
  _FaxCode(54, 12, 0x38),
  _FaxCode(55, 12, 0x27),
  _FaxCode(56, 12, 0x28),
  _FaxCode(57, 12, 0x58),
  _FaxCode(58, 12, 0x59),
  _FaxCode(59, 12, 0x2b),
  _FaxCode(60, 12, 0x2c),
  _FaxCode(61, 12, 0x5a),
  _FaxCode(62, 12, 0x66),
  _FaxCode(63, 12, 0x67),
  _FaxCode(64, 10, 0x0f),
  _FaxCode(128, 12, 0xc8),
  _FaxCode(192, 12, 0xc9),
  _FaxCode(256, 12, 0x5b),
  _FaxCode(320, 12, 0x33),
  _FaxCode(384, 12, 0x34),
  _FaxCode(448, 12, 0x35),
  _FaxCode(512, 13, 0x6c),
  _FaxCode(576, 13, 0x6d),
  _FaxCode(640, 13, 0x4a),
  _FaxCode(704, 13, 0x4b),
  _FaxCode(768, 13, 0x4c),
  _FaxCode(832, 13, 0x4d),
  _FaxCode(896, 13, 0x72),
  _FaxCode(960, 13, 0x73),
  _FaxCode(1024, 13, 0x74),
  _FaxCode(1088, 13, 0x75),
  _FaxCode(1152, 13, 0x76),
  _FaxCode(1216, 13, 0x77),
  _FaxCode(1280, 13, 0x52),
  _FaxCode(1344, 13, 0x53),
  _FaxCode(1408, 13, 0x54),
  _FaxCode(1472, 13, 0x55),
  _FaxCode(1536, 13, 0x5a),
  _FaxCode(1600, 13, 0x5b),
  _FaxCode(1664, 13, 0x64),
  _FaxCode(1728, 13, 0x65),
  ..._longFaxMakeupCodes,
]);

const _longFaxMakeupCodes = <_FaxCode>[
  _FaxCode(1792, 11, 0x08),
  _FaxCode(1856, 11, 0x0c),
  _FaxCode(1920, 11, 0x0d),
  _FaxCode(1984, 12, 0x12),
  _FaxCode(2048, 12, 0x13),
  _FaxCode(2112, 12, 0x14),
  _FaxCode(2176, 12, 0x15),
  _FaxCode(2240, 12, 0x16),
  _FaxCode(2304, 12, 0x17),
  _FaxCode(2368, 12, 0x1c),
  _FaxCode(2432, 12, 0x1d),
  _FaxCode(2496, 12, 0x1e),
  _FaxCode(2560, 12, 0x1f),
];
