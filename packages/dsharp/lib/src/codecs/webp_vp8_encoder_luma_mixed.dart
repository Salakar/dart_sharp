part of 'webp_vp8.dart';

typedef _LossyLumaAcBlocksBuilder =
    List<int> Function(
      Uint8List rgba, {
      required int width,
      required int height,
      required int quality,
    });

List<List<int>> _lossyLumaAcBlocks(
  Uint8List rgba, {
  required int width,
  required int height,
  required int quality,
}) {
  List<int> build(_LossyLumaAcBlocksBuilder builder) {
    return builder(rgba, width: width, height: height, quality: quality);
  }

  return <List<int>>[
    build(_lossyLumaHorizontalAcBlocks),
    build(_lossyLumaVerticalAcBlocks),
    build(_lossyLumaSecondVerticalAcBlocks),
    build(_lossyLumaDiagonalAcBlocks),
    build(_lossyLumaSecondHorizontalAcBlocks),
    build(_lossyLumaThirdHorizontalAcBlocks),
    build(_lossyLumaSecondHorizontalVerticalAcBlocks),
    build(_lossyLumaHorizontalSecondVerticalAcBlocks),
    build(_lossyLumaThirdVerticalAcBlocks),
    build(_lossyLumaHorizontalThirdVerticalAcBlocks),
    build(_lossyLumaSecondHorizontalSecondVerticalAcBlocks),
    build(_lossyLumaThirdHorizontalVerticalAcBlocks),
    build(_lossyLumaThirdHorizontalSecondVerticalAcBlocks),
    build(_lossyLumaSecondHorizontalThirdVerticalAcBlocks),
    build(_lossyLumaThirdHorizontalThirdVerticalAcBlocks),
  ];
}

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

List<int> _lossyLumaThirdHorizontalVerticalAcBlocks(
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
          _lossyLumaThirdHorizontalVerticalAcBlock(
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

List<int> _lossyLumaThirdHorizontalSecondVerticalAcBlocks(
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
          _lossyLumaThirdHorizontalSecondVerticalAcBlock(
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

List<int> _lossyLumaSecondHorizontalThirdVerticalAcBlocks(
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
          _lossyLumaSecondHorizontalThirdVerticalAcBlock(
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

List<int> _lossyLumaThirdHorizontalThirdVerticalAcBlocks(
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
          _lossyLumaThirdHorizontalThirdVerticalAcBlock(
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

int _lossyLumaThirdHorizontalVerticalAcBlock(
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
      return localX.isEven == (localY < 2);
    },
    scale: 2,
  );
}

int _lossyLumaThirdHorizontalSecondVerticalAcBlock(
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
      final isOuterRow = localY == 0 || localY == 3;
      return localX.isEven == isOuterRow;
    },
    scale: 2,
  );
}

int _lossyLumaSecondHorizontalThirdVerticalAcBlock(
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
      return isOuterColumn == localY.isEven;
    },
    scale: 2,
  );
}

int _lossyLumaThirdHorizontalThirdVerticalAcBlock(
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
      return localX.isEven == localY.isEven;
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
