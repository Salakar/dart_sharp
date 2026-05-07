import 'dart:math' as math;

/// Runs an 8x8 inverse DCT and adds the JPEG 128 sample bias.
List<int> jpegIdct(List<int> coeffs) {
  final out = List<int>.filled(64, 0);
  for (var y = 0; y < 8; y += 1) {
    for (var x = 0; x < 8; x += 1) {
      var sum = 0.0;
      for (var v = 0; v < 8; v += 1) {
        for (var u = 0; u < 8; u += 1) {
          final cu = u == 0 ? 1 / math.sqrt2 : 1.0;
          final cv = v == 0 ? 1 / math.sqrt2 : 1.0;
          sum +=
              cu *
              cv *
              coeffs[v * 8 + u] *
              math.cos(((2 * x + 1) * u * math.pi) / 16) *
              math.cos(((2 * y + 1) * v * math.pi) / 16);
        }
      }
      out[y * 8 + x] = _clamp((sum / 4 + 128).round());
    }
  }
  return out;
}

/// Runs an 8x8 forward DCT after subtracting the JPEG 128 sample bias.
List<int> jpegFdct(List<int> samples, List<int> quant) {
  final out = List<int>.filled(64, 0);
  for (var v = 0; v < 8; v += 1) {
    for (var u = 0; u < 8; u += 1) {
      var sum = 0.0;
      for (var y = 0; y < 8; y += 1) {
        for (var x = 0; x < 8; x += 1) {
          sum +=
              (samples[y * 8 + x] - 128) *
              math.cos(((2 * x + 1) * u * math.pi) / 16) *
              math.cos(((2 * y + 1) * v * math.pi) / 16);
        }
      }
      final cu = u == 0 ? 1 / math.sqrt2 : 1.0;
      final cv = v == 0 ? 1 / math.sqrt2 : 1.0;
      out[v * 8 + u] = (0.25 * cu * cv * sum / quant[v * 8 + u]).round();
    }
  }
  return out;
}

/// Converts RGB to JPEG YCbCr.
({int y, int cb, int cr}) jpegRgbToYcbcr(int r, int g, int b) {
  return (
    y: _clamp((0.299 * r + 0.587 * g + 0.114 * b).round()),
    cb: _clamp((-0.168736 * r - 0.331264 * g + 0.5 * b + 128).round()),
    cr: _clamp((0.5 * r - 0.418688 * g - 0.081312 * b + 128).round()),
  );
}

/// Converts JPEG YCbCr to RGB.
({int r, int g, int b}) jpegYcbcrToRgb(int y, int cb, int cr) {
  final cbb = cb - 128;
  final crr = cr - 128;
  return (
    r: _clamp((y + 1.402 * crr).round()),
    g: _clamp((y - 0.344136 * cbb - 0.714136 * crr).round()),
    b: _clamp((y + 1.772 * cbb).round()),
  );
}

int _clamp(int value) => value < 0 ? 0 : (value > 255 ? 255 : value);
