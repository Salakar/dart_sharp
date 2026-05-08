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
  if (xmp != null) {
    throw const UnsupportedCodecException(
      'XMP metadata writing is only implemented for PNG output.',
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
