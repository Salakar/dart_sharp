part of 'webp_lossless.dart';

final class _BitReader {
  _BitReader(this.bytes, {required this.byteOffset});

  final Uint8List bytes;
  int byteOffset;
  var bitOffset = 0;

  int readBits(int count) {
    var value = 0;
    for (var i = 0; i < count; i += 1) {
      if (byteOffset >= bytes.length) {
        throw const InvalidImageException('Truncated VP8L bitstream.');
      }
      value |= ((bytes[byteOffset] >> bitOffset) & 1) << i;
      bitOffset += 1;
      if (bitOffset == 8) {
        bitOffset = 0;
        byteOffset += 1;
      }
    }
    return value;
  }
}
