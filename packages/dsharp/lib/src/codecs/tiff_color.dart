part of 'tiff_codec.dart';

Uint8List _cielabToRgba(
  Uint8List source,
  int width,
  int height,
  int samples,
  List<int> bitsPerSample,
  _TiffEndian endian,
) {
  if (samples < 3) {
    throw const UnsupportedCodecException(
      'CIELab TIFF images require at least three samples per pixel.',
    );
  }
  final bitDepth = bitsPerSample.first;
  if (!_allTiffBitsPerSample(bitsPerSample, 8) &&
      !_allTiffBitsPerSample(bitsPerSample, 16)) {
    throw const UnsupportedCodecException(
      'CIELab TIFF decoding supports 8-bit and 16-bit samples.',
    );
  }
  final bytesPerSample = bitDepth == 16 ? 2 : 1;
  final pixelCount = width * height;
  final expected = pixelCount * samples * bytesPerSample;
  if (source.length < expected) {
    throw const InvalidImageException('Truncated TIFF pixel data.');
  }
  final output = Uint8List(pixelCount * 4);
  for (var pixel = 0; pixel < pixelCount; pixel += 1) {
    final src = pixel * samples * bytesPerSample;
    final lab = bitDepth == 16
        ? _read16BitCielab(source, src, endian)
        : _read8BitCielab(source, src);
    final rgb = _labToSrgb(lab.$1, lab.$2, lab.$3);
    final dst = pixel * 4;
    output[dst] = rgb.$1;
    output[dst + 1] = rgb.$2;
    output[dst + 2] = rgb.$3;
    output[dst + 3] = samples >= 4
        ? _extraTiffSample(source, src, 3, bytesPerSample, endian)
        : 255;
  }
  return output;
}

(double, double, double) _read8BitCielab(Uint8List source, int offset) {
  return (
    source[offset] * 100 / 255,
    _signed8(source[offset + 1]).toDouble(),
    _signed8(source[offset + 2]).toDouble(),
  );
}

(double, double, double) _read16BitCielab(
  Uint8List source,
  int offset,
  _TiffEndian endian,
) {
  final l = endian.readUint16(source, offset) ~/ 257;
  final a = _signed16(endian.readUint16(source, offset + 2)) / 256;
  final b = _signed16(endian.readUint16(source, offset + 4)) / 256;
  return (l * 100 / 255, a, b);
}

int _signed8(int value) => value >= 128 ? value - 256 : value;

int _signed16(int value) => value >= 32768 ? value - 65536 : value;

int _extraTiffSample(
  Uint8List source,
  int offset,
  int sample,
  int bytesPerSample,
  _TiffEndian endian,
) {
  if (bytesPerSample == 1) {
    return source[offset + sample];
  }
  return _tiffColorMapSample(endian.readUint16(source, offset + sample * 2));
}

(int, int, int) _labToSrgb(double l, double a, double b) {
  final fy = (l + 16) / 116;
  final fx = fy + a / 500;
  final fz = fy - b / 200;
  final x = 0.95047 * _labPivotInverse(fx);
  final y = _labPivotInverse(fy);
  final z = 1.08883 * _labPivotInverse(fz);
  final r = x * 3.2404542 + y * -1.5371385 + z * -0.4985314;
  final g = x * -0.9692660 + y * 1.8760108 + z * 0.0415560;
  final blue = x * 0.0556434 + y * -0.2040259 + z * 1.0572252;
  return (_srgbSample(r), _srgbSample(g), _srgbSample(blue));
}

double _labPivotInverse(double value) {
  final cube = value * value * value;
  if (cube > 0.008856) {
    return cube;
  }
  return (116 * value - 16) / 903.3;
}

int _srgbSample(double value) {
  final clamped = value <= 0 ? 0.0 : (value >= 1 ? 1.0 : value);
  final encoded = clamped <= 0.0031308
      ? clamped * 12.92
      : 1.055 * math.pow(clamped, 1 / 2.4) - 0.055;
  return (encoded * 255).round().clamp(0, 255);
}
