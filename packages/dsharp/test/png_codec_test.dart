import 'dart:convert';
import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:dsharp/src/codecs/binary_io.dart';
import 'package:dsharp/src/codecs/deflate_codec.dart';
import 'package:test/test.dart';

void main() {
  test('rejects oversized PNG dimensions before pixel allocation', () async {
    await expectLater(
      ImagePipeline.fromBytes(
        _pngHeaderOnly(width: 65536, height: 1),
      ).toPixelImage(),
      throwsA(isA<ImageLimitException>()),
    );
  });

  test('decodes 16-bit grayscale PNG samples', () async {
    final image = await ImagePipeline.fromBytes(
      _png(
        width: 3,
        height: 1,
        bitDepth: 16,
        colorType: 0,
        samples: const <int>[0, 0x8080, 0xffff],
      ),
    ).toPixelImage();

    expect(image.firstFrameBytes(), <int>[
      0,
      0,
      0,
      255,
      128,
      128,
      128,
      255,
      255,
      255,
      255,
      255,
    ]);
  });

  test('decodes 16-bit grayscale alpha PNG samples', () async {
    final image = await ImagePipeline.fromBytes(
      _png(
        width: 1,
        height: 1,
        bitDepth: 16,
        colorType: 4,
        samples: const <int>[0x4000, 0x8080],
      ),
    ).toPixelImage();

    expect(image.firstFrameBytes(), <int>[64, 64, 64, 128]);
  });

  test('decodes 16-bit truecolour alpha PNG samples', () async {
    final image = await ImagePipeline.fromBytes(
      _png(
        width: 1,
        height: 1,
        bitDepth: 16,
        colorType: 6,
        samples: const <int>[0x1234, 0x8080, 0xffff, 0x4000],
      ),
    ).toPixelImage();

    expect(image.firstFrameBytes(), <int>[18, 128, 255, 64]);
  });

  test('applies grayscale PNG transparency chunks', () async {
    final image = await ImagePipeline.fromBytes(
      _png(
        width: 3,
        height: 1,
        bitDepth: 8,
        colorType: 0,
        samples: const <int>[0, 128, 255],
        transparentSamples: const <int>[128],
      ),
    ).toPixelImage();

    expect(image.firstFrameBytes(), <int>[
      0,
      0,
      0,
      255,
      128,
      128,
      128,
      0,
      255,
      255,
      255,
      255,
    ]);
  });

  test('applies low-bit grayscale PNG transparency chunks', () async {
    final image = await ImagePipeline.fromBytes(
      _png(
        width: 4,
        height: 1,
        bitDepth: 2,
        colorType: 0,
        samples: const <int>[0, 1, 2, 3],
        transparentSamples: const <int>[2],
      ),
    ).toPixelImage();

    expect(image.firstFrameBytes(), <int>[
      0,
      0,
      0,
      255,
      85,
      85,
      85,
      255,
      170,
      170,
      170,
      0,
      255,
      255,
      255,
      255,
    ]);
  });

  test('applies truecolour PNG transparency chunks', () async {
    final image = await ImagePipeline.fromBytes(
      _png(
        width: 2,
        height: 1,
        bitDepth: 16,
        colorType: 2,
        samples: const <int>[0xffff, 0, 0, 0x1234, 0x5678, 0x9abc],
        transparentSamples: const <int>[0x1234, 0x5678, 0x9abc],
      ),
    ).toPixelImage();

    expect(image.firstFrameBytes(), <int>[255, 0, 0, 255, 18, 86, 154, 0]);
  });

  test('rejects malformed PNG containers with typed errors', () async {
    final scanline = zlibEncodeStored(Uint8List.fromList(<int>[0, 0]));
    final cases = <Uint8List>[
      _withLastByteFlipped(
        _png(
          width: 1,
          height: 1,
          bitDepth: 8,
          colorType: 0,
          samples: const <int>[0],
        ),
      ),
      _pngChunks(<(String, List<int>)>[
        ('IHDR', _ihdrData(1, 1).sublist(0, 12)),
        ('IDAT', scanline),
        ('IEND', const <int>[]),
      ]),
      _pngChunks(<(String, List<int>)>[
        ('IDAT', scanline),
        ('IEND', const <int>[]),
      ]),
      _pngChunks(<(String, List<int>)>[
        ('IHDR', _ihdrData(1, 1, colorType: 3)),
        ('IDAT', scanline),
        ('IEND', const <int>[]),
      ]),
      _pngChunks(<(String, List<int>)>[
        ('IHDR', _ihdrData(1, 1, colorType: 3)),
        ('PLTE', const <int>[0, 0]),
        ('IDAT', scanline),
        ('IEND', const <int>[]),
      ]),
      _withoutIend(
        _png(
          width: 1,
          height: 1,
          bitDepth: 8,
          colorType: 0,
          samples: const <int>[0],
        ),
      ),
      _pngChunks(<(String, List<int>)>[
        ('IHDR', _ihdrData(1, 1)),
        ('IDAT', zlibEncodeStored(Uint8List.fromList(<int>[0]))),
        ('IEND', const <int>[]),
      ]),
    ];

    for (final bytes in cases) {
      await expectLater(
        ImagePipeline.fromBytes(bytes).toPixelImage(),
        throwsA(isA<InvalidImageException>()),
      );
    }
  });
}

Uint8List _png({
  required int width,
  required int height,
  required int bitDepth,
  required int colorType,
  required List<int> samples,
  List<int>? transparentSamples,
}) {
  final channels = switch (colorType) {
    0 => 1,
    2 => 3,
    4 => 2,
    6 => 4,
    _ => throw ArgumentError.value(colorType, 'colorType'),
  };
  final raw = ByteWriter();
  var sample = 0;
  for (var y = 0; y < height; y += 1) {
    raw.writeByte(0);
    if (bitDepth < 8) {
      var current = 0;
      var bits = 0;
      final mask = (1 << bitDepth) - 1;
      for (var x = 0; x < width * channels; x += 1) {
        current = (current << bitDepth) | (samples[sample++] & mask);
        bits += bitDepth;
        if (bits == 8) {
          raw.writeByte(current);
          current = 0;
          bits = 0;
        }
      }
      if (bits > 0) {
        raw.writeByte(current << (8 - bits));
      }
    } else {
      for (var x = 0; x < width * channels; x += 1) {
        if (bitDepth == 16) {
          raw.writeUint16Be(samples[sample++]);
        } else {
          raw.writeByte(samples[sample++]);
        }
      }
    }
  }
  final writer = ByteWriter()
    ..writeBytes(const <int>[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  final ihdr = ByteWriter()
    ..writeUint32Be(width)
    ..writeUint32Be(height)
    ..writeByte(bitDepth)
    ..writeByte(colorType)
    ..writeByte(0)
    ..writeByte(0)
    ..writeByte(0);
  _writeChunk(writer, 'IHDR', ihdr.toBytes());
  if (transparentSamples != null) {
    final trns = ByteWriter();
    for (final sample in transparentSamples) {
      trns.writeUint16Be(sample);
    }
    _writeChunk(writer, 'tRNS', trns.toBytes());
  }
  _writeChunk(writer, 'IDAT', zlibEncodeStored(raw.toBytes()));
  _writeChunk(writer, 'IEND', Uint8List(0));
  return writer.toBytes();
}

Uint8List _pngHeaderOnly({required int width, required int height}) {
  final writer = ByteWriter()
    ..writeBytes(const <int>[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  final ihdr = ByteWriter()
    ..writeUint32Be(width)
    ..writeUint32Be(height)
    ..writeByte(8)
    ..writeByte(6)
    ..writeByte(0)
    ..writeByte(0)
    ..writeByte(0);
  _writeChunk(writer, 'IHDR', ihdr.toBytes());
  _writeChunk(writer, 'IEND', Uint8List(0));
  return writer.toBytes();
}

Uint8List _pngChunks(List<(String, List<int>)> chunks) {
  final writer = ByteWriter()
    ..writeBytes(const <int>[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  for (final (type, data) in chunks) {
    _writeChunk(writer, type, Uint8List.fromList(data));
  }
  return writer.toBytes();
}

List<int> _ihdrData(
  int width,
  int height, {
  int bitDepth = 8,
  int colorType = 0,
}) {
  return (ByteWriter()
        ..writeUint32Be(width)
        ..writeUint32Be(height)
        ..writeByte(bitDepth)
        ..writeByte(colorType)
        ..writeByte(0)
        ..writeByte(0)
        ..writeByte(0))
      .toBytes();
}

Uint8List _withoutIend(Uint8List bytes) {
  return Uint8List.fromList(bytes.sublist(0, bytes.length - 12));
}

Uint8List _withLastByteFlipped(Uint8List bytes) {
  final copy = Uint8List.fromList(bytes);
  copy[copy.length - 1] ^= 0xff;
  return copy;
}

void _writeChunk(ByteWriter writer, String type, Uint8List data) {
  final typeBytes = ascii.encode(type);
  writer
    ..writeUint32Be(data.length)
    ..writeBytes(typeBytes)
    ..writeBytes(data)
    ..writeUint32Be(crc32(<int>[...typeBytes, ...data]));
}
