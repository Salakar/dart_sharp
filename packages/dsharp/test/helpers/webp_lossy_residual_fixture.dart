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
    if ((chromaDc || chromaAc) && i == 0) {
      _writeUvToken(
        coeffs,
        coefficient,
        chromaAc ? chromaCoefficientIndex : 0,
        uvDcCatFiveProbability,
      );
    } else {
      coeffs.prob(
        _fixtureUvProbability(0, 0, 0, uvDcCatFiveProbability),
        false,
      );
    }
    for (var block = 1; block < 8; block += 1) {
      coeffs.prob(
        _fixtureUvProbability(0, 0, 0, uvDcCatFiveProbability),
        false,
      );
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
  int? uvDcCatFiveProbability,
) {
  final magnitude = coefficient.abs();
  if (magnitude < 1 || magnitude > 2048) {
    throw ArgumentError.value(coefficient, 'coefficient');
  }
  if (coefficientIndex < 0 || coefficientIndex > 15) {
    throw ArgumentError.value(coefficientIndex, 'coefficientIndex');
  }
  var context = 0;
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
