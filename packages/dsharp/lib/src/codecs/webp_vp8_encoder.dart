part of 'webp_vp8.dart';

/// Encodes a static image as a simple lossy VP8 WebP keyframe.
Uint8List encodeWebpVp8(
  RawPixels raw, {
  required int quality,
  required int alphaQuality,
}) {
  _validateLossyDimensions(raw);
  final rgba = rawToRgba(raw);
  final vp8 = _encodeVp8SolidFromRgba(
    rgba,
    width: raw.width,
    height: raw.height,
    quality: quality,
  );
  final alpha = _lossyAlphaPayload(rgba, alphaQuality);
  if (alpha == null) {
    return _simpleVp8Webp(vp8);
  }
  return _extendedVp8Webp(
    vp8,
    width: raw.width,
    height: raw.height,
    alpha: alpha,
  );
}

/// Encodes animation frames as simple lossy VP8 WebP keyframes.
Uint8List encodeAnimatedWebpVp8(
  PixelImage image, {
  required int quality,
  required int alphaQuality,
}) {
  final content = ByteWriter()
    ..writeAscii('WEBP')
    ..writeAscii('VP8X')
    ..writeUint32Le(10)
    ..writeByte(_hasLossyAnimationAlpha(image) ? 0x12 : 0x02)
    ..writeByte(0)
    ..writeByte(0)
    ..writeByte(0);
  _writeUint24Le(content, image.width - 1);
  _writeUint24Le(content, image.height - 1);
  _writeWebpChunk(
    content,
    'ANIM',
    _lossyAnimationPayload(image.loopCount ?? 0),
  );
  for (final frame in image.frames) {
    _writeWebpChunk(
      content,
      'ANMF',
      _lossyFramePayload(frame, quality: quality, alphaQuality: alphaQuality),
    );
  }
  return _riffWebp(content.toBytes());
}

Uint8List _encodeVp8SolidFromRgba(
  Uint8List rgba, {
  required int width,
  required int height,
  required int quality,
}) {
  final colors = _lossyMacroblockColors(
    rgba,
    width: width,
    height: height,
    quality: quality,
  );
  final lumaBlocks = _lossyLumaBlocks(
    rgba,
    width: width,
    height: height,
    quality: quality,
    macroblockColors: colors,
  );
  return _encodeVp8SolidPayload(
    width: width,
    height: height,
    colors: colors,
    lumaBlocks: lumaBlocks,
  );
}

Uint8List _lossyAnimationPayload(int loopCount) {
  if (loopCount < 0 || loopCount > 0xffff) {
    throw const OperationValidationException(
      'WebP loop count must be 0..65535.',
    );
  }
  final writer = ByteWriter()
    ..writeUint32Le(0)
    ..writeUint16Le(loopCount);
  return writer.toBytes();
}

Uint8List _lossyFramePayload(
  ImageFrame frame, {
  required int quality,
  required int alphaQuality,
}) {
  _validateLossyDimensions(frame.pixels);
  final rgba = rawToRgba(frame.pixels);
  final vp8 = _encodeVp8SolidFromRgba(
    rgba,
    width: frame.width,
    height: frame.height,
    quality: quality,
  );
  final writer = ByteWriter();
  _writeUint24Le(writer, 0);
  _writeUint24Le(writer, 0);
  _writeUint24Le(writer, frame.width - 1);
  _writeUint24Le(writer, frame.height - 1);
  final durationMs = frame.delay?.inMilliseconds ?? 0;
  if (durationMs < 0 || durationMs > 0xffffff) {
    throw const OperationValidationException(
      'WebP frame delay must be 0..16777215 ms.',
    );
  }
  _writeUint24Le(writer, durationMs);
  writer.writeByte(0x02);
  final alpha = _lossyAlphaPayload(rgba, alphaQuality);
  if (alpha != null) {
    _writeWebpChunk(writer, 'ALPH', alpha);
  }
  _writeWebpChunk(writer, 'VP8 ', vp8);
  return writer.toBytes();
}

void _validateLossyDimensions(RawPixels raw) {
  if (raw.width > 16383 || raw.height > 16383) {
    throw const OperationValidationException(
      'Lossy WebP dimensions must be at most 16383x16383.',
    );
  }
}

bool _hasLossyAnimationAlpha(PixelImage image) {
  for (final frame in image.frames) {
    final bytes = rawToRgba(frame.pixels);
    for (var offset = 3; offset < bytes.length; offset += 4) {
      if (bytes[offset] != 255) {
        return true;
      }
    }
  }
  return false;
}

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
  final u = 128 + (((color.blue - y) * 36982 + 32768) >> 16);
  final v = 128 + (((color.red - y) * 46727 + 32768) >> 16);
  return _Vp8Yuv(_clampByte(y), _clampByte(u), _clampByte(v));
}

Uint8List _encodeVp8SolidPayload({
  required int width,
  required int height,
  required List<_Vp8Yuv> colors,
  required List<int> lumaBlocks,
}) {
  final mbCols = (width + 15) >> 4;
  final mbRows = (height + 15) >> 4;
  final first = _Vp8BoolWriter()
    ..bit(false)
    ..bit(false)
    ..bit(false)
    ..bit(false)
    ..literal(0, 6)
    ..literal(0, 3)
    ..bit(false)
    ..literal(0, 2)
    ..literal(0, 7);
  for (var i = 0; i < 5; i += 1) {
    first.bit(false);
  }
  first.bit(false);
  for (var i = 0; i < 4 * 8 * 3 * 11; i += 1) {
    first.prob(_coefficientUpdateProbCodes.codeUnitAt(i), false);
  }
  first.bit(false);
  for (var i = 0; i < mbCols * mbRows; i += 1) {
    _writeVp8BPredMode(first);
    for (var block = 0; block < 16; block += 1) {
      _writeVp8BMode0(first);
    }
    first.prob(142, false);
  }
  final firstPartition = first.finish();
  final coeffs = _Vp8BoolWriter();
  final contexts = _Vp8TokenContexts(mbCols);
  for (var mbY = 0; mbY < mbRows; mbY += 1) {
    contexts.resetLeft();
    for (var mbX = 0; mbX < mbCols; mbX += 1) {
      final color = colors[mbY * mbCols + mbX];
      for (var block = 0; block < 16; block += 1) {
        final target = lumaBlocks[(mbY * mbCols + mbX) * 16 + block];
        _writeLumaDc(
          coeffs,
          contexts,
          mbX,
          block,
          (target - _predictedSubblockDc(lumaBlocks, mbCols, mbX, mbY, block)) *
              2,
        );
      }
      for (var block = 0; block < 4; block += 1) {
        _writeChromaDc(
          coeffs,
          contexts,
          mbX,
          16 + block,
          (color.u -
                  _predictedMacroblockDc(
                    colors,
                    mbCols,
                    mbX,
                    mbY,
                    (c) => c.u,
                  )) *
              2,
        );
      }
      for (var block = 0; block < 4; block += 1) {
        _writeChromaDc(
          coeffs,
          contexts,
          mbX,
          20 + block,
          (color.v -
                  _predictedMacroblockDc(
                    colors,
                    mbCols,
                    mbX,
                    mbY,
                    (c) => c.v,
                  )) *
              2,
        );
      }
    }
  }
  final tokenPartition = coeffs.finish();
  final writer = ByteWriter()
    ..writeByte((1 << 4) | ((firstPartition.length << 5) & 0xff))
    ..writeByte(firstPartition.length >> 3)
    ..writeByte(firstPartition.length >> 11)
    ..writeByte(0x9d)
    ..writeByte(0x01)
    ..writeByte(0x2a)
    ..writeUint16Le(width)
    ..writeUint16Le(height)
    ..writeBytes(firstPartition)
    ..writeBytes(tokenPartition);
  return writer.toBytes();
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

int _predictedMacroblockDc(
  List<_Vp8Yuv> colors,
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
  if (hasTop && hasLeft) {
    final top = sample(colors[(mbY - 1) * mbCols + mbX]);
    final left = sample(colors[mbY * mbCols + mbX - 1]);
    return (top + left + 1) >> 1;
  }
  if (hasTop) {
    return sample(colors[(mbY - 1) * mbCols + mbX]);
  }
  return sample(colors[mbY * mbCols + mbX - 1]);
}

void _writeLumaDc(
  _Vp8BoolWriter out,
  _Vp8TokenContexts contexts,
  int mbX,
  int block,
  int coefficient,
) {
  final probs = _Vp8LumaProbs.defaults();
  final context = contexts.contextFor(mbX, block);
  if (coefficient == 0) {
    out.prob(probs.probabilityAt(0, context, _dctEobNode), false);
    contexts.setHasCoefficients(mbX, block, false);
    return;
  }
  _writeDctToken(out, coefficient, context, (coefficientIndex, context, node) {
    return probs.probabilityAt(coefficientIndex, context, node);
  });
  contexts.setHasCoefficients(mbX, block, true);
}

void _writeChromaDc(
  _Vp8BoolWriter out,
  _Vp8TokenContexts contexts,
  int mbX,
  int block,
  int coefficient,
) {
  final context = contexts.contextFor(mbX, block);
  final probs = _Vp8ChromaProbs.defaults();
  if (coefficient == 0) {
    out.prob(probs.probabilityAt(0, context, _dctEobNode), false);
    contexts.setHasCoefficients(mbX, block, false);
    return;
  }
  _writeDctToken(out, coefficient, context, (coefficientIndex, context, node) {
    return probs.probabilityAt(coefficientIndex, context, node);
  });
  contexts.setHasCoefficients(mbX, block, true);
}

void _writeDctToken(
  _Vp8BoolWriter out,
  int coefficient,
  int initialContext,
  int Function(int coefficientIndex, int context, int node) probabilityAt,
) {
  final magnitude = coefficient.abs();
  int currentProbability(int node) => probabilityAt(0, initialContext, node);
  out
    ..prob(currentProbability(_dctEobNode), true)
    ..prob(currentProbability(_dctZeroNode), true);
  _writeDctMagnitude(out, magnitude, currentProbability);
  out.bit(coefficient.isNegative);
  final nextContext = magnitude == 1 ? 1 : 2;
  out.prob(probabilityAt(1, nextContext, _dctEobNode), false);
}

void _writeDctMagnitude(
  _Vp8BoolWriter out,
  int magnitude,
  int Function(int node) probabilityAt,
) {
  if (magnitude == 1) {
    out.prob(probabilityAt(_dctOneNode), false);
    return;
  }
  out.prob(probabilityAt(_dctOneNode), true);
  if (magnitude <= 4) {
    out
      ..prob(probabilityAt(_dctSmallNode), false)
      ..prob(probabilityAt(_dctTwoNode), magnitude > 2);
    if (magnitude > 2) {
      out.prob(probabilityAt(_dctThreeNode), magnitude == 4);
    }
    return;
  }
  out.prob(probabilityAt(_dctSmallNode), true);
  if (magnitude <= 6) {
    out
      ..prob(probabilityAt(_dctHighLowNode), false)
      ..prob(probabilityAt(_dctCatOneNode), false)
      ..prob(_catOneExtraProb, magnitude == 6);
    return;
  }
  if (magnitude <= 10) {
    out
      ..prob(probabilityAt(_dctHighLowNode), false)
      ..prob(probabilityAt(_dctCatOneNode), true);
    _writeExtraBits(out, magnitude - 7, _catTwoExtraProbs);
    return;
  }
  if (magnitude <= 18) {
    out
      ..prob(probabilityAt(_dctHighLowNode), true)
      ..prob(probabilityAt(_dctCatThreeFourNode), false)
      ..prob(probabilityAt(_dctCatThreeNode), false);
    _writeExtraBits(out, magnitude - 11, _catThreeExtraProbs);
    return;
  }
  if (magnitude <= 34) {
    out
      ..prob(probabilityAt(_dctHighLowNode), true)
      ..prob(probabilityAt(_dctCatThreeFourNode), false)
      ..prob(probabilityAt(_dctCatThreeNode), true);
    _writeExtraBits(out, magnitude - 19, _catFourExtraProbs);
    return;
  }
  if (magnitude <= 66) {
    out
      ..prob(probabilityAt(_dctHighLowNode), true)
      ..prob(probabilityAt(_dctCatThreeFourNode), true)
      ..prob(probabilityAt(_dctCatFiveNode), false);
    _writeExtraBits(out, magnitude - 35, _catFiveExtraProbs);
    return;
  }
  out
    ..prob(probabilityAt(_dctHighLowNode), true)
    ..prob(probabilityAt(_dctCatThreeFourNode), true)
    ..prob(probabilityAt(_dctCatFiveNode), true);
  _writeExtraBits(out, magnitude - 67, _catSixExtraProbs);
}

void _writeExtraBits(_Vp8BoolWriter out, int value, List<int> probabilities) {
  for (var i = 0; i < probabilities.length; i += 1) {
    final shift = probabilities.length - i - 1;
    out.prob(probabilities[i], ((value >> shift) & 1) == 1);
  }
}

void _writeVp8BPredMode(_Vp8BoolWriter out) => out.prob(145, false);

void _writeVp8BMode0(_Vp8BoolWriter out) =>
    out.prob(_kfBModeProb[0][0][0], false);

Uint8List? _lossyAlphaPayload(Uint8List rgba, int quality) {
  var hasAlpha = false;
  final alpha = Uint8List((rgba.length ~/ 4) + 1);
  for (var i = 0; i < alpha.length - 1; i += 1) {
    final value = rgba[i * 4 + 3];
    alpha[i + 1] = _quantizeLossySample(value, _lossyStep(quality));
    hasAlpha = hasAlpha || alpha[i + 1] != 255;
  }
  return hasAlpha ? alpha : null;
}

Uint8List _simpleVp8Webp(Uint8List vp8) {
  final content = ByteWriter()..writeAscii('WEBP');
  _writeWebpChunk(content, 'VP8 ', vp8);
  return _riffWebp(content.toBytes());
}

Uint8List _extendedVp8Webp(
  Uint8List vp8, {
  required int width,
  required int height,
  required Uint8List alpha,
}) {
  final content = ByteWriter()
    ..writeAscii('WEBP')
    ..writeAscii('VP8X')
    ..writeUint32Le(10)
    ..writeByte(0x10)
    ..writeByte(0)
    ..writeByte(0)
    ..writeByte(0);
  _writeUint24Le(content, width - 1);
  _writeUint24Le(content, height - 1);
  _writeWebpChunk(content, 'ALPH', alpha);
  _writeWebpChunk(content, 'VP8 ', vp8);
  return _riffWebp(content.toBytes());
}

Uint8List _riffWebp(Uint8List content) {
  final writer = ByteWriter()
    ..writeAscii('RIFF')
    ..writeUint32Le(content.length)
    ..writeBytes(content);
  return writer.toBytes();
}

void _writeWebpChunk(ByteWriter writer, String type, Uint8List payload) {
  writer
    ..writeAscii(type)
    ..writeUint32Le(payload.length)
    ..writeBytes(payload);
  if (payload.length.isOdd) {
    writer.writeByte(0);
  }
}

void _writeUint24Le(ByteWriter writer, int value) {
  writer
    ..writeByte(value)
    ..writeByte(value >> 8)
    ..writeByte(value >> 16);
}

int _lossyStep(int quality) => (((100 - quality) + 12) ~/ 13) + 1;

int _quantizeLossySample(int value, int step) {
  final quantized = ((value + (step >> 1)) ~/ step) * step;
  return _clampByte(quantized);
}

int _clampByte(int value) => value < 0 ? 0 : (value > 255 ? 255 : value);

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

final class _Vp8BoolWriter {
  final _bytes = <int>[];
  var _range = 255;
  var _bottom = 0;
  var _bitCount = 24;

  void bit(bool value) => prob(128, value);

  void literal(int value, int bits) {
    for (var bit = bits - 1; bit >= 0; bit -= 1) {
      prob(128, ((value >> bit) & 1) == 1);
    }
  }

  void prob(int probability, bool value) {
    final split = 1 + (((_range - 1) * probability) >> 8);
    if (value) {
      _bottom = (_bottom + split) & 0xffffffff;
      _range -= split;
    } else {
      _range = split;
    }
    while (_range < 128) {
      _range <<= 1;
      if ((_bottom & 0x80000000) != 0) {
        _addOneToOutput();
      }
      _bottom = (_bottom << 1) & 0xffffffff;
      _bitCount -= 1;
      if (_bitCount == 0) {
        _bytes.add((_bottom >> 24) & 0xff);
        _bottom &= 0x00ffffff;
        _bitCount = 8;
      }
    }
  }

  Uint8List finish() {
    var c = _bitCount;
    var value = _bottom;
    if ((value & (1 << (32 - c))) != 0) {
      _addOneToOutput();
    }
    value = (value << (c & 7)) & 0xffffffff;
    c >>= 3;
    while (true) {
      c -= 1;
      if (c < 0) {
        break;
      }
      value = (value << 8) & 0xffffffff;
    }
    for (var i = 0; i < 4; i += 1) {
      _bytes.add((value >> 24) & 0xff);
      value = (value << 8) & 0xffffffff;
    }
    return Uint8List.fromList(_bytes);
  }

  void _addOneToOutput() {
    var index = _bytes.length - 1;
    while (index >= 0 && _bytes[index] == 255) {
      _bytes[index] = 0;
      index -= 1;
    }
    if (index >= 0) {
      _bytes[index] += 1;
    }
  }
}
