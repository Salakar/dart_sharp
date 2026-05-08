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
}

Uint8List _lzwPredictorTiff() {
  final compressed = _lzwLiteralBytes(<int>[10, 20, 30, 5, 5, 5]);
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

  const entryCount = 11;
  const ifdOffset = 8;
  const bitsOffset = ifdOffset + 2 + entryCount * 12 + 4;
  const stripOffset = bitsOffset + 6;
  bytes.addAll(<int>[0x49, 0x49]);
  u16(42);
  u32(ifdOffset);
  u16(entryCount);
  entry(256, 4, 1, 2);
  entry(257, 4, 1, 1);
  entry(258, 3, 3, bitsOffset);
  entry(259, 3, 1, 5);
  entry(262, 3, 1, 2);
  entry(273, 4, 1, stripOffset);
  entry(277, 3, 1, 3);
  entry(278, 4, 1, 1);
  entry(279, 4, 1, compressed.length);
  entry(284, 3, 1, 1);
  entry(317, 3, 1, 2);
  u32(0);
  bytes.addAll(<int>[8, 0, 8, 0, 8, 0]);
  bytes.addAll(compressed);
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
