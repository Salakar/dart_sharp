part of 'webp_lossy_fixture.dart';

/// Builds a lossy VP8 WebP whose residual partition contains EOB blocks.
Uint8List eobResidualVp8Webp({
  required int width,
  required int height,
  int qIndex = 0,
}) {
  final vp8 = _residualVp8Payload(width: width, height: height, qIndex: qIndex);
  return _simpleWebp(vp8);
}

/// Builds a VP8 WebP with a residual token that this decoder rejects.
Uint8List nonEmptyResidualVp8Webp({required int width, required int height}) {
  final vp8 = _residualVp8Payload(width: width, height: height, nonEmpty: true);
  return _simpleWebp(vp8);
}

/// Builds a VP8 WebP with a supported chroma DC residual.
Uint8List chromaDcResidualVp8Webp({
  required int width,
  required int height,
  int qIndex = 0,
  int coefficient = 1,
}) {
  final vp8 = _residualVp8Payload(
    width: width,
    height: height,
    chromaDc: true,
    qIndex: qIndex,
    coefficient: coefficient,
  );
  return _simpleWebp(vp8);
}

Uint8List _residualVp8Payload({
  required int width,
  required int height,
  bool nonEmpty = false,
  bool chromaDc = false,
  int qIndex = 0,
  int coefficient = 1,
}) {
  final mbCols = (width + 15) >> 4;
  final mbRows = (height + 15) >> 4;
  final first = _BoolWriter()
    ..bit(false)
    ..bit(false)
    ..bit(false)
    ..bit(false)
    ..literal(0, 6)
    ..literal(0, 3)
    ..bit(false)
    ..literal(0, 2)
    ..literal(qIndex, 7);
  for (var i = 0; i < 5; i += 1) {
    first.bit(false);
  }
  first.bit(false);
  for (var i = 0; i < 4 * 8 * 3 * 11; i += 1) {
    first.bit(false);
  }
  first.bit(false);
  for (var i = 0; i < mbCols * mbRows; i += 1) {
    _writeYMode(first, 0);
    first.prob(142, false);
  }
  final firstPartition = first.finish();
  final coeffs = _BoolWriter();
  for (var i = 0; i < mbCols * mbRows; i += 1) {
    coeffs.prob(198, nonEmpty && i == 0);
    for (var block = 0; block < 16; block += 1) {
      coeffs.prob(253, false);
    }
    if (chromaDc && i == 0) {
      _writeUvDcToken(coeffs, coefficient);
    } else {
      coeffs.prob(202, false);
    }
    for (var block = 1; block < 8; block += 1) {
      coeffs.prob(202, false);
    }
  }
  return (_ByteWriter()
        ..u24((1 << 4) | (firstPartition.length << 5))
        ..byte(0x9d)
        ..byte(0x01)
        ..byte(0x2a)
        ..u16(width)
        ..u16(height)
        ..bytes(firstPartition)
        ..bytes(coeffs.finish()))
      .finish();
}

void _writeUvDcToken(_BoolWriter coeffs, int coefficient) {
  final magnitude = coefficient.abs();
  if (magnitude < 1 || magnitude > 6) {
    throw ArgumentError.value(coefficient, 'coefficient');
  }
  coeffs
    ..prob(202, true)
    ..prob(24, true);
  if (magnitude == 1) {
    coeffs.prob(213, false);
  } else if (magnitude <= 4) {
    coeffs
      ..prob(213, true)
      ..prob(235, false);
    if (magnitude == 2) {
      coeffs.prob(186, false);
    } else {
      coeffs
        ..prob(186, true)
        ..prob(191, magnitude == 4);
    }
  } else {
    coeffs
      ..prob(213, true)
      ..prob(235, true)
      ..prob(220, false)
      ..prob(160, false)
      ..prob(159, magnitude == 6);
  }
  coeffs
    ..bit(coefficient.isNegative)
    ..prob(166, false);
}
