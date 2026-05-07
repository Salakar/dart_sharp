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
  if (magnitude < 1 || magnitude > 2048) {
    throw ArgumentError.value(coefficient, 'coefficient');
  }
  coeffs
    ..prob(253, true)
    ..prob(136, true);
  if (magnitude == 1) {
    coeffs.prob(254, false);
  } else if (magnitude <= 4) {
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
  } else if (magnitude <= 6) {
    coeffs
      ..prob(254, true)
      ..prob(255, true)
      ..prob(128, false)
      ..prob(128, false)
      ..prob(159, magnitude == 6);
  } else if (magnitude <= 10) {
    final offset = magnitude - 7;
    coeffs
      ..prob(254, true)
      ..prob(255, true)
      ..prob(128, false)
      ..prob(128, true)
      ..prob(165, offset >= 2)
      ..prob(145, offset.isOdd);
  } else if (magnitude <= 18) {
    final offset = magnitude - 11;
    coeffs
      ..prob(254, true)
      ..prob(255, true)
      ..prob(128, true)
      ..prob(128, false)
      ..prob(128, false)
      ..prob(173, (offset & 4) != 0)
      ..prob(148, (offset & 2) != 0)
      ..prob(140, offset.isOdd);
  } else if (magnitude <= 34) {
    final offset = magnitude - 19;
    coeffs
      ..prob(254, true)
      ..prob(255, true)
      ..prob(128, true)
      ..prob(128, false)
      ..prob(128, true)
      ..prob(176, (offset & 8) != 0)
      ..prob(155, (offset & 4) != 0)
      ..prob(140, (offset & 2) != 0)
      ..prob(135, offset.isOdd);
  } else if (magnitude <= 66) {
    final offset = magnitude - 35;
    coeffs
      ..prob(254, true)
      ..prob(255, true)
      ..prob(128, true)
      ..prob(128, true)
      ..prob(128, false)
      ..prob(180, (offset & 16) != 0)
      ..prob(157, (offset & 8) != 0)
      ..prob(141, (offset & 4) != 0)
      ..prob(134, (offset & 2) != 0)
      ..prob(130, offset.isOdd);
  } else {
    final offset = magnitude - 67;
    coeffs
      ..prob(254, true)
      ..prob(255, true)
      ..prob(128, true)
      ..prob(128, true)
      ..prob(128, true)
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
  coeffs
    ..bit(coefficient.isNegative)
    ..prob(magnitude == 1 ? 181 : 78, false);
}
