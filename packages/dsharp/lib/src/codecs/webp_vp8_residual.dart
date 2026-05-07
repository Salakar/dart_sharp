part of 'webp_vp8.dart';

const _y2EobProb = 198;
const _yAcPostOneEobProb = 181;
const _yAcPostLargeEobProb = 78;
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
const _defaultYAcProbs = <int>[
  253,
  136,
  254,
  255,
  228,
  219,
  128,
  128,
  128,
  128,
  128,
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
  if (coeffs.readBool(_defaultYAcProbability(_dctEobNode)) == 0) {
    return;
  }
  if (coeffs.readBool(_defaultYAcProbability(_dctZeroNode)) == 0) {
    throw const UnsupportedCodecException(
      'VP8 luma AC residual coefficients are not implemented yet.',
    );
  }
  final magnitude = _readDctMagnitude(coeffs, _defaultYAcProbability);
  final coefficient = coeffs.readBit() == 1 ? -magnitude : magnitude;
  final nextEobProb = magnitude == 1
      ? _yAcPostOneEobProb
      : _yAcPostLargeEobProb;
  if (coeffs.readBool(nextEobProb) != 0) {
    throw const UnsupportedCodecException(
      'VP8 residual coefficient runs are not implemented yet.',
    );
  }
  planes.addLumaDct(
    mbX,
    mbY,
    block,
    coefficient,
    _yAcQuant(frame.yAcQuantIndex),
  );
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

int _defaultYAcProbability(int node) => _defaultYAcProbs[node];

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
