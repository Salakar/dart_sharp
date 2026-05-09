part of 'tiff_codec.dart';

Uint8List _normalizeTiffPaletteIndices(
  Uint8List source,
  int width,
  int height,
  int samples,
  List<int> bitsPerSample,
) {
  if (samples != 1 || bitsPerSample.length != 1) {
    throw const UnsupportedCodecException(
      'Paletted TIFF images require one indexed sample per pixel.',
    );
  }
  final bitDepth = bitsPerSample.single;
  if (bitDepth == 1 || bitDepth == 2 || bitDepth == 4) {
    return _unpackLowBitSamples(source, width, height, bitDepth);
  }
  if (bitDepth != 8) {
    throw const UnsupportedCodecException(
      'Only 1/2/4/8-bit paletted TIFF samples are supported.',
    );
  }
  final expected = width * height;
  if (source.length < expected) {
    throw const InvalidImageException('Truncated TIFF pixel data.');
  }
  return source;
}

Uint8List _paletteToRgba(
  Uint8List indices,
  int pixelCount,
  List<int> colorMap,
  int bitDepth,
) {
  final colorCount = 1 << bitDepth;
  if (colorMap.length < colorCount * 3) {
    throw const InvalidImageException('Truncated TIFF color map.');
  }
  final output = Uint8List(pixelCount * 4);
  for (var pixel = 0; pixel < pixelCount; pixel += 1) {
    final index = indices[pixel];
    final dst = pixel * 4;
    output[dst] = _tiffColorMapSample(colorMap[index]);
    output[dst + 1] = _tiffColorMapSample(colorMap[colorCount + index]);
    output[dst + 2] = _tiffColorMapSample(colorMap[colorCount * 2 + index]);
    output[dst + 3] = 255;
  }
  return output;
}

int _tiffColorMapSample(int value) {
  return (value * 255 + 32767) ~/ 65535;
}

Uint8List _normalizeTiffSamples(
  Uint8List source,
  int width,
  int height,
  int samples,
  List<int> bitsPerSample,
  _TiffEndian endian,
) {
  if (bitsPerSample.length != 1 && bitsPerSample.length != samples) {
    throw const UnsupportedCodecException(
      'Unsupported TIFF bits-per-sample layout.',
    );
  }
  final bitDepth = bitsPerSample.first;
  if (samples == 1 && (bitDepth == 1 || bitDepth == 2 || bitDepth == 4)) {
    return _scaleLowBitSamples(
      _unpackLowBitSamples(source, width, height, bitDepth),
      bitDepth,
    );
  }
  if (_allTiffBitsPerSample(bitsPerSample, 16)) {
    return _scale16BitSamples(source, width, height, samples, endian);
  }
  if (!_allTiffBitsPerSample(bitsPerSample, 8)) {
    throw const UnsupportedCodecException(
      'Only 1/2/4-bit grayscale, 8-bit, and 16-bit TIFF samples are supported.',
    );
  }
  final expected = width * height * samples;
  if (source.length < expected) {
    throw const InvalidImageException('Truncated TIFF pixel data.');
  }
  return source;
}

bool _allTiffBitsPerSample(List<int> bitsPerSample, int value) {
  for (final bits in bitsPerSample) {
    if (bits != value) {
      return false;
    }
  }
  return true;
}

Uint8List _unpackLowBitSamples(
  Uint8List source,
  int width,
  int height,
  int bitDepth,
) {
  final rowBytes = (width * bitDepth + 7) >> 3;
  if (source.length < rowBytes * height) {
    throw const InvalidImageException('Truncated TIFF pixel data.');
  }
  final mask = (1 << bitDepth) - 1;
  final output = Uint8List(width * height);
  for (var y = 0; y < height; y += 1) {
    final row = y * rowBytes;
    for (var x = 0; x < width; x += 1) {
      final bitOffset = x * bitDepth;
      final byte = source[row + (bitOffset >> 3)];
      final shift = 8 - bitDepth - (bitOffset & 7);
      final sample = (byte >> shift) & mask;
      output[y * width + x] = sample;
    }
  }
  return output;
}

Uint8List _scaleLowBitSamples(Uint8List samples, int bitDepth) {
  final maxSample = (1 << bitDepth) - 1;
  final output = Uint8List(samples.length);
  for (var i = 0; i < samples.length; i += 1) {
    output[i] = (samples[i] * 255) ~/ maxSample;
  }
  return output;
}

Uint8List _scale16BitSamples(
  Uint8List source,
  int width,
  int height,
  int samples,
  _TiffEndian endian,
) {
  final sampleCount = width * height * samples;
  final expected = sampleCount * 2;
  if (source.length < expected) {
    throw const InvalidImageException('Truncated TIFF pixel data.');
  }
  final output = Uint8List(sampleCount);
  for (var i = 0; i < sampleCount; i += 1) {
    final sample = endian.readUint16(source, i * 2);
    output[i] = (sample * 255 + 32767) ~/ 65535;
  }
  return output;
}

Uint8List _lowBitTiffPixels(RawPixels raw, int bitDepth, bool miniswhite) {
  final rgba = rawToRgba(raw);
  final writer = ByteWriter();
  final maxSample = (1 << bitDepth) - 1;
  for (var y = 0; y < raw.height; y += 1) {
    var byte = 0;
    var bits = 0;
    for (var x = 0; x < raw.width; x += 1) {
      final sample = _lowBitTiffSample(
        rgba,
        y * raw.width + x,
        maxSample,
        miniswhite,
      );
      byte = (byte << bitDepth) | sample;
      bits += bitDepth;
      if (bits == 8) {
        writer.writeByte(byte);
        byte = 0;
        bits = 0;
      }
    }
    if (bits > 0) {
      writer.writeByte(byte << (8 - bits));
    }
  }
  return writer.toBytes();
}

int _lowBitTiffSample(
  Uint8List rgba,
  int pixel,
  int maxSample,
  bool miniswhite,
) {
  final offset = pixel * 4;
  if (rgba[offset + 3] != 255) {
    throw const UnsupportedCodecException('Opaque pixels required.');
  }
  final gray =
      (rgba[offset] * 299 + rgba[offset + 1] * 587 + rgba[offset + 2] * 114) ~/
      1000;
  final sample = (gray * maxSample + 127) ~/ 255;
  return miniswhite ? maxSample - sample : sample;
}
