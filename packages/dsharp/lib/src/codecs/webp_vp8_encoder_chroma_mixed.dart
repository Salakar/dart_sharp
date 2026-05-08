part of 'webp_vp8.dart';

typedef _LossyChromaMixedPredicate = bool Function(int sampleX, int sampleY);

_Vp8ChromaAc _lossyChromaSecondHorizontalVerticalAcBlock(
  Uint8List rgba, {
  required int width,
  required int height,
  required int quality,
  required int mbX,
  required int mbY,
  required int block,
}) {
  return _lossyChromaMixedAcBlock(
    rgba,
    width: width,
    height: height,
    quality: quality,
    mbX: mbX,
    mbY: mbY,
    block: block,
    positive: (sampleX, sampleY) {
      final isTop = sampleY < 2;
      final isOuterColumn = sampleX == 0 || sampleX == 3;
      return isTop == isOuterColumn;
    },
  );
}

_Vp8ChromaAc _lossyChromaHorizontalSecondVerticalAcBlock(
  Uint8List rgba, {
  required int width,
  required int height,
  required int quality,
  required int mbX,
  required int mbY,
  required int block,
}) {
  return _lossyChromaMixedAcBlock(
    rgba,
    width: width,
    height: height,
    quality: quality,
    mbX: mbX,
    mbY: mbY,
    block: block,
    positive: (sampleX, sampleY) {
      final isLeft = sampleX < 2;
      final isOuterRow = sampleY == 0 || sampleY == 3;
      return isLeft == isOuterRow;
    },
  );
}

_Vp8ChromaAc _lossyChromaHorizontalThirdVerticalAcBlock(
  Uint8List rgba, {
  required int width,
  required int height,
  required int quality,
  required int mbX,
  required int mbY,
  required int block,
}) {
  return _lossyChromaMixedAcBlock(
    rgba,
    width: width,
    height: height,
    quality: quality,
    mbX: mbX,
    mbY: mbY,
    block: block,
    positive: (sampleX, sampleY) {
      final isLeft = sampleX < 2;
      return isLeft == sampleY.isEven;
    },
    scale: 2,
  );
}

_Vp8ChromaAc _lossyChromaSecondHorizontalSecondVerticalAcBlock(
  Uint8List rgba, {
  required int width,
  required int height,
  required int quality,
  required int mbX,
  required int mbY,
  required int block,
}) {
  return _lossyChromaMixedAcBlock(
    rgba,
    width: width,
    height: height,
    quality: quality,
    mbX: mbX,
    mbY: mbY,
    block: block,
    positive: (sampleX, sampleY) {
      final isOuterColumn = sampleX == 0 || sampleX == 3;
      final isOuterRow = sampleY == 0 || sampleY == 3;
      return isOuterColumn == isOuterRow;
    },
    scale: 2,
  );
}

_Vp8ChromaAc _lossyChromaThirdHorizontalVerticalAcBlock(
  Uint8List rgba, {
  required int width,
  required int height,
  required int quality,
  required int mbX,
  required int mbY,
  required int block,
}) {
  return _lossyChromaMixedAcBlock(
    rgba,
    width: width,
    height: height,
    quality: quality,
    mbX: mbX,
    mbY: mbY,
    block: block,
    positive: (sampleX, sampleY) {
      return sampleX.isEven == (sampleY < 2);
    },
    scale: 2,
  );
}

_Vp8ChromaAc _lossyChromaMixedAcBlock(
  Uint8List rgba, {
  required int width,
  required int height,
  required int quality,
  required int mbX,
  required int mbY,
  required int block,
  required _LossyChromaMixedPredicate positive,
  int scale = 1,
}) {
  final blockX = block & 1;
  final blockY = block >> 1;
  final xStart = mbX * 16 + blockX * 8;
  final yStart = mbY * 16 + blockY * 8;
  if (xStart + 7 >= width || yStart + 7 >= height) {
    return const _Vp8ChromaAc(u: 0, v: 0);
  }
  var positiveU = 0;
  var positiveV = 0;
  var negativeU = 0;
  var negativeV = 0;
  var positivePixels = 0;
  var negativePixels = 0;
  for (var y = yStart; y < yStart + 8; y += 1) {
    var offset = (y * width + xStart) * 4;
    for (var x = xStart; x < xStart + 8; x += 1) {
      final color = _rgbToVp8Yuv(
        _quantizeLossyColor(
          _Rgb(rgba[offset], rgba[offset + 1], rgba[offset + 2]),
          quality,
        ),
      );
      final sampleX = (x - xStart) >> 1;
      final sampleY = (y - yStart) >> 1;
      if (positive(sampleX, sampleY)) {
        positiveU += color.u;
        positiveV += color.v;
        positivePixels += 1;
      } else {
        negativeU += color.u;
        negativeV += color.v;
        negativePixels += 1;
      }
      offset += 4;
    }
  }
  final positiveUAverage = (positiveU + positivePixels ~/ 2) ~/ positivePixels;
  final positiveVAverage = (positiveV + positivePixels ~/ 2) ~/ positivePixels;
  final negativeUAverage = (negativeU + negativePixels ~/ 2) ~/ negativePixels;
  final negativeVAverage = (negativeV + negativePixels ~/ 2) ~/ negativePixels;
  return _Vp8ChromaAc(
    u: _clampDctCoefficient((positiveUAverage - negativeUAverage) * scale),
    v: _clampDctCoefficient((positiveVAverage - negativeVAverage) * scale),
  );
}
