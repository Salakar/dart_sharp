part of 'tiff_codec.dart';

RawPixels _decodeJpegCompressedTiff(
  Uint8List bytes,
  _Ifd tags,
  int width,
  int height,
) {
  final offsets = tags.values(273);
  final byteCounts = tags.values(279);
  if (offsets.isEmpty || offsets.length != byteCounts.length) {
    throw const InvalidImageException('Invalid TIFF strip layout.');
  }
  final rowsPerStrip = tags.value(278, fallback: height);
  final tables = tags.byteValues(347, fallback: Uint8List(0));
  final output = Uint8List(width * height * 4);
  var destY = 0;
  for (var i = 0; i < offsets.length; i += 1) {
    final offset = offsets[i];
    final byteCount = byteCounts[i];
    if (offset + byteCount > bytes.length) {
      throw const InvalidImageException('Truncated TIFF strip.');
    }
    final strip = Uint8List.sublistView(bytes, offset, offset + byteCount);
    final decoded = decodeJpegBytes(_assembleTiffJpeg(tables, strip));
    if (decoded.width != width) {
      throw const InvalidImageException('Invalid TIFF JPEG strip dimensions.');
    }
    final rows = math.min(
      math.min(rowsPerStrip, decoded.height),
      height - destY,
    );
    for (var row = 0; row < rows; row += 1) {
      final srcStart = row * width * 4;
      final dstStart = (destY + row) * width * 4;
      output.setRange(dstStart, dstStart + width * 4, decoded.bytes, srcStart);
    }
    destY += rows;
  }
  if (destY < height) {
    throw const InvalidImageException('Truncated TIFF JPEG strips.');
  }
  return RawPixels(
    bytes: output,
    width: width,
    height: height,
    channels: ChannelCount.four,
  );
}

Uint8List _assembleTiffJpeg(Uint8List tables, Uint8List strip) {
  if (!_startsWithJpegSoi(strip)) {
    throw const InvalidImageException('Invalid TIFF JPEG strip.');
  }
  final output = <int>[0xff, 0xd8];
  if (tables.isNotEmpty) {
    final tableStart = _startsWithJpegSoi(tables) ? 2 : 0;
    final tableEnd = _endsWithJpegEoi(tables)
        ? tables.length - 2
        : tables.length;
    output.addAll(tables.sublist(tableStart, tableEnd));
  }
  output.addAll(strip.sublist(2));
  return Uint8List.fromList(output);
}

bool _startsWithJpegSoi(Uint8List bytes) {
  return bytes.length >= 2 && bytes[0] == 0xff && bytes[1] == 0xd8;
}

bool _endsWithJpegEoi(Uint8List bytes) {
  return bytes.length >= 2 &&
      bytes[bytes.length - 2] == 0xff &&
      bytes[bytes.length - 1] == 0xd9;
}
