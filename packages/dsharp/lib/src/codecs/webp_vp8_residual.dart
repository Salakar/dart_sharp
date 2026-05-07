part of 'webp_vp8.dart';

const _y2EobProb = 198;
const _dctEobNode = 0;
const _dctZeroNode = 1;
const _dctOneNode = 2;
const _dctSmallNode = 3;
const _dctTwoNode = 4;
const _dctThreeNode = 5;
const _dctHighLowNode = 6;
const _dctCatOneNode = 7;
const _dctCatThreeFourNode = 8;
const _dctCatThreeNode = 9;
const _dctCatFiveNode = 10;
const _coefficientBands = <int>[0, 1, 2, 3, 6, 4, 5, 6, 6, 6, 6, 6, 6, 6, 6, 7];
const _zigZag = <int>[0, 1, 4, 8, 5, 2, 3, 6, 9, 12, 13, 10, 7, 11, 14, 15];
const _defaultYAcProbs = <List<List<int>>>[
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
const _defaultUvDcProbs = <int>[
  202,
  24,
  213,
  235,
  186,
  191,
  220,
  160,
  240,
  175,
  255,
];
const _catOneExtraProb = 159;
const _catTwoExtraProbs = <int>[165, 145];
const _catThreeExtraProbs = <int>[173, 148, 140];
const _catFourExtraProbs = <int>[176, 155, 140, 135];
const _catFiveExtraProbs = <int>[180, 157, 141, 134, 130];
const _catSixExtraProbs = <int>[
  254,
  254,
  243,
  230,
  196,
  177,
  153,
  140,
  133,
  130,
  129,
];
const _uvPostOneEobProb = 166;

void _readResidual(
  Vp8BoolDecoder coeffs,
  _Vp8Planes planes,
  int mbX,
  int mbY,
  _Vp8FrameHeader frame,
) {
  _readEobOnlyBlock(coeffs, _y2EobProb);
  for (var block = 0; block < 16; block += 1) {
    _readLumaAcBlock(coeffs, planes, mbX, mbY, block, frame);
  }
  for (var block = 0; block < 4; block += 1) {
    final coefficient = _readUvDcCoefficient(coeffs, frame.uvDcProbs);
    if (coefficient != 0) {
      planes.addChromaDc(
        mbX,
        mbY,
        block,
        true,
        coefficient,
        _uvDcQuant(frame.uvDcQuantIndex),
      );
    }
  }
  for (var block = 0; block < 4; block += 1) {
    final coefficient = _readUvDcCoefficient(coeffs, frame.uvDcProbs);
    if (coefficient != 0) {
      planes.addChromaDc(
        mbX,
        mbY,
        block,
        false,
        coefficient,
        _uvDcQuant(frame.uvDcQuantIndex),
      );
    }
  }
}

void _readLumaAcBlock(
  Vp8BoolDecoder coeffs,
  _Vp8Planes planes,
  int mbX,
  int mbY,
  int block,
  _Vp8FrameHeader frame,
) {
  final quant = _yAcQuant(frame.yAcQuantIndex);
  List<int>? coefficients;
  var context = 0;
  for (var coefficientIndex = 1; coefficientIndex < 16; coefficientIndex += 1) {
    int probabilityAt(int node) =>
        frame.yAcProbs.probabilityAt(coefficientIndex, context, node);
    if (coeffs.readBool(probabilityAt(_dctEobNode)) == 0) {
      break;
    }
    if (coeffs.readBool(probabilityAt(_dctZeroNode)) == 0) {
      context = 0;
      continue;
    }
    final magnitude = _readDctMagnitude(coeffs, probabilityAt);
    final coefficient = coeffs.readBit() == 1 ? -magnitude : magnitude;
    coefficients ??= List<int>.filled(16, 0);
    coefficients[_zigZag[coefficientIndex]] = coefficient * quant;
    context = magnitude == 1 ? 1 : 2;
  }
  if (coefficients != null) {
    planes.addLumaDct(mbX, mbY, block, coefficients);
  }
}

void _readEobOnlyBlock(Vp8BoolDecoder coeffs, int eobProbability) {
  if (coeffs.readBool(eobProbability) != 0) {
    throw const UnsupportedCodecException(
      'VP8 residual coefficient values are not implemented yet.',
    );
  }
}

int _readUvDcCoefficient(
  Vp8BoolDecoder coeffs,
  _Vp8ChromaDcProbs probabilities,
) {
  if (coeffs.readBool(probabilities[_dctEobNode]) == 0) {
    return 0;
  }
  if (coeffs.readBool(probabilities[_dctZeroNode]) == 0) {
    throw const UnsupportedCodecException(
      'VP8 residual coefficient values are not implemented yet.',
    );
  }
  final magnitude = _readDctMagnitude(coeffs, probabilities.probabilityAt);
  final sign = coeffs.readBit() == 1;
  if (coeffs.readBool(_uvPostOneEobProb) != 0) {
    throw const UnsupportedCodecException(
      'VP8 residual coefficient runs are not implemented yet.',
    );
  }
  return sign ? -magnitude : magnitude;
}

int _readDctMagnitude(
  Vp8BoolDecoder coeffs,
  int Function(int node) probabilityAt,
) {
  if (coeffs.readBool(probabilityAt(_dctOneNode)) == 0) {
    return 1;
  }
  if (coeffs.readBool(probabilityAt(_dctSmallNode)) != 0) {
    return _readDctCategory(coeffs, probabilityAt);
  }
  if (coeffs.readBool(probabilityAt(_dctTwoNode)) == 0) {
    return 2;
  }
  return coeffs.readBool(probabilityAt(_dctThreeNode)) == 0 ? 3 : 4;
}

int _readDctCategory(
  Vp8BoolDecoder coeffs,
  int Function(int node) probabilityAt,
) {
  if (coeffs.readBool(probabilityAt(_dctHighLowNode)) == 0) {
    if (coeffs.readBool(probabilityAt(_dctCatOneNode)) == 0) {
      return 5 + coeffs.readBool(_catOneExtraProb);
    }
    return 7 + _readCategoryExtra(coeffs, _catTwoExtraProbs);
  }

  if (coeffs.readBool(probabilityAt(_dctCatThreeFourNode)) != 0) {
    if (coeffs.readBool(probabilityAt(_dctCatFiveNode)) == 0) {
      return 35 + _readCategoryExtra(coeffs, _catFiveExtraProbs);
    }
    return 67 + _readCategoryExtra(coeffs, _catSixExtraProbs);
  }
  if (coeffs.readBool(probabilityAt(_dctCatThreeNode)) == 0) {
    return 11 + _readCategoryExtra(coeffs, _catThreeExtraProbs);
  }
  return 19 + _readCategoryExtra(coeffs, _catFourExtraProbs);
}

final class _Vp8LumaAcProbs {
  _Vp8LumaAcProbs.defaults()
    : _probabilities = [
        for (final band in _defaultYAcProbs)
          [for (final context in band) List<int>.of(context, growable: false)],
      ];

  final List<List<List<int>>> _probabilities;

  List<List<int>> operator [](int band) => _probabilities[band];

  int probabilityAt(int coefficientIndex, int context, int node) {
    return _probabilities[_coefficientBands[coefficientIndex]][context][node];
  }
}

final class _Vp8ChromaDcProbs {
  _Vp8ChromaDcProbs.defaults()
    : _probabilities = List<int>.of(_defaultUvDcProbs, growable: false);

  final List<int> _probabilities;

  int operator [](int index) => _probabilities[index];

  int probabilityAt(int index) => _probabilities[index];

  void operator []=(int index, int value) {
    _probabilities[index] = value;
  }
}

int _readCategoryExtra(Vp8BoolDecoder coeffs, List<int> probabilities) {
  var value = 0;
  for (final probability in probabilities) {
    value = (value << 1) | coeffs.readBool(probability);
  }
  return value;
}
