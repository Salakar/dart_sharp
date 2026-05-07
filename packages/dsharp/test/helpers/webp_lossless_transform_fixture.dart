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
