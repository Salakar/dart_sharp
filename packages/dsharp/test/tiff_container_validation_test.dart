import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

void main() {
  test('rejects malformed TIFF IFD offsets with typed errors', () async {
    final cases = <Uint8List>[
      _tiffHeader(2),
      _tiffHeader(99),
      Uint8List.fromList(<int>[..._tiffHeader(8), 1, 0, 0, 0]),
      _minimalGrayTiff(nextIfdOffset: 8),
      _minimalGrayTiff(nextIfdOffset: 999),
    ];
    for (final bytes in cases) {
      await expectLater(
        ImagePipeline.fromBytes(bytes).toPixelImage(),
        throwsA(isA<InvalidImageException>()),
      );
    }
  });
}

Uint8List _tiffHeader(int ifdOffset) {
  final bytes = <int>[0x49, 0x49];
  _u16(bytes, 42);
  _u32(bytes, ifdOffset);
  return Uint8List.fromList(bytes);
}

Uint8List _minimalGrayTiff({required int nextIfdOffset}) {
  final bytes = _tiffHeader(8).toList();
  const entries = 6;
  final pixelOffset = 8 + 2 + entries * 12 + 4;
  _u16(bytes, entries);
  _entry(bytes, 256, 4, 1, 1);
  _entry(bytes, 257, 4, 1, 1);
  _entry(bytes, 259, 3, 1, 1);
  _entry(bytes, 262, 3, 1, 1);
  _entry(bytes, 273, 4, 1, pixelOffset);
  _entry(bytes, 279, 4, 1, 1);
  _u32(bytes, nextIfdOffset);
  bytes.add(0);
  return Uint8List.fromList(bytes);
}

void _entry(List<int> bytes, int tag, int type, int count, int value) {
  _u16(bytes, tag);
  _u16(bytes, type);
  _u32(bytes, count);
  if (type == 3 && count == 1) {
    _u16(bytes, value);
    _u16(bytes, 0);
  } else {
    _u32(bytes, value);
  }
}

void _u16(List<int> bytes, int value) {
  bytes
    ..add(value & 0xff)
    ..add((value >> 8) & 0xff);
}

void _u32(List<int> bytes, int value) {
  bytes
    ..add(value & 0xff)
    ..add((value >> 8) & 0xff)
    ..add((value >> 16) & 0xff)
    ..add((value >> 24) & 0xff);
}
