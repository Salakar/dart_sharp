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
    expect(metadata.hasExif, isTrue);
    expect(metadata.hasXmp, isTrue);
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
    expect(metadata.hasExif, isTrue);
    expect(metadata.hasXmp, isTrue);
    expect(metadata.orientation, 6);
  });

  test('rejects WebP metadata without image payload', () async {
    await expectLater(
      ImagePipeline.fromBytes(_webpHeaderOnlyBytes()).metadata(),
      throwsA(isA<InvalidImageException>()),
    );
  });

  test('rejects WebP metadata with duplicate image chunks', () async {
    await expectLater(
      ImagePipeline.fromBytes(_duplicateWebpImageBytes()).metadata(),
      throwsA(isA<InvalidImageException>()),
    );
  });

  test('rejects WebP with truncated RIFF payload size', () async {
    final bytes = solidVp8lWebp(
      width: 1,
      height: 1,
      red: 1,
      green: 2,
      blue: 3,
      alpha: 255,
    );
    final malformed = _webpWithDeclaredLength(bytes, bytes.length - 7);

    await expectLater(
      ImagePipeline.fromBytes(malformed).metadata(),
      throwsA(isA<InvalidImageException>()),
    );
    await expectLater(
      ImagePipeline.fromBytes(malformed).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
  });

  test('rejects WebP with trailing partial top-level chunk', () async {
    final bytes = solidVp8lWebp(
      width: 1,
      height: 1,
      red: 1,
      green: 2,
      blue: 3,
      alpha: 255,
    );
    final malformed = Uint8List(bytes.length + 1)
      ..setAll(0, bytes)
      ..[bytes.length] = 0xff;

    await expectLater(
      ImagePipeline.fromBytes(
        _webpWithDeclaredLength(malformed, malformed.length - 8),
      ).metadata(),
      throwsA(isA<InvalidImageException>()),
    );
  });

  test('rejects malformed WebP animation metadata chunks', () async {
    await expectLater(
      ImagePipeline.fromBytes(_truncatedWebpAnimBytes()).metadata(),
      throwsA(isA<InvalidImageException>()),
    );
  });

  test('rejects malformed WebP frame metadata chunks', () async {
    await expectLater(
      ImagePipeline.fromBytes(_truncatedWebpAnmfBytes()).metadata(),
      throwsA(isA<InvalidImageException>()),
    );
  });

  test('rejects WebP frame metadata outside canvas', () async {
    await expectLater(
      ImagePipeline.fromBytes(_outOfBoundsWebpFrameBytes()).metadata(),
      throwsA(isA<InvalidImageException>()),
    );
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
  _jpegSegment(writer, 0xe1, <int>[
    ...ascii.encode('http://ns.adobe.com/xap/1.0/'),
    0,
    ...utf8.encode('<x:xmpmeta />'),
  ]);
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

Uint8List _webpHeaderOnlyBytes() {
  final content = ByteWriter()
    ..writeAscii('WEBP')
    ..writeAscii('VP8X')
    ..writeUint32Le(10)
    ..writeByte(0)
    ..writeByte(0)
    ..writeByte(0)
    ..writeByte(0);
  _writeUint24Le(content, 0);
  _writeUint24Le(content, 0);
  final writer = ByteWriter()
    ..writeAscii('RIFF')
    ..writeUint32Le(content.length)
    ..writeBytes(content.toBytes());
  return writer.toBytes();
}

Uint8List _duplicateWebpImageBytes() {
  final content = ByteWriter()..writeAscii('WEBP');
  final vp8l = ByteWriter()
    ..writeByte(0x2f)
    ..writeUint32Le(0);
  _riffChunk(content, 'VP8L', vp8l.toBytes());
  _riffChunk(content, 'VP8L', vp8l.toBytes());
  final writer = ByteWriter()
    ..writeAscii('RIFF')
    ..writeUint32Le(content.length)
    ..writeBytes(content.toBytes());
  return writer.toBytes();
}

Uint8List _webpWithDeclaredLength(Uint8List bytes, int length) {
  final out = Uint8List.fromList(bytes);
  out[4] = length & 0xff;
  out[5] = (length >> 8) & 0xff;
  out[6] = (length >> 16) & 0xff;
  out[7] = (length >> 24) & 0xff;
  return out;
}

Uint8List _truncatedWebpAnimBytes() {
  final content = ByteWriter()
    ..writeAscii('WEBP')
    ..writeAscii('VP8X')
    ..writeUint32Le(10)
    ..writeByte(0x02)
    ..writeByte(0)
    ..writeByte(0)
    ..writeByte(0);
  _writeUint24Le(content, 0);
  _writeUint24Le(content, 0);
  _riffChunk(content, 'ANIM', <int>[0, 0, 0, 0, 1]);
  final vp8l = ByteWriter()..writeByte(0x2f);
  vp8l.writeUint32Le(0);
  _riffChunk(content, 'VP8L', vp8l.toBytes());
  final writer = ByteWriter()
    ..writeAscii('RIFF')
    ..writeUint32Le(content.length)
    ..writeBytes(content.toBytes());
  return writer.toBytes();
}

Uint8List _truncatedWebpAnmfBytes() {
  final content = ByteWriter()
    ..writeAscii('WEBP')
    ..writeAscii('VP8X')
    ..writeUint32Le(10)
    ..writeByte(0x02)
    ..writeByte(0)
    ..writeByte(0)
    ..writeByte(0);
  _writeUint24Le(content, 0);
  _writeUint24Le(content, 0);
  _riffChunk(content, 'ANIM', <int>[0, 0, 0, 0, 1, 0]);
  final frame = ByteWriter();
  _writeUint24Le(frame, 0);
  _writeUint24Le(frame, 0);
  _writeUint24Le(frame, 0);
  _writeUint24Le(frame, 0);
  _writeUint24Le(frame, 1);
  frame
    ..writeByte(0)
    ..writeAscii('VP8L')
    ..writeUint32Le(5)
    ..writeByte(0x2f);
  _riffChunk(content, 'ANMF', frame.toBytes());
  final writer = ByteWriter()
    ..writeAscii('RIFF')
    ..writeUint32Le(content.length)
    ..writeBytes(content.toBytes());
  return writer.toBytes();
}

Uint8List _outOfBoundsWebpFrameBytes() {
  final content = ByteWriter()
    ..writeAscii('WEBP')
    ..writeAscii('VP8X')
    ..writeUint32Le(10)
    ..writeByte(0x02)
    ..writeByte(0)
    ..writeByte(0)
    ..writeByte(0);
  _writeUint24Le(content, 0);
  _writeUint24Le(content, 0);
  _riffChunk(content, 'ANIM', <int>[0, 0, 0, 0, 1, 0]);
  final frame = ByteWriter();
  _writeUint24Le(frame, 1);
  _writeUint24Le(frame, 0);
  _writeUint24Le(frame, 0);
  _writeUint24Le(frame, 0);
  _writeUint24Le(frame, 1);
  frame.writeByte(0);
  final vp8l = ByteWriter()
    ..writeByte(0x2f)
    ..writeUint32Le(0);
  _riffChunk(frame, 'VP8L', vp8l.toBytes());
  _riffChunk(content, 'ANMF', frame.toBytes());
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
