import 'dart:convert';
import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:dsharp/src/codecs/binary_io.dart';
import 'package:test/test.dart';

import 'helpers/webp_lossless_fixture.dart';

void main() {
  test('reads PNG header metadata without pixel data', () async {
    final metadata = await ImagePipeline.fromBytes(
      _pngMetadataBytes(),
    ).metadata();

    expect(metadata.format, ImageFormat.png);
    expect(metadata.width, 3);
    expect(metadata.height, 2);
    expect(metadata.channels, 4);
    expect(metadata.hasAlpha, isTrue);
    expect(metadata.bitDepth, 16);
    expect(metadata.density, closeTo(300, 0.05));
    expect(metadata.hasProfile, isTrue);
    expect(metadata.isProgressive, isTrue);
  });

  test('reads JPEG frame and app marker metadata', () async {
    final metadata = await ImagePipeline.fromBytes(
      _jpegMetadataBytes(),
    ).metadata();

    expect(metadata.format, ImageFormat.jpeg);
    expect(metadata.width, 5);
    expect(metadata.height, 4);
    expect(metadata.channels, 3);
    expect(metadata.bitDepth, 8);
    expect(metadata.density, 72);
    expect(metadata.orientation, 6);
    expect(metadata.hasProfile, isTrue);
    expect(metadata.isProgressive, isTrue);
  });

  test('reads GIF animation metadata from headers', () async {
    final metadata = await ImagePipeline.fromBytes(
      _gifMetadataBytes(),
    ).metadata();

    expect(metadata.format, ImageFormat.gif);
    expect(metadata.width, 1);
    expect(metadata.height, 1);
    expect(metadata.frames, 2);
    expect(metadata.loopCount, 3);
    expect(metadata.hasAlpha, isTrue);
  });

  test('reads TIFF page metadata without strip data', () async {
    final metadata = await ImagePipeline.fromBytes(
      _tiffMetadataBytes(),
    ).metadata();

    expect(metadata.format, ImageFormat.tiff);
    expect(metadata.width, 3);
    expect(metadata.height, 2);
    expect(metadata.frames, 2);
    expect(metadata.pageHeight, 2);
    expect(metadata.channels, 3);
    expect(metadata.bitDepth, 8);
  });

  test('transformed WebP metadata reflects transformed pixels', () async {
    final bytes = solidVp8lWebp(
      width: 2,
      height: 2,
      red: 20,
      green: 40,
      blue: 60,
      alpha: 255,
    );

    final source = await ImagePipeline.fromBytes(bytes).metadata();
    final resized = await ImagePipeline.fromBytes(
      bytes,
    ).resize(const ResizeOptions(width: 1)).metadata();

    expect(source.width, 2);
    expect(source.height, 2);
    expect(resized.width, 1);
    expect(resized.height, 1);
  });

  test('reads WebP ICC and EXIF metadata from extended chunks', () async {
    final metadata = await ImagePipeline.fromBytes(
      _webpMetadataBytes(),
    ).metadata();

    expect(metadata.format, ImageFormat.webp);
    expect(metadata.width, 3);
    expect(metadata.height, 2);
    expect(metadata.hasProfile, isTrue);
    expect(metadata.orientation, 6);
  });
}

Uint8List _pngMetadataBytes() {
  final writer = ByteWriter()
    ..writeBytes(<int>[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  _pngChunk(writer, 'IHDR', <int>[0, 0, 0, 3, 0, 0, 0, 2, 16, 6, 0, 0, 1]);
  _pngChunk(writer, 'pHYs', <int>[0, 0, 0x2e, 0x23, 0, 0, 0x2e, 0x23, 1]);
  _pngChunk(writer, 'iCCP', <int>[...ascii.encode('test'), 0, 0, 1, 2, 3]);
  _pngChunk(writer, 'IEND', const <int>[]);
  return writer.toBytes();
}

Uint8List _jpegMetadataBytes() {
  final writer = ByteWriter()
    ..writeByte(0xff)
    ..writeByte(0xd8);
  _jpegSegment(writer, 0xe0, <int>[
    ...ascii.encode('JFIF'),
    0,
    1,
    2,
    1,
    0,
    72,
    0,
    72,
    0,
    0,
  ]);
  _jpegSegment(writer, 0xe1, _exifOrientation(6));
  _jpegSegment(writer, 0xe2, <int>[...ascii.encode('ICC_PROFILE'), 0, 1, 1, 0]);
  _jpegSegment(writer, 0xc2, <int>[
    8,
    0,
    4,
    0,
    5,
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
  ]);
  return (writer
        ..writeByte(0xff)
        ..writeByte(0xd9))
      .toBytes();
}

Uint8List _gifMetadataBytes() {
  final writer = ByteWriter()
    ..writeAscii('GIF89a')
    ..writeUint16Le(1)
    ..writeUint16Le(1)
    ..writeByte(0x80)
    ..writeByte(0)
    ..writeByte(0)
    ..writeBytes(<int>[0, 0, 0, 255, 255, 255])
    ..writeBytes(<int>[0x21, 0xff, 0x0b])
    ..writeAscii('NETSCAPE2.0')
    ..writeBytes(<int>[3, 1, 3, 0, 0]);
  _gifFrame(writer);
  _gifFrame(writer);
  return (writer..writeByte(0x3b)).toBytes();
}

Uint8List _tiffMetadataBytes() {
  const firstIfd = 8;
  const ifdSize = 2 + 5 * 12 + 4;
  final writer = ByteWriter()
    ..writeAscii('II')
    ..writeUint16Le(42)
    ..writeUint32Le(firstIfd);
  _writeIfd(writer, nextOffset: firstIfd + ifdSize);
  _writeIfd(writer, nextOffset: 0);
  return writer.toBytes();
}

void _pngChunk(ByteWriter writer, String type, List<int> data) {
  final typeBytes = ascii.encode(type);
  writer
    ..writeUint32Be(data.length)
    ..writeBytes(typeBytes)
    ..writeBytes(data)
    ..writeUint32Be(crc32(<int>[...typeBytes, ...data]));
}

Uint8List _webpMetadataBytes() {
  final content = ByteWriter()
    ..writeAscii('WEBP')
    ..writeAscii('VP8X')
    ..writeUint32Le(10)
    ..writeByte(0x2c)
    ..writeByte(0)
    ..writeByte(0)
    ..writeByte(0);
  _writeUint24Le(content, 2);
  _writeUint24Le(content, 1);
  _riffChunk(content, 'ICCP', <int>[1, 2, 3, 4]);
  _riffChunk(content, 'EXIF', _exifOrientation(6).sublist(6));
  _riffChunk(content, 'XMP ', utf8.encode('<x:xmpmeta />'));
  final vp8l = ByteWriter()..writeByte(0x2f);
  final bits = 2 | (1 << 14);
  vp8l.writeUint32Le(bits);
  _riffChunk(content, 'VP8L', vp8l.toBytes());
  final writer = ByteWriter()
    ..writeAscii('RIFF')
    ..writeUint32Le(content.length)
    ..writeBytes(content.toBytes());
  return writer.toBytes();
}

void _riffChunk(ByteWriter writer, String type, Iterable<int> data) {
  final payload = Uint8List.fromList(List<int>.from(data));
  writer
    ..writeAscii(type)
    ..writeUint32Le(payload.length)
    ..writeBytes(payload);
  if (payload.length.isOdd) {
    writer.writeByte(0);
  }
}

void _writeUint24Le(ByteWriter writer, int value) {
  writer
    ..writeByte(value)
    ..writeByte(value >> 8)
    ..writeByte(value >> 16);
}

void _jpegSegment(ByteWriter writer, int marker, List<int> data) {
  writer
    ..writeByte(0xff)
    ..writeByte(marker)
    ..writeUint16Be(data.length + 2)
    ..writeBytes(data);
}

Uint8List _exifOrientation(int orientation) {
  final writer = ByteWriter()
    ..writeAscii('Exif')
    ..writeUint16Be(0)
    ..writeAscii('II')
    ..writeUint16Le(42)
    ..writeUint32Le(8)
    ..writeUint16Le(1)
    ..writeUint16Le(0x0112)
    ..writeUint16Le(3)
    ..writeUint32Le(1)
    ..writeUint16Le(orientation)
    ..writeUint16Le(0)
    ..writeUint32Le(0);
  return writer.toBytes();
}

void _gifFrame(ByteWriter writer) {
  writer
    ..writeBytes(<int>[0x21, 0xf9, 4, 1, 0, 0, 0, 0])
    ..writeByte(0x2c)
    ..writeUint16Le(0)
    ..writeUint16Le(0)
    ..writeUint16Le(1)
    ..writeUint16Le(1)
    ..writeByte(0)
    ..writeBytes(<int>[2, 2, 0x44, 0x01, 0]);
}

void _writeIfd(ByteWriter writer, {required int nextOffset}) {
  writer.writeUint16Le(5);
  _tiffLong(writer, 256, 3);
  _tiffLong(writer, 257, 2);
  _tiffShort(writer, 258, 8);
  _tiffShort(writer, 262, 2);
  _tiffShort(writer, 277, 3);
  writer.writeUint32Le(nextOffset);
}

void _tiffShort(ByteWriter writer, int tag, int value) {
  writer
    ..writeUint16Le(tag)
    ..writeUint16Le(3)
    ..writeUint32Le(1)
    ..writeUint16Le(value)
    ..writeUint16Le(0);
}

void _tiffLong(ByteWriter writer, int tag, int value) {
  writer
    ..writeUint16Le(tag)
    ..writeUint16Le(4)
    ..writeUint32Le(1)
    ..writeUint32Le(value);
}
