part of 'webp_vp8.dart';

const _y2EobProb = 198;
const _yAcEobProb = 253;
const _uvEobProb = 202;
const _uvZeroProb = 24;
const _uvOneProb = 213;
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
        _dcQuant(frame.uvDcQuantIndex),
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
        _dcQuant(frame.uvDcQuantIndex),
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
  if (coeffs.readBool(_uvZeroProb) == 0 || coeffs.readBool(_uvOneProb) != 0) {
    throw const UnsupportedCodecException(
      'VP8 residual coefficient values are not implemented yet.',
    );
  }
  final sign = coeffs.readBit() == 1;
  if (coeffs.readBool(_uvPostOneEobProb) != 0) {
    throw const UnsupportedCodecException(
      'VP8 residual coefficient runs are not implemented yet.',
    );
  }
  return sign ? -1 : 1;
}
