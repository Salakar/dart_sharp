part of 'webp_vp8.dart';

List<int> _lossyLumaHorizontalAcBlocks(
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
          _lossyLumaHorizontalAcBlock(
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

List<int> _lossyLumaVerticalAcBlocks(
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
          _lossyLumaVerticalAcBlock(
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

List<int> _lossyLumaSecondVerticalAcBlocks(
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
          _lossyLumaSecondVerticalAcBlock(
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

List<int> _lossyLumaDiagonalAcBlocks(
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
          _lossyLumaDiagonalAcBlock(
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

List<int> _lossyLumaSecondHorizontalAcBlocks(
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
          _lossyLumaSecondHorizontalAcBlock(
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

List<int> _lossyLumaThirdHorizontalAcBlocks(
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
          _lossyLumaThirdHorizontalAcBlock(
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

List<int> _lossyLumaThirdVerticalAcBlocks(
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
          _lossyLumaThirdVerticalAcBlock(
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

int _lossyLumaHorizontalAcBlock(
  Uint8List rgba, {
  required int width,
  required int height,
  required int quality,
  required int mbX,
  required int mbY,
  required int block,
}) {
  final blockX = block & 3;
  final blockY = block >> 2;
  final xStart = mbX * 16 + blockX * 4;
  final yStart = mbY * 16 + blockY * 4;
  if (xStart >= width || yStart >= height) {
    return 0;
  }
  var left = 0;
  var right = 0;
  var leftPixels = 0;
  var rightPixels = 0;
  final xEnd = xStart + 4 < width ? xStart + 4 : width;
  final yEnd = yStart + 4 < height ? yStart + 4 : height;
  for (var y = yStart; y < yEnd; y += 1) {
    var offset = (y * width + xStart) * 4;
    for (var x = xStart; x < xEnd; x += 1) {
      final luma = _rgbToVp8Yuv(
        _quantizeLossyColor(
          _Rgb(rgba[offset], rgba[offset + 1], rgba[offset + 2]),
          quality,
        ),
      ).y;
      if (x - xStart < 2) {
        left += luma;
        leftPixels += 1;
      } else {
        right += luma;
        rightPixels += 1;
      }
      offset += 4;
    }
  }
  if (leftPixels == 0 || rightPixels == 0) {
    return 0;
  }
  final leftAverage = (left + leftPixels ~/ 2) ~/ leftPixels;
  final rightAverage = (right + rightPixels ~/ 2) ~/ rightPixels;
  return _clampDctCoefficient(((leftAverage - rightAverage) * 3) ~/ 4);
}

int _lossyLumaVerticalAcBlock(
  Uint8List rgba, {
  required int width,
  required int height,
  required int quality,
  required int mbX,
  required int mbY,
  required int block,
}) {
  final blockX = block & 3;
  final blockY = block >> 2;
  final xStart = mbX * 16 + blockX * 4;
  final yStart = mbY * 16 + blockY * 4;
  if (xStart >= width || yStart >= height) {
    return 0;
  }
  var top = 0;
  var bottom = 0;
  var topPixels = 0;
  var bottomPixels = 0;
  final xEnd = xStart + 4 < width ? xStart + 4 : width;
  final yEnd = yStart + 4 < height ? yStart + 4 : height;
  for (var y = yStart; y < yEnd; y += 1) {
    var offset = (y * width + xStart) * 4;
    for (var x = xStart; x < xEnd; x += 1) {
      final luma = _rgbToVp8Yuv(
        _quantizeLossyColor(
          _Rgb(rgba[offset], rgba[offset + 1], rgba[offset + 2]),
          quality,
        ),
      ).y;
      if (y - yStart < 2) {
        top += luma;
        topPixels += 1;
      } else {
        bottom += luma;
        bottomPixels += 1;
      }
      offset += 4;
    }
  }
  if (topPixels == 0 || bottomPixels == 0) {
    return 0;
  }
  final topAverage = (top + topPixels ~/ 2) ~/ topPixels;
  final bottomAverage = (bottom + bottomPixels ~/ 2) ~/ bottomPixels;
  return _clampDctCoefficient(((topAverage - bottomAverage) * 3) ~/ 4);
}

int _lossyLumaSecondVerticalAcBlock(
  Uint8List rgba, {
  required int width,
  required int height,
  required int quality,
  required int mbX,
  required int mbY,
  required int block,
}) {
  final blockX = block & 3;
  final blockY = block >> 2;
  final xStart = mbX * 16 + blockX * 4;
  final yStart = mbY * 16 + blockY * 4;
  if (xStart >= width || yStart >= height) {
    return 0;
  }
  var outer = 0;
  var inner = 0;
  var outerPixels = 0;
  var innerPixels = 0;
  var topOuterPixels = 0;
  var bottomOuterPixels = 0;
  final xEnd = xStart + 4 < width ? xStart + 4 : width;
  final yEnd = yStart + 4 < height ? yStart + 4 : height;
  for (var y = yStart; y < yEnd; y += 1) {
    var offset = (y * width + xStart) * 4;
    for (var x = xStart; x < xEnd; x += 1) {
      final luma = _rgbToVp8Yuv(
        _quantizeLossyColor(
          _Rgb(rgba[offset], rgba[offset + 1], rgba[offset + 2]),
          quality,
        ),
      ).y;
      final localY = y - yStart;
      if (localY == 0) {
        outer += luma;
        outerPixels += 1;
        topOuterPixels += 1;
      } else if (localY == 3) {
        outer += luma;
        outerPixels += 1;
        bottomOuterPixels += 1;
      } else {
        inner += luma;
        innerPixels += 1;
      }
      offset += 4;
    }
  }
  if (topOuterPixels == 0 || bottomOuterPixels == 0 || innerPixels == 0) {
    return 0;
  }
  final outerAverage = (outer + outerPixels ~/ 2) ~/ outerPixels;
  final innerAverage = (inner + innerPixels ~/ 2) ~/ innerPixels;
  return _clampDctCoefficient(((outerAverage - innerAverage) * 3) ~/ 4);
}

int _lossyLumaThirdHorizontalAcBlock(
  Uint8List rgba, {
  required int width,
  required int height,
  required int quality,
  required int mbX,
  required int mbY,
  required int block,
}) {
  final blockX = block & 3;
  final blockY = block >> 2;
  final xStart = mbX * 16 + blockX * 4;
  final yStart = mbY * 16 + blockY * 4;
  if (xStart >= width || yStart >= height) {
    return 0;
  }
  var even = 0;
  var odd = 0;
  var evenPixels = 0;
  var oddPixels = 0;
  var col0Pixels = 0;
  var col1Pixels = 0;
  var col2Pixels = 0;
  var col3Pixels = 0;
  final xEnd = xStart + 4 < width ? xStart + 4 : width;
  final yEnd = yStart + 4 < height ? yStart + 4 : height;
  for (var y = yStart; y < yEnd; y += 1) {
    var offset = (y * width + xStart) * 4;
    for (var x = xStart; x < xEnd; x += 1) {
      final luma = _rgbToVp8Yuv(
        _quantizeLossyColor(
          _Rgb(rgba[offset], rgba[offset + 1], rgba[offset + 2]),
          quality,
        ),
      ).y;
      final localX = x - xStart;
      if (localX == 0) {
        even += luma;
        evenPixels += 1;
        col0Pixels += 1;
      } else if (localX == 1) {
        odd += luma;
        oddPixels += 1;
        col1Pixels += 1;
      } else if (localX == 2) {
        even += luma;
        evenPixels += 1;
        col2Pixels += 1;
      } else if (localX == 3) {
        odd += luma;
        oddPixels += 1;
        col3Pixels += 1;
      }
      offset += 4;
    }
  }
  if (col0Pixels == 0 ||
      col1Pixels == 0 ||
      col2Pixels == 0 ||
      col3Pixels == 0) {
    return 0;
  }
  final evenAverage = (even + evenPixels ~/ 2) ~/ evenPixels;
  final oddAverage = (odd + oddPixels ~/ 2) ~/ oddPixels;
  return _clampDctCoefficient(evenAverage - oddAverage);
}

int _lossyLumaThirdVerticalAcBlock(
  Uint8List rgba, {
  required int width,
  required int height,
  required int quality,
  required int mbX,
  required int mbY,
  required int block,
}) {
  final blockX = block & 3;
  final blockY = block >> 2;
  final xStart = mbX * 16 + blockX * 4;
  final yStart = mbY * 16 + blockY * 4;
  if (xStart >= width || yStart >= height) {
    return 0;
  }
  var even = 0;
  var odd = 0;
  var evenPixels = 0;
  var oddPixels = 0;
  var row0Pixels = 0;
  var row1Pixels = 0;
  var row2Pixels = 0;
  var row3Pixels = 0;
  final xEnd = xStart + 4 < width ? xStart + 4 : width;
  final yEnd = yStart + 4 < height ? yStart + 4 : height;
  for (var y = yStart; y < yEnd; y += 1) {
    var offset = (y * width + xStart) * 4;
    for (var x = xStart; x < xEnd; x += 1) {
      final luma = _rgbToVp8Yuv(
        _quantizeLossyColor(
          _Rgb(rgba[offset], rgba[offset + 1], rgba[offset + 2]),
          quality,
        ),
      ).y;
      final localY = y - yStart;
      if (localY == 0) {
        even += luma;
        evenPixels += 1;
        row0Pixels += 1;
      } else if (localY == 1) {
        odd += luma;
        oddPixels += 1;
        row1Pixels += 1;
      } else if (localY == 2) {
        even += luma;
        evenPixels += 1;
        row2Pixels += 1;
      } else if (localY == 3) {
        odd += luma;
        oddPixels += 1;
        row3Pixels += 1;
      }
      offset += 4;
    }
  }
  if (row0Pixels == 0 ||
      row1Pixels == 0 ||
      row2Pixels == 0 ||
      row3Pixels == 0) {
    return 0;
  }
  final evenAverage = (even + evenPixels ~/ 2) ~/ evenPixels;
  final oddAverage = (odd + oddPixels ~/ 2) ~/ oddPixels;
  return _clampDctCoefficient(evenAverage - oddAverage);
}

int _lossyLumaDiagonalAcBlock(
  Uint8List rgba, {
  required int width,
  required int height,
  required int quality,
  required int mbX,
  required int mbY,
  required int block,
}) {
  final blockX = block & 3;
  final blockY = block >> 2;
  final xStart = mbX * 16 + blockX * 4;
  final yStart = mbY * 16 + blockY * 4;
  if (xStart >= width || yStart >= height) {
    return 0;
  }
  var topLeft = 0;
  var topRight = 0;
  var bottomLeft = 0;
  var bottomRight = 0;
  var topLeftPixels = 0;
  var topRightPixels = 0;
  var bottomLeftPixels = 0;
  var bottomRightPixels = 0;
  final xEnd = xStart + 4 < width ? xStart + 4 : width;
  final yEnd = yStart + 4 < height ? yStart + 4 : height;
  for (var y = yStart; y < yEnd; y += 1) {
    var offset = (y * width + xStart) * 4;
    for (var x = xStart; x < xEnd; x += 1) {
      final luma = _rgbToVp8Yuv(
        _quantizeLossyColor(
          _Rgb(rgba[offset], rgba[offset + 1], rgba[offset + 2]),
          quality,
        ),
      ).y;
      final isTop = y - yStart < 2;
      final isLeft = x - xStart < 2;
      if (isTop && isLeft) {
        topLeft += luma;
        topLeftPixels += 1;
      } else if (isTop) {
        topRight += luma;
        topRightPixels += 1;
      } else if (isLeft) {
        bottomLeft += luma;
        bottomLeftPixels += 1;
      } else {
        bottomRight += luma;
        bottomRightPixels += 1;
      }
      offset += 4;
    }
  }
  if (topLeftPixels == 0 ||
      topRightPixels == 0 ||
      bottomLeftPixels == 0 ||
      bottomRightPixels == 0) {
    return 0;
  }
  final topLeftAverage = (topLeft + topLeftPixels ~/ 2) ~/ topLeftPixels;
  final topRightAverage = (topRight + topRightPixels ~/ 2) ~/ topRightPixels;
  final bottomLeftAverage =
      (bottomLeft + bottomLeftPixels ~/ 2) ~/ bottomLeftPixels;
  final bottomRightAverage =
      (bottomRight + bottomRightPixels ~/ 2) ~/ bottomRightPixels;
  final diagonal = topLeftAverage + bottomRightAverage;
  final antiDiagonal = topRightAverage + bottomLeftAverage;
  return _clampDctCoefficient(((diagonal - antiDiagonal) * 3) ~/ 8);
}

int _lossyLumaSecondHorizontalAcBlock(
  Uint8List rgba, {
  required int width,
  required int height,
  required int quality,
  required int mbX,
  required int mbY,
  required int block,
}) {
  final blockX = block & 3;
  final blockY = block >> 2;
  final xStart = mbX * 16 + blockX * 4;
  final yStart = mbY * 16 + blockY * 4;
  if (xStart >= width || yStart >= height) {
    return 0;
  }
  var outer = 0;
  var inner = 0;
  var outerPixels = 0;
  var innerPixels = 0;
  var leftOuterPixels = 0;
  var rightOuterPixels = 0;
  final xEnd = xStart + 4 < width ? xStart + 4 : width;
  final yEnd = yStart + 4 < height ? yStart + 4 : height;
  for (var y = yStart; y < yEnd; y += 1) {
    var offset = (y * width + xStart) * 4;
    for (var x = xStart; x < xEnd; x += 1) {
      final luma = _rgbToVp8Yuv(
        _quantizeLossyColor(
          _Rgb(rgba[offset], rgba[offset + 1], rgba[offset + 2]),
          quality,
        ),
      ).y;
      final localX = x - xStart;
      if (localX == 0) {
        outer += luma;
        outerPixels += 1;
        leftOuterPixels += 1;
      } else if (localX == 3) {
        outer += luma;
        outerPixels += 1;
        rightOuterPixels += 1;
      } else {
        inner += luma;
        innerPixels += 1;
      }
      offset += 4;
    }
  }
  if (leftOuterPixels == 0 || rightOuterPixels == 0 || innerPixels == 0) {
    return 0;
  }
  final outerAverage = (outer + outerPixels ~/ 2) ~/ outerPixels;
  final innerAverage = (inner + innerPixels ~/ 2) ~/ innerPixels;
  return _clampDctCoefficient(((outerAverage - innerAverage) * 3) ~/ 4);
}
