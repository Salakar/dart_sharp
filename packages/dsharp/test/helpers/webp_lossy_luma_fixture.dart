part of 'webp_lossy_fixture.dart';

Uint8List lumaAcResidualVp8Webp({required int width, required int height}) =>
    _simpleWebp(
      _residualVp8Payload(width: width, height: height, lumaAc: true),
    );

void _writeYAcToken(_BoolWriter coeffs) {
  coeffs
    ..prob(253, true)
    ..prob(136, true)
    ..prob(254, false)
    ..bit(false)
    ..prob(181, false);
}
