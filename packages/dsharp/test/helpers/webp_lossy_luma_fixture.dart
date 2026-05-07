part of 'webp_lossy_fixture.dart';

Uint8List lumaAcResidualVp8Webp({
  required int width,
  required int height,
  int coefficient = 1,
  int coefficientIndex = 1,
}) => _simpleWebp(
  _residualVp8Payload(
    width: width,
    height: height,
    lumaAc: true,
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

void _writeYAcToken(_BoolWriter coeffs, int coefficient, int coefficientIndex) {
  final magnitude = coefficient.abs();
  if (magnitude < 1 || magnitude > 2048) {
    throw ArgumentError.value(coefficient, 'coefficient');
  }
  if (coefficientIndex < 1 || coefficientIndex > 15) {
    throw ArgumentError.value(coefficientIndex, 'coefficientIndex');
  }
  var context = 0;
  for (var index = 1; index < coefficientIndex; index += 1) {
    coeffs
      ..prob(_fixtureYAcProbability(index, context, 0), true)
      ..prob(_fixtureYAcProbability(index, context, 1), false);
    context = 0;
  }
  coeffs
    ..prob(_fixtureYAcProbability(coefficientIndex, context, 0), true)
    ..prob(_fixtureYAcProbability(coefficientIndex, context, 1), true);
  if (magnitude == 1) {
    coeffs.prob(_fixtureYAcProbability(coefficientIndex, context, 2), false);
  } else if (magnitude <= 4) {
    coeffs
      ..prob(_fixtureYAcProbability(coefficientIndex, context, 2), true)
      ..prob(_fixtureYAcProbability(coefficientIndex, context, 3), false);
    if (magnitude == 2) {
      coeffs.prob(_fixtureYAcProbability(coefficientIndex, context, 4), false);
    } else {
      coeffs
        ..prob(_fixtureYAcProbability(coefficientIndex, context, 4), true)
        ..prob(
          _fixtureYAcProbability(coefficientIndex, context, 5),
          magnitude == 4,
        );
    }
  } else if (magnitude <= 6) {
    coeffs
      ..prob(_fixtureYAcProbability(coefficientIndex, context, 2), true)
      ..prob(_fixtureYAcProbability(coefficientIndex, context, 3), true)
      ..prob(_fixtureYAcProbability(coefficientIndex, context, 6), false)
      ..prob(_fixtureYAcProbability(coefficientIndex, context, 7), false)
      ..prob(159, magnitude == 6);
  } else if (magnitude <= 10) {
    final offset = magnitude - 7;
    coeffs
      ..prob(_fixtureYAcProbability(coefficientIndex, context, 2), true)
      ..prob(_fixtureYAcProbability(coefficientIndex, context, 3), true)
      ..prob(_fixtureYAcProbability(coefficientIndex, context, 6), false)
      ..prob(_fixtureYAcProbability(coefficientIndex, context, 7), true)
      ..prob(165, offset >= 2)
      ..prob(145, offset.isOdd);
  } else if (magnitude <= 18) {
    final offset = magnitude - 11;
    coeffs
      ..prob(_fixtureYAcProbability(coefficientIndex, context, 2), true)
      ..prob(_fixtureYAcProbability(coefficientIndex, context, 3), true)
      ..prob(_fixtureYAcProbability(coefficientIndex, context, 6), true)
      ..prob(_fixtureYAcProbability(coefficientIndex, context, 8), false)
      ..prob(_fixtureYAcProbability(coefficientIndex, context, 9), false)
      ..prob(173, (offset & 4) != 0)
      ..prob(148, (offset & 2) != 0)
      ..prob(140, offset.isOdd);
  } else if (magnitude <= 34) {
    final offset = magnitude - 19;
    coeffs
      ..prob(_fixtureYAcProbability(coefficientIndex, context, 2), true)
      ..prob(_fixtureYAcProbability(coefficientIndex, context, 3), true)
      ..prob(_fixtureYAcProbability(coefficientIndex, context, 6), true)
      ..prob(_fixtureYAcProbability(coefficientIndex, context, 8), false)
      ..prob(_fixtureYAcProbability(coefficientIndex, context, 9), true)
      ..prob(176, (offset & 8) != 0)
      ..prob(155, (offset & 4) != 0)
      ..prob(140, (offset & 2) != 0)
      ..prob(135, offset.isOdd);
  } else if (magnitude <= 66) {
    final offset = magnitude - 35;
    coeffs
      ..prob(_fixtureYAcProbability(coefficientIndex, context, 2), true)
      ..prob(_fixtureYAcProbability(coefficientIndex, context, 3), true)
      ..prob(_fixtureYAcProbability(coefficientIndex, context, 6), true)
      ..prob(_fixtureYAcProbability(coefficientIndex, context, 8), true)
      ..prob(_fixtureYAcProbability(coefficientIndex, context, 10), false)
      ..prob(180, (offset & 16) != 0)
      ..prob(157, (offset & 8) != 0)
      ..prob(141, (offset & 4) != 0)
      ..prob(134, (offset & 2) != 0)
      ..prob(130, offset.isOdd);
  } else {
    final offset = magnitude - 67;
    coeffs
      ..prob(_fixtureYAcProbability(coefficientIndex, context, 2), true)
      ..prob(_fixtureYAcProbability(coefficientIndex, context, 3), true)
      ..prob(_fixtureYAcProbability(coefficientIndex, context, 6), true)
      ..prob(_fixtureYAcProbability(coefficientIndex, context, 8), true)
      ..prob(_fixtureYAcProbability(coefficientIndex, context, 10), true)
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
  final nextIndex = coefficientIndex + 1;
  final nextContext = magnitude == 1 ? 1 : 2;
  coeffs.bit(coefficient.isNegative);
  if (nextIndex < 16) {
    coeffs.prob(_fixtureYAcProbability(nextIndex, nextContext, 0), false);
  }
}

int _fixtureYAcProbability(int coefficientIndex, int context, int node) {
  return _fixtureYAcProbs[_fixtureCoefficientBands[coefficientIndex]][context][node];
}
