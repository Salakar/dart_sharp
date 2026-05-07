part of 'webp_vp8.dart';

final class _Vp8Planes {
  _Vp8Planes(this.width, this.height)
    : mbCols = (width + 15) >> 4,
      mbRows = (height + 15) >> 4,
      yWidth = ((width + 15) >> 4) * 16,
      uvWidth = ((width + 15) >> 4) * 8,
      y = Uint8List(((width + 15) >> 4) * 16 * ((height + 15) >> 4) * 16),
      u = Uint8List(((width + 15) >> 4) * 8 * ((height + 15) >> 4) * 8),
      v = Uint8List(((width + 15) >> 4) * 8 * ((height + 15) >> 4) * 8);

  final int width;
  final int height;
  final int mbCols;
  final int mbRows;
  final int yWidth;
  final int uvWidth;
  final Uint8List y;
  final Uint8List u;
  final Uint8List v;

  void predictMacroblock(int mbX, int mbY, int yMode, int uvMode) {
    _predictBlock(y, yWidth, mbX * 16, mbY * 16, 16, yMode);
    _predictBlock(u, uvWidth, mbX * 8, mbY * 8, 8, uvMode);
    _predictBlock(v, uvWidth, mbX * 8, mbY * 8, 8, uvMode);
  }

  void addChromaDc(
    int mbX,
    int mbY,
    int block,
    bool isU,
    int coefficient,
    int quant,
  ) {
    if (coefficient == 0) {
      return;
    }
    final plane = isU ? u : v;
    final bx = mbX * 8 + (block & 1) * 4;
    final by = mbY * 8 + (block >> 1) * 4;
    final residue = ((coefficient * quant) + 4) >> 3;
    for (var row = 0; row < 4; row += 1) {
      for (var col = 0; col < 4; col += 1) {
        final offset = (by + row) * uvWidth + bx + col;
        plane[offset] = _clip(plane[offset] + residue);
      }
    }
  }

  void addLumaDct(int mbX, int mbY, int block, List<int> coefficients) {
    final bx = mbX * 16 + (block & 3) * 4;
    final by = mbY * 16 + (block >> 2) * 4;
    _addDctBlock(y, yWidth, bx, by, coefficients);
  }

  Uint8List composeRgba() {
    final rgba = Uint8List(width * height * 4);
    for (var py = 0; py < height; py += 1) {
      for (var px = 0; px < width; px += 1) {
        final yy = y[py * yWidth + px];
        final uu = u[(py >> 1) * uvWidth + (px >> 1)];
        final vv = v[(py >> 1) * uvWidth + (px >> 1)];
        final out = (py * width + px) * 4;
        rgba[out] = _clip(yy + ((91881 * (vv - 128)) >> 16));
        rgba[out + 1] = _clip(
          yy - ((22554 * (uu - 128) + 46802 * (vv - 128)) >> 16),
        );
        rgba[out + 2] = _clip(yy + ((116130 * (uu - 128)) >> 16));
        rgba[out + 3] = 255;
      }
    }
    return rgba;
  }
}

void _addDctBlock(Uint8List plane, int stride, int x, int y, List<int> coeffs) {
  const cospi8Sqrt2Minus1 = 20091;
  const sinpi8Sqrt2 = 35468;
  final tmp = List<int>.filled(16, 0);
  for (var i = 0; i < 4; i += 1) {
    final a1 = coeffs[i] + coeffs[8 + i];
    final b1 = coeffs[i] - coeffs[8 + i];
    final c1 =
        ((coeffs[4 + i] * sinpi8Sqrt2) >> 16) -
        coeffs[12 + i] -
        ((coeffs[12 + i] * cospi8Sqrt2Minus1) >> 16);
    final d1 =
        coeffs[4 + i] +
        ((coeffs[4 + i] * cospi8Sqrt2Minus1) >> 16) +
        ((coeffs[12 + i] * sinpi8Sqrt2) >> 16);
    tmp[i] = a1 + d1;
    tmp[12 + i] = a1 - d1;
    tmp[4 + i] = b1 + c1;
    tmp[8 + i] = b1 - c1;
  }
  for (var row = 0; row < 4; row += 1) {
    final base = row * 4;
    final a1 = tmp[base] + tmp[base + 2];
    final b1 = tmp[base] - tmp[base + 2];
    final c1 =
        ((tmp[base + 1] * sinpi8Sqrt2) >> 16) -
        tmp[base + 3] -
        ((tmp[base + 3] * cospi8Sqrt2Minus1) >> 16);
    final d1 =
        tmp[base + 1] +
        ((tmp[base + 1] * cospi8Sqrt2Minus1) >> 16) +
        ((tmp[base + 3] * sinpi8Sqrt2) >> 16);
    plane[(y + row) * stride + x] = _clip(
      plane[(y + row) * stride + x] + ((a1 + d1 + 4) >> 3),
    );
    plane[(y + row) * stride + x + 3] = _clip(
      plane[(y + row) * stride + x + 3] + ((a1 - d1 + 4) >> 3),
    );
    plane[(y + row) * stride + x + 1] = _clip(
      plane[(y + row) * stride + x + 1] + ((b1 + c1 + 4) >> 3),
    );
    plane[(y + row) * stride + x + 2] = _clip(
      plane[(y + row) * stride + x + 2] + ((b1 - c1 + 4) >> 3),
    );
  }
}

void _predictBlock(
  Uint8List plane,
  int stride,
  int x,
  int y,
  int size,
  int mode,
) {
  switch (mode) {
    case 0:
      _predictDc(plane, stride, x, y, size);
    case 1:
      _predictVertical(plane, stride, x, y, size);
    case 2:
      _predictHorizontal(plane, stride, x, y, size);
    case 3:
      _predictTrueMotion(plane, stride, x, y, size);
    default:
      throw const UnsupportedCodecException(
        'Unsupported VP8 intra prediction mode.',
      );
  }
}

void _predictDc(Uint8List plane, int stride, int x, int y, int size) {
  final hasTop = y > 0;
  final hasLeft = x > 0;
  var value = 128;
  if (hasTop || hasLeft) {
    var sum = 0;
    var count = 0;
    if (hasTop) {
      for (var col = 0; col < size; col += 1) {
        sum += plane[(y - 1) * stride + x + col];
      }
      count += size;
    }
    if (hasLeft) {
      for (var row = 0; row < size; row += 1) {
        sum += plane[(y + row) * stride + x - 1];
      }
      count += size;
    }
    value = (sum + (count >> 1)) ~/ count;
  }
  _fillBlock(plane, stride, x, y, size, value);
}

void _predictVertical(Uint8List plane, int stride, int x, int y, int size) {
  for (var row = 0; row < size; row += 1) {
    for (var col = 0; col < size; col += 1) {
      plane[(y + row) * stride + x + col] = y == 0
          ? 127
          : plane[(y - 1) * stride + x + col];
    }
  }
}

void _predictHorizontal(Uint8List plane, int stride, int x, int y, int size) {
  for (var row = 0; row < size; row += 1) {
    final value = x == 0 ? 129 : plane[(y + row) * stride + x - 1];
    for (var col = 0; col < size; col += 1) {
      plane[(y + row) * stride + x + col] = value;
    }
  }
}

void _predictTrueMotion(Uint8List plane, int stride, int x, int y, int size) {
  final topLeft = x == 0 || y == 0 ? 127 : plane[(y - 1) * stride + x - 1];
  for (var row = 0; row < size; row += 1) {
    final left = x == 0 ? 129 : plane[(y + row) * stride + x - 1];
    for (var col = 0; col < size; col += 1) {
      final top = y == 0 ? 127 : plane[(y - 1) * stride + x + col];
      plane[(y + row) * stride + x + col] = _clip(left + top - topLeft);
    }
  }
}

void _fillBlock(
  Uint8List plane,
  int stride,
  int x,
  int y,
  int size,
  int value,
) {
  for (var row = 0; row < size; row += 1) {
    for (var col = 0; col < size; col += 1) {
      plane[(y + row) * stride + x + col] = value;
    }
  }
}

int _clip(int value) => value < 0 ? 0 : (value > 255 ? 255 : value);
