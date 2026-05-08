import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

void main() {
  test('decodes TIFF LZW with horizontal predictor', () async {
    final image = await ImagePipeline.fromBytes(
      _lzwPredictorTiff(),
    ).toPixelImage();

    expect(image.width, 2);
    expect(image.height, 1);
    expect(image.firstFrameBytes(), <int>[10, 20, 30, 255, 15, 25, 35, 255]);
  });

  test('decodes TIFF LZW after 9-bit dictionary growth', () async {
    const width = 520;
    final samples = Uint8List.fromList(<int>[
      for (var i = 0; i < width; i += 1) (i * 37) & 0xff,
    ]);
    final image = await ImagePipeline.fromBytes(
      _littleEndianTiff(
        width: width,
        height: 1,
        samples: 1,
        compression: 5,
        photometric: 1,
        bitsPerSample: const <int>[8],
        strip: _lzwEncodeTiff(samples),
      ),
    ).toPixelImage();
    final rgba = image.firstFrameBytes();

    expect(rgba.length, width * 4);
    for (final x in <int>[0, 1, 255, 256, 519]) {
      final sample = samples[x];
      expect(rgba.sublist(x * 4, x * 4 + 4), <int>[
        sample,
        sample,
        sample,
        255,
      ]);
    }
  });

  test('decodes TIFF PackBits literal and replicated runs', () async {
    final image = await ImagePipeline.fromBytes(_packBitsTiff()).toPixelImage();

    expect(image.width, 6);
    expect(image.height, 1);
    expect(image.firstFrameBytes(), <int>[
      10,
      10,
      10,
      255,
      20,
      20,
      20,
      255,
      30,
      30,
      30,
      255,
      40,
      40,
      40,
      255,
      40,
      40,
      40,
      255,
      40,
      40,
      40,
      255,
    ]);
  });

  test('decodes multi-strip TIFF rows', () async {
    final image = await ImagePipeline.fromBytes(
      _littleEndianTiff(
        width: 2,
        height: 2,
        samples: 3,
        compression: 1,
        photometric: 2,
        bitsPerSample: const <int>[8, 8, 8],
        strips: <Uint8List>[
          Uint8List.fromList(<int>[1, 2, 3, 4, 5, 6]),
          Uint8List.fromList(<int>[7, 8, 9, 10, 11, 12]),
        ],
        rowsPerStrip: 1,
      ),
    ).toPixelImage();

    expect(image.width, 2);
    expect(image.height, 2);
    expect(image.firstFrameBytes(), <int>[
      1,
      2,
      3,
      255,
      4,
      5,
      6,
      255,
      7,
      8,
      9,
      255,
      10,
      11,
      12,
      255,
    ]);
  });

  test('decodes 1-bit grayscale TIFF rows', () async {
    final image = await ImagePipeline.fromBytes(
      _littleEndianTiff(
        width: 8,
        height: 1,
        samples: 1,
        compression: 1,
        photometric: 1,
        bitsPerSample: const <int>[1],
        strip: Uint8List.fromList(<int>[0xb2]),
      ),
    ).toPixelImage();

    expect(
      image.firstFrameBytes(),
      _rgbaGray(<int>[255, 0, 255, 255, 0, 0, 255, 0]),
    );
  });

  test('decodes Group 3 one-dimensional fax TIFF rows', () async {
    for (final fillOrder in <int>[1, 2]) {
      final image = await ImagePipeline.fromBytes(
        _littleEndianTiff(
          width: 8,
          height: 2,
          samples: 1,
          compression: 3,
          photometric: 0,
          bitsPerSample: const <int>[1],
          fillOrder: fillOrder,
          strip: _group3FaxStrip(fillOrder: fillOrder),
        ),
      ).toPixelImage();

      expect(image.firstFrameBytes(), <int>[
        ..._rgbaGray(<int>[255, 255, 0, 0, 0, 255, 255, 255]),
        ..._rgbaGray(<int>[0, 0, 0, 0, 0, 0, 0, 0]),
      ]);
    }
  });

  test('decodes 2-bit grayscale TIFF rows', () async {
    final image = await ImagePipeline.fromBytes(
      _littleEndianTiff(
        width: 4,
        height: 1,
        samples: 1,
        compression: 1,
        photometric: 1,
        bitsPerSample: const <int>[2],
        strip: Uint8List.fromList(<int>[0x1b]),
      ),
    ).toPixelImage();

    expect(image.firstFrameBytes(), _rgbaGray(<int>[0, 85, 170, 255]));
  });

  test('decodes 4-bit white-is-zero grayscale TIFF rows', () async {
    final image = await ImagePipeline.fromBytes(
      _littleEndianTiff(
        width: 2,
        height: 1,
        samples: 1,
        compression: 1,
        photometric: 0,
        bitsPerSample: const <int>[4],
        strip: Uint8List.fromList(<int>[0x0f]),
      ),
    ).toPixelImage();

    expect(image.firstFrameBytes(), _rgbaGray(<int>[255, 0]));
  });

  test('decodes low-bit paletted TIFF color maps', () async {
    final image = await ImagePipeline.fromBytes(
      _littleEndianTiff(
        width: 4,
        height: 1,
        samples: 1,
        compression: 1,
        photometric: 3,
        bitsPerSample: const <int>[2],
        strip: Uint8List.fromList(<int>[0x1b]),
        colorMap: _paletteColorMap(4, const <List<int>>[
          <int>[0, 0, 0],
          <int>[255, 0, 0],
          <int>[0, 255, 0],
          <int>[0, 0, 255],
        ]),
      ),
    ).toPixelImage();

    expect(image.firstFrameBytes(), <int>[
      0,
      0,
      0,
      255,
      255,
      0,
      0,
      255,
      0,
      255,
      0,
      255,
      0,
      0,
      255,
      255,
    ]);
  });

  test('decodes 8-bit paletted TIFF color maps', () async {
    final image = await ImagePipeline.fromBytes(
      _littleEndianTiff(
        width: 3,
        height: 1,
        samples: 1,
        compression: 1,
        photometric: 3,
        bitsPerSample: const <int>[8],
        strip: Uint8List.fromList(<int>[0, 1, 2]),
        colorMap: _paletteColorMap(256, const <List<int>>[
          <int>[12, 34, 56],
          <int>[90, 120, 150],
          <int>[200, 210, 220],
        ]),
      ),
    ).toPixelImage();

    expect(image.firstFrameBytes(), <int>[
      12,
      34,
      56,
      255,
      90,
      120,
      150,
      255,
      200,
      210,
      220,
      255,
    ]);
  });

  test('decodes 16-bit grayscale TIFF samples', () async {
    final image = await ImagePipeline.fromBytes(
      _littleEndianTiff(
        width: 3,
        height: 1,
        samples: 1,
        compression: 1,
        photometric: 1,
        bitsPerSample: const <int>[16],
        strip: Uint8List.fromList(<int>[0x00, 0x00, 0x80, 0x80, 0xff, 0xff]),
      ),
    ).toPixelImage();

    expect(image.firstFrameBytes(), _rgbaGray(<int>[0, 128, 255]));
  });

  test('decodes 16-bit TIFF horizontal predictor rows', () async {
    final image = await ImagePipeline.fromBytes(
      _littleEndianTiff(
        width: 3,
        height: 1,
        samples: 1,
        compression: 1,
        photometric: 1,
        bitsPerSample: const <int>[16],
        predictor: 2,
        strip: Uint8List.fromList(<int>[0x00, 0x00, 0x80, 0x80, 0x7f, 0x7f]),
      ),
    ).toPixelImage();

    expect(image.firstFrameBytes(), _rgbaGray(<int>[0, 128, 255]));
  });

  test('decodes 16-bit RGB TIFF samples', () async {
    final image = await ImagePipeline.fromBytes(
      _littleEndianTiff(
        width: 1,
        height: 1,
        samples: 3,
        compression: 1,
        photometric: 2,
        bitsPerSample: const <int>[16, 16, 16],
        strip: Uint8List.fromList(<int>[0x34, 0x12, 0x80, 0x80, 0xff, 0xff]),
      ),
    ).toPixelImage();

    expect(image.firstFrameBytes(), <int>[18, 128, 255, 255]);
  });

  test('decodes CIELab TIFF samples to sRGB', () async {
    final image = await ImagePipeline.fromBytes(
      _littleEndianTiff(
        width: 2,
        height: 1,
        samples: 3,
        compression: 1,
        photometric: 8,
        bitsPerSample: const <int>[8, 8, 8],
        strip: Uint8List.fromList(<int>[0, 0, 0, 255, 0, 0]),
      ),
    ).toPixelImage();

    expect(image.firstFrameBytes(), <int>[0, 0, 0, 255, 255, 255, 255, 255]);
  });

  test('encodes TIFF PackBits compression', () async {
    final raw = RawPixels(
      bytes: Uint8List.fromList(<int>[
        for (final value in <int>[7, 7, 7, 120, 130, 130]) ...[
          value,
          value,
          value,
          255,
        ],
      ]),
      width: 6,
      height: 1,
      channels: ChannelCount.four,
    );

    final encoded = await ImagePipeline.fromRawPixels(raw)
        .tiff(const TiffEncoderOptions(compression: TiffCompression.packBits))
        .toBytes();
    final decoded = await ImagePipeline.fromBytes(encoded).toPixelImage();

    expect(_tiffShortTagValue(encoded, 259), 32773);
    expect(decoded.firstFrameBytes(), raw.bytes);
  });

  test('rejects truncated TIFF PackBits packets', () async {
    await expectLater(
      ImagePipeline.fromBytes(_packBitsTiff(strip: <int>[5, 1])).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
    await expectLater(
      ImagePipeline.fromBytes(_packBitsTiff(strip: <int>[255])).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
  });

  test('rejects truncated low-bit grayscale TIFF rows', () async {
    await expectLater(
      ImagePipeline.fromBytes(
        _littleEndianTiff(
          width: 9,
          height: 1,
          samples: 1,
          compression: 1,
          photometric: 1,
          bitsPerSample: const <int>[1],
          strip: Uint8List.fromList(<int>[0xff]),
        ),
      ).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
  });

  test('rejects truncated 16-bit TIFF samples', () async {
    await expectLater(
      ImagePipeline.fromBytes(
        _littleEndianTiff(
          width: 1,
          height: 1,
          samples: 1,
          compression: 1,
          photometric: 1,
          bitsPerSample: const <int>[16],
          strip: Uint8List.fromList(<int>[0x00]),
        ),
      ).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
  });

  test('rejects unsupported TIFF photometric modes', () async {
    await expectLater(
      ImagePipeline.fromBytes(
        _littleEndianTiff(
          width: 1,
          height: 1,
          samples: 4,
          compression: 1,
          photometric: 5,
          bitsPerSample: const <int>[8, 8, 8, 8],
          strip: Uint8List.fromList(<int>[0, 255, 255, 0]),
        ),
      ).toPixelImage(),
      throwsA(isA<UnsupportedCodecException>()),
    );
  });

  test('rejects unsupported two-dimensional Group 3 TIFF coding', () async {
    await expectLater(
      ImagePipeline.fromBytes(
        _littleEndianTiff(
          width: 8,
          height: 1,
          samples: 1,
          compression: 3,
          photometric: 0,
          bitsPerSample: const <int>[1],
          group3Options: 1,
          strip: _group3FaxStrip(),
        ),
      ).toPixelImage(),
      throwsA(isA<UnsupportedCodecException>()),
    );
  });

  test('rejects truncated paletted TIFF color maps', () async {
    await expectLater(
      ImagePipeline.fromBytes(
        _littleEndianTiff(
          width: 4,
          height: 1,
          samples: 1,
          compression: 1,
          photometric: 3,
          bitsPerSample: const <int>[2],
          strip: Uint8List.fromList(<int>[0x1b]),
          colorMap: const <int>[0, 65535, 0, 0, 0, 0],
        ),
      ).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
  });
}

Uint8List _packBitsTiff({
  List<int> strip = const <int>[2, 10, 20, 30, 254, 40],
}) {
  return _littleEndianTiff(
    width: 6,
    height: 1,
    samples: 1,
    compression: 32773,
    photometric: 1,
    bitsPerSample: const <int>[8],
    strip: Uint8List.fromList(strip),
  );
}

Uint8List _lzwPredictorTiff() {
  final compressed = _lzwEncodeTiff(<int>[10, 20, 30, 5, 5, 5]);
  return _littleEndianTiff(
    width: 2,
    height: 1,
    samples: 3,
    compression: 5,
    photometric: 2,
    bitsPerSample: const <int>[8, 8, 8],
    strip: compressed,
    predictor: 2,
  );
}

Uint8List _littleEndianTiff({
  required int width,
  required int height,
  required int samples,
  required int compression,
  required int photometric,
  required List<int> bitsPerSample,
  Uint8List? strip,
  List<Uint8List>? strips,
  int? predictor,
  int? rowsPerStrip,
  int? fillOrder,
  int? group3Options,
  List<int>? colorMap,
}) {
  final stripList = strips ?? <Uint8List>[strip!];
  final bytes = <int>[];

  void u16(int value) {
    bytes
      ..add(value & 0xff)
      ..add((value >> 8) & 0xff);
  }

  void u32(int value) {
    bytes
      ..add(value & 0xff)
      ..add((value >> 8) & 0xff)
      ..add((value >> 16) & 0xff)
      ..add((value >> 24) & 0xff);
  }

  void entry(int tag, int type, int count, int value) {
    u16(tag);
    u16(type);
    u32(count);
    if (type == 3 && count == 1) {
      u16(value);
      u16(0);
    } else {
      u32(value);
    }
  }

  final entryCount =
      10 +
      (predictor == null ? 0 : 1) +
      (fillOrder == null ? 0 : 1) +
      (group3Options == null ? 0 : 1) +
      (colorMap == null ? 0 : 1);
  const ifdOffset = 8;
  final extraOffset = ifdOffset + 2 + entryCount * 12 + 4;
  var dataOffset = extraOffset;
  final bitsOffset = dataOffset;
  if (bitsPerSample.length > 1) {
    dataOffset += bitsPerSample.length * 2;
  }
  final colorMapOffset = dataOffset;
  if (colorMap != null) {
    dataOffset += colorMap.length * 2;
  }
  final stripOffsetsOffset = dataOffset;
  if (stripList.length > 1) {
    dataOffset += stripList.length * 4;
  }
  final stripByteCountsOffset = dataOffset;
  if (stripList.length > 1) {
    dataOffset += stripList.length * 4;
  }
  final firstStripOffset = dataOffset;
  final stripOffsets = <int>[];
  var nextStripOffset = firstStripOffset;
  for (final currentStrip in stripList) {
    stripOffsets.add(nextStripOffset);
    nextStripOffset += currentStrip.length;
  }
  bytes.addAll(<int>[0x49, 0x49]);
  u16(42);
  u32(ifdOffset);
  u16(entryCount);
  entry(256, 4, 1, width);
  entry(257, 4, 1, height);
  if (bitsPerSample.length == 1) {
    entry(258, 3, 1, bitsPerSample.single);
  } else {
    entry(258, 3, bitsPerSample.length, bitsOffset);
  }
  entry(259, 3, 1, compression);
  entry(262, 3, 1, photometric);
  entry(
    273,
    4,
    stripList.length,
    stripList.length == 1 ? stripOffsets.single : stripOffsetsOffset,
  );
  entry(277, 3, 1, samples);
  entry(278, 4, 1, rowsPerStrip ?? height);
  entry(
    279,
    4,
    stripList.length,
    stripList.length == 1 ? stripList.single.length : stripByteCountsOffset,
  );
  entry(284, 3, 1, 1);
  if (fillOrder != null) {
    entry(266, 3, 1, fillOrder);
  }
  if (group3Options != null) {
    entry(292, 4, 1, group3Options);
  }
  if (predictor != null) {
    entry(317, 3, 1, predictor);
  }
  if (colorMap != null) {
    entry(320, 3, colorMap.length, colorMapOffset);
  }
  u32(0);
  if (bitsPerSample.length > 1) {
    for (final bits in bitsPerSample) {
      u16(bits);
    }
  }
  if (colorMap != null) {
    for (final value in colorMap) {
      u16(value);
    }
  }
  if (stripList.length > 1) {
    for (final offset in stripOffsets) {
      u32(offset);
    }
    for (final currentStrip in stripList) {
      u32(currentStrip.length);
    }
  }
  for (final currentStrip in stripList) {
    bytes.addAll(currentStrip);
  }
  return Uint8List.fromList(bytes);
}

int _tiffShortTagValue(Uint8List bytes, int tag) {
  final ifd = bytes[4] | (bytes[5] << 8) | (bytes[6] << 16) | (bytes[7] << 24);
  final count = bytes[ifd] | (bytes[ifd + 1] << 8);
  for (var i = 0; i < count; i += 1) {
    final entry = ifd + 2 + i * 12;
    final current = bytes[entry] | (bytes[entry + 1] << 8);
    if (current == tag) {
      return bytes[entry + 8] | (bytes[entry + 9] << 8);
    }
  }
  throw StateError('TIFF tag $tag not found.');
}

Uint8List _lzwEncodeTiff(List<int> values) {
  final writer = _MsbCodeWriter()..write(256, 9);
  final dictionary = <String, int>{
    for (var i = 0; i < 256; i += 1) String.fromCharCode(i): i,
  };
  var nextCode = 258;
  var codeWidth = 9;
  var current = '';
  for (final value in values) {
    final char = String.fromCharCode(value);
    final candidate = current + char;
    if (dictionary.containsKey(candidate)) {
      current = candidate;
      continue;
    }
    writer.write(dictionary[current]!, codeWidth);
    if (nextCode < 4096) {
      dictionary[candidate] = nextCode;
      nextCode += 1;
      if (nextCode == (1 << codeWidth) && codeWidth < 12) {
        codeWidth += 1;
      }
    }
    current = char;
  }
  if (current.isNotEmpty) {
    writer.write(dictionary[current]!, codeWidth);
  }
  writer.write(257, codeWidth);
  return writer.finish();
}

Uint8List _group3FaxStrip({int fillOrder = 1}) {
  const eol = '000000000001';
  const row0 = '0111101000';
  const row1 = '00110101000101';
  return _bitsToBytes('$eol$row0$eol$row1$eol', lsbFirst: fillOrder == 2);
}

Uint8List _bitsToBytes(String bits, {required bool lsbFirst}) {
  final out = Uint8List((bits.length + 7) >> 3);
  for (var i = 0; i < bits.length; i += 1) {
    if (bits.codeUnitAt(i) != 0x31) {
      continue;
    }
    final bit = lsbFirst ? i & 7 : 7 - (i & 7);
    out[i >> 3] |= 1 << bit;
  }
  return out;
}

final class _MsbCodeWriter {
  final _bytes = <int>[];
  var _buffer = 0;
  var _bits = 0;

  void write(int value, int count) {
    for (var bit = count - 1; bit >= 0; bit -= 1) {
      _buffer = (_buffer << 1) | ((value >> bit) & 1);
      _bits += 1;
      if (_bits == 8) {
        _bytes.add(_buffer);
        _buffer = 0;
        _bits = 0;
      }
    }
  }

  Uint8List finish() {
    if (_bits > 0) {
      _bytes.add(_buffer << (8 - _bits));
    }
    return Uint8List.fromList(_bytes);
  }
}

List<int> _rgbaGray(List<int> values) {
  return <int>[
    for (final value in values) ...<int>[value, value, value, 255],
  ];
}

List<int> _paletteColorMap(int colorCount, List<List<int>> colors) {
  final red = List<int>.filled(colorCount, 0);
  final green = List<int>.filled(colorCount, 0);
  final blue = List<int>.filled(colorCount, 0);
  for (var i = 0; i < colors.length; i += 1) {
    red[i] = colors[i][0] * 257;
    green[i] = colors[i][1] * 257;
    blue[i] = colors[i][2] * 257;
  }
  return <int>[...red, ...green, ...blue];
}
