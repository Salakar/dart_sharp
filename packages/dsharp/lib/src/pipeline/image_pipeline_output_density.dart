part of 'image_pipeline.dart';

Uint8List _writePngDensity(Uint8List bytes, double density) {
  if (bytes.length < 33 || !_hasPngSignature(bytes)) {
    throw const InvalidImageException('Invalid PNG signature.');
  }
  final writer = ByteWriter()..writeBytes(bytes.sublist(0, 8));
  var offset = 8;
  var inserted = false;
  while (offset + 12 <= bytes.length) {
    final length = readUint32Be(bytes, offset);
    final type = ascii.decode(bytes.sublist(offset + 4, offset + 8));
    final dataStart = offset + 8;
    final dataEnd = dataStart + length;
    if (dataEnd + 4 > bytes.length) {
      throw const InvalidImageException('Truncated PNG chunk.');
    }
    final chunkEnd = dataEnd + 4;
    if (type == 'pHYs') {
      offset = chunkEnd;
      continue;
    }
    if ((type == 'IDAT' || type == 'IEND') && !inserted) {
      _writePngChunk(writer, 'pHYs', _pngDensityData(density));
      inserted = true;
    }
    writer.writeBytes(bytes.sublist(offset, chunkEnd));
    offset = chunkEnd;
    if (type == 'IEND') {
      break;
    }
  }
  if (!inserted) {
    throw const InvalidImageException('PNG missing image data.');
  }
  return writer.toBytes();
}

Uint8List _pngDensityData(double density) {
  final pixelsPerMeter = (density / 0.0254).round();
  final writer = ByteWriter()
    ..writeUint32Be(pixelsPerMeter)
    ..writeUint32Be(pixelsPerMeter)
    ..writeByte(1);
  return writer.toBytes();
}

Uint8List _writeJpegDensity(Uint8List bytes, double density) {
  if (bytes.length < 4 || bytes[0] != 0xff || bytes[1] != 0xd8) {
    throw const InvalidImageException('Invalid JPEG signature.');
  }
  final writer = ByteWriter()
    ..writeByte(0xff)
    ..writeByte(0xd8);
  _writeJpegJfifSegment(writer, density);
  var offset = 2;
  while (offset < bytes.length) {
    if (bytes[offset] != 0xff) {
      throw const InvalidImageException('Invalid JPEG marker.');
    }
    final markerStart = offset;
    while (offset < bytes.length && bytes[offset] == 0xff) {
      offset += 1;
    }
    if (offset >= bytes.length) {
      break;
    }
    final marker = bytes[offset];
    offset += 1;
    if (marker == 0xda || marker == 0xd9) {
      writer.writeBytes(bytes.sublist(markerStart));
      break;
    }
    if (_jpegStandaloneMarker(marker)) {
      writer.writeBytes(bytes.sublist(markerStart, offset));
      continue;
    }
    if (offset + 2 > bytes.length) {
      throw const InvalidImageException('Truncated JPEG marker.');
    }
    final length = readUint16Be(bytes, offset);
    final segmentEnd = offset + length;
    if (length < 2 || segmentEnd > bytes.length) {
      throw const InvalidImageException('Invalid JPEG marker length.');
    }
    final data = bytes.sublist(offset + 2, segmentEnd);
    if (marker != 0xe0 || !_isJpegJfifData(data)) {
      writer.writeBytes(bytes.sublist(markerStart, segmentEnd));
    }
    offset = segmentEnd;
  }
  return writer.toBytes();
}

void _writeJpegJfifSegment(ByteWriter writer, double density) {
  final dpi = density.round().clamp(1, 0xffff).toInt();
  final payload = Uint8List.fromList(<int>[
    ...ascii.encode('JFIF'),
    0,
    1,
    1,
    1,
    dpi >> 8,
    dpi & 0xff,
    dpi >> 8,
    dpi & 0xff,
    0,
    0,
  ]);
  writer
    ..writeByte(0xff)
    ..writeByte(0xe0)
    ..writeUint16Be(payload.length + 2)
    ..writeBytes(payload);
}

bool _isJpegJfifData(Uint8List data) {
  const header = 'JFIF';
  if (data.length < 12 || data[4] != 0) {
    return false;
  }
  for (var i = 0; i < header.length; i += 1) {
    if (data[i] != header.codeUnitAt(i)) {
      return false;
    }
  }
  return true;
}
