part of 'image_pipeline.dart';

ImagePipeline _copyPipelineWith(
  ImagePipeline pipeline, {
  ImageFormat? outputFormat,
  bool clearOutputFormat = false,
  EncoderOptions? encoderOptions,
  bool clearEncoderOptions = false,
  Duration? timeout,
  bool clearTimeout = false,
  CancellationToken? cancellationToken,
  bool clearCancellationToken = false,
  MetadataWriteOptions? metadataWrites,
}) {
  return ImagePipeline._(
    source: pipeline.source,
    steps: pipeline._steps,
    outputFormat: clearOutputFormat
        ? null
        : outputFormat ?? pipeline._outputFormat,
    encoderOptions: clearEncoderOptions
        ? null
        : encoderOptions ?? pipeline._encoderOptions,
    timeout: clearTimeout ? null : timeout ?? pipeline._timeout,
    cancellationToken: clearCancellationToken
        ? null
        : cancellationToken ?? pipeline._cancellationToken,
    metadataWrites: metadataWrites ?? pipeline._metadataWrites,
  );
}

Future<T> _runWithTimeout<T>(ImagePipeline pipeline, Future<T> Function() run) {
  final timeout = pipeline._timeout;
  if (timeout == null) {
    return run();
  }
  return run().timeout(
    timeout,
    onTimeout: () {
      throw ImageCancellationException(
        'Image pipeline timed out after ${timeout.inMilliseconds} ms.',
      );
    },
  );
}

ImageFormat _resolveOutputFormat(
  ImagePipeline pipeline,
  ImageFormat? explicitFormat,
) {
  if (explicitFormat != null) {
    return explicitFormat;
  }
  final options = pipeline._encoderOptions;
  if (options != null) {
    options.validate();
    if (!options.force) {
      final sourceFormat = pipeline._sourceFormat();
      if (sourceFormat != ImageFormat.unknown &&
          sourceFormat != ImageFormat.raw) {
        return sourceFormat;
      }
    }
    return options.format;
  }
  return pipeline._outputFormat ?? ImageFormat.raw;
}

void _validateMetadataWrites(ImagePipeline pipeline) {
  final writes = pipeline._metadataWrites;
  if (!writes.isRequested || _isPngXmpOnlyWrite(writes)) {
    return;
  }
  throw const UnsupportedCodecException(
    'Only explicit XMP metadata writes are implemented for PNG output.',
  );
}

bool _isPngXmpOnlyWrite(MetadataWriteOptions writes) {
  return writes.xmp != null &&
      !writes.keepExif &&
      !writes.keepIcc &&
      !writes.keepXmp &&
      !writes.withMetadata;
}

EncodedImage _applyMetadataWrites(
  ImagePipeline pipeline,
  EncodedImage encoded,
) {
  final writes = pipeline._metadataWrites;
  if (!writes.isRequested) {
    return encoded;
  }
  final xmp = writes.xmp;
  if (xmp != null && encoded.info.format == ImageFormat.png) {
    final bytes = _writePngXmp(encoded.bytes, xmp);
    return EncodedImage(
      bytes: bytes,
      info: _copyOutputInfoWithSize(encoded.info, bytes.length),
    );
  }
  if (xmp != null && encoded.info.format == ImageFormat.webp) {
    final bytes = _writeWebpXmp(encoded.bytes, xmp);
    return EncodedImage(
      bytes: bytes,
      info: _copyOutputInfoWithSize(encoded.info, bytes.length),
    );
  }
  if (xmp != null) {
    throw const UnsupportedCodecException(
      'XMP metadata writing is only implemented for PNG and WebP output.',
    );
  }
  return encoded;
}

Uint8List _writePngXmp(Uint8List bytes, XmpMetadata xmp) {
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
    final data = bytes.sublist(dataStart, dataEnd);
    final chunkEnd = dataEnd + 4;
    if (type == 'iTXt' && _isPngXmpData(data)) {
      offset = chunkEnd;
      continue;
    }
    if (type == 'IEND' && !inserted) {
      _writePngChunk(writer, 'iTXt', _pngXmpData(xmp));
      inserted = true;
    }
    writer.writeBytes(bytes.sublist(offset, chunkEnd));
    offset = chunkEnd;
    if (type == 'IEND') {
      break;
    }
  }
  if (!inserted) {
    throw const InvalidImageException('PNG missing IEND chunk.');
  }
  return writer.toBytes();
}

bool _hasPngSignature(Uint8List bytes) {
  const signature = <int>[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
  for (var i = 0; i < signature.length; i += 1) {
    if (bytes[i] != signature[i]) {
      return false;
    }
  }
  return true;
}

Uint8List _pngXmpData(XmpMetadata xmp) {
  return Uint8List.fromList(<int>[
    ...ascii.encode('XML:com.adobe.xmp'),
    0,
    0,
    0,
    0,
    0,
    ...utf8.encode(xmp.xmlText),
  ]);
}

bool _isPngXmpData(Uint8List data) {
  const keyword = 'XML:com.adobe.xmp';
  if (data.length <= keyword.length || data[keyword.length] != 0) {
    return false;
  }
  for (var i = 0; i < keyword.length; i += 1) {
    if (data[i] != keyword.codeUnitAt(i)) {
      return false;
    }
  }
  return true;
}

void _writePngChunk(ByteWriter writer, String type, Uint8List data) {
  final typeBytes = ascii.encode(type);
  writer
    ..writeUint32Be(data.length)
    ..writeBytes(typeBytes)
    ..writeBytes(data)
    ..writeUint32Be(crc32(<int>[...typeBytes, ...data]));
}

Uint8List _writeWebpXmp(Uint8List bytes, XmpMetadata xmp) {
  final info = readWebpInfo(bytes);
  final riffEnd = _webpRiffEndForWrite(bytes);
  final content = ByteWriter()..writeAscii('WEBP');
  var offset = 12;
  var hasVp8x = false;
  var wroteXmp = false;
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
      _writeWebpChunk(content, 'VP8X', _webpVp8xPayload(info, xmp: true));
      _writeWebpChunk(
        content,
        'XMP ',
        Uint8List.fromList(utf8.encode(xmp.xmlText)),
      );
      wroteXmp = true;
      hasVp8x = true;
    }
    if (type == 'VP8X') {
      hasVp8x = true;
      final vp8x = Uint8List.fromList(data);
      vp8x[0] |= 0x04;
      _writeWebpChunk(content, 'VP8X', vp8x);
      _writeWebpChunk(
        content,
        'XMP ',
        Uint8List.fromList(utf8.encode(xmp.xmlText)),
      );
      wroteXmp = true;
    } else if (type != 'XMP ') {
      _writeWebpChunk(content, type, data);
    }
    offset = end + (length.isOdd ? 1 : 0);
  }
  if (offset != riffEnd) {
    throw const InvalidImageException('Truncated WebP chunk.');
  }
  if (!wroteXmp) {
    _writeWebpChunk(content, 'VP8X', _webpVp8xPayload(info, xmp: true));
    _writeWebpChunk(
      content,
      'XMP ',
      Uint8List.fromList(utf8.encode(xmp.xmlText)),
    );
  }
  final writer = ByteWriter()
    ..writeAscii('RIFF')
    ..writeUint32Le(content.length)
    ..writeBytes(content.toBytes());
  return writer.toBytes();
}

int _webpRiffEndForWrite(Uint8List bytes) {
  if (bytes.length < 12 ||
      ascii.decode(bytes.sublist(0, 4)) != 'RIFF' ||
      ascii.decode(bytes.sublist(8, 12)) != 'WEBP') {
    throw const InvalidImageException('Invalid WebP signature.');
  }
  final size = readUint32Le(bytes, 4);
  final end = 8 + size;
  if (size < 4 || end > bytes.length) {
    throw const InvalidImageException('Truncated WebP RIFF payload.');
  }
  return end;
}

Uint8List _webpVp8xPayload(WebpImageInfo info, {required bool xmp}) {
  final flags =
      (info.hasProfile ? 0x20 : 0) |
      (info.hasAlpha ? 0x10 : 0) |
      (info.hasExif ? 0x08 : 0) |
      (xmp ? 0x04 : 0) |
      (info.isAnimated ? 0x02 : 0);
  final writer = ByteWriter()
    ..writeByte(flags)
    ..writeByte(0)
    ..writeByte(0)
    ..writeByte(0);
  _writeUint24Le(writer, info.width - 1);
  _writeUint24Le(writer, info.height - 1);
  return writer.toBytes();
}

void _writeWebpChunk(ByteWriter writer, String type, Uint8List data) {
  writer
    ..writeAscii(type)
    ..writeUint32Le(data.length)
    ..writeBytes(data);
  if (data.length.isOdd) {
    writer.writeByte(0);
  }
}

void _writeUint24Le(ByteWriter writer, int value) {
  if (value < 0 || value > 0xffffff) {
    throw const InvalidImageException('Invalid WebP VP8X dimensions.');
  }
  writer
    ..writeByte(value)
    ..writeByte(value >> 8)
    ..writeByte(value >> 16);
}

OutputInfo _copyOutputInfoWithSize(OutputInfo info, int size) {
  return OutputInfo(
    format: info.format,
    size: size,
    width: info.width,
    height: info.height,
    channels: info.channels,
    premultiplied: info.premultiplied,
    cropOffsetLeft: info.cropOffsetLeft,
    cropOffsetTop: info.cropOffsetTop,
    trimOffsetLeft: info.trimOffsetLeft,
    trimOffsetTop: info.trimOffsetTop,
    frames: info.frames,
    pageHeight: info.pageHeight,
    loopCount: info.loopCount,
    frameDelays: info.frameDelays,
    textAutofitDpi: info.textAutofitDpi,
  );
}

OutputInfo _outputInfo(OutputInfo info, PixelImage image) {
  return OutputInfo(
    format: info.format,
    size: info.size,
    width: info.width,
    height: info.height,
    channels: info.channels,
    premultiplied:
        info.premultiplied ||
        image.firstFrame.pixels.premultiplication ==
            Premultiplication.premultiplied,
    cropOffsetLeft: info.cropOffsetLeft,
    cropOffsetTop: info.cropOffsetTop,
    trimOffsetLeft: info.trimOffsetLeft,
    trimOffsetTop: info.trimOffsetTop,
    frames: info.frames == 1 && image.frames.length != 1
        ? image.frames.length
        : info.frames,
    pageHeight: image.firstFrame.pixels.pageHeight,
    loopCount: info.loopCount ?? image.loopCount,
    frameDelays: info.frameDelays.isNotEmpty
        ? info.frameDelays
        : <Duration>[
            for (final frame in image.frames)
              if (frame.delay != null) frame.delay!,
          ],
    textAutofitDpi: info.textAutofitDpi,
  );
}
