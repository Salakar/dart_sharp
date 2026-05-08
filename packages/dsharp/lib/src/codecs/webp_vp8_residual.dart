part of 'webp_vp8.dart';

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
const _leftContextIndex = <int>[
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
const _aboveContextIndex = <int>[
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
const _y2BlockIndex = 24;
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
const _defaultY2Probs = <List<List<int>>>[
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
const _defaultUvProbs = <List<List<int>>>[
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
const _defaultYProbs = <List<List<int>>>[
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

bool _readResidual(
  Vp8BoolDecoder coeffs,
  _Vp8Planes planes,
  _Vp8TokenContexts contexts,
  int mbX,
  int mbY,
  _Vp8FrameHeader frame,
  int segmentId,
) {
  final lumaDc = _readY2Block(
    coeffs,
    frame,
    segmentId,
    contexts.contextFor(mbX, _y2BlockIndex),
  );
  var hasAnyCoefficients = lumaDc != null;
  contexts.setHasCoefficients(mbX, _y2BlockIndex, lumaDc != null);
  for (var block = 0; block < 16; block += 1) {
    final hasCoefficients = _readLumaAcBlock(
      coeffs,
      planes,
      mbX,
      mbY,
      block,
      frame,
      segmentId,
      lumaDc?[block] ?? 0,
      contexts.contextFor(mbX, block),
    );
    contexts.setHasCoefficients(mbX, block, hasCoefficients);
    hasAnyCoefficients = hasAnyCoefficients || hasCoefficients;
  }
  for (var block = 0; block < 4; block += 1) {
    final blockIndex = 16 + block;
    final hasCoefficients = _readChromaBlock(
      coeffs,
      planes,
      mbX,
      mbY,
      block,
      true,
      frame,
      segmentId,
      contexts.contextFor(mbX, blockIndex),
    );
    contexts.setHasCoefficients(mbX, blockIndex, hasCoefficients);
    hasAnyCoefficients = hasAnyCoefficients || hasCoefficients;
  }
  for (var block = 0; block < 4; block += 1) {
    final blockIndex = 20 + block;
    final hasCoefficients = _readChromaBlock(
      coeffs,
      planes,
      mbX,
      mbY,
      block,
      false,
      frame,
      segmentId,
      contexts.contextFor(mbX, blockIndex),
    );
    contexts.setHasCoefficients(mbX, blockIndex, hasCoefficients);
    hasAnyCoefficients = hasAnyCoefficients || hasCoefficients;
  }
  return hasAnyCoefficients;
}

bool _readBPredResidual(
  Vp8BoolDecoder coeffs,
  _Vp8Planes planes,
  _Vp8TokenContexts contexts,
  int mbX,
  int mbY,
  _Vp8FrameHeader frame,
  int segmentId,
  List<int> bModes,
) {
  var hasAnyCoefficients = false;
  contexts.setHasCoefficients(mbX, _y2BlockIndex, false);
  for (var block = 0; block < 16; block += 1) {
    planes.predictLumaSubblock(mbX, mbY, block, bModes[block]);
    final hasCoefficients = _readLumaBlock(
      coeffs,
      planes,
      mbX,
      mbY,
      block,
      frame,
      segmentId,
      contexts.contextFor(mbX, block),
    );
    contexts.setHasCoefficients(mbX, block, hasCoefficients);
    hasAnyCoefficients = hasAnyCoefficients || hasCoefficients;
  }
  for (var block = 0; block < 4; block += 1) {
    final blockIndex = 16 + block;
    final hasCoefficients = _readChromaBlock(
      coeffs,
      planes,
      mbX,
      mbY,
      block,
      true,
      frame,
      segmentId,
      contexts.contextFor(mbX, blockIndex),
    );
    contexts.setHasCoefficients(mbX, blockIndex, hasCoefficients);
    hasAnyCoefficients = hasAnyCoefficients || hasCoefficients;
  }
  for (var block = 0; block < 4; block += 1) {
    final blockIndex = 20 + block;
    final hasCoefficients = _readChromaBlock(
      coeffs,
      planes,
      mbX,
      mbY,
      block,
      false,
      frame,
      segmentId,
      contexts.contextFor(mbX, blockIndex),
    );
    contexts.setHasCoefficients(mbX, blockIndex, hasCoefficients);
    hasAnyCoefficients = hasAnyCoefficients || hasCoefficients;
  }
  return hasAnyCoefficients;
}

List<int>? _readY2Block(
  Vp8BoolDecoder coeffs,
  _Vp8FrameHeader frame,
  int segmentId,
  int initialContext,
) {
  List<int>? coefficients;
  var context = initialContext;
  for (var coefficientIndex = 0; coefficientIndex < 16; coefficientIndex += 1) {
    int probabilityAt(int node) =>
        frame.y2Probs.probabilityAt(coefficientIndex, context, node);
    if (coeffs.readBool(probabilityAt(_dctEobNode)) == 0) {
      break;
    }
    if (coeffs.readBool(probabilityAt(_dctZeroNode)) == 0) {
      context = 0;
      continue;
    }
    final magnitude = _readDctMagnitude(coeffs, probabilityAt);
    final coefficient = coeffs.readBit() == 1 ? -magnitude : magnitude;
    final quant = coefficientIndex == 0
        ? _y2DcQuant(frame.y2DcQuantIndex(segmentId))
        : _y2AcQuant(frame.y2AcQuantIndex(segmentId));
    coefficients ??= List<int>.filled(16, 0);
    coefficients[_zigZag[coefficientIndex]] = coefficient * quant;
    context = magnitude == 1 ? 1 : 2;
  }
  return coefficients == null ? null : _inverseWht(coefficients);
}

bool _readLumaAcBlock(
  Vp8BoolDecoder coeffs,
  _Vp8Planes planes,
  int mbX,
  int mbY,
  int block,
  _Vp8FrameHeader frame,
  int segmentId,
  int dcCoefficient,
  int initialContext,
) {
  final quant = _yAcQuant(frame.yAcQuantIndex(segmentId));
  List<int>? coefficients = dcCoefficient == 0 ? null : List<int>.filled(16, 0);
  var context = initialContext;
  var hasTokenCoefficient = false;
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
    hasTokenCoefficient = true;
  }
  if (dcCoefficient != 0) {
    planes.addLumaDctWithDc(mbX, mbY, block, dcCoefficient, coefficients);
  } else if (coefficients != null) {
    planes.addLumaDct(mbX, mbY, block, coefficients);
  }
  return hasTokenCoefficient;
}

bool _readLumaBlock(
  Vp8BoolDecoder coeffs,
  _Vp8Planes planes,
  int mbX,
  int mbY,
  int block,
  _Vp8FrameHeader frame,
  int segmentId,
  int initialContext,
) {
  List<int>? coefficients;
  var context = initialContext;
  for (var coefficientIndex = 0; coefficientIndex < 16; coefficientIndex += 1) {
    int probabilityAt(int node) =>
        frame.yProbs.probabilityAt(coefficientIndex, context, node);
    if (coeffs.readBool(probabilityAt(_dctEobNode)) == 0) {
      break;
    }
    if (coeffs.readBool(probabilityAt(_dctZeroNode)) == 0) {
      context = 0;
      continue;
    }
    final magnitude = _readDctMagnitude(coeffs, probabilityAt);
    final coefficient = coeffs.readBit() == 1 ? -magnitude : magnitude;
    final quant = coefficientIndex == 0
        ? _yDcQuant(frame.yDcQuantIndex(segmentId))
        : _yAcQuant(frame.yAcQuantIndex(segmentId));
    coefficients ??= List<int>.filled(16, 0);
    coefficients[_zigZag[coefficientIndex]] = coefficient * quant;
    context = magnitude == 1 ? 1 : 2;
  }
  if (coefficients != null) {
    planes.addLumaDct(mbX, mbY, block, coefficients);
  }
  return coefficients != null;
}

bool _readChromaBlock(
  Vp8BoolDecoder coeffs,
  _Vp8Planes planes,
  int mbX,
  int mbY,
  int block,
  bool isU,
  _Vp8FrameHeader frame,
  int segmentId,
  int initialContext,
) {
  List<int>? coefficients;
  var context = initialContext;
  for (var coefficientIndex = 0; coefficientIndex < 16; coefficientIndex += 1) {
    int probabilityAt(int node) =>
        frame.uvProbs.probabilityAt(coefficientIndex, context, node);
    if (coeffs.readBool(probabilityAt(_dctEobNode)) == 0) {
      break;
    }
    if (coeffs.readBool(probabilityAt(_dctZeroNode)) == 0) {
      context = 0;
      continue;
    }
    final magnitude = _readDctMagnitude(coeffs, probabilityAt);
    final coefficient = coeffs.readBit() == 1 ? -magnitude : magnitude;
    final quant = coefficientIndex == 0
        ? _uvDcQuant(frame.uvDcQuantIndex(segmentId))
        : _uvAcQuant(frame.uvAcQuantIndex(segmentId));
    coefficients ??= List<int>.filled(16, 0);
    coefficients[_zigZag[coefficientIndex]] = coefficient * quant;
    context = magnitude == 1 ? 1 : 2;
  }
  if (coefficients != null) {
    planes.addChromaDct(mbX, mbY, block, isU, coefficients);
  }
  return coefficients != null;
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

final class _Vp8LumaProbs {
  _Vp8LumaProbs.defaults()
    : _probabilities = [
        for (final band in _defaultYProbs)
          [for (final context in band) List<int>.of(context, growable: false)],
      ];

  final List<List<List<int>>> _probabilities;

  List<List<int>> operator [](int band) => _probabilities[band];

  int probabilityAt(int coefficientIndex, int context, int node) {
    return _probabilities[_coefficientBands[coefficientIndex]][context][node];
  }
}

final class _Vp8Y2Probs {
  _Vp8Y2Probs.defaults()
    : _probabilities = [
        for (final band in _defaultY2Probs)
          [for (final context in band) List<int>.of(context, growable: false)],
      ];

  final List<List<List<int>>> _probabilities;

  List<List<int>> operator [](int band) => _probabilities[band];

  int probabilityAt(int coefficientIndex, int context, int node) {
    return _probabilities[_coefficientBands[coefficientIndex]][context][node];
  }
}

final class _Vp8ChromaProbs {
  _Vp8ChromaProbs.defaults()
    : _probabilities = [
        for (final band in _defaultUvProbs)
          [for (final context in band) List<int>.of(context, growable: false)],
      ];

  final List<List<List<int>>> _probabilities;

  List<List<int>> operator [](int band) => _probabilities[band];

  int probabilityAt(int coefficientIndex, int context, int node) {
    return _probabilities[_coefficientBands[coefficientIndex]][context][node];
  }
}

final class _Vp8TokenContexts {
  _Vp8TokenContexts(int mbCols) : _above = List<int>.filled(mbCols * 9, 0);

  final List<int> _above;
  final _left = List<int>.filled(9, 0);

  void resetLeft() {
    _left.fillRange(0, _left.length, 0);
  }

  void clearMacroblock(int mbX) {
    _left.fillRange(0, _left.length, 0);
    _above.fillRange(mbX * 9, (mbX + 1) * 9, 0);
  }

  int contextFor(int mbX, int block) {
    return _left[_leftContextIndex[block]] +
        _above[mbX * 9 + _aboveContextIndex[block]];
  }

  void setHasCoefficients(int mbX, int block, bool hasCoefficients) {
    final value = hasCoefficients ? 1 : 0;
    _left[_leftContextIndex[block]] = value;
    _above[mbX * 9 + _aboveContextIndex[block]] = value;
  }
}

List<int> _inverseWht(List<int> input) {
  final output = List<int>.filled(16, 0);
  for (var i = 0; i < 4; i += 1) {
    final a1 = input[i] + input[12 + i];
    final b1 = input[4 + i] + input[8 + i];
    final c1 = input[4 + i] - input[8 + i];
    final d1 = input[i] - input[12 + i];
    output[i] = a1 + b1;
    output[4 + i] = c1 + d1;
    output[8 + i] = a1 - b1;
    output[12 + i] = d1 - c1;
  }
  for (var row = 0; row < 4; row += 1) {
    final base = row * 4;
    final a1 = output[base] + output[base + 3];
    final b1 = output[base + 1] + output[base + 2];
    final c1 = output[base + 1] - output[base + 2];
    final d1 = output[base] - output[base + 3];
    output[base] = (a1 + b1 + 3) >> 3;
    output[base + 1] = (c1 + d1 + 3) >> 3;
    output[base + 2] = (a1 - b1 + 3) >> 3;
    output[base + 3] = (d1 - c1 + 3) >> 3;
  }
  return output;
}

int _readCategoryExtra(Vp8BoolDecoder coeffs, List<int> probabilities) {
  var value = 0;
  for (final probability in probabilities) {
    value = (value << 1) | coeffs.readBool(probability);
  }
  return value;
}
