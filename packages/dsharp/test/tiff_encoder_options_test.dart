import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:dsharp/src/codecs/binary_io.dart';
import 'package:test/test.dart';

void main() {
  test('TIFF encoder writes LZW and Deflate compression', () async {
    final raw = _raw();

    for (final entry in <(TiffCompression, int)>[
      (TiffCompression.lzw, 5),
      (TiffCompression.deflate, 8),
    ]) {
      final encoded = await ImagePipeline.fromRawPixels(
        raw,
      ).tiff(TiffEncoderOptions(compression: entry.$1)).toBytes();
      final decoded = await ImagePipeline.fromBytes(encoded).toPixelImage();

      expect(_tiffShortTagValue(encoded, 259), entry.$2);
      expect(decoded.firstFrameBytes(), raw.bytes);
    }
  });
}

RawPixels _raw() {
  return RawPixels(
    bytes: Uint8List.fromList(<int>[
      for (final rgba in <List<int>>[
        <int>[0, 10, 20, 255],
        <int>[40, 50, 60, 255],
        <int>[80, 90, 100, 255],
        <int>[120, 130, 140, 255],
      ])
        ...rgba,
    ]),
    width: 4,
    height: 1,
    channels: ChannelCount.four,
  );
}

int _tiffShortTagValue(Uint8List bytes, int tag) {
  final ifdOffset = readUint32Le(bytes, 4);
  final count = readUint16Le(bytes, ifdOffset);
  for (var i = 0; i < count; i += 1) {
    final entry = ifdOffset + 2 + i * 12;
    if (readUint16Le(bytes, entry) == tag) {
      return readUint16Le(bytes, entry + 8);
    }
  }
  throw StateError('Missing TIFF tag $tag.');
}
