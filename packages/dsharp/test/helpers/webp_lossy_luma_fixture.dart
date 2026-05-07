part of 'webp_lossy_fixture.dart';

Uint8List lumaAcResidualVp8Webp({
  required int width,
  required int height,
  int coefficient = 1,
}) => _simpleWebp(
  _residualVp8Payload(
    width: width,
    height: height,
    lumaAc: true,
    coefficient: coefficient,
  ),
);

void _writeYAcToken(_BoolWriter coeffs, int coefficient) {
  final magnitude = coefficient.abs();
  if (magnitude < 1 || magnitude > 4) {
    throw ArgumentError.value(coefficient, 'coefficient');
  }
  coeffs
    ..prob(253, true)
    ..prob(136, true);
  if (magnitude == 1) {
    coeffs.prob(254, false);
  } else {
    coeffs
      ..prob(254, true)
      ..prob(255, false);
    if (magnitude == 2) {
      coeffs.prob(228, false);
    } else {
      coeffs
        ..prob(228, true)
        ..prob(219, magnitude == 4);
    }
  }
  coeffs
    ..bit(coefficient.isNegative)
    ..prob(magnitude == 1 ? 181 : 78, false);
}
