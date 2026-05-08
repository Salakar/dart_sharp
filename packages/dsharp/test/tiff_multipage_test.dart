import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

void main() {
  test('decodes matching-size multi-page TIFF frames', () async {
    final bytes = _twoPageGrayTiff();
    final image = await ImagePipeline.fromBytes(bytes).toPixelImage();
    final metadata = await ImagePipeline.fromBytes(bytes).metadata();

    expect(image.isAnimated, isTrue);
    expect(image.frames.length, 2);
    expect(metadata.frames, 2);
    expect(image.frames[0].pixels.bytes, _rgbaGray(<int>[10]));
    expect(image.frames[1].pixels.bytes, _rgbaGray(<int>[240]));
  });
}

Uint8List _twoPageGrayTiff() {
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

  void ifd(int nextIfd, int stripOffset) {
    u16(10);
    entry(256, 4, 1, 1);
    entry(257, 4, 1, 1);
    entry(258, 3, 1, 8);
    entry(259, 3, 1, 1);
    entry(262, 3, 1, 1);
    entry(273, 4, 1, stripOffset);
    entry(277, 3, 1, 1);
    entry(278, 4, 1, 1);
    entry(279, 4, 1, 1);
    entry(284, 3, 1, 1);
    u32(nextIfd);
  }

  const firstIfd = 8;
  const ifdSize = 2 + 10 * 12 + 4;
  const secondIfd = firstIfd + ifdSize;
  const firstStrip = secondIfd + ifdSize;
  const secondStrip = firstStrip + 1;
  bytes.addAll(<int>[0x49, 0x49]);
  u16(42);
  u32(firstIfd);
  ifd(secondIfd, firstStrip);
  ifd(0, secondStrip);
  bytes
    ..add(10)
    ..add(240);
  return Uint8List.fromList(bytes);
}

List<int> _rgbaGray(List<int> values) {
  return <int>[
    for (final value in values) ...<int>[value, value, value, 255],
  ];
}
