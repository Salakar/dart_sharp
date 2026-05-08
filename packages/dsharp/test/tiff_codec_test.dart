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
  final compressed = _lzwLiteralBytes(<int>[10, 20, 30, 5, 5, 5]);
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

  final entryCount = predictor == null ? 10 : 11;
  const ifdOffset = 8;
  final extraOffset = ifdOffset + 2 + entryCount * 12 + 4;
  final bitsOffset = extraOffset;
  final stripOffsetsOffset =
      bitsOffset + (bitsPerSample.length > 1 ? bitsPerSample.length * 2 : 0);
  final stripByteCountsOffset =
      stripOffsetsOffset + (stripList.length > 1 ? stripList.length * 4 : 0);
  final firstStripOffset =
      stripByteCountsOffset + (stripList.length > 1 ? stripList.length * 4 : 0);
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
  if (predictor != null) {
    entry(317, 3, 1, predictor);
  }
  u32(0);
  if (bitsPerSample.length > 1) {
    for (final bits in bitsPerSample) {
      u16(bits);
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

Uint8List _lzwLiteralBytes(List<int> values) {
  final bytes = <int>[];
  var buffer = 0;
  var bits = 0;

  void write(int code) {
    for (var bit = 8; bit >= 0; bit -= 1) {
      buffer = (buffer << 1) | ((code >> bit) & 1);
      bits += 1;
      if (bits == 8) {
        bytes.add(buffer);
        buffer = 0;
        bits = 0;
      }
    }
  }

  write(256);
  for (final value in values) {
    write(value);
  }
  write(257);
  if (bits > 0) {
    bytes.add(buffer << (8 - bits));
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
