part of 'jpeg_encoder.dart';

Uint8List _encodeProgressiveJpegBytes(
  Uint8List rgb,
  int width,
  int height,
  List<int> lumaQuant,
  List<int> chromaQuant,
  String chromaSubsampling,
) {
  final frame = _progressiveFrame(
    rgb,
    width,
    height,
    lumaQuant,
    chromaQuant,
    chromaSubsampling,
  );
  final writer = ByteWriter()
    ..writeByte(0xff)
    ..writeByte(0xd8);
  _segment(writer, 0xe0, _jfif());
  _segment(writer, 0xdb, _dqt(0, lumaQuant));
  _segment(writer, 0xdb, _dqt(1, chromaQuant));
  _segment(writer, 0xc2, _sof(width, height, chromaSubsampling));
  _segment(writer, 0xc4, _dht(0, 0));
  _segment(writer, 0xc4, _dht(1, 0));
  _segment(writer, 0xda, _dcSos());
  writer.writeBytes(_progressiveDcEntropy(frame));
  for (final component in frame.components) {
    _segment(writer, 0xda, _acSos(component.id));
    writer.writeBytes(_progressiveAcEntropy(component));
  }
  writer
    ..writeByte(0xff)
    ..writeByte(0xd9);
  return writer.toBytes();
}

_ProgressiveFrame _progressiveFrame(
  Uint8List rgb,
  int width,
  int height,
  List<int> lumaQuant,
  List<int> chromaQuant,
  String chromaSubsampling,
) {
  if (chromaSubsampling == '4:2:0') {
    return _progressiveFrame420(rgb, width, height, lumaQuant, chromaQuant);
  }
  return _progressiveFrame444(rgb, width, height, lumaQuant, chromaQuant);
}

_ProgressiveFrame _progressiveFrame444(
  Uint8List rgb,
  int width,
  int height,
  List<int> lumaQuant,
  List<int> chromaQuant,
) {
  final blocksX = (width + 7) ~/ 8;
  final blocksY = (height + 7) ~/ 8;
  final components = <_ProgressiveComponent>[
    _ProgressiveComponent(1, 1, 1, blocksX, blocksY),
    _ProgressiveComponent(2, 1, 1, blocksX, blocksY),
    _ProgressiveComponent(3, 1, 1, blocksX, blocksY),
  ];
  for (var by = 0; by < blocksY; by += 1) {
    for (var bx = 0; bx < blocksX; bx += 1) {
      final planes = _blockPlanes(rgb, width, height, bx, by);
      components[0].setBlock(bx, by, jpegFdct(planes[0], lumaQuant));
      components[1].setBlock(bx, by, jpegFdct(planes[1], chromaQuant));
      components[2].setBlock(bx, by, jpegFdct(planes[2], chromaQuant));
    }
  }
  return _ProgressiveFrame(components, blocksX, blocksY);
}

_ProgressiveFrame _progressiveFrame420(
  Uint8List rgb,
  int width,
  int height,
  List<int> lumaQuant,
  List<int> chromaQuant,
) {
  final mcuCols = (width + 15) ~/ 16;
  final mcuRows = (height + 15) ~/ 16;
  final components = <_ProgressiveComponent>[
    _ProgressiveComponent(1, 2, 2, mcuCols * 2, mcuRows * 2),
    _ProgressiveComponent(2, 1, 1, mcuCols, mcuRows),
    _ProgressiveComponent(3, 1, 1, mcuCols, mcuRows),
  ];
  for (var my = 0; my < mcuRows; my += 1) {
    for (var mx = 0; mx < mcuCols; mx += 1) {
      for (var vy = 0; vy < 2; vy += 1) {
        for (var hx = 0; hx < 2; hx += 1) {
          components[0].setBlock(
            mx * 2 + hx,
            my * 2 + vy,
            jpegFdct(
              _lumaBlock(rgb, width, height, mx * 2 + hx, my * 2 + vy),
              lumaQuant,
            ),
          );
        }
      }
      final chroma = _chroma420Block(rgb, width, height, mx, my);
      components[1].setBlock(mx, my, jpegFdct(chroma[0], chromaQuant));
      components[2].setBlock(mx, my, jpegFdct(chroma[1], chromaQuant));
    }
  }
  return _ProgressiveFrame(components, mcuCols, mcuRows);
}

Uint8List _progressiveDcEntropy(_ProgressiveFrame frame) {
  final bits = JpegBitWriter();
  final predictors = List<int>.filled(frame.components.length, 0);
  for (var my = 0; my < frame.mcuRows; my += 1) {
    for (var mx = 0; mx < frame.mcuCols; mx += 1) {
      for (var ci = 0; ci < frame.components.length; ci += 1) {
        final component = frame.components[ci];
        for (var vy = 0; vy < component.v; vy += 1) {
          for (var hx = 0; hx < component.h; hx += 1) {
            final dc = component.block(
              mx * component.h + hx,
              my * component.v + vy,
            )[0];
            _writeValue(bits, dc - predictors[ci], 0);
            predictors[ci] = dc;
          }
        }
      }
    }
  }
  return bits.finish();
}

Uint8List _progressiveAcEntropy(_ProgressiveComponent component) {
  final bits = JpegBitWriter();
  for (var by = 0; by < component.blockRows; by += 1) {
    for (var bx = 0; bx < component.blockCols; bx += 1) {
      _writeAcCoefficients(bits, component.block(bx, by));
    }
  }
  return bits.finish();
}

void _writeAcCoefficients(JpegBitWriter bits, List<int> coeffs) {
  var run = 0;
  for (var k = 1; k < 64; k += 1) {
    final value = coeffs[jpegZigZag[k]];
    if (value == 0) {
      run += 1;
      continue;
    }
    while (run > 15) {
      bits.writeSymbol(0xf0);
      run -= 16;
    }
    _writeValue(bits, value, run);
    run = 0;
  }
  if (run > 0) {
    bits.writeSymbol(0);
  }
}

final class _ProgressiveFrame {
  const _ProgressiveFrame(this.components, this.mcuCols, this.mcuRows);

  final List<_ProgressiveComponent> components;
  final int mcuCols;
  final int mcuRows;
}

final class _ProgressiveComponent {
  _ProgressiveComponent(this.id, this.h, this.v, this.blockCols, this.blockRows)
    : blocks = List<List<int>>.generate(
        blockCols * blockRows,
        (_) => List<int>.filled(64, 0),
      );

  final int id;
  final int h;
  final int v;
  final int blockCols;
  final int blockRows;
  final List<List<int>> blocks;

  List<int> block(int x, int y) => blocks[y * blockCols + x];

  void setBlock(int x, int y, List<int> coeffs) {
    blocks[y * blockCols + x] = coeffs;
  }
}
