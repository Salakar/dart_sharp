part of 'webp_lossy_fixture.dart';

Uint8List lumaAcResidualVp8Webp({
  required int width,
  required int height,
  int coefficient = 1,
  int coefficientIndex = 1,
  int? secondCoefficient,
  int? secondCoefficientIndex,
  int? yAcBandOneEobProbability,
  int? yAcBandTwoEobProbability,
}) => _simpleWebp(
  _residualVp8Payload(
    width: width,
    height: height,
    lumaAc: true,
    coefficient: coefficient,
    lumaCoefficientIndex: coefficientIndex,
    secondLumaCoefficient: secondCoefficient,
    secondLumaCoefficientIndex: secondCoefficientIndex,
    yAcBandOneEobProbability: yAcBandOneEobProbability,
    yAcBandTwoEobProbability: yAcBandTwoEobProbability,
  ),
);

Uint8List bPredLumaDcResidualVp8Webp({
  required int width,
  required int height,
  int coefficient = 1,
  int coefficientIndex = 0,
}) => _simpleWebp(
  _residualVp8Payload(
    width: width,
    height: height,
    bPred: true,
    lumaDc: true,
    coefficient: coefficient,
    lumaCoefficientIndex: coefficientIndex,
  ),
);

const _fixtureCoefficientBands = <int>[
  0,
  1,
  2,
  3,
  6,
  4,
  5,
  6,
  6,
  6,
  6,
  6,
  6,
  6,
  6,
  7,
];
const _fixtureYProbs = <List<List<int>>>[
  [
    [202, 24, 213, 235, 186, 191, 220, 160, 240, 175, 255],
    [126, 38, 182, 232, 169, 184, 228, 174, 255, 187, 128],
    [61, 46, 138, 219, 151, 178, 240, 170, 255, 216, 128],
  ],
  [
    [1, 112, 230, 250, 199, 191, 247, 159, 255, 255, 128],
    [166, 109, 228, 252, 211, 215, 255, 174, 128, 128, 128],
    [39, 77, 162, 232, 172, 180, 245, 178, 255, 255, 128],
  ],
  [
    [1, 52, 220, 246, 198, 199, 249, 220, 255, 255, 128],
    [124, 74, 191, 243, 183, 193, 250, 221, 255, 255, 128],
    [24, 71, 130, 219, 154, 170, 243, 182, 255, 255, 128],
  ],
  [
    [1, 182, 225, 249, 219, 240, 255, 224, 128, 128, 128],
    [149, 150, 226, 252, 216, 205, 255, 171, 128, 128, 128],
    [28, 108, 170, 242, 183, 194, 254, 223, 255, 255, 128],
  ],
  [
    [1, 81, 230, 252, 204, 203, 255, 192, 128, 128, 128],
    [123, 102, 209, 247, 188, 196, 255, 233, 128, 128, 128],
    [20, 95, 153, 243, 164, 173, 255, 203, 128, 128, 128],
  ],
  [
    [1, 222, 248, 255, 216, 213, 128, 128, 128, 128, 128],
    [168, 175, 246, 252, 235, 205, 255, 255, 128, 128, 128],
    [47, 116, 215, 255, 211, 212, 255, 255, 128, 128, 128],
  ],
  [
    [1, 121, 236, 253, 212, 214, 255, 255, 128, 128, 128],
    [141, 84, 213, 252, 201, 202, 255, 219, 128, 128, 128],
    [42, 80, 160, 240, 162, 185, 255, 205, 128, 128, 128],
  ],
  [
    [1, 1, 255, 128, 128, 128, 128, 128, 128, 128, 128],
    [244, 1, 255, 128, 128, 128, 128, 128, 128, 128, 128],
    [238, 1, 255, 128, 128, 128, 128, 128, 128, 128, 128],
  ],
];
const _fixtureYAcProbs = <List<List<int>>>[
  [
    [128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128],
    [128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128],
    [128, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128],
  ],
  [
    [253, 136, 254, 255, 228, 219, 128, 128, 128, 128, 128],
    [189, 129, 242, 255, 227, 213, 255, 219, 128, 128, 128],
    [106, 126, 227, 252, 214, 209, 255, 255, 128, 128, 128],
  ],
  [
    [1, 98, 248, 255, 236, 226, 255, 255, 128, 128, 128],
    [181, 133, 238, 254, 221, 234, 255, 154, 128, 128, 128],
    [78, 134, 202, 247, 198, 180, 255, 219, 128, 128, 128],
  ],
  [
    [1, 185, 249, 255, 243, 255, 128, 128, 128, 128, 128],
    [184, 150, 247, 255, 236, 224, 128, 128, 128, 128, 128],
    [77, 110, 216, 255, 236, 230, 128, 128, 128, 128, 128],
  ],
  [
    [1, 101, 251, 255, 241, 255, 128, 128, 128, 128, 128],
    [170, 139, 241, 252, 236, 209, 255, 255, 128, 128, 128],
    [37, 116, 196, 243, 228, 255, 255, 255, 128, 128, 128],
  ],
  [
    [1, 204, 254, 255, 245, 255, 128, 128, 128, 128, 128],
    [207, 160, 250, 255, 238, 128, 128, 128, 128, 128, 128],
    [102, 103, 231, 255, 211, 171, 128, 128, 128, 128, 128],
  ],
  [
    [1, 152, 252, 255, 240, 255, 128, 128, 128, 128, 128],
    [177, 135, 243, 255, 234, 225, 128, 128, 128, 128, 128],
    [80, 129, 211, 255, 194, 224, 128, 128, 128, 128, 128],
  ],
  [
    [1, 1, 255, 128, 128, 128, 128, 128, 128, 128, 128],
    [246, 1, 255, 128, 128, 128, 128, 128, 128, 128, 128],
    [255, 128, 128, 128, 128, 128, 128, 128, 128, 128, 128],
  ],
];

void _writeYToken(
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
    int probabilityAt(int node) => _fixtureYProbability(index, context, node);
    coeffs
      ..prob(probabilityAt(0), true)
      ..prob(probabilityAt(1), false);
    context = 0;
  }
  int probabilityAt(int node) =>
      _fixtureYProbability(coefficientIndex, context, node);
  coeffs
    ..prob(probabilityAt(0), true)
    ..prob(probabilityAt(1), true);
  _writeDctMagnitude(coeffs, magnitude, probabilityAt);
  final nextIndex = coefficientIndex + 1;
  coeffs.bit(coefficient.isNegative);
  if (nextIndex < 16) {
    coeffs.prob(
      _fixtureYProbability(nextIndex, magnitude == 1 ? 1 : 2, 0),
      false,
    );
  }
}

void _writeYAcToken(
  _BoolWriter coeffs,
  int coefficient,
  int coefficientIndex, {
  int initialContext = 0,
  int? secondCoefficient,
  int? secondCoefficientIndex,
  int? yAcBandOneEobProbability,
  int? yAcBandTwoEobProbability,
}) {
  final magnitude = coefficient.abs();
  if (magnitude < 1 || magnitude > 2048) {
    throw ArgumentError.value(coefficient, 'coefficient');
  }
  if (coefficientIndex < 1 || coefficientIndex > 15) {
    throw ArgumentError.value(coefficientIndex, 'coefficientIndex');
  }
  if (secondCoefficient != null) {
    final secondIndex = secondCoefficientIndex;
    if (secondIndex == null ||
        secondIndex <= coefficientIndex ||
        secondIndex > 15) {
      throw ArgumentError.value(
        secondCoefficientIndex,
        'secondCoefficientIndex',
      );
    }
  }
  var context = initialContext;
  for (var index = 1; index < coefficientIndex; index += 1) {
    int probabilityAt(int node) => _fixtureYAcProbability(
      index,
      context,
      node,
      yAcBandOneEobProbability,
      yAcBandTwoEobProbability,
    );
    coeffs
      ..prob(probabilityAt(0), true)
      ..prob(probabilityAt(1), false);
    context = 0;
  }
  int probabilityAt(int node) => _fixtureYAcProbability(
    coefficientIndex,
    context,
    node,
    yAcBandOneEobProbability,
    yAcBandTwoEobProbability,
  );
  coeffs
    ..prob(probabilityAt(0), true)
    ..prob(probabilityAt(1), true);
  _writeDctMagnitude(coeffs, magnitude, probabilityAt);
  final nextIndex = coefficientIndex + 1;
  final nextContext = magnitude == 1 ? 1 : 2;
  coeffs.bit(coefficient.isNegative);
  if (secondCoefficient != null && secondCoefficientIndex != null) {
    _writeYAcTokenTail(
      coeffs,
      secondCoefficient,
      secondCoefficientIndex,
      nextIndex,
      nextContext,
      yAcBandOneEobProbability,
      yAcBandTwoEobProbability,
    );
  } else if (nextIndex < 16) {
    coeffs.prob(
      _fixtureYAcProbability(
        nextIndex,
        nextContext,
        0,
        yAcBandOneEobProbability,
        yAcBandTwoEobProbability,
      ),
      false,
    );
  }
}

void _writeYAcTokenTail(
  _BoolWriter coeffs,
  int coefficient,
  int coefficientIndex,
  int nextIndex,
  int context,
  int? yAcBandOneEobProbability,
  int? yAcBandTwoEobProbability,
) {
  var currentContext = context;
  for (var index = nextIndex; index < coefficientIndex; index += 1) {
    int probabilityAt(int node) => _fixtureYAcProbability(
      index,
      currentContext,
      node,
      yAcBandOneEobProbability,
      yAcBandTwoEobProbability,
    );
    coeffs
      ..prob(probabilityAt(0), true)
      ..prob(probabilityAt(1), false);
    currentContext = 0;
  }
  final magnitude = coefficient.abs();
  int probabilityAt(int node) => _fixtureYAcProbability(
    coefficientIndex,
    currentContext,
    node,
    yAcBandOneEobProbability,
    yAcBandTwoEobProbability,
  );
  coeffs
    ..prob(probabilityAt(0), true)
    ..prob(probabilityAt(1), true);
  _writeDctMagnitude(coeffs, magnitude, probabilityAt);
  coeffs.bit(coefficient.isNegative);
  final finalIndex = coefficientIndex + 1;
  if (finalIndex < 16) {
    coeffs.prob(
      _fixtureYAcProbability(
        finalIndex,
        magnitude == 1 ? 1 : 2,
        0,
        yAcBandOneEobProbability,
        yAcBandTwoEobProbability,
      ),
      false,
    );
  }
}

void _writeDctMagnitude(
  _BoolWriter coeffs,
  int magnitude,
  int Function(int node) probabilityAt,
) {
  if (magnitude == 1) {
    coeffs.prob(probabilityAt(2), false);
  } else if (magnitude <= 4) {
    coeffs
      ..prob(probabilityAt(2), true)
      ..prob(probabilityAt(3), false);
    if (magnitude == 2) {
      coeffs.prob(probabilityAt(4), false);
    } else {
      coeffs
        ..prob(probabilityAt(4), true)
        ..prob(probabilityAt(5), magnitude == 4);
    }
  } else if (magnitude <= 6) {
    coeffs
      ..prob(probabilityAt(2), true)
      ..prob(probabilityAt(3), true)
      ..prob(probabilityAt(6), false)
      ..prob(probabilityAt(7), false)
      ..prob(159, magnitude == 6);
  } else if (magnitude <= 10) {
    final offset = magnitude - 7;
    coeffs
      ..prob(probabilityAt(2), true)
      ..prob(probabilityAt(3), true)
      ..prob(probabilityAt(6), false)
      ..prob(probabilityAt(7), true)
      ..prob(165, offset >= 2)
      ..prob(145, offset.isOdd);
  } else if (magnitude <= 18) {
    final offset = magnitude - 11;
    coeffs
      ..prob(probabilityAt(2), true)
      ..prob(probabilityAt(3), true)
      ..prob(probabilityAt(6), true)
      ..prob(probabilityAt(8), false)
      ..prob(probabilityAt(9), false)
      ..prob(173, (offset & 4) != 0)
      ..prob(148, (offset & 2) != 0)
      ..prob(140, offset.isOdd);
  } else if (magnitude <= 34) {
    final offset = magnitude - 19;
    coeffs
      ..prob(probabilityAt(2), true)
      ..prob(probabilityAt(3), true)
      ..prob(probabilityAt(6), true)
      ..prob(probabilityAt(8), false)
      ..prob(probabilityAt(9), true)
      ..prob(176, (offset & 8) != 0)
      ..prob(155, (offset & 4) != 0)
      ..prob(140, (offset & 2) != 0)
      ..prob(135, offset.isOdd);
  } else if (magnitude <= 66) {
    final offset = magnitude - 35;
    coeffs
      ..prob(probabilityAt(2), true)
      ..prob(probabilityAt(3), true)
      ..prob(probabilityAt(6), true)
      ..prob(probabilityAt(8), true)
      ..prob(probabilityAt(10), false)
      ..prob(180, (offset & 16) != 0)
      ..prob(157, (offset & 8) != 0)
      ..prob(141, (offset & 4) != 0)
      ..prob(134, (offset & 2) != 0)
      ..prob(130, offset.isOdd);
  } else {
    final offset = magnitude - 67;
    coeffs
      ..prob(probabilityAt(2), true)
      ..prob(probabilityAt(3), true)
      ..prob(probabilityAt(6), true)
      ..prob(probabilityAt(8), true)
      ..prob(probabilityAt(10), true)
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
}

int _fixtureYAcProbability(
  int coefficientIndex,
  int context,
  int node,
  int? yAcBandOneEobProbability,
  int? yAcBandTwoEobProbability,
) {
  final band = _fixtureCoefficientBands[coefficientIndex];
  if (band == 1 &&
      context == 0 &&
      node == 0 &&
      yAcBandOneEobProbability != null) {
    return yAcBandOneEobProbability;
  }
  if (band == 2 &&
      context == 0 &&
      node == 0 &&
      yAcBandTwoEobProbability != null) {
    return yAcBandTwoEobProbability;
  }
  return _fixtureYAcProbs[band][context][node];
}

int _fixtureYProbability(int coefficientIndex, int context, int node) =>
    _fixtureYProbs[_fixtureCoefficientBands[coefficientIndex]][context][node];
