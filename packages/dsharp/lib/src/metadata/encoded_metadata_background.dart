part of 'encoded_metadata.dart';

RgbaColor? _pngBackgroundColor({
  required int colorType,
  required int bitDepth,
  required Uint8List? background,
  required Uint8List? palette,
}) {
  final data = background;
  if (data == null) {
    return null;
  }
  return switch (colorType) {
    0 || 4 when data.length == 2 => _grayBackground(data, bitDepth),
    2 || 6 when data.length == 6 => RgbaColor.rgb(
      _pngSampleTo8(readUint16Be(data, 0), bitDepth),
      _pngSampleTo8(readUint16Be(data, 2), bitDepth),
      _pngSampleTo8(readUint16Be(data, 4), bitDepth),
    ),
    3 when data.length == 1 => _paletteBackground(palette, data[0]),
    _ => null,
  };
}

RgbaColor _grayBackground(Uint8List data, int bitDepth) {
  final gray = _pngSampleTo8(readUint16Be(data, 0), bitDepth);
  return RgbaColor.rgb(gray, gray, gray);
}

RgbaColor? _paletteBackground(Uint8List? palette, int index) {
  final table = palette;
  final offset = index * 3;
  if (table == null || offset + 2 >= table.length) {
    return null;
  }
  return RgbaColor.rgb(table[offset], table[offset + 1], table[offset + 2]);
}

int _pngSampleTo8(int sample, int bitDepth) {
  if (bitDepth == 16) {
    return sample >> 8;
  }
  if (bitDepth == 8) {
    return sample;
  }
  final max = (1 << bitDepth) - 1;
  return ((sample * 255) + (max >> 1)) ~/ max;
}

RgbaColor? _gifBackgroundColor(Uint8List? palette, int backgroundIndex) {
  final table = palette;
  final offset = backgroundIndex * 3;
  if (table == null || offset + 2 >= table.length) {
    return null;
  }
  return RgbaColor.rgb(table[offset], table[offset + 1], table[offset + 2]);
}
