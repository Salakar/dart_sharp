import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:dsharp/src/codecs/binary_io.dart';
import 'package:test/test.dart';

void main() {
  test('decodes minimal lossless JPEG pixels', () async {
    final image = await ImagePipeline.fromBytes(_losslessJpeg()).toPixelImage();

    expect(image.width, 1);
    expect(image.height, 1);
    expect(image.firstFrameBytes(), <int>[128, 128, 128, 255]);
  });
}

Uint8List _losslessJpeg() {
  final writer = ByteWriter()
    ..writeByte(0xff)
    ..writeByte(0xd8);
  _segment(
    writer,
    0xc3,
    Uint8List.fromList(<int>[
      8,
      0,
      1,
      0,
      1,
      3,
      1,
      0x11,
      0,
      2,
      0x11,
      0,
      3,
      0x11,
      0,
    ]),
  );
  _segment(
    writer,
    0xc4,
    Uint8List.fromList(<int>[
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
    ]),
  );
  _segment(
    writer,
    0xda,
    Uint8List.fromList(<int>[3, 1, 0, 2, 0, 3, 0, 1, 0, 0]),
  );
  writer
    ..writeByte(0x1f)
    ..writeByte(0xff)
    ..writeByte(0xd9);
  return writer.toBytes();
}

void _segment(ByteWriter writer, int marker, Uint8List data) {
  writer
    ..writeByte(0xff)
    ..writeByte(marker)
    ..writeUint16Be(data.length + 2)
    ..writeBytes(data);
}
