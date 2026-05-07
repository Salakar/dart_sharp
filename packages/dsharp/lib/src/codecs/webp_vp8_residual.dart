part of 'webp_vp8.dart';

const _y2EobProb = 198;
const _yAcEobProb = 253;
const _uvEobProb = 202;
const _uvZeroProb = 24;
const _uvOneProb = 213;
const _uvSmallProb = 235;
const _uvTwoProb = 186;
const _uvThreeProb = 191;
const _uvHighLowProb = 220;
const _uvCatOneProb = 160;
const _uvCatThreeFourProb = 240;
const _uvCatThreeProb = 175;
const _catOneExtraProb = 159;
const _catTwoExtraProbs = <int>[165, 145];
const _catThreeExtraProbs = <int>[173, 148, 140];
const _catFourExtraProbs = <int>[176, 155, 140, 135];
const _uvPostOneEobProb = 166;

void _readResidual(
  Vp8BoolDecoder coeffs,
  _Vp8Planes planes,
  int mbX,
  int mbY,
  _Vp8FrameHeader frame,
) {
  _readEobOnlyBlock(coeffs, _y2EobProb);
  for (var i = 0; i < 16; i += 1) {
    _readEobOnlyBlock(coeffs, _yAcEobProb);
  }
  for (var block = 0; block < 4; block += 1) {
    final coefficient = _readUvDcCoefficient(coeffs);
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
    final coefficient = _readUvDcCoefficient(coeffs);
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

void _readEobOnlyBlock(Vp8BoolDecoder coeffs, int eobProbability) {
  if (coeffs.readBool(eobProbability) != 0) {
    throw const UnsupportedCodecException(
      'VP8 residual coefficient values are not implemented yet.',
    );
  }
}

int _readUvDcCoefficient(Vp8BoolDecoder coeffs) {
  if (coeffs.readBool(_uvEobProb) == 0) {
    return 0;
  }
  if (coeffs.readBool(_uvZeroProb) == 0) {
    throw const UnsupportedCodecException(
      'VP8 residual coefficient values are not implemented yet.',
    );
  }
  final magnitude = _readUvDcMagnitude(coeffs);
  final sign = coeffs.readBit() == 1;
  if (coeffs.readBool(_uvPostOneEobProb) != 0) {
    throw const UnsupportedCodecException(
      'VP8 residual coefficient runs are not implemented yet.',
    );
  }
  return sign ? -magnitude : magnitude;
}

int _readUvDcMagnitude(Vp8BoolDecoder coeffs) {
  if (coeffs.readBool(_uvOneProb) == 0) {
    return 1;
  }
  if (coeffs.readBool(_uvSmallProb) != 0) {
    return _readUvDcCategory(coeffs);
  }
  if (coeffs.readBool(_uvTwoProb) == 0) {
    return 2;
  }
  return coeffs.readBool(_uvThreeProb) == 0 ? 3 : 4;
}

int _readUvDcCategory(Vp8BoolDecoder coeffs) {
  if (coeffs.readBool(_uvHighLowProb) == 0) {
    if (coeffs.readBool(_uvCatOneProb) == 0) {
      return 5 + coeffs.readBool(_catOneExtraProb);
    }
    return 7 + _readCategoryExtra(coeffs, _catTwoExtraProbs);
  }

  if (coeffs.readBool(_uvCatThreeFourProb) != 0) {
    throw const UnsupportedCodecException(
      'VP8 residual coefficient categories are not implemented yet.',
    );
  }
  if (coeffs.readBool(_uvCatThreeProb) == 0) {
    return 11 + _readCategoryExtra(coeffs, _catThreeExtraProbs);
  }
  return 19 + _readCategoryExtra(coeffs, _catFourExtraProbs);
}

int _readCategoryExtra(Vp8BoolDecoder coeffs, List<int> probabilities) {
  var value = 0;
  for (final probability in probabilities) {
    value = (value << 1) | coeffs.readBool(probability);
  }
  return value;
}
