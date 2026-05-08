part of 'webp_vp8.dart';

final class _Vp8ChromaAc {
  const _Vp8ChromaAc({required this.u, required this.v});

  final int u;
  final int v;
}

typedef _LossyChromaAcBlocksBuilder =
    List<_Vp8ChromaAc> Function(
      Uint8List rgba, {
      required int width,
      required int height,
      required int quality,
    });

List<List<_Vp8ChromaAc>> _lossyChromaAcBlocks(
  Uint8List rgba, {
  required int width,
  required int height,
  required int quality,
}) {
  List<_Vp8ChromaAc> build(_LossyChromaAcBlocksBuilder builder) {
    return builder(rgba, width: width, height: height, quality: quality);
  }

  return <List<_Vp8ChromaAc>>[
    build(_lossyChromaHorizontalAcBlocks),
    build(_lossyChromaVerticalAcBlocks),
    build(_lossyChromaSecondVerticalAcBlocks),
    build(_lossyChromaDiagonalAcBlocks),
    build(_lossyChromaSecondHorizontalAcBlocks),
  ];
}

List<_Vp8ChromaAc> _lossyChromaHorizontalAcBlocks(
  Uint8List rgba, {
  required int width,
  required int height,
  required int quality,
}) {
  final mbCols = (width + 15) >> 4;
  final mbRows = (height + 15) >> 4;
  final blocks = <_Vp8ChromaAc>[];
  for (var mbY = 0; mbY < mbRows; mbY += 1) {
    for (var mbX = 0; mbX < mbCols; mbX += 1) {
      for (var block = 0; block < 4; block += 1) {
        blocks.add(
          _lossyChromaHorizontalAcBlock(
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

List<_Vp8ChromaAc> _lossyChromaVerticalAcBlocks(
  Uint8List rgba, {
  required int width,
  required int height,
  required int quality,
}) {
  final mbCols = (width + 15) >> 4;
  final mbRows = (height + 15) >> 4;
  final blocks = <_Vp8ChromaAc>[];
  for (var mbY = 0; mbY < mbRows; mbY += 1) {
    for (var mbX = 0; mbX < mbCols; mbX += 1) {
      for (var block = 0; block < 4; block += 1) {
        blocks.add(
          _lossyChromaVerticalAcBlock(
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

List<_Vp8ChromaAc> _lossyChromaSecondVerticalAcBlocks(
  Uint8List rgba, {
  required int width,
  required int height,
  required int quality,
}) {
  final mbCols = (width + 15) >> 4;
  final mbRows = (height + 15) >> 4;
  final blocks = <_Vp8ChromaAc>[];
  for (var mbY = 0; mbY < mbRows; mbY += 1) {
    for (var mbX = 0; mbX < mbCols; mbX += 1) {
      for (var block = 0; block < 4; block += 1) {
        blocks.add(
          _lossyChromaSecondVerticalAcBlock(
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

List<_Vp8ChromaAc> _lossyChromaDiagonalAcBlocks(
  Uint8List rgba, {
  required int width,
  required int height,
  required int quality,
}) {
  final mbCols = (width + 15) >> 4;
  final mbRows = (height + 15) >> 4;
  final blocks = <_Vp8ChromaAc>[];
  for (var mbY = 0; mbY < mbRows; mbY += 1) {
    for (var mbX = 0; mbX < mbCols; mbX += 1) {
      for (var block = 0; block < 4; block += 1) {
        blocks.add(
          _lossyChromaDiagonalAcBlock(
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

List<_Vp8ChromaAc> _lossyChromaSecondHorizontalAcBlocks(
  Uint8List rgba, {
  required int width,
  required int height,
  required int quality,
}) {
  final mbCols = (width + 15) >> 4;
  final mbRows = (height + 15) >> 4;
  final blocks = <_Vp8ChromaAc>[];
  for (var mbY = 0; mbY < mbRows; mbY += 1) {
    for (var mbX = 0; mbX < mbCols; mbX += 1) {
      for (var block = 0; block < 4; block += 1) {
        blocks.add(
          _lossyChromaSecondHorizontalAcBlock(
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

_Vp8ChromaAc _lossyChromaHorizontalAcBlock(
  Uint8List rgba, {
  required int width,
  required int height,
  required int quality,
  required int mbX,
  required int mbY,
  required int block,
}) {
  final blockX = block & 1;
  final blockY = block >> 1;
  final xStart = mbX * 16 + blockX * 8;
  final yStart = mbY * 16 + blockY * 8;
  if (xStart >= width || yStart >= height) {
    return const _Vp8ChromaAc(u: 0, v: 0);
  }
  var leftU = 0;
  var leftV = 0;
  var rightU = 0;
  var rightV = 0;
  var leftPixels = 0;
  var rightPixels = 0;
  final xEnd = xStart + 8 < width ? xStart + 8 : width;
  final yEnd = yStart + 8 < height ? yStart + 8 : height;
  for (var y = yStart; y < yEnd; y += 1) {
    var offset = (y * width + xStart) * 4;
    for (var x = xStart; x < xEnd; x += 1) {
      final color = _rgbToVp8Yuv(
        _quantizeLossyColor(
          _Rgb(rgba[offset], rgba[offset + 1], rgba[offset + 2]),
          quality,
        ),
      );
      if (x - xStart < 4) {
        leftU += color.u;
        leftV += color.v;
        leftPixels += 1;
      } else {
        rightU += color.u;
        rightV += color.v;
        rightPixels += 1;
      }
      offset += 4;
    }
  }
  if (leftPixels == 0 || rightPixels == 0) {
    return const _Vp8ChromaAc(u: 0, v: 0);
  }
  final leftUAverage = (leftU + leftPixels ~/ 2) ~/ leftPixels;
  final leftVAverage = (leftV + leftPixels ~/ 2) ~/ leftPixels;
  final rightUAverage = (rightU + rightPixels ~/ 2) ~/ rightPixels;
  final rightVAverage = (rightV + rightPixels ~/ 2) ~/ rightPixels;
  return _Vp8ChromaAc(
    u: _clampDctCoefficient(((leftUAverage - rightUAverage) * 3) ~/ 4),
    v: _clampDctCoefficient(((leftVAverage - rightVAverage) * 3) ~/ 4),
  );
}

_Vp8ChromaAc _lossyChromaSecondHorizontalAcBlock(
  Uint8List rgba, {
  required int width,
  required int height,
  required int quality,
  required int mbX,
  required int mbY,
  required int block,
}) {
  final blockX = block & 1;
  final blockY = block >> 1;
  final xStart = mbX * 16 + blockX * 8;
  final yStart = mbY * 16 + blockY * 8;
  if (xStart >= width || yStart >= height) {
    return const _Vp8ChromaAc(u: 0, v: 0);
  }
  var outerU = 0;
  var outerV = 0;
  var innerU = 0;
  var innerV = 0;
  var outerPixels = 0;
  var innerPixels = 0;
  var leftOuterPixels = 0;
  var rightOuterPixels = 0;
  final xEnd = xStart + 8 < width ? xStart + 8 : width;
  final yEnd = yStart + 8 < height ? yStart + 8 : height;
  for (var y = yStart; y < yEnd; y += 1) {
    var offset = (y * width + xStart) * 4;
    for (var x = xStart; x < xEnd; x += 1) {
      final color = _rgbToVp8Yuv(
        _quantizeLossyColor(
          _Rgb(rgba[offset], rgba[offset + 1], rgba[offset + 2]),
          quality,
        ),
      );
      final localX = x - xStart;
      if (localX < 2) {
        outerU += color.u;
        outerV += color.v;
        outerPixels += 1;
        leftOuterPixels += 1;
      } else if (localX >= 6) {
        outerU += color.u;
        outerV += color.v;
        outerPixels += 1;
        rightOuterPixels += 1;
      } else {
        innerU += color.u;
        innerV += color.v;
        innerPixels += 1;
      }
      offset += 4;
    }
  }
  if (leftOuterPixels == 0 || rightOuterPixels == 0 || innerPixels == 0) {
    return const _Vp8ChromaAc(u: 0, v: 0);
  }
  final outerUAverage = (outerU + outerPixels ~/ 2) ~/ outerPixels;
  final outerVAverage = (outerV + outerPixels ~/ 2) ~/ outerPixels;
  final innerUAverage = (innerU + innerPixels ~/ 2) ~/ innerPixels;
  final innerVAverage = (innerV + innerPixels ~/ 2) ~/ innerPixels;
  return _Vp8ChromaAc(
    u: _clampDctCoefficient(((outerUAverage - innerUAverage) * 3) ~/ 4),
    v: _clampDctCoefficient(((outerVAverage - innerVAverage) * 3) ~/ 4),
  );
}

_Vp8ChromaAc _lossyChromaVerticalAcBlock(
  Uint8List rgba, {
  required int width,
  required int height,
  required int quality,
  required int mbX,
  required int mbY,
  required int block,
}) {
  final blockX = block & 1;
  final blockY = block >> 1;
  final xStart = mbX * 16 + blockX * 8;
  final yStart = mbY * 16 + blockY * 8;
  if (xStart >= width || yStart >= height) {
    return const _Vp8ChromaAc(u: 0, v: 0);
  }
  var topU = 0;
  var topV = 0;
  var bottomU = 0;
  var bottomV = 0;
  var topPixels = 0;
  var bottomPixels = 0;
  final xEnd = xStart + 8 < width ? xStart + 8 : width;
  final yEnd = yStart + 8 < height ? yStart + 8 : height;
  for (var y = yStart; y < yEnd; y += 1) {
    var offset = (y * width + xStart) * 4;
    for (var x = xStart; x < xEnd; x += 1) {
      final color = _rgbToVp8Yuv(
        _quantizeLossyColor(
          _Rgb(rgba[offset], rgba[offset + 1], rgba[offset + 2]),
          quality,
        ),
      );
      if (y - yStart < 4) {
        topU += color.u;
        topV += color.v;
        topPixels += 1;
      } else {
        bottomU += color.u;
        bottomV += color.v;
        bottomPixels += 1;
      }
      offset += 4;
    }
  }
  if (topPixels == 0 || bottomPixels == 0) {
    return const _Vp8ChromaAc(u: 0, v: 0);
  }
  final topUAverage = (topU + topPixels ~/ 2) ~/ topPixels;
  final topVAverage = (topV + topPixels ~/ 2) ~/ topPixels;
  final bottomUAverage = (bottomU + bottomPixels ~/ 2) ~/ bottomPixels;
  final bottomVAverage = (bottomV + bottomPixels ~/ 2) ~/ bottomPixels;
  return _Vp8ChromaAc(
    u: _clampDctCoefficient(((topUAverage - bottomUAverage) * 3) ~/ 4),
    v: _clampDctCoefficient(((topVAverage - bottomVAverage) * 3) ~/ 4),
  );
}

_Vp8ChromaAc _lossyChromaSecondVerticalAcBlock(
  Uint8List rgba, {
  required int width,
  required int height,
  required int quality,
  required int mbX,
  required int mbY,
  required int block,
}) {
  final blockX = block & 1;
  final blockY = block >> 1;
  final xStart = mbX * 16 + blockX * 8;
  final yStart = mbY * 16 + blockY * 8;
  if (xStart >= width || yStart >= height) {
    return const _Vp8ChromaAc(u: 0, v: 0);
  }
  var outerU = 0;
  var outerV = 0;
  var innerU = 0;
  var innerV = 0;
  var outerPixels = 0;
  var innerPixels = 0;
  var topOuterPixels = 0;
  var bottomOuterPixels = 0;
  final xEnd = xStart + 8 < width ? xStart + 8 : width;
  final yEnd = yStart + 8 < height ? yStart + 8 : height;
  for (var y = yStart; y < yEnd; y += 1) {
    var offset = (y * width + xStart) * 4;
    for (var x = xStart; x < xEnd; x += 1) {
      final color = _rgbToVp8Yuv(
        _quantizeLossyColor(
          _Rgb(rgba[offset], rgba[offset + 1], rgba[offset + 2]),
          quality,
        ),
      );
      final localY = y - yStart;
      if (localY < 2) {
        outerU += color.u;
        outerV += color.v;
        outerPixels += 1;
        topOuterPixels += 1;
      } else if (localY >= 6) {
        outerU += color.u;
        outerV += color.v;
        outerPixels += 1;
        bottomOuterPixels += 1;
      } else {
        innerU += color.u;
        innerV += color.v;
        innerPixels += 1;
      }
      offset += 4;
    }
  }
  if (topOuterPixels == 0 || bottomOuterPixels == 0 || innerPixels == 0) {
    return const _Vp8ChromaAc(u: 0, v: 0);
  }
  final outerUAverage = (outerU + outerPixels ~/ 2) ~/ outerPixels;
  final outerVAverage = (outerV + outerPixels ~/ 2) ~/ outerPixels;
  final innerUAverage = (innerU + innerPixels ~/ 2) ~/ innerPixels;
  final innerVAverage = (innerV + innerPixels ~/ 2) ~/ innerPixels;
  return _Vp8ChromaAc(
    u: _clampDctCoefficient(((outerUAverage - innerUAverage) * 3) ~/ 4),
    v: _clampDctCoefficient(((outerVAverage - innerVAverage) * 3) ~/ 4),
  );
}

_Vp8ChromaAc _lossyChromaDiagonalAcBlock(
  Uint8List rgba, {
  required int width,
  required int height,
  required int quality,
  required int mbX,
  required int mbY,
  required int block,
}) {
  final blockX = block & 1;
  final blockY = block >> 1;
  final xStart = mbX * 16 + blockX * 8;
  final yStart = mbY * 16 + blockY * 8;
  if (xStart >= width || yStart >= height) {
    return const _Vp8ChromaAc(u: 0, v: 0);
  }
  var diagonalU = 0;
  var diagonalV = 0;
  var antiDiagonalU = 0;
  var antiDiagonalV = 0;
  var diagonalPixels = 0;
  var antiDiagonalPixels = 0;
  final xEnd = xStart + 8 < width ? xStart + 8 : width;
  final yEnd = yStart + 8 < height ? yStart + 8 : height;
  for (var y = yStart; y < yEnd; y += 1) {
    var offset = (y * width + xStart) * 4;
    for (var x = xStart; x < xEnd; x += 1) {
      final color = _rgbToVp8Yuv(
        _quantizeLossyColor(
          _Rgb(rgba[offset], rgba[offset + 1], rgba[offset + 2]),
          quality,
        ),
      );
      final isLeft = x - xStart < 4;
      final isTop = y - yStart < 4;
      if (isLeft == isTop) {
        diagonalU += color.u;
        diagonalV += color.v;
        diagonalPixels += 1;
      } else {
        antiDiagonalU += color.u;
        antiDiagonalV += color.v;
        antiDiagonalPixels += 1;
      }
      offset += 4;
    }
  }
  if (diagonalPixels == 0 || antiDiagonalPixels == 0) {
    return const _Vp8ChromaAc(u: 0, v: 0);
  }
  final diagonalUAverage = (diagonalU + diagonalPixels ~/ 2) ~/ diagonalPixels;
  final diagonalVAverage = (diagonalV + diagonalPixels ~/ 2) ~/ diagonalPixels;
  final antiDiagonalUAverage =
      (antiDiagonalU + antiDiagonalPixels ~/ 2) ~/ antiDiagonalPixels;
  final antiDiagonalVAverage =
      (antiDiagonalV + antiDiagonalPixels ~/ 2) ~/ antiDiagonalPixels;
  return _Vp8ChromaAc(
    u: _clampDctCoefficient(
      ((diagonalUAverage - antiDiagonalUAverage) * 3) ~/ 4,
    ),
    v: _clampDctCoefficient(
      ((diagonalVAverage - antiDiagonalVAverage) * 3) ~/ 4,
    ),
  );
}
