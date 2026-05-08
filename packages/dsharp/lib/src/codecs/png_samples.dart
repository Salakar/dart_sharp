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
    final gray = _scaleSample(row, source, bitDepth);
    output[target] = gray;
    output[target + 1] = gray;
    output[target + 2] = gray;
    output[target + 3] = 255;
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
    output[target] = _scaleSample(row, source, bitDepth);
    output[target + 1] = _scaleSample(row, source + sampleBytes, bitDepth);
    output[target + 2] = _scaleSample(row, source + sampleBytes * 2, bitDepth);
    output[target + 3] = colorType == 6
        ? _scaleSample(row, source + sampleBytes * 3, bitDepth)
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
  if (bitDepth == 16) {
    final sample = (row[offset] << 8) | row[offset + 1];
    return (sample * 255 + 32767) ~/ 65535;
  }
  if (bitDepth == 8) {
    return row[offset];
  }
  final max = (1 << bitDepth) - 1;
  return (row[offset] * 255 + max ~/ 2) ~/ max;
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
