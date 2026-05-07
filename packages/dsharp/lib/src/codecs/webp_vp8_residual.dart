part of 'webp_vp8.dart';

const _y2EobProb = 198;
const _yAcEobProb = 253;
const _uvEobProb = 202;

void _readEmptyResidual(Vp8BoolDecoder coeffs) {
  _readEobOnlyBlock(coeffs, _y2EobProb);
  for (var i = 0; i < 16; i += 1) {
    _readEobOnlyBlock(coeffs, _yAcEobProb);
  }
  for (var i = 0; i < 8; i += 1) {
    _readEobOnlyBlock(coeffs, _uvEobProb);
  }
}

void _readEobOnlyBlock(Vp8BoolDecoder coeffs, int eobProbability) {
  if (coeffs.readBool(eobProbability) != 0) {
    throw const UnsupportedCodecException(
      'VP8 residual coefficient values are not implemented yet.',
    );
  }
}
