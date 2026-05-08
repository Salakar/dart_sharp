part of 'webp_vp8.dart';

List<int> _lossyLumaSecondHorizontalVerticalAcBlocks(
  Uint8List rgba, {
  required int width,
  required int height,
  required int quality,
}) {
  final mbCols = (width + 15) >> 4;
  final mbRows = (height + 15) >> 4;
  final blocks = <int>[];
  for (var mbY = 0; mbY < mbRows; mbY += 1) {
    for (var mbX = 0; mbX < mbCols; mbX += 1) {
      for (var block = 0; block < 16; block += 1) {
        blocks.add(
          _lossyLumaSecondHorizontalVerticalAcBlock(
            rgba,
            width: width,
            height: height,
            quality: quality,
            mbX: mbX,
            mbY: mbY,
            block: block,
          ),
        );
      }
    }
  }
  return blocks;
}

List<int> _lossyLumaHorizontalSecondVerticalAcBlocks(
  Uint8List rgba, {
  required int width,
  required int height,
  required int quality,
}) {
  final mbCols = (width + 15) >> 4;
  final mbRows = (height + 15) >> 4;
  final blocks = <int>[];
  for (var mbY = 0; mbY < mbRows; mbY += 1) {
    for (var mbX = 0; mbX < mbCols; mbX += 1) {
      for (var block = 0; block < 16; block += 1) {
        blocks.add(
          _lossyLumaHorizontalSecondVerticalAcBlock(
            rgba,
            width: width,
            height: height,
            quality: quality,
            mbX: mbX,
            mbY: mbY,
            block: block,
          ),
        );
      }
    }
  }
  return blocks;
}

List<int> _lossyLumaHorizontalThirdVerticalAcBlocks(
  Uint8List rgba, {
  required int width,
  required int height,
  required int quality,
}) {
  final mbCols = (width + 15) >> 4;
  final mbRows = (height + 15) >> 4;
  final blocks = <int>[];
  for (var mbY = 0; mbY < mbRows; mbY += 1) {
    for (var mbX = 0; mbX < mbCols; mbX += 1) {
      for (var block = 0; block < 16; block += 1) {
        blocks.add(
          _lossyLumaHorizontalThirdVerticalAcBlock(
            rgba,
            width: width,
            height: height,
            quality: quality,
            mbX: mbX,
            mbY: mbY,
            block: block,
          ),
        );
      }
    }
  }
  return blocks;
}

List<int> _lossyLumaSecondHorizontalSecondVerticalAcBlocks(
  Uint8List rgba, {
  required int width,
  required int height,
  required int quality,
}) {
  final mbCols = (width + 15) >> 4;
  final mbRows = (height + 15) >> 4;
  final blocks = <int>[];
  for (var mbY = 0; mbY < mbRows; mbY += 1) {
    for (var mbX = 0; mbX < mbCols; mbX += 1) {
      for (var block = 0; block < 16; block += 1) {
        blocks.add(
          _lossyLumaSecondHorizontalSecondVerticalAcBlock(
            rgba,
            width: width,
            height: height,
            quality: quality,
            mbX: mbX,
            mbY: mbY,
            block: block,
          ),
        );
      }
    }
  }
  return blocks;
}

int _lossyLumaSecondHorizontalVerticalAcBlock(
  Uint8List rgba, {
  required int width,
  required int height,
  required int quality,
  required int mbX,
  required int mbY,
  required int block,
}) {
  return _lossyLumaMixedAcBlock(
    rgba,
    width: width,
    height: height,
    quality: quality,
    mbX: mbX,
    mbY: mbY,
    block: block,
    positive: (localX, localY) {
      final isTop = localY < 2;
      final isOuterColumn = localX == 0 || localX == 3;
      return isTop == isOuterColumn;
    },
  );
}

int _lossyLumaHorizontalSecondVerticalAcBlock(
  Uint8List rgba, {
  required int width,
  required int height,
  required int quality,
  required int mbX,
  required int mbY,
  required int block,
}) {
  return _lossyLumaMixedAcBlock(
    rgba,
    width: width,
    height: height,
    quality: quality,
    mbX: mbX,
    mbY: mbY,
    block: block,
    positive: (localX, localY) {
      final isLeft = localX < 2;
      final isOuterRow = localY == 0 || localY == 3;
      return isLeft == isOuterRow;
    },
  );
}

int _lossyLumaHorizontalThirdVerticalAcBlock(
  Uint8List rgba, {
  required int width,
  required int height,
  required int quality,
  required int mbX,
  required int mbY,
  required int block,
}) {
  return _lossyLumaMixedAcBlock(
    rgba,
    width: width,
    height: height,
    quality: quality,
    mbX: mbX,
    mbY: mbY,
    block: block,
    positive: (localX, localY) {
      final isLeft = localX < 2;
      return isLeft == localY.isEven;
    },
    scale: 2,
  );
}

int _lossyLumaSecondHorizontalSecondVerticalAcBlock(
  Uint8List rgba, {
  required int width,
  required int height,
  required int quality,
  required int mbX,
  required int mbY,
  required int block,
}) {
  return _lossyLumaMixedAcBlock(
    rgba,
    width: width,
    height: height,
    quality: quality,
    mbX: mbX,
    mbY: mbY,
    block: block,
    positive: (localX, localY) {
      final isOuterColumn = localX == 0 || localX == 3;
      final isOuterRow = localY == 0 || localY == 3;
      return isOuterColumn == isOuterRow;
    },
    scale: 2,
  );
}

int _lossyLumaMixedAcBlock(
  Uint8List rgba, {
  required int width,
  required int height,
  required int quality,
  required int mbX,
  required int mbY,
  required int block,
  required bool Function(int localX, int localY) positive,
  int scale = 1,
}) {
  final blockX = block & 3;
  final blockY = block >> 2;
  final xStart = mbX * 16 + blockX * 4;
  final yStart = mbY * 16 + blockY * 4;
  if (xStart + 3 >= width || yStart + 3 >= height) {
    return 0;
  }
  var positiveTotal = 0;
  var negativeTotal = 0;
  for (var y = yStart; y < yStart + 4; y += 1) {
    var offset = (y * width + xStart) * 4;
    for (var x = xStart; x < xStart + 4; x += 1) {
      final luma = _rgbToVp8Yuv(
        _quantizeLossyColor(
          _Rgb(rgba[offset], rgba[offset + 1], rgba[offset + 2]),
          quality,
        ),
      ).y;
      if (positive(x - xStart, y - yStart)) {
        positiveTotal += luma;
      } else {
        negativeTotal += luma;
      }
      offset += 4;
    }
  }
  final positiveAverage = (positiveTotal + 4) ~/ 8;
  final negativeAverage = (negativeTotal + 4) ~/ 8;
  return _clampDctCoefficient((positiveAverage - negativeAverage) * scale);
}
