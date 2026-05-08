part of 'webp_vp8.dart';

final class _Vp8ChromaAc {
  const _Vp8ChromaAc({required this.u, required this.v});

  final int u;
  final int v;
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
