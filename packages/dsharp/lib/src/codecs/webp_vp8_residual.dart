part of 'webp_vp8.dart';

const _y2EobProb = 198;
const _yAcEobProb = 253;
const _yAcZeroProb = 136;
const _yAcOneProb = 254;
const _yAcPostOneEobProb = 181;
const _uvEobNode = 0;
const _uvZeroNode = 1;
const _uvOneNode = 2;
const _uvSmallNode = 3;
const _uvTwoNode = 4;
const _uvThreeNode = 5;
const _uvHighLowNode = 6;
const _uvCatOneNode = 7;
const _uvCatThreeFourNode = 8;
const _uvCatThreeNode = 9;
const _uvCatFiveNode = 10;
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
  if (coeffs.readBool(_yAcEobProb) == 0) {
    return;
  }
  if (coeffs.readBool(_yAcZeroProb) == 0 || coeffs.readBool(_yAcOneProb) != 0) {
    throw const UnsupportedCodecException(
      'VP8 luma AC residual coefficients are not implemented yet.',
    );
  }
  final coefficient = coeffs.readBit() == 1 ? -1 : 1;
  if (coeffs.readBool(_yAcPostOneEobProb) != 0) {
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
  if (coeffs.readBool(probabilities[_uvEobNode]) == 0) {
    return 0;
  }
  if (coeffs.readBool(probabilities[_uvZeroNode]) == 0) {
    throw const UnsupportedCodecException(
      'VP8 residual coefficient values are not implemented yet.',
    );
  }
  final magnitude = _readUvDcMagnitude(coeffs, probabilities);
  final sign = coeffs.readBit() == 1;
  if (coeffs.readBool(_uvPostOneEobProb) != 0) {
    throw const UnsupportedCodecException(
      'VP8 residual coefficient runs are not implemented yet.',
    );
  }
  return sign ? -magnitude : magnitude;
}

int _readUvDcMagnitude(Vp8BoolDecoder coeffs, _Vp8ChromaDcProbs probabilities) {
  if (coeffs.readBool(probabilities[_uvOneNode]) == 0) {
    return 1;
  }
  if (coeffs.readBool(probabilities[_uvSmallNode]) != 0) {
    return _readUvDcCategory(coeffs, probabilities);
  }
  if (coeffs.readBool(probabilities[_uvTwoNode]) == 0) {
    return 2;
  }
  return coeffs.readBool(probabilities[_uvThreeNode]) == 0 ? 3 : 4;
}

int _readUvDcCategory(Vp8BoolDecoder coeffs, _Vp8ChromaDcProbs probabilities) {
  if (coeffs.readBool(probabilities[_uvHighLowNode]) == 0) {
    if (coeffs.readBool(probabilities[_uvCatOneNode]) == 0) {
      return 5 + coeffs.readBool(_catOneExtraProb);
    }
    return 7 + _readCategoryExtra(coeffs, _catTwoExtraProbs);
  }

  if (coeffs.readBool(probabilities[_uvCatThreeFourNode]) != 0) {
    if (coeffs.readBool(probabilities[_uvCatFiveNode]) == 0) {
      return 35 + _readCategoryExtra(coeffs, _catFiveExtraProbs);
    }
    return 67 + _readCategoryExtra(coeffs, _catSixExtraProbs);
  }
  if (coeffs.readBool(probabilities[_uvCatThreeNode]) == 0) {
    return 11 + _readCategoryExtra(coeffs, _catThreeExtraProbs);
  }
  return 19 + _readCategoryExtra(coeffs, _catFourExtraProbs);
}

final class _Vp8ChromaDcProbs {
  _Vp8ChromaDcProbs.defaults()
    : _probabilities = List<int>.of(_defaultUvDcProbs, growable: false);

  final List<int> _probabilities;

  int operator [](int index) => _probabilities[index];

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
