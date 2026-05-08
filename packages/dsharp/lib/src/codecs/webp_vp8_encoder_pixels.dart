part of 'webp_vp8.dart';

List<_Vp8Yuv> _lossyMacroblockColors(
  Uint8List rgba, {
  required int width,
  required int height,
  required int quality,
}) {
  final mbCols = (width + 15) >> 4;
  final mbRows = (height + 15) >> 4;
  final colors = <_Vp8Yuv>[];
  for (var mbY = 0; mbY < mbRows; mbY += 1) {
    for (var mbX = 0; mbX < mbCols; mbX += 1) {
      final average = _averageLossyMacroblock(
        rgba,
        width: width,
        height: height,
        mbX: mbX,
        mbY: mbY,
      );
      colors.add(_rgbToVp8Yuv(_quantizeLossyColor(average, quality)));
    }
  }
  return colors;
}

_Rgb _averageLossyMacroblock(
  Uint8List rgba, {
  required int width,
  required int height,
  required int mbX,
  required int mbY,
}) {
  var red = 0;
  var green = 0;
  var blue = 0;
  var pixels = 0;
  final xStart = mbX * 16;
  final yStart = mbY * 16;
  final xEnd = xStart + 16 < width ? xStart + 16 : width;
  final yEnd = yStart + 16 < height ? yStart + 16 : height;
  for (var y = yStart; y < yEnd; y += 1) {
    var offset = (y * width + xStart) * 4;
    for (var x = xStart; x < xEnd; x += 1) {
      red += rgba[offset];
      green += rgba[offset + 1];
      blue += rgba[offset + 2];
      pixels += 1;
      offset += 4;
    }
  }
  return _Rgb(
    (red + pixels ~/ 2) ~/ pixels,
    (green + pixels ~/ 2) ~/ pixels,
    (blue + pixels ~/ 2) ~/ pixels,
  );
}

List<int> _lossyLumaBlocks(
  Uint8List rgba, {
  required int width,
  required int height,
  required int quality,
  required List<_Vp8Yuv> macroblockColors,
}) {
  final mbCols = (width + 15) >> 4;
  final mbRows = (height + 15) >> 4;
  final blocks = <int>[];
  for (var mbY = 0; mbY < mbRows; mbY += 1) {
    for (var mbX = 0; mbX < mbCols; mbX += 1) {
      final fallback = macroblockColors[mbY * mbCols + mbX].y;
      for (var block = 0; block < 16; block += 1) {
        blocks.add(
          _lossyLumaBlock(
            rgba,
            width: width,
            height: height,
            quality: quality,
            mbX: mbX,
            mbY: mbY,
            block: block,
            fallback: fallback,
          ),
        );
      }
    }
  }
  return blocks;
}

int _lossyLumaBlock(
  Uint8List rgba, {
  required int width,
  required int height,
  required int quality,
  required int mbX,
  required int mbY,
  required int block,
  required int fallback,
}) {
  final blockX = block & 3;
  final blockY = block >> 2;
  final xStart = mbX * 16 + blockX * 4;
  final yStart = mbY * 16 + blockY * 4;
  if (xStart >= width || yStart >= height) {
    return fallback;
  }
  var red = 0;
  var green = 0;
  var blue = 0;
  var pixels = 0;
  final xEnd = xStart + 4 < width ? xStart + 4 : width;
  final yEnd = yStart + 4 < height ? yStart + 4 : height;
  for (var y = yStart; y < yEnd; y += 1) {
    var offset = (y * width + xStart) * 4;
    for (var x = xStart; x < xEnd; x += 1) {
      red += rgba[offset];
      green += rgba[offset + 1];
      blue += rgba[offset + 2];
      pixels += 1;
      offset += 4;
    }
  }
  return _rgbToVp8Yuv(
    _quantizeLossyColor(
      _Rgb(
        (red + pixels ~/ 2) ~/ pixels,
        (green + pixels ~/ 2) ~/ pixels,
        (blue + pixels ~/ 2) ~/ pixels,
      ),
      quality,
    ),
  ).y;
}

List<_Vp8Yuv> _lossyChromaBlocks(
  Uint8List rgba, {
  required int width,
  required int height,
  required int quality,
  required List<_Vp8Yuv> macroblockColors,
}) {
  final mbCols = (width + 15) >> 4;
  final mbRows = (height + 15) >> 4;
  final blocks = <_Vp8Yuv>[];
  for (var mbY = 0; mbY < mbRows; mbY += 1) {
    for (var mbX = 0; mbX < mbCols; mbX += 1) {
      final fallback = macroblockColors[mbY * mbCols + mbX];
      for (var block = 0; block < 4; block += 1) {
        blocks.add(
          _lossyChromaBlock(
            rgba,
            width: width,
            height: height,
            quality: quality,
            mbX: mbX,
            mbY: mbY,
            block: block,
            fallback: fallback,
          ),
        );
      }
    }
  }
  return blocks;
}

_Vp8Yuv _lossyChromaBlock(
  Uint8List rgba, {
  required int width,
  required int height,
  required int quality,
  required int mbX,
  required int mbY,
  required int block,
  required _Vp8Yuv fallback,
}) {
  final blockX = block & 1;
  final blockY = block >> 1;
  final xStart = mbX * 16 + blockX * 8;
  final yStart = mbY * 16 + blockY * 8;
  if (xStart >= width || yStart >= height) {
    return fallback;
  }
  var red = 0;
  var green = 0;
  var blue = 0;
  var pixels = 0;
  final xEnd = xStart + 8 < width ? xStart + 8 : width;
  final yEnd = yStart + 8 < height ? yStart + 8 : height;
  for (var y = yStart; y < yEnd; y += 1) {
    var offset = (y * width + xStart) * 4;
    for (var x = xStart; x < xEnd; x += 1) {
      red += rgba[offset];
      green += rgba[offset + 1];
      blue += rgba[offset + 2];
      pixels += 1;
      offset += 4;
    }
  }
  return _rgbToVp8Yuv(
    _quantizeLossyColor(
      _Rgb(
        (red + pixels ~/ 2) ~/ pixels,
        (green + pixels ~/ 2) ~/ pixels,
        (blue + pixels ~/ 2) ~/ pixels,
      ),
      quality,
    ),
  );
}

int _predictedSubblockDc(
  List<int> lumaBlocks,
  int mbCols,
  int mbX,
  int mbY,
  int block,
) {
  final blockX = block & 3;
  final blockY = block >> 2;
  final mbBase = (mbY * mbCols + mbX) * 16;
  final top = blockY > 0
      ? lumaBlocks[mbBase + block - 4]
      : mbY > 0
      ? lumaBlocks[((mbY - 1) * mbCols + mbX) * 16 + 12 + blockX]
      : 127;
  final left = blockX > 0
      ? lumaBlocks[mbBase + block - 1]
      : mbX > 0
      ? lumaBlocks[(mbY * mbCols + mbX - 1) * 16 + blockY * 4 + 3]
      : 129;
  return (4 + top * 4 + left * 4) >> 3;
}

int _predictedChromaDc(
  List<_Vp8Yuv> chromaBlocks,
  int mbCols,
  int mbX,
  int mbY,
  int Function(_Vp8Yuv color) sample,
) {
  final hasTop = mbY > 0;
  final hasLeft = mbX > 0;
  if (!hasTop && !hasLeft) {
    return 128;
  }
  var sum = 0;
  var count = 0;
  if (hasTop) {
    final topBase = ((mbY - 1) * mbCols + mbX) * 4;
    sum += sample(chromaBlocks[topBase + 2]) * 4;
    sum += sample(chromaBlocks[topBase + 3]) * 4;
    count += 8;
  }
  if (hasLeft) {
    final leftBase = (mbY * mbCols + mbX - 1) * 4;
    sum += sample(chromaBlocks[leftBase + 1]) * 4;
    sum += sample(chromaBlocks[leftBase + 3]) * 4;
    count += 8;
  }
  return (sum + (count >> 1)) ~/ count;
}

_Rgb _quantizeLossyColor(_Rgb color, int quality) {
  final step = _lossyStep(quality);
  return _Rgb(
    _quantizeLossySample(color.red, step),
    _quantizeLossySample(color.green, step),
    _quantizeLossySample(color.blue, step),
  );
}

_Vp8Yuv _rgbToVp8Yuv(_Rgb color) {
  final y =
      ((19595 * color.red + 38470 * color.green + 7471 * color.blue + 32768) >>
      16);
  final u = 128 + _shiftRightSigned((color.blue - y) * 36982 + 32768, 16);
  final v = 128 + _shiftRightSigned((color.red - y) * 46727 + 32768, 16);
  return _Vp8Yuv(_clampByte(y), _clampByte(u), _clampByte(v));
}

int _lossyStep(int quality) => (((100 - quality) + 12) ~/ 13) + 1;

int _quantizeLossySample(int value, int step) {
  final quantized = ((value + (step >> 1)) ~/ step) * step;
  return _clampByte(quantized);
}

int _clampByte(int value) => value < 0 ? 0 : (value > 255 ? 255 : value);

int _clampDctCoefficient(int value) {
  if (value < -2048) {
    return -2048;
  }
  if (value > 2048) {
    return 2048;
  }
  return value;
}

final class _Rgb {
  const _Rgb(this.red, this.green, this.blue);

  final int red;
  final int green;
  final int blue;
}

final class _Vp8Yuv {
  const _Vp8Yuv(this.y, this.u, this.v);

  final int y;
  final int u;
  final int v;
}
