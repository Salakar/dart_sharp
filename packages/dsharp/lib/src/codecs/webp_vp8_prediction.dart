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
