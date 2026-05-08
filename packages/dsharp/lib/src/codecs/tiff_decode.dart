part of 'tiff_codec.dart';

PixelImage _decodeTiffImage(Uint8List bytes) {
  final endian = _TiffEndian.fromHeader(bytes);
  if (endian == null) {
    throw const UnsupportedCodecException(
      'Only baseline TIFF byte orders are supported.',
    );
  }
  if (endian.readUint16(bytes, 2) != 42) {
    throw const InvalidImageException('Invalid TIFF header.');
  }
  final frames = <ImageFrame>[];
  var offset = endian.readUint32(bytes, 4);
  while (offset != 0) {
    final tags = _readIfd(bytes, offset, endian);
    if (frames.isNotEmpty &&
        (tags.value(256) != frames.first.width ||
            tags.value(257) != frames.first.height)) {
      break;
    }
    final pixels = _decodeTiffFrame(bytes, tags);
    frames.add(ImageFrame(pixels: pixels));
    offset = tags.nextOffset;
  }
  if (frames.isEmpty) {
    throw const InvalidImageException('TIFF contains no image frames.');
  }
  return PixelImage(frames: frames);
}

RawPixels _decodeTiffFrame(Uint8List bytes, _Ifd tags) {
  final width = tags.value(256);
  final height = tags.value(257);
  final compression = tags.value(259);
  final photometric = tags.value(262);
  final samples = tags.value(277, fallback: 1);
  final bitsPerSample = tags.values(258, fallback: const <int>[8]);
  final predictor = tags.value(317, fallback: 1);
  if (compression == 7) {
    return _decodeJpegCompressedTiff(bytes, tags, width, height);
  }
  final source = compression == 3
      ? _decodeGroup3FaxTiff(bytes, tags, width, height)
      : _decodeTiffStrips(
          bytes,
          tags.values(273),
          tags.values(279),
          compression,
        );
  if (predictor == 2) {
    if (photometric == 3) {
      throw const UnsupportedCodecException(
        'TIFF horizontal predictor is not supported for palette images.',
      );
    }
    final predictorBitDepth = bitsPerSample.first;
    if (!_allTiffBitsPerSample(bitsPerSample, 8) &&
        !_allTiffBitsPerSample(bitsPerSample, 16)) {
      throw const UnsupportedCodecException(
        'TIFF horizontal predictor requires 8-bit or 16-bit samples.',
      );
    }
    _undoHorizontalPredictor(
      source,
      width,
      height,
      samples,
      predictorBitDepth,
      tags.endian,
    );
  } else if (predictor != 1) {
    throw const UnsupportedCodecException(
      'Only TIFF predictors 1 and 2 are supported.',
    );
  }
  if (photometric == 3) {
    final indices = _normalizeTiffPaletteIndices(
      source,
      width,
      height,
      samples,
      bitsPerSample,
    );
    final rgba = _paletteToRgba(
      indices,
      width * height,
      tags.values(320),
      bitsPerSample.first,
    );
    return _rgbaTiffPixels(rgba, width, height);
  }
  if (photometric == 8) {
    final rgba = _cielabToRgba(
      source,
      width,
      height,
      samples,
      bitsPerSample,
      tags.endian,
    );
    return _rgbaTiffPixels(rgba, width, height);
  }
  final normalized = _normalizeTiffSamples(
    source,
    width,
    height,
    samples,
    bitsPerSample,
    tags.endian,
  );
  return _rgbaTiffPixels(
    _toRgba(normalized, width, height, samples, photometric),
    width,
    height,
  );
}

RawPixels _rgbaTiffPixels(List<int> rgba, int width, int height) {
  return RawPixels(
    bytes: Uint8List.fromList(rgba),
    width: width,
    height: height,
    channels: ChannelCount.four,
  );
}
