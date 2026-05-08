part of 'image_pipeline.dart';

Uint8List? _sourceExif(ImagePipeline pipeline) {
  if (pipeline.source case BytesImageSource(:final bytes)) {
    return switch (sniffImageFormat(bytes)) {
      ImageFormat.jpeg => _readJpegExif(bytes),
      ImageFormat.png => _readPngExif(bytes),
      ImageFormat.webp => _readWebpExif(bytes),
      _ => null,
    };
  }
  return null;
}

Uint8List _writePngExif(Uint8List bytes, Uint8List exif) {
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
    if (type == 'eXIf') {
      offset = chunkEnd;
      continue;
    }
    if ((type == 'IDAT' || type == 'IEND') && !inserted) {
      _writePngChunk(writer, 'eXIf', exif);
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

Uint8List? _readPngExif(Uint8List bytes) {
  if (bytes.length < 33 || !_hasPngSignature(bytes)) {
    return null;
  }
  var offset = 8;
  while (offset + 12 <= bytes.length) {
    final length = readUint32Be(bytes, offset);
    final type = ascii.decode(bytes.sublist(offset + 4, offset + 8));
    final dataStart = offset + 8;
    final dataEnd = dataStart + length;
    if (dataEnd + 4 > bytes.length) {
      return null;
    }
    if (type == 'eXIf') {
      return bytes.sublist(dataStart, dataEnd);
    }
    offset = dataEnd + 4;
  }
  return null;
}

Uint8List _writeWebpExif(Uint8List bytes, Uint8List exif) {
  final info = readWebpInfo(bytes);
  final riffEnd = _webpRiffEndForWrite(bytes);
  final content = ByteWriter()..writeAscii('WEBP');
  var offset = 12;
  var hasVp8x = false;
  var wroteExif = false;
  while (offset + 8 <= riffEnd) {
    final type = ascii.decode(bytes.sublist(offset, offset + 4));
    final length = readUint32Le(bytes, offset + 4);
    final start = offset + 8;
    final end = start + length;
    if (end > riffEnd) {
      throw const InvalidImageException('Truncated WebP chunk.');
    }
    final data = bytes.sublist(start, end);
    if (!hasVp8x && type != 'VP8X') {
      _writeWebpChunk(
        content,
        'VP8X',
        _webpVp8xPayload(info, exif: true, xmp: info.hasXmp),
      );
      _writeWebpChunk(content, 'EXIF', exif);
      wroteExif = true;
      hasVp8x = true;
    }
    if (type == 'VP8X') {
      hasVp8x = true;
      final vp8x = Uint8List.fromList(data);
      vp8x[0] |= 0x08;
      _writeWebpChunk(content, 'VP8X', vp8x);
      _writeWebpChunk(content, 'EXIF', exif);
      wroteExif = true;
    } else if (type != 'EXIF') {
      _writeWebpChunk(content, type, data);
    }
    offset = end + (length.isOdd ? 1 : 0);
  }
  if (offset != riffEnd) {
    throw const InvalidImageException('Truncated WebP chunk.');
  }
  if (!wroteExif) {
    _writeWebpChunk(
      content,
      'VP8X',
      _webpVp8xPayload(info, exif: true, xmp: info.hasXmp),
    );
    _writeWebpChunk(content, 'EXIF', exif);
  }
  final writer = ByteWriter()
    ..writeAscii('RIFF')
    ..writeUint32Le(content.length)
    ..writeBytes(content.toBytes());
  return writer.toBytes();
}

Uint8List? _readWebpExif(Uint8List bytes) {
  final riffEnd = _webpRiffEndForWrite(bytes);
  var offset = 12;
  while (offset + 8 <= riffEnd) {
    final type = ascii.decode(bytes.sublist(offset, offset + 4));
    final length = readUint32Le(bytes, offset + 4);
    final start = offset + 8;
    final end = start + length;
    if (end > riffEnd) {
      return null;
    }
    if (type == 'EXIF') {
      return _stripExifHeader(bytes.sublist(start, end));
    }
    offset = end + (length.isOdd ? 1 : 0);
  }
  return null;
}

Uint8List _writeJpegExif(Uint8List bytes, Uint8List exif) {
  if (bytes.length < 4 || bytes[0] != 0xff || bytes[1] != 0xd8) {
    throw const InvalidImageException('Invalid JPEG signature.');
  }
  final writer = ByteWriter()
    ..writeByte(0xff)
    ..writeByte(0xd8);
  _writeJpegExifSegment(writer, exif);
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
    if (marker != 0xe1 || !_isJpegExifData(data)) {
      writer.writeBytes(bytes.sublist(markerStart, segmentEnd));
    }
    offset = segmentEnd;
  }
  return writer.toBytes();
}

void _writeJpegExifSegment(ByteWriter writer, Uint8List exif) {
  final payload = Uint8List.fromList(<int>[
    ...ascii.encode('Exif'),
    0,
    0,
    ..._stripExifHeader(exif),
  ]);
  if (payload.length + 2 > 0xffff) {
    throw const OperationValidationException(
      'JPEG EXIF metadata is too large.',
    );
  }
  writer
    ..writeByte(0xff)
    ..writeByte(0xe1)
    ..writeUint16Be(payload.length + 2)
    ..writeBytes(payload);
}

Uint8List? _readJpegExif(Uint8List bytes) {
  if (bytes.length < 4 || bytes[0] != 0xff || bytes[1] != 0xd8) {
    return null;
  }
  var offset = 2;
  while (offset < bytes.length) {
    if (bytes[offset] != 0xff) {
      return null;
    }
    while (offset < bytes.length && bytes[offset] == 0xff) {
      offset += 1;
    }
    if (offset >= bytes.length) {
      return null;
    }
    final marker = bytes[offset];
    offset += 1;
    if (marker == 0xda || marker == 0xd9) {
      return null;
    }
    if (_jpegStandaloneMarker(marker)) {
      continue;
    }
    if (offset + 2 > bytes.length) {
      return null;
    }
    final length = readUint16Be(bytes, offset);
    final segmentEnd = offset + length;
    if (length < 2 || segmentEnd > bytes.length) {
      return null;
    }
    final data = bytes.sublist(offset + 2, segmentEnd);
    if (marker == 0xe1 && _isJpegExifData(data)) {
      return _stripExifHeader(data);
    }
    offset = segmentEnd;
  }
  return null;
}

Uint8List _stripExifHeader(Uint8List data) {
  if (data.length >= 6 &&
      data[0] == 0x45 &&
      data[1] == 0x78 &&
      data[2] == 0x69 &&
      data[3] == 0x66 &&
      data[4] == 0 &&
      data[5] == 0) {
    return data.sublist(6);
  }
  return data;
}

bool _isJpegExifData(Uint8List data) {
  return data.length > 6 &&
      data[0] == 0x45 &&
      data[1] == 0x78 &&
      data[2] == 0x69 &&
      data[3] == 0x66 &&
      data[4] == 0 &&
      data[5] == 0;
}
