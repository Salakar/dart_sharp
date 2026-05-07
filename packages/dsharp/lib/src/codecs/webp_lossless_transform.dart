part of 'webp_lossless.dart';

abstract interface class _LosslessTransform {
  int get type;

  void apply(Uint8List bytes, int width, int height);

  static _LosslessTransform read(_BitReader reader) {
    final type = reader.readBits(2);
    return switch (type) {
      2 => const _SubtractGreenTransform(),
      _ => throw const UnsupportedCodecException(
        'Only the VP8L subtract-green transform is implemented so far.',
      ),
    };
  }
}

final class _SubtractGreenTransform implements _LosslessTransform {
  const _SubtractGreenTransform();

  @override
  int get type => 2;

  @override
  void apply(Uint8List bytes, int width, int height) {
    final pixels = width * height;
    for (var pixel = 0; pixel < pixels; pixel += 1) {
      final offset = pixel * 4;
      final green = bytes[offset + 1];
      bytes[offset] = (bytes[offset] + green) & 0xff;
      bytes[offset + 2] = (bytes[offset + 2] + green) & 0xff;
    }
  }
}
