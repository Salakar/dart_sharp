part of 'webp_lossless_fixture.dart';

/// Builds a VP8L WebP using the subtract-green transform.
Uint8List subtractGreenVp8lWebp({
  required int width,
  required int height,
  required int red,
  required int green,
  required int blue,
  required int alpha,
}) {
  final bits = _BitWriter()
    ..write(width - 1, 14)
    ..write(height - 1, 14)
    ..write(alpha == 255 ? 0 : 1, 1)
    ..write(0, 3)
    ..write(1, 1)
    ..write(2, 2)
    ..write(0, 1)
    ..write(0, 1)
    ..write(0, 1);
  _writeSingleSymbolCode(bits, green);
  _writeSingleSymbolCode(bits, (red - green) & 0xff);
  _writeSingleSymbolCode(bits, (blue - green) & 0xff);
  _writeSingleSymbolCode(bits, alpha);
  _writeSingleSymbolCode(bits, 0);
  return _webpContainer(Uint8List.fromList(<int>[0x2f, ...bits.finish()]));
}

/// Builds a VP8L WebP using one color transform block.
Uint8List colorTransformVp8lWebp({
  required int width,
  required int height,
  required int red,
  required int green,
  required int blue,
  required int alpha,
  required int greenToRed,
  required int greenToBlue,
  required int redToBlue,
}) {
  final residualRed = (red - _colorTransformDelta(greenToRed, green)) & 0xff;
  final residualBlue =
      (blue -
          _colorTransformDelta(greenToBlue, green) -
          _colorTransformDelta(redToBlue, red)) &
      0xff;
  final bits = _BitWriter()
    ..write(width - 1, 14)
    ..write(height - 1, 14)
    ..write(alpha == 255 ? 0 : 1, 1)
    ..write(0, 3)
    ..write(1, 1)
    ..write(1, 2)
    ..write(0, 3);
  _writeSolidImageData(
    bits,
    red: redToBlue,
    green: greenToBlue,
    blue: greenToRed,
    alpha: 255,
    writeMetaPrefix: false,
  );
  bits.write(0, 1);
  _writeSolidImageData(
    bits,
    red: residualRed,
    green: green,
    blue: residualBlue,
    alpha: alpha,
    writeMetaPrefix: true,
  );
  return _webpContainer(Uint8List.fromList(<int>[0x2f, ...bits.finish()]));
}

/// Builds a 2x2 VP8L WebP using predictor mode 7.
Uint8List predictorVp8lWebp() {
  final bits = _BitWriter()
    ..write(1, 14)
    ..write(1, 14)
    ..write(0, 1)
    ..write(0, 3)
    ..write(1, 1)
    ..write(0, 2)
    ..write(0, 3);
  _writeSolidImageData(
    bits,
    red: 0,
    green: 7,
    blue: 0,
    alpha: 255,
    writeMetaPrefix: false,
  );
  bits.write(0, 1);
  _writeSolidImageData(
    bits,
    red: 10,
    green: 20,
    blue: 30,
    alpha: 0,
    writeMetaPrefix: true,
  );
  return _webpContainer(Uint8List.fromList(<int>[0x2f, ...bits.finish()]));
}

void _writeSolidImageData(
  _BitWriter bits, {
  required int red,
  required int green,
  required int blue,
  required int alpha,
  required bool writeMetaPrefix,
}) {
  bits.write(0, 1);
  if (writeMetaPrefix) {
    bits.write(0, 1);
  }
  _writeSingleSymbolCode(bits, green);
  _writeSingleSymbolCode(bits, red);
  _writeSingleSymbolCode(bits, blue);
  _writeSingleSymbolCode(bits, alpha);
  _writeSingleSymbolCode(bits, 0);
}

int _colorTransformDelta(int transform, int channel) {
  return (_fixtureSigned8(transform) * _fixtureSigned8(channel)) >> 5;
}

int _fixtureSigned8(int value) => value < 128 ? value : value - 256;
