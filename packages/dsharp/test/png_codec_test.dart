import 'dart:convert';
import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:dsharp/src/codecs/binary_io.dart';
import 'package:dsharp/src/codecs/deflate_codec.dart';
import 'package:test/test.dart';

void main() {
  test('decodes 16-bit grayscale PNG samples', () async {
    final image = await ImagePipeline.fromBytes(
      _png16(
        width: 3,
        height: 1,
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
      _png16(
        width: 1,
        height: 1,
        colorType: 4,
        samples: const <int>[0x4000, 0x8080],
      ),
    ).toPixelImage();

    expect(image.firstFrameBytes(), <int>[64, 64, 64, 128]);
  });

  test('decodes 16-bit truecolour alpha PNG samples', () async {
    final image = await ImagePipeline.fromBytes(
      _png16(
        width: 1,
        height: 1,
        colorType: 6,
        samples: const <int>[0x1234, 0x8080, 0xffff, 0x4000],
      ),
    ).toPixelImage();

    expect(image.firstFrameBytes(), <int>[18, 128, 255, 64]);
  });
}

Uint8List _png16({
  required int width,
  required int height,
  required int colorType,
  required List<int> samples,
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
    for (var x = 0; x < width * channels; x += 1) {
      raw.writeUint16Be(samples[sample++]);
    }
  }
  final writer = ByteWriter()
    ..writeBytes(const <int>[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  final ihdr = ByteWriter()
    ..writeUint32Be(width)
    ..writeUint32Be(height)
    ..writeByte(16)
    ..writeByte(colorType)
    ..writeByte(0)
    ..writeByte(0)
    ..writeByte(0);
  _writeChunk(writer, 'IHDR', ihdr.toBytes());
  _writeChunk(writer, 'IDAT', zlibEncodeStored(raw.toBytes()));
  _writeChunk(writer, 'IEND', Uint8List(0));
  return writer.toBytes();
}

void _writeChunk(ByteWriter writer, String type, Uint8List data) {
  final typeBytes = ascii.encode(type);
  writer
    ..writeUint32Be(data.length)
    ..writeBytes(typeBytes)
    ..writeBytes(data)
    ..writeUint32Be(crc32(<int>[...typeBytes, ...data]));
}
