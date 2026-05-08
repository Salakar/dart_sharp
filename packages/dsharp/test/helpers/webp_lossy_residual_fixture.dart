part of 'webp_lossy_fixture.dart';

const _uvDcCatFiveProbabilityUpdate = 2 * 8 * 3 * 11 + 10;
const _yAcBandOneEobProbabilityUpdate = 1 * 3 * 11;
const _yAcBandTwoEobProbabilityUpdate = 2 * 3 * 11;
const _fixtureY2BlockIndex = 24;
const _fixtureLeftContextIndex = <int>[
  0,
  0,
  0,
  0,
  1,
  1,
  1,
  1,
  2,
  2,
  2,
  2,
  3,
  3,
  3,
  3,
  4,
  4,
  5,
  5,
  6,
  6,
  7,
  7,
  8,
];
const _fixtureAboveContextIndex = <int>[
  0,
  1,
  2,
  3,
  0,
  1,
  2,
  3,
  0,
  1,
  2,
  3,
  0,
  1,
  2,
  3,
  4,
  5,
  4,
  5,
  6,
  7,
  6,
  7,
  8,
];
const _fixtureCoefficientUpdateProbCodes =
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff'
    '\u00ff\u00b0\u00f6\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00df\u00f1\u00fc\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00f9\u00fd\u00fd\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff'
    '\u00ff\u00ff\u00ff\u00f4\u00fc\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ea\u00fe\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fd\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00f6\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ef\u00fd\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fe\u00ff\u00fe\u00ff\u00ff\u00ff\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00f8\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fb\u00ff\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fd\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fb\u00fe\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fe\u00ff\u00fe\u00ff\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fe\u00fd\u00ff\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fa\u00ff\u00fe\u00ff\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fe\u00ff\u00ff\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00d9\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00e1\u00fc\u00f1\u00fd\u00ff\u00ff\u00fe\u00ff\u00ff\u00ff\u00ff\u00ea\u00fa'
    '\u00f1\u00fa\u00fd\u00ff\u00fd\u00fe\u00ff\u00ff\u00ff\u00ff\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00df\u00fe\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ee'
    '\u00fd\u00fe\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00f8\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00f9\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fd\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00f7\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fd\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fc\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fe\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fd\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fe\u00fd\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fa\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ba\u00fb\u00fa\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ea\u00fb\u00f4\u00fe\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fb\u00fb\u00f3\u00fd\u00fe\u00ff\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00fd\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ec\u00fd\u00fe\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fb\u00fd\u00fd\u00fe\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fe\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fe\u00fe\u00fe'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fe\u00fe'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fe'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00f8\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff'
    '\u00ff\u00ff\u00ff\u00fa\u00fe\u00fc\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00f8\u00fe\u00f9\u00fd\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fd\u00fd\u00ff\u00ff\u00ff\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00f6\u00fd\u00fd\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fc\u00fe\u00fb\u00fe\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fe\u00fc\u00ff\u00ff\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00f8\u00fe\u00fd\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fd\u00ff\u00fe\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fb\u00fe\u00ff\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00f5\u00fb\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fd\u00fd\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fb\u00fd\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fc\u00fd\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fc\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00f9\u00ff\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff'
    '\u00fd\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fa\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff';

/// Builds a lossy VP8 WebP whose residual partition contains EOB blocks.
Uint8List eobResidualVp8Webp({
  required int width,
  required int height,
  int qIndex = 0,
  int tokenPartitionBits = 0,
}) {
  final vp8 = _residualVp8Payload(
    width: width,
    height: height,
    qIndex: qIndex,
    tokenPartitionBits: tokenPartitionBits,
  );
  return _simpleWebp(vp8);
}

/// Builds a VP8 WebP with a supported Y2 DC residual.
Uint8List y2DcResidualVp8Webp({
  required int width,
  required int height,
  int qIndex = 12,
  int coefficient = 1,
}) {
  final vp8 = _residualVp8Payload(
    width: width,
    height: height,
    y2: true,
    qIndex: qIndex,
    coefficient: coefficient,
  );
  return _simpleWebp(vp8);
}

/// Builds a VP8 WebP whose first macroblock uses a segment quantizer.
Uint8List segmentedY2DcResidualVp8Webp({
  required int width,
  required int height,
  int segmentQIndex = 40,
}) {
  final mbCount = ((width + 15) >> 4) * ((height + 15) >> 4);
  final vp8 = _residualVp8Payload(
    width: width,
    height: height,
    y2: true,
    qIndex: 0,
    segmentIds: List<int>.filled(mbCount, 1),
    segmentQuantIndexes: <int?>[null, segmentQIndex, null, null],
    segmentAbsolute: true,
  );
  return _simpleWebp(vp8);
}

/// Builds a VP8 WebP with a supported Y2 AC residual.
Uint8List y2AcResidualVp8Webp({
  required int width,
  required int height,
  int qIndex = 12,
  int coefficient = 2,
  int coefficientIndex = 1,
}) {
  final vp8 = _residualVp8Payload(
    width: width,
    height: height,
    y2: true,
    y2CoefficientIndex: coefficientIndex,
    qIndex: qIndex,
    coefficient: coefficient,
  );
  return _simpleWebp(vp8);
}

/// Builds a VP8 WebP with a supported chroma DC residual.
Uint8List chromaDcResidualVp8Webp({
  required int width,
  required int height,
  int qIndex = 0,
  int coefficient = 1,
  int? uvDcCatFiveProbability,
}) {
  final vp8 = _residualVp8Payload(
    width: width,
    height: height,
    chromaDc: true,
    qIndex: qIndex,
    coefficient: coefficient,
    uvDcCatFiveProbability: uvDcCatFiveProbability,
  );
  return _simpleWebp(vp8);
}

/// Builds a VP8 WebP with a supported chroma AC residual.
Uint8List chromaAcResidualVp8Webp({
  required int width,
  required int height,
  int qIndex = 12,
  int coefficient = 2,
  int coefficientIndex = 1,
}) {
  final vp8 = _residualVp8Payload(
    width: width,
    height: height,
    chromaAc: true,
    qIndex: qIndex,
    coefficient: coefficient,
    chromaCoefficientIndex: coefficientIndex,
  );
  return _simpleWebp(vp8);
}

Uint8List _residualVp8Payload({
  required int width,
  required int height,
  bool y2 = false,
  bool lumaAc = false,
  bool lumaDc = false,
  bool bPred = false,
  bool chromaDc = false,
  bool chromaAc = false,
  int qIndex = 0,
  int coefficient = 1,
  int y2CoefficientIndex = 0,
  int lumaCoefficientIndex = 1,
  int chromaCoefficientIndex = 0,
  int? secondLumaCoefficient,
  int? secondLumaCoefficientIndex,
  int? uvDcCatFiveProbability,
  int? yAcBandOneEobProbability,
  int? yAcBandTwoEobProbability,
  List<int>? segmentIds,
  List<int?>? segmentQuantIndexes,
  bool segmentAbsolute = false,
  int tokenPartitionBits = 0,
}) {
  final mbCols = (width + 15) >> 4;
  final mbRows = (height + 15) >> 4;
  if (tokenPartitionBits < 0 || tokenPartitionBits > 3) {
    throw ArgumentError.value(tokenPartitionBits, 'tokenPartitionBits');
  }
  final currentSegmentIds = segmentIds;
  if (currentSegmentIds != null &&
      currentSegmentIds.length != mbCols * mbRows) {
    throw ArgumentError.value(currentSegmentIds.length, 'segmentIds.length');
  }
  if (segmentQuantIndexes != null && segmentQuantIndexes.length != 4) {
    throw ArgumentError.value(
      segmentQuantIndexes.length,
      'segmentQuantIndexes',
    );
  }
  final first = _BoolWriter()
    ..bit(false)
    ..bit(false);
  _writeSegmentationHeader(
    first,
    segmentIds: currentSegmentIds,
    segmentQuantIndexes: segmentQuantIndexes,
    segmentAbsolute: segmentAbsolute,
  );
  first
    ..bit(false)
    ..literal(0, 6)
    ..literal(0, 3)
    ..bit(false)
    ..literal(tokenPartitionBits, 2)
    ..literal(qIndex, 7);
  for (var i = 0; i < 5; i += 1) {
    first.bit(false);
  }
  first.bit(false);
  for (var i = 0; i < 4 * 8 * 3 * 11; i += 1) {
    final updateProbability = _fixtureCoefficientUpdateProbabilityByIndex(i);
    if (i == _yAcBandOneEobProbabilityUpdate &&
        yAcBandOneEobProbability != null) {
      first
        ..prob(updateProbability, true)
        ..literal(yAcBandOneEobProbability, 8);
    } else if (i == _yAcBandTwoEobProbabilityUpdate &&
        yAcBandTwoEobProbability != null) {
      first
        ..prob(updateProbability, true)
        ..literal(yAcBandTwoEobProbability, 8);
    } else if (i == _uvDcCatFiveProbabilityUpdate &&
        uvDcCatFiveProbability != null) {
      first
        ..prob(updateProbability, true)
        ..literal(uvDcCatFiveProbability, 8);
    } else {
      first.prob(updateProbability, false);
    }
  }
  first.bit(false);
  for (var i = 0; i < mbCols * mbRows; i += 1) {
    if (currentSegmentIds != null) {
      _writeSegmentId(first, currentSegmentIds[i]);
    }
    _writeYMode(first, bPred ? 4 : 0);
    if (bPred) {
      _writeBdcSubblockModes(first);
    }
    first.prob(142, false);
  }
  final firstPartition = first.finish();
  final coeffWriters = [
    for (var i = 0; i < 1 << tokenPartitionBits; i += 1) _BoolWriter(),
  ];
  final contexts = _FixtureTokenContexts(mbCols);
  for (var i = 0; i < mbCols * mbRows; i += 1) {
    final mbX = i % mbCols;
    final mbY = i ~/ mbCols;
    final coeffs = coeffWriters[mbY & (coeffWriters.length - 1)];
    if (mbX == 0) {
      contexts.resetLeft();
    }
    if (bPred) {
      contexts.setHasCoefficients(mbX, _fixtureY2BlockIndex, false);
    } else if (y2 && i == 0) {
      _writeY2Token(
        coeffs,
        coefficient,
        y2CoefficientIndex,
        initialContext: contexts.contextFor(mbX, _fixtureY2BlockIndex),
      );
      contexts.setHasCoefficients(mbX, _fixtureY2BlockIndex, true);
    } else {
      coeffs.prob(
        _fixtureY2Probability(
          0,
          contexts.contextFor(mbX, _fixtureY2BlockIndex),
          0,
        ),
        false,
      );
      contexts.setHasCoefficients(mbX, _fixtureY2BlockIndex, false);
    }
    for (var block = 0; block < 16; block += 1) {
      if (bPred) {
        if (lumaDc && i == 0 && block == 0) {
          _writeYToken(
            coeffs,
            coefficient,
            lumaCoefficientIndex,
            initialContext: contexts.contextFor(mbX, block),
          );
          contexts.setHasCoefficients(mbX, block, true);
        } else {
          coeffs.prob(
            _fixtureYProbability(0, contexts.contextFor(mbX, block), 0),
            false,
          );
          contexts.setHasCoefficients(mbX, block, false);
        }
      } else if (lumaAc && i == 0 && block == 0) {
        _writeYAcToken(
          coeffs,
          coefficient,
          lumaCoefficientIndex,
          initialContext: contexts.contextFor(mbX, block),
          secondCoefficient: secondLumaCoefficient,
          secondCoefficientIndex: secondLumaCoefficientIndex,
          yAcBandOneEobProbability: yAcBandOneEobProbability,
          yAcBandTwoEobProbability: yAcBandTwoEobProbability,
        );
        contexts.setHasCoefficients(mbX, block, true);
      } else {
        coeffs.prob(
          _fixtureYAcProbability(
            1,
            contexts.contextFor(mbX, block),
            0,
            yAcBandOneEobProbability,
            yAcBandTwoEobProbability,
          ),
          false,
        );
        contexts.setHasCoefficients(mbX, block, false);
      }
    }
    for (var block = 0; block < 8; block += 1) {
      final blockIndex = 16 + block;
      if ((chromaDc || chromaAc) && i == 0 && block == 0) {
        _writeUvToken(
          coeffs,
          coefficient,
          chromaAc ? chromaCoefficientIndex : 0,
          uvDcCatFiveProbability,
          initialContext: contexts.contextFor(mbX, blockIndex),
        );
        contexts.setHasCoefficients(mbX, blockIndex, true);
      } else {
        coeffs.prob(
          _fixtureUvProbability(
            0,
            contexts.contextFor(mbX, blockIndex),
            0,
            uvDcCatFiveProbability,
          ),
          false,
        );
        contexts.setHasCoefficients(mbX, blockIndex, false);
      }
    }
  }
  final tokenPartitions = [for (final coeffs in coeffWriters) coeffs.finish()];
  final vp8 = _ByteWriter()
    ..u24((1 << 4) | (firstPartition.length << 5))
    ..byte(0x9d)
    ..byte(0x01)
    ..byte(0x2a)
    ..u16(width)
    ..u16(height)
    ..bytes(firstPartition);
  for (var i = 0; i < tokenPartitions.length - 1; i += 1) {
    vp8.u24(tokenPartitions[i].length);
  }
  for (final partition in tokenPartitions) {
    vp8.bytes(partition);
  }
  return vp8.finish();
}

void _writeSegmentationHeader(
  _BoolWriter out, {
  required List<int>? segmentIds,
  required List<int?>? segmentQuantIndexes,
  required bool segmentAbsolute,
}) {
  if (segmentIds == null) {
    out.bit(false);
    return;
  }
  out
    ..bit(true)
    ..bit(true)
    ..bit(segmentQuantIndexes != null);
  if (segmentQuantIndexes != null) {
    out.bit(segmentAbsolute);
    for (final quantIndex in segmentQuantIndexes) {
      out.bit(quantIndex != null);
      if (quantIndex != null) {
        out
          ..literal(quantIndex.abs(), 7)
          ..bit(quantIndex < 0);
      }
    }
    for (var i = 0; i < 4; i += 1) {
      out.bit(false);
    }
  }
  for (var i = 0; i < 3; i += 1) {
    out
      ..bit(true)
      ..literal(128, 8);
  }
}

void _writeSegmentId(_BoolWriter out, int segmentId) {
  if (segmentId < 0 || segmentId > 3) {
    throw ArgumentError.value(segmentId, 'segmentId');
  }
  if (segmentId < 2) {
    out
      ..prob(128, false)
      ..prob(128, segmentId == 1);
  } else {
    out
      ..prob(128, true)
      ..prob(128, segmentId == 3);
  }
}

final class _FixtureTokenContexts {
  _FixtureTokenContexts(int mbCols) : _above = List<int>.filled(mbCols * 9, 0);

  final List<int> _above;
  final _left = List<int>.filled(9, 0);

  void resetLeft() {
    _left.fillRange(0, _left.length, 0);
  }

  int contextFor(int mbX, int block) {
    return _left[_fixtureLeftContextIndex[block]] +
        _above[mbX * 9 + _fixtureAboveContextIndex[block]];
  }

  void setHasCoefficients(int mbX, int block, bool hasCoefficients) {
    final value = hasCoefficients ? 1 : 0;
    _left[_fixtureLeftContextIndex[block]] = value;
    _above[mbX * 9 + _fixtureAboveContextIndex[block]] = value;
  }
}

int _fixtureCoefficientUpdateProbabilityByIndex(int index) {
  return _fixtureCoefficientUpdateProbCodes.codeUnitAt(index);
}

const _fixtureY2Probs = <List<List<int>>>[
  [
    [198, 35, 237, 223, 193, 187, 162, 160, 145, 155, 62],
    [131, 45, 198, 221, 172, 176, 220, 157, 252, 221, 1],
    [68, 47, 146, 208, 149, 167, 221, 162, 255, 223, 128],
  ],
  [
    [1, 149, 241, 255, 221, 224, 255, 255, 128, 128, 128],
    [184, 141, 234, 253, 222, 220, 255, 199, 128, 128, 128],
    [81, 99, 181, 242, 176, 190, 249, 202, 255, 255, 128],
  ],
  [
    [1, 129, 232, 253, 214, 197, 242, 196, 255, 255, 128],
    [99, 121, 210, 250, 201, 198, 255, 202, 128, 128, 128],
    [23, 91, 163, 242, 170, 187, 247, 210, 255, 255, 128],
  ],
  [
    [1, 200, 246, 255, 234, 255, 128, 128, 128, 128, 128],
    [109, 178, 241, 255, 231, 245, 255, 255, 128, 128, 128],
    [44, 130, 201, 253, 205, 192, 255, 255, 128, 128, 128],
  ],
  [
    [1, 132, 239, 251, 219, 209, 255, 165, 128, 128, 128],
    [94, 136, 225, 251, 218, 190, 255, 255, 128, 128, 128],
    [22, 100, 174, 245, 186, 161, 255, 199, 128, 128, 128],
  ],
  [
    [1, 182, 249, 255, 232, 235, 128, 128, 128, 128, 128],
    [124, 143, 241, 255, 227, 234, 128, 128, 128, 128, 128],
    [35, 77, 181, 251, 193, 211, 255, 205, 128, 128, 128],
  ],
  [
    [1, 157, 247, 255, 236, 231, 255, 255, 128, 128, 128],
    [121, 141, 235, 255, 225, 227, 255, 255, 128, 128, 128],
    [45, 99, 188, 251, 195, 217, 255, 224, 128, 128, 128],
  ],
  [
    [1, 1, 251, 255, 213, 255, 128, 128, 128, 128, 128],
    [203, 1, 248, 255, 255, 128, 128, 128, 128, 128, 128],
    [137, 1, 177, 255, 224, 255, 128, 128, 128, 128, 128],
  ],
];

void _writeY2Token(
  _BoolWriter coeffs,
  int coefficient,
  int coefficientIndex, {
  int initialContext = 0,
}) {
  final magnitude = coefficient.abs();
  if (magnitude < 1 || magnitude > 2048) {
    throw ArgumentError.value(coefficient, 'coefficient');
  }
  if (coefficientIndex < 0 || coefficientIndex > 15) {
    throw ArgumentError.value(coefficientIndex, 'coefficientIndex');
  }
  var context = initialContext;
  for (var index = 0; index < coefficientIndex; index += 1) {
    int probabilityAt(int node) => _fixtureY2Probability(index, context, node);
    coeffs
      ..prob(probabilityAt(0), true)
      ..prob(probabilityAt(1), false);
    context = 0;
  }
  int probabilityAt(int node) =>
      _fixtureY2Probability(coefficientIndex, context, node);
  coeffs
    ..prob(probabilityAt(0), true)
    ..prob(probabilityAt(1), true);
  _writeDctMagnitude(coeffs, magnitude, probabilityAt);
  final nextIndex = coefficientIndex + 1;
  coeffs.bit(coefficient.isNegative);
  if (nextIndex < 16) {
    coeffs.prob(
      _fixtureY2Probability(nextIndex, magnitude == 1 ? 1 : 2, 0),
      false,
    );
  }
}

int _fixtureY2Probability(int coefficientIndex, int context, int node) =>
    _fixtureY2Probs[_fixtureCoefficientBands[coefficientIndex]][context][node];

const _fixtureUvProbs = <List<List<int>>>[
  [
    [253, 9, 248, 251, 207, 208, 255, 192, 128, 128, 128],
    [175, 13, 224, 243, 193, 185, 249, 198, 255, 255, 128],
    [73, 17, 171, 221, 161, 179, 236, 167, 255, 234, 128],
  ],
  [
    [1, 95, 247, 253, 212, 183, 255, 255, 128, 128, 128],
    [239, 90, 244, 250, 211, 209, 255, 255, 128, 128, 128],
    [155, 77, 195, 248, 188, 195, 255, 255, 128, 128, 128],
  ],
  [
    [1, 24, 239, 251, 218, 219, 255, 205, 128, 128, 128],
    [201, 51, 219, 255, 196, 186, 128, 128, 128, 128, 128],
    [69, 46, 190, 239, 201, 218, 255, 228, 128, 128, 128],
  ],
  [
    [1, 191, 251, 255, 255, 128, 128, 128, 128, 128, 128],
    [223, 165, 249, 255, 213, 255, 128, 128, 128, 128, 128],
    [141, 124, 248, 255, 255, 128, 128, 128, 128, 128, 128],
  ],
  [
    [1, 16, 248, 255, 255, 128, 128, 128, 128, 128, 128],
    [190, 36, 230, 255, 236, 255, 128, 128, 128, 128, 128],
    [149, 1, 255, 128, 128, 128, 128, 128, 128, 128, 128],
  ],
  [
    [1, 226, 255, 128, 128, 128, 128, 128, 128, 128, 128],
    [247, 192, 255, 128, 128, 128, 128, 128, 128, 128, 128],
    [240, 128, 255, 128, 128, 128, 128, 128, 128, 128, 128],
  ],
  [
    [1, 134, 252, 255, 255, 128, 128, 128, 128, 128, 128],
    [213, 62, 250, 255, 255, 128, 128, 128, 128, 128, 128],
    [55, 93, 255, 128, 128, 128, 128, 128, 128, 128, 128],
  ],
  [
    [128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128],
    [128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128],
    [128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128],
  ],
];

void _writeUvToken(
  _BoolWriter coeffs,
  int coefficient,
  int coefficientIndex,
  int? uvDcCatFiveProbability, {
  int initialContext = 0,
}) {
  final magnitude = coefficient.abs();
  if (magnitude < 1 || magnitude > 2048) {
    throw ArgumentError.value(coefficient, 'coefficient');
  }
  if (coefficientIndex < 0 || coefficientIndex > 15) {
    throw ArgumentError.value(coefficientIndex, 'coefficientIndex');
  }
  var context = initialContext;
  for (var index = 0; index < coefficientIndex; index += 1) {
    int probabilityAt(int node) =>
        _fixtureUvProbability(index, context, node, uvDcCatFiveProbability);
    coeffs
      ..prob(probabilityAt(0), true)
      ..prob(probabilityAt(1), false);
    context = 0;
  }
  int probabilityAt(int node) => _fixtureUvProbability(
    coefficientIndex,
    context,
    node,
    uvDcCatFiveProbability,
  );
  coeffs
    ..prob(probabilityAt(0), true)
    ..prob(probabilityAt(1), true);
  _writeDctMagnitude(coeffs, magnitude, probabilityAt);
  final nextIndex = coefficientIndex + 1;
  coeffs.bit(coefficient.isNegative);
  if (nextIndex < 16) {
    coeffs.prob(
      _fixtureUvProbability(
        nextIndex,
        magnitude == 1 ? 1 : 2,
        0,
        uvDcCatFiveProbability,
      ),
      false,
    );
  }
}

int _fixtureUvProbability(
  int coefficientIndex,
  int context,
  int node,
  int? uvDcCatFiveProbability,
) {
  if (coefficientIndex == 0 &&
      context == 0 &&
      node == 10 &&
      uvDcCatFiveProbability != null) {
    return uvDcCatFiveProbability;
  }
  return _fixtureUvProbs[_fixtureCoefficientBands[coefficientIndex]][context][node];
}
