part of 'webp_lossy_fixture.dart';

const _uvDcCatFiveProbabilityUpdate = 2 * 8 * 3 * 11 + 10;
const _yAcBandOneEobProbabilityUpdate = 1 * 3 * 11;
const _yAcBandTwoEobProbabilityUpdate = 2 * 3 * 11;
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
}) {
  final vp8 = _residualVp8Payload(width: width, height: height, qIndex: qIndex);
  return _simpleWebp(vp8);
}

/// Builds a VP8 WebP with a residual token that this decoder rejects.
Uint8List nonEmptyResidualVp8Webp({required int width, required int height}) {
  final vp8 = _residualVp8Payload(width: width, height: height, nonEmpty: true);
  return _simpleWebp(vp8);
}

/// Builds a VP8 WebP with a chroma DC coefficient run this decoder rejects.
Uint8List unsupportedChromaDcRunVp8Webp({
  required int width,
  required int height,
}) {
  final vp8 = _residualVp8Payload(
    width: width,
    height: height,
    unsupportedChromaRun: true,
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

Uint8List _residualVp8Payload({
  required int width,
  required int height,
  bool nonEmpty = false,
  bool y2 = false,
  bool lumaAc = false,
  bool chromaDc = false,
  bool unsupportedChromaRun = false,
  int qIndex = 0,
  int coefficient = 1,
  int y2CoefficientIndex = 0,
  int lumaCoefficientIndex = 1,
  int? secondLumaCoefficient,
  int? secondLumaCoefficientIndex,
  int? uvDcCatFiveProbability,
  int? yAcBandOneEobProbability,
  int? yAcBandTwoEobProbability,
}) {
  final mbCols = (width + 15) >> 4;
  final mbRows = (height + 15) >> 4;
  final first = _BoolWriter()
    ..bit(false)
    ..bit(false)
    ..bit(false)
    ..bit(false)
    ..literal(0, 6)
    ..literal(0, 3)
    ..bit(false)
    ..literal(0, 2)
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
    _writeYMode(first, 0);
    first.prob(142, false);
  }
  final firstPartition = first.finish();
  final coeffs = _BoolWriter();
  for (var i = 0; i < mbCols * mbRows; i += 1) {
    if (y2 && i == 0) {
      _writeY2Token(coeffs, coefficient, y2CoefficientIndex);
    } else {
      coeffs.prob(198, false);
    }
    for (var block = 0; block < 16; block += 1) {
      if (lumaAc && i == 0 && block == 0) {
        _writeYAcToken(
          coeffs,
          coefficient,
          lumaCoefficientIndex,
          secondCoefficient: secondLumaCoefficient,
          secondCoefficientIndex: secondLumaCoefficientIndex,
          yAcBandOneEobProbability: yAcBandOneEobProbability,
          yAcBandTwoEobProbability: yAcBandTwoEobProbability,
        );
      } else {
        coeffs.prob(253, false);
      }
    }
    if (nonEmpty && i == 0) {
      _writeUnsupportedUvDcZeroToken(coeffs);
    } else if (unsupportedChromaRun && i == 0) {
      _writeUnsupportedUvDcRunToken(coeffs);
    } else if (chromaDc && i == 0) {
      _writeUvDcToken(
        coeffs,
        coefficient,
        catFiveProbability: uvDcCatFiveProbability ?? 255,
      );
    } else {
      coeffs.prob(202, false);
    }
    for (var block = 1; block < 8; block += 1) {
      coeffs.prob(202, false);
    }
  }
  return (_ByteWriter()
        ..u24((1 << 4) | (firstPartition.length << 5))
        ..byte(0x9d)
        ..byte(0x01)
        ..byte(0x2a)
        ..u16(width)
        ..u16(height)
        ..bytes(firstPartition)
        ..bytes(coeffs.finish()))
      .finish();
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

void _writeY2Token(_BoolWriter coeffs, int coefficient, int coefficientIndex) {
  final magnitude = coefficient.abs();
  if (magnitude < 1 || magnitude > 2048) {
    throw ArgumentError.value(coefficient, 'coefficient');
  }
  if (coefficientIndex < 0 || coefficientIndex > 15) {
    throw ArgumentError.value(coefficientIndex, 'coefficientIndex');
  }
  var context = 0;
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

void _writeUnsupportedUvDcZeroToken(_BoolWriter coeffs) {
  coeffs
    ..prob(202, true)
    ..prob(24, false);
}

void _writeUnsupportedUvDcRunToken(_BoolWriter coeffs) =>
    _writeUvDcToken(coeffs, 1, hasMore: true);

void _writeUvDcToken(
  _BoolWriter coeffs,
  int coefficient, {
  bool hasMore = false,
  int catFiveProbability = 255,
}) {
  final magnitude = coefficient.abs();
  if (magnitude < 1 || magnitude > 2048) {
    throw ArgumentError.value(coefficient, 'coefficient');
  }
  coeffs
    ..prob(202, true)
    ..prob(24, true);
  if (magnitude == 1) {
    coeffs.prob(213, false);
  } else if (magnitude <= 4) {
    coeffs
      ..prob(213, true)
      ..prob(235, false);
    if (magnitude == 2) {
      coeffs.prob(186, false);
    } else {
      coeffs
        ..prob(186, true)
        ..prob(191, magnitude == 4);
    }
  } else if (magnitude <= 6) {
    coeffs
      ..prob(213, true)
      ..prob(235, true)
      ..prob(220, false)
      ..prob(160, false)
      ..prob(159, magnitude == 6);
  } else if (magnitude <= 10) {
    final offset = magnitude - 7;
    coeffs
      ..prob(213, true)
      ..prob(235, true)
      ..prob(220, false)
      ..prob(160, true)
      ..prob(165, offset >= 2)
      ..prob(145, offset.isOdd);
  } else if (magnitude <= 18) {
    final offset = magnitude - 11;
    coeffs
      ..prob(213, true)
      ..prob(235, true)
      ..prob(220, true)
      ..prob(240, false)
      ..prob(175, false)
      ..prob(173, (offset & 4) != 0)
      ..prob(148, (offset & 2) != 0)
      ..prob(140, offset.isOdd);
  } else if (magnitude <= 34) {
    final offset = magnitude - 19;
    coeffs
      ..prob(213, true)
      ..prob(235, true)
      ..prob(220, true)
      ..prob(240, false)
      ..prob(175, true)
      ..prob(176, (offset & 8) != 0)
      ..prob(155, (offset & 4) != 0)
      ..prob(140, (offset & 2) != 0)
      ..prob(135, offset.isOdd);
  } else if (magnitude <= 66) {
    final offset = magnitude - 35;
    coeffs
      ..prob(213, true)
      ..prob(235, true)
      ..prob(220, true)
      ..prob(240, true)
      ..prob(catFiveProbability, false)
      ..prob(180, (offset & 16) != 0)
      ..prob(157, (offset & 8) != 0)
      ..prob(141, (offset & 4) != 0)
      ..prob(134, (offset & 2) != 0)
      ..prob(130, offset.isOdd);
  } else {
    final offset = magnitude - 67;
    coeffs
      ..prob(213, true)
      ..prob(235, true)
      ..prob(220, true)
      ..prob(240, true)
      ..prob(catFiveProbability, true)
      ..prob(254, (offset & 1024) != 0)
      ..prob(254, (offset & 512) != 0)
      ..prob(243, (offset & 256) != 0)
      ..prob(230, (offset & 128) != 0)
      ..prob(196, (offset & 64) != 0)
      ..prob(177, (offset & 32) != 0)
      ..prob(153, (offset & 16) != 0)
      ..prob(140, (offset & 8) != 0)
      ..prob(133, (offset & 4) != 0)
      ..prob(130, (offset & 2) != 0)
      ..prob(129, offset.isOdd);
  }
  coeffs
    ..bit(coefficient.isNegative)
    ..prob(166, hasMore);
}
