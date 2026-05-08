part of 'image_pipeline.dart';

Uint8List? _sourceIcc(ImagePipeline pipeline) {
  if (pipeline.source case BytesImageSource(:final bytes)) {
    return switch (sniffImageFormat(bytes)) {
      ImageFormat.jpeg => _readJpegIcc(bytes),
      ImageFormat.png => _readPngIcc(bytes),
      ImageFormat.webp => _readWebpIcc(bytes),
      _ => null,
    };
  }
  return null;
}

Uint8List _writePngIcc(Uint8List bytes, Uint8List icc) {
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
    if (type == 'iCCP') {
      offset = chunkEnd;
      continue;
    }
    if ((type == 'IDAT' || type == 'IEND') && !inserted) {
      _writePngChunk(writer, 'iCCP', _pngIccData(icc));
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

Uint8List _pngIccData(Uint8List icc) {
  return Uint8List.fromList(<int>[
    ...ascii.encode('ICC'),
    0,
    0,
    ...zlibEncodeStored(icc),
  ]);
}

Uint8List? _readPngIcc(Uint8List bytes) {
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
    final data = bytes.sublist(dataStart, dataEnd);
    if (type == 'iCCP') {
      final methodOffset = _skipNullTerminated(data, 0);
      if (methodOffset < 0 ||
          methodOffset >= data.length ||
          data[methodOffset] != 0) {
        return null;
      }
      try {
        return zlibDecode(data.sublist(methodOffset + 1));
      } on ImageProcessingException {
        return null;
      }
    }
    offset = dataEnd + 4;
  }
  return null;
}

Uint8List _writeWebpIcc(Uint8List bytes, Uint8List icc) {
  final info = readWebpInfo(bytes);
  final riffEnd = _webpRiffEndForWrite(bytes);
  final content = ByteWriter()..writeAscii('WEBP');
  var offset = 12;
  var hasVp8x = false;
  var wroteIcc = false;
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
        _webpVp8xPayload(
          info,
          profile: true,
          exif: info.hasExif,
          xmp: info.hasXmp,
        ),
      );
      _writeWebpChunk(content, 'ICCP', icc);
      wroteIcc = true;
      hasVp8x = true;
    }
    if (type == 'VP8X') {
      hasVp8x = true;
      final vp8x = Uint8List.fromList(data);
      vp8x[0] |= 0x20;
      _writeWebpChunk(content, 'VP8X', vp8x);
      _writeWebpChunk(content, 'ICCP', icc);
      wroteIcc = true;
    } else if (type != 'ICCP') {
      _writeWebpChunk(content, type, data);
    }
    offset = end + (length.isOdd ? 1 : 0);
  }
  if (offset != riffEnd) {
    throw const InvalidImageException('Truncated WebP chunk.');
  }
  if (!wroteIcc) {
    _writeWebpChunk(
      content,
      'VP8X',
      _webpVp8xPayload(
        info,
        profile: true,
        exif: info.hasExif,
        xmp: info.hasXmp,
      ),
    );
    _writeWebpChunk(content, 'ICCP', icc);
  }
  final writer = ByteWriter()
    ..writeAscii('RIFF')
    ..writeUint32Le(content.length)
    ..writeBytes(content.toBytes());
  return writer.toBytes();
}

Uint8List? _readWebpIcc(Uint8List bytes) {
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
    if (type == 'ICCP') {
      return bytes.sublist(start, end);
    }
    offset = end + (length.isOdd ? 1 : 0);
  }
  return null;
}

Uint8List _writeJpegIcc(Uint8List bytes, Uint8List icc) {
  if (bytes.length < 4 || bytes[0] != 0xff || bytes[1] != 0xd8) {
    throw const InvalidImageException('Invalid JPEG signature.');
  }
  final writer = ByteWriter()
    ..writeByte(0xff)
    ..writeByte(0xd8);
  _writeJpegIccSegments(writer, icc);
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
    if (marker != 0xe2 || !_isJpegIccData(data)) {
      writer.writeBytes(bytes.sublist(markerStart, segmentEnd));
    }
    offset = segmentEnd;
  }
  return writer.toBytes();
}

void _writeJpegIccSegments(ByteWriter writer, Uint8List icc) {
  const maxChunk = 65519;
  final count = icc.isEmpty ? 1 : (icc.length + maxChunk - 1) ~/ maxChunk;
  if (count > 255) {
    throw const OperationValidationException('JPEG ICC profile is too large.');
  }
  for (var i = 0; i < count; i += 1) {
    final start = i * maxChunk;
    final end = start + maxChunk > icc.length ? icc.length : start + maxChunk;
    final payload = Uint8List.fromList(<int>[
      ...ascii.encode('ICC_PROFILE'),
      0,
      i + 1,
      count,
      ...icc.sublist(start, end),
    ]);
    writer
      ..writeByte(0xff)
      ..writeByte(0xe2)
      ..writeUint16Be(payload.length + 2)
      ..writeBytes(payload);
  }
}

Uint8List? _readJpegIcc(Uint8List bytes) {
  if (bytes.length < 4 || bytes[0] != 0xff || bytes[1] != 0xd8) {
    return null;
  }
  final chunks = <int, Uint8List>{};
  int? expectedCount;
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
      break;
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
    if (marker == 0xe2 && _isJpegIccData(data)) {
      final sequence = data[12];
      final count = data[13];
      if (sequence == 0 ||
          count == 0 ||
          sequence > count ||
          chunks.containsKey(sequence) ||
          expectedCount != null && expectedCount != count) {
        return null;
      }
      expectedCount = count;
      chunks[sequence] = data.sublist(14);
    }
    offset = segmentEnd;
  }
  final count = expectedCount;
  if (count == null || chunks.length != count) {
    return null;
  }
  final writer = ByteWriter();
  for (var i = 1; i <= count; i += 1) {
    final chunk = chunks[i];
    if (chunk == null) {
      return null;
    }
    writer.writeBytes(chunk);
  }
  return writer.toBytes();
}

bool _isJpegIccData(Uint8List data) {
  const header = 'ICC_PROFILE';
  if (data.length < header.length + 3 || data[header.length] != 0) {
    return false;
  }
  for (var i = 0; i < header.length; i += 1) {
    if (data[i] != header.codeUnitAt(i)) {
      return false;
    }
  }
  return true;
}
