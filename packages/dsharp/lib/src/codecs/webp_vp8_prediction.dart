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

  void predictLumaMacroblock(int mbX, int mbY, int yMode) {
    _predictBlock(y, yWidth, mbX * 16, mbY * 16, 16, yMode);
  }

  void predictChroma(int mbX, int mbY, int uvMode) {
    _predictBlock(u, uvWidth, mbX * 8, mbY * 8, 8, uvMode);
    _predictBlock(v, uvWidth, mbX * 8, mbY * 8, 8, uvMode);
  }

  void predictBPredMacroblock(int mbX, int mbY, List<int> modes) {
    for (var block = 0; block < 16; block += 1) {
      predictLumaSubblock(mbX, mbY, block, modes[block]);
    }
  }

  void predictLumaSubblock(int mbX, int mbY, int block, int mode) {
    final blockX = block & 3;
    final blockY = block >> 2;
    final bx = mbX * 16 + blockX * 4;
    final by = mbY * 16 + blockY * 4;
    final top = _subblockTop(y, yWidth, bx, by, mbX, mbY, blockX);
    final left = _subblockLeft(y, yWidth, bx, by);
    final topLeft = bx == 0 || by == 0 ? 127 : y[(by - 1) * yWidth + bx - 1];
    _predictSubblock(y, yWidth, bx, by, mode, top, left, topLeft);
  }

  void addChromaDct(
    int mbX,
    int mbY,
    int block,
    bool isU,
    List<int> coefficients,
  ) {
    final plane = isU ? u : v;
    final bx = mbX * 8 + (block & 1) * 4;
    final by = mbY * 8 + (block >> 1) * 4;
    _addDctBlock(plane, uvWidth, bx, by, coefficients);
  }

  void addLumaDct(int mbX, int mbY, int block, List<int> coefficients) {
    final bx = mbX * 16 + (block & 3) * 4;
    final by = mbY * 16 + (block >> 2) * 4;
    _addDctBlock(y, yWidth, bx, by, coefficients);
  }

  void addLumaDctWithDc(
    int mbX,
    int mbY,
    int block,
    int dcCoefficient,
    List<int>? acCoefficients,
  ) {
    final coefficients = acCoefficients ?? List<int>.filled(16, 0);
    coefficients[0] = dcCoefficient;
    addLumaDct(mbX, mbY, block, coefficients);
  }

  Uint8List composeRgba() {
    final rgba = Uint8List(width * height * 4);
    for (var py = 0; py < height; py += 1) {
      for (var px = 0; px < width; px += 1) {
        final yy = y[py * yWidth + px];
        final uu = u[(py >> 1) * uvWidth + (px >> 1)];
        final vv = v[(py >> 1) * uvWidth + (px >> 1)];
        final out = (py * width + px) * 4;
        rgba[out] = _clip(yy + _shiftRightSigned(91881 * (vv - 128), 16));
        rgba[out + 1] = _clip(
          yy - _shiftRightSigned(22554 * (uu - 128) + 46802 * (vv - 128), 16),
        );
        rgba[out + 2] = _clip(yy + _shiftRightSigned(116130 * (uu - 128), 16));
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
        _shiftRightSigned(coeffs[4 + i] * sinpi8Sqrt2, 16) -
        coeffs[12 + i] -
        _shiftRightSigned(coeffs[12 + i] * cospi8Sqrt2Minus1, 16);
    final d1 =
        coeffs[4 + i] +
        _shiftRightSigned(coeffs[4 + i] * cospi8Sqrt2Minus1, 16) +
        _shiftRightSigned(coeffs[12 + i] * sinpi8Sqrt2, 16);
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
        _shiftRightSigned(tmp[base + 1] * sinpi8Sqrt2, 16) -
        tmp[base + 3] -
        _shiftRightSigned(tmp[base + 3] * cospi8Sqrt2Minus1, 16);
    final d1 =
        tmp[base + 1] +
        _shiftRightSigned(tmp[base + 1] * cospi8Sqrt2Minus1, 16) +
        _shiftRightSigned(tmp[base + 3] * sinpi8Sqrt2, 16);
    plane[(y + row) * stride + x] = _clip(
      plane[(y + row) * stride + x] + _shiftRightSigned(a1 + d1 + 4, 3),
    );
    plane[(y + row) * stride + x + 3] = _clip(
      plane[(y + row) * stride + x + 3] + _shiftRightSigned(a1 - d1 + 4, 3),
    );
    plane[(y + row) * stride + x + 1] = _clip(
      plane[(y + row) * stride + x + 1] + _shiftRightSigned(b1 + c1 + 4, 3),
    );
    plane[(y + row) * stride + x + 2] = _clip(
      plane[(y + row) * stride + x + 2] + _shiftRightSigned(b1 - c1 + 4, 3),
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

List<int> _subblockTop(
  Uint8List plane,
  int stride,
  int x,
  int y,
  int mbX,
  int mbY,
  int blockX,
) {
  final values = List<int>.filled(8, 127);
  if (y == 0) {
    return values;
  }
  final row = y - 1;
  for (var i = 0; i < 8; i += 1) {
    if (blockX == 3 && i >= 4) {
      values[i] = _topRightSubblockSample(plane, stride, mbX, mbY, i - 4);
    } else {
      final px = x + i;
      values[i] = px < stride ? plane[row * stride + px] : values[i - 1];
    }
  }
  return values;
}

int _topRightSubblockSample(
  Uint8List plane,
  int stride,
  int mbX,
  int mbY,
  int index,
) {
  if (mbY == 0) {
    return 127;
  }
  final row = mbY * 16 - 1;
  final px = mbX * 16 + 16 + index;
  if (px < stride) {
    return plane[row * stride + px];
  }
  return plane[row * stride + mbX * 16 + 15];
}

List<int> _subblockLeft(Uint8List plane, int stride, int x, int y) {
  final values = List<int>.filled(4, 129);
  if (x == 0) {
    return values;
  }
  for (var i = 0; i < 4; i += 1) {
    values[i] = plane[(y + i) * stride + x - 1];
  }
  return values;
}

void _predictSubblock(
  Uint8List plane,
  int stride,
  int x,
  int y,
  int mode,
  List<int> top,
  List<int> left,
  int topLeft,
) {
  void set(int row, int col, int value) {
    plane[(y + row) * stride + x + col] = value;
  }

  switch (mode) {
    case 0:
      final value =
          (4 +
              top[0] +
              top[1] +
              top[2] +
              top[3] +
              left[0] +
              left[1] +
              left[2] +
              left[3]) >>
          3;
      for (var row = 0; row < 4; row += 1) {
        for (var col = 0; col < 4; col += 1) {
          set(row, col, value);
        }
      }
    case 1:
      for (var row = 0; row < 4; row += 1) {
        for (var col = 0; col < 4; col += 1) {
          set(row, col, _clip(left[row] + top[col] - topLeft));
        }
      }
    case 2:
      final values = <int>[
        _avg3(topLeft, top[0], top[1]),
        _avg3(top[0], top[1], top[2]),
        _avg3(top[1], top[2], top[3]),
        _avg3(top[2], top[3], top[4]),
      ];
      for (var row = 0; row < 4; row += 1) {
        for (var col = 0; col < 4; col += 1) {
          set(row, col, values[col]);
        }
      }
    case 3:
      final values = <int>[
        _avg3(topLeft, left[0], left[1]),
        _avg3(left[0], left[1], left[2]),
        _avg3(left[1], left[2], left[3]),
        _avg3(left[2], left[3], left[3]),
      ];
      for (var row = 0; row < 4; row += 1) {
        for (var col = 0; col < 4; col += 1) {
          set(row, col, values[row]);
        }
      }
    case 4:
      final values = <int>[
        _avg3(top[0], top[1], top[2]),
        _avg3(top[1], top[2], top[3]),
        _avg3(top[2], top[3], top[4]),
        _avg3(top[3], top[4], top[5]),
        _avg3(top[4], top[5], top[6]),
        _avg3(top[5], top[6], top[7]),
        _avg3(top[6], top[7], top[7]),
      ];
      for (var row = 0; row < 4; row += 1) {
        for (var col = 0; col < 4; col += 1) {
          set(row, col, values[row + col]);
        }
      }
    case 5:
      final edge = <int>[
        left[3],
        left[2],
        left[1],
        left[0],
        topLeft,
        top[0],
        top[1],
        top[2],
        top[3],
      ];
      for (var row = 0; row < 4; row += 1) {
        for (var col = 0; col < 4; col += 1) {
          set(
            row,
            col,
            _avg3(
              edge[3 + col - row],
              edge[4 + col - row],
              edge[5 + col - row],
            ),
          );
        }
      }
    case 6:
      final edge = <int>[
        left[3],
        left[2],
        left[1],
        left[0],
        topLeft,
        top[0],
        top[1],
        top[2],
        top[3],
      ];
      int avg2Edge(int index) => _avg2(edge[index], edge[index + 1]);
      int avg3Edge(int index) =>
          _avg3(edge[index - 1], edge[index], edge[index + 1]);

      set(3, 0, avg3Edge(2));
      set(2, 0, avg3Edge(3));
      set(3, 1, avg3Edge(4));
      set(1, 0, avg3Edge(4));
      set(2, 1, avg2Edge(4));
      set(0, 0, avg2Edge(4));
      set(3, 2, avg3Edge(5));
      set(1, 1, avg3Edge(5));
      set(2, 2, avg2Edge(5));
      set(0, 1, avg2Edge(5));
      set(3, 3, avg3Edge(6));
      set(1, 2, avg3Edge(6));
      set(2, 3, avg2Edge(6));
      set(0, 2, avg2Edge(6));
      set(1, 3, avg3Edge(7));
      set(0, 3, avg2Edge(7));
    case 7:
      set(0, 0, _avg2(top[0], top[1]));
      set(1, 0, _avg3(top[0], top[1], top[2]));
      set(0, 1, _avg3(top[0], top[1], top[2]));
      set(2, 0, _avg2(top[1], top[2]));
      set(1, 1, _avg2(top[1], top[2]));
      set(0, 2, _avg2(top[1], top[2]));
      set(3, 0, _avg3(top[1], top[2], top[3]));
      set(2, 1, _avg3(top[1], top[2], top[3]));
      set(1, 2, _avg3(top[1], top[2], top[3]));
      set(0, 3, _avg3(top[1], top[2], top[3]));
      set(3, 1, _avg2(top[2], top[3]));
      set(2, 2, _avg2(top[2], top[3]));
      set(1, 3, _avg2(top[2], top[3]));
      set(3, 2, _avg3(top[3], top[4], top[5]));
      set(2, 3, _avg3(top[4], top[5], top[6]));
      set(3, 3, _avg3(top[5], top[6], top[7]));
    case 8:
      final edge = <int>[
        left[3],
        left[2],
        left[1],
        left[0],
        topLeft,
        top[0],
        top[1],
        top[2],
      ];
      int avg2Edge(int index) => _avg2(edge[index], edge[index + 1]);
      int avg3Edge(int index) =>
          _avg3(edge[index - 1], edge[index], edge[index + 1]);

      set(3, 0, avg2Edge(0));
      set(3, 1, avg3Edge(1));
      set(2, 0, avg2Edge(1));
      set(3, 2, avg2Edge(1));
      set(2, 1, avg3Edge(2));
      set(3, 3, avg3Edge(2));
      set(2, 2, avg2Edge(2));
      set(1, 0, avg2Edge(2));
      set(2, 3, avg3Edge(3));
      set(1, 1, avg3Edge(3));
      set(1, 2, avg2Edge(3));
      set(0, 0, avg2Edge(3));
      set(1, 3, avg3Edge(4));
      set(0, 1, avg3Edge(4));
      set(0, 2, avg3Edge(5));
      set(0, 3, avg3Edge(6));
    case 9:
      set(0, 0, _avg2(left[0], left[1]));
      set(0, 1, _avg3(left[0], left[1], left[2]));
      set(0, 2, _avg2(left[1], left[2]));
      set(0, 3, _avg3(left[1], left[2], left[3]));
      set(1, 0, _avg2(left[1], left[2]));
      set(1, 1, _avg3(left[1], left[2], left[3]));
      set(1, 2, _avg2(left[2], left[3]));
      set(1, 3, _avg3(left[2], left[3], left[3]));
      set(2, 0, _avg2(left[2], left[3]));
      set(2, 1, _avg3(left[2], left[3], left[3]));
      set(2, 2, left[3]);
      set(2, 3, left[3]);
      set(3, 0, left[3]);
      set(3, 1, left[3]);
      set(3, 2, left[3]);
      set(3, 3, left[3]);
    default:
      throw const InvalidImageException('Invalid VP8 B_PRED mode.');
  }
}

int _avg2(int a, int b) => (a + b + 1) >> 1;

int _avg3(int a, int b, int c) => (a + 2 * b + c + 2) >> 2;

int _clip(int value) => value < 0 ? 0 : (value > 255 ? 255 : value);
