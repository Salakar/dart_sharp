part of 'webp_lossless_fixture.dart';

/// Builds a VP8L WebP that carries a single meta-prefix code group.
Uint8List metaPrefixVp8lWebp({
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
    ..write(0, 1)
    ..write(0, 1)
    ..write(1, 1)
    ..write(0, 3);
  _writeSolidImageData(
    bits,
    red: 0,
    green: 0,
    blue: 0,
    alpha: 255,
    writeMetaPrefix: false,
  );
  _writeSingleSymbolCode(bits, green);
  _writeSingleSymbolCode(bits, red);
  _writeSingleSymbolCode(bits, blue);
  _writeSingleSymbolCode(bits, alpha);
  _writeSingleSymbolCode(bits, 0);
  return _webpContainer(Uint8List.fromList(<int>[0x2f, ...bits.finish()]));
}

/// Builds a VP8L WebP with two meta-prefix code groups.
Uint8List twoGroupMetaPrefixVp8lWebp() {
  final bits = _BitWriter()
    ..write(4, 14)
    ..write(0, 14)
    ..write(0, 1)
    ..write(0, 3)
    ..write(0, 1)
    ..write(0, 1)
    ..write(1, 1)
    ..write(0, 3);
  _writeTwoPixelImageData(
    bits,
    firstRed: 0,
    firstGreen: 0,
    firstBlue: 0,
    firstAlpha: 255,
    secondRed: 0,
    secondGreen: 1,
    secondBlue: 0,
    secondAlpha: 255,
    writeMetaPrefix: false,
  );
  _writeCodeGroup(bits, red: 10, green: 20, blue: 30, alpha: 255);
  _writeCodeGroup(bits, red: 200, green: 150, blue: 100, alpha: 255);
  return _webpContainer(Uint8List.fromList(<int>[0x2f, ...bits.finish()]));
}

void _writeCodeGroup(
  _BitWriter bits, {
  required int red,
  required int green,
  required int blue,
  required int alpha,
}) {
  _writeSingleSymbolCode(bits, green);
  _writeSingleSymbolCode(bits, red);
  _writeSingleSymbolCode(bits, blue);
  _writeSingleSymbolCode(bits, alpha);
  _writeSingleSymbolCode(bits, 0);
}
