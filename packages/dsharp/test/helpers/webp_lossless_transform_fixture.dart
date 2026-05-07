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

/// Builds a VP8L WebP using an unpacked color-indexing transform.
Uint8List colorIndexingVp8lWebp({
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
    ..write(3, 2)
    ..write(16, 8);
  _writeSolidImageData(
    bits,
    red: red,
    green: green,
    blue: blue,
    alpha: alpha,
    writeMetaPrefix: false,
  );
  bits.write(0, 1);
  _writeSolidImageData(
    bits,
    red: 0,
    green: 0,
    blue: 0,
    alpha: 255,
    writeMetaPrefix: true,
  );
  return _webpContainer(Uint8List.fromList(<int>[0x2f, ...bits.finish()]));
}

/// Builds a VP8L WebP using a 1-bit packed color-indexing transform.
Uint8List packedColorIndexingVp8lWebp() {
  const first = (red: 20, green: 40, blue: 60, alpha: 255);
  const second = (red: 200, green: 80, blue: 10, alpha: 255);
  final bits = _BitWriter()
    ..write(3, 14)
    ..write(0, 14)
    ..write(0, 1)
    ..write(0, 3)
    ..write(1, 1)
    ..write(3, 2)
    ..write(1, 8);
  _writeTwoPixelImageData(
    bits,
    firstRed: first.red,
    firstGreen: first.green,
    firstBlue: first.blue,
    firstAlpha: first.alpha,
    secondRed: (second.red - first.red) & 0xff,
    secondGreen: (second.green - first.green) & 0xff,
    secondBlue: (second.blue - first.blue) & 0xff,
    secondAlpha: (second.alpha - first.alpha) & 0xff,
    writeMetaPrefix: false,
  );
  bits.write(0, 1);
  _writeSolidImageData(
    bits,
    red: 0,
    green: 0x0a,
    blue: 0,
    alpha: 255,
    writeMetaPrefix: true,
  );
  return _webpContainer(Uint8List.fromList(<int>[0x2f, ...bits.finish()]));
}

/// Builds a VP8L WebP with duplicate transform markers.
Uint8List duplicateTransformVp8lWebp() {
  final bits = _BitWriter()
    ..write(0, 14)
    ..write(0, 14)
    ..write(0, 1)
    ..write(0, 3)
    ..write(1, 1)
    ..write(2, 2)
    ..write(1, 1)
    ..write(2, 2);
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

void _writeTwoPixelImageData(
  _BitWriter bits, {
  required int firstRed,
  required int firstGreen,
  required int firstBlue,
  required int firstAlpha,
  required int secondRed,
  required int secondGreen,
  required int secondBlue,
  required int secondAlpha,
  required bool writeMetaPrefix,
}) {
  bits.write(0, 1);
  if (writeMetaPrefix) {
    bits.write(0, 1);
  }
  _writeTwoSymbolCode(bits, firstGreen, secondGreen);
  _writeTwoSymbolCode(bits, firstRed, secondRed);
  _writeTwoSymbolCode(bits, firstBlue, secondBlue);
  _writeTwoSymbolCode(bits, firstAlpha, secondAlpha);
  _writeSingleSymbolCode(bits, 0);
  bits
    ..write(0, 1)
    ..write(0, 1)
    ..write(0, 1)
    ..write(0, 1)
    ..write(1, 1)
    ..write(1, 1)
    ..write(1, 1)
    ..write(1, 1);
}

int _colorTransformDelta(int transform, int channel) {
  return (_fixtureSigned8(transform) * _fixtureSigned8(channel)) >> 5;
}

int _fixtureSigned8(int value) => value < 128 ? value : value - 256;
