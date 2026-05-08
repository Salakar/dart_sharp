part of 'png_codec.dart';

void _writeRgbaRow(
  Uint8List output,
  int y,
  int width,
  int bitDepth,
  int colorType,
  Uint8List row,
  List<int>? palette,
  List<int>? transparency,
) {
  for (var x = 0; x < width; x += 1) {
    _writeRgbaPixel(
      output,
      x,
      y,
      width,
      bitDepth,
      colorType,
      row,
      x,
      palette,
      transparency,
    );
  }
}

void _writeRgbaPixel(
  Uint8List output,
  int x,
  int y,
  int width,
  int bitDepth,
  int colorType,
  Uint8List row,
  int column,
  List<int>? palette,
  List<int>? transparency,
) {
  final target = (y * width + x) * 4;
  final sampleBytes = bitDepth == 16 ? 2 : 1;
  final source = switch (colorType) {
    0 => column * sampleBytes,
    3 => column,
    2 => column * 3 * sampleBytes,
    4 => column * 2 * sampleBytes,
    _ => column * 4 * sampleBytes,
  };
  if (colorType == 0) {
    final sample = _sampleValue(row, source, bitDepth);
    final gray = _scaleRawSample(sample, bitDepth);
    output[target] = gray;
    output[target + 1] = gray;
    output[target + 2] = gray;
    output[target + 3] = _matchesTransparentGray(sample, transparency)
        ? 0
        : 255;
  } else if (colorType == 3) {
    final index = row[source];
    final paletteOffset = index * 3;
    if (palette == null || paletteOffset + 2 >= palette.length) {
      throw const InvalidImageException('Invalid PNG palette index.');
    }
    output[target] = palette[paletteOffset];
    output[target + 1] = palette[paletteOffset + 1];
    output[target + 2] = palette[paletteOffset + 2];
    output[target + 3] = index < (transparency?.length ?? 0)
        ? transparency![index]
        : 255;
  } else if (colorType == 4) {
    final gray = _scaleSample(row, source, bitDepth);
    output[target] = gray;
    output[target + 1] = gray;
    output[target + 2] = gray;
    output[target + 3] = _scaleSample(row, source + sampleBytes, bitDepth);
  } else {
    final red = _sampleValue(row, source, bitDepth);
    final green = _sampleValue(row, source + sampleBytes, bitDepth);
    final blue = _sampleValue(row, source + sampleBytes * 2, bitDepth);
    output[target] = _scaleRawSample(red, bitDepth);
    output[target + 1] = _scaleRawSample(green, bitDepth);
    output[target + 2] = _scaleRawSample(blue, bitDepth);
    output[target + 3] = colorType == 6
        ? _scaleSample(row, source + sampleBytes * 3, bitDepth)
        : _matchesTransparentRgb(red, green, blue, transparency)
        ? 0
        : 255;
  }
}

int _pngChannels(int colorType) {
  return switch (colorType) {
    0 => 1,
    2 => 3,
    3 => 1,
    4 => 2,
    6 => 4,
    _ => 0,
  };
}

bool _supportsPngBitDepth(int colorType, int bitDepth) {
  return switch (colorType) {
    0 => _supportsPaletteBitDepth(bitDepth) || bitDepth == 16,
    3 => _supportsPaletteBitDepth(bitDepth),
    2 || 4 || 6 => bitDepth == 8 || bitDepth == 16,
    _ => false,
  };
}

bool _supportsPaletteBitDepth(int bitDepth) =>
    bitDepth == 1 || bitDepth == 2 || bitDepth == 4 || bitDepth == 8;

int _scanlineBytes(int width, int channels, int bitDepth) {
  return ((width * channels * bitDepth) + 7) >> 3;
}

int _filterBytesPerPixel(int channels, int bitDepth) {
  final bytes = (channels * bitDepth + 7) >> 3;
  return bytes < 1 ? 1 : bytes;
}

Uint8List _unpackSamples(Uint8List packed, int sampleCount, int bitDepth) {
  final samples = Uint8List(sampleCount);
  final mask = (1 << bitDepth) - 1;
  for (var sample = 0; sample < sampleCount; sample += 1) {
    final bitOffset = sample * bitDepth;
    final byte = packed[bitOffset >> 3];
    final shift = 8 - bitDepth - (bitOffset & 7);
    samples[sample] = (byte >> shift) & mask;
  }
  return samples;
}

int _scaleSample(Uint8List row, int offset, int bitDepth) {
  return _scaleRawSample(_sampleValue(row, offset, bitDepth), bitDepth);
}

int _sampleValue(Uint8List row, int offset, int bitDepth) {
  if (bitDepth == 16) {
    return (row[offset] << 8) | row[offset + 1];
  }
  return row[offset];
}

int _scaleRawSample(int sample, int bitDepth) {
  if (bitDepth == 8) {
    return sample;
  }
  if (bitDepth == 16) {
    return (sample * 255 + 32767) ~/ 65535;
  }
  final max = (1 << bitDepth) - 1;
  return (sample * 255 + max ~/ 2) ~/ max;
}

bool _matchesTransparentGray(int sample, List<int>? transparency) {
  if (transparency == null) {
    return false;
  }
  if (transparency.length < 2) {
    throw const InvalidImageException('Truncated PNG transparency chunk.');
  }
  return sample == _readUint16(transparency, 0);
}

bool _matchesTransparentRgb(
  int red,
  int green,
  int blue,
  List<int>? transparency,
) {
  if (transparency == null) {
    return false;
  }
  if (transparency.length < 6) {
    throw const InvalidImageException('Truncated PNG transparency chunk.');
  }
  return red == _readUint16(transparency, 0) &&
      green == _readUint16(transparency, 2) &&
      blue == _readUint16(transparency, 4);
}

int _readUint16(List<int> bytes, int offset) {
  return (bytes[offset] << 8) | bytes[offset + 1];
}

int _paeth(int left, int up, int upLeft) {
  final p = left + up - upLeft;
  final pa = (p - left).abs();
  final pb = (p - up).abs();
  final pc = (p - upLeft).abs();
  if (pa <= pb && pa <= pc) {
    return left;
  }
  return pb <= pc ? up : upLeft;
}
