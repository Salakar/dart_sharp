part of 'encoded_metadata.dart';

bool _jpegSofMarker(int marker) {
  return marker >= 0xc0 &&
      marker <= 0xcf &&
      marker != 0xc4 &&
      marker != 0xc8 &&
      marker != 0xcc;
}

_JpegFrameInfo _jpegFrameInfo(int marker, Uint8List data) {
  if (data.length < 6) {
    throw const InvalidImageException('Truncated JPEG frame header.');
  }
  return _JpegFrameInfo(
    width: readUint16Be(data, 3),
    height: readUint16Be(data, 1),
    components: data[5],
    precision: data[0],
    progressive: marker == 0xc2,
    chromaSubsampling: _jpegChromaSubsampling(data),
  );
}

({double density, String unit})? _jpegJfifResolution(Uint8List data) {
  if (data.length < 12 || !_startsWithAscii(data, 'JFIF')) {
    return null;
  }
  final units = data[7];
  final xDensity = readUint16Be(data, 8);
  if (xDensity == 0) {
    return null;
  }
  return switch (units) {
    1 => (density: xDensity.toDouble(), unit: 'inch'),
    2 => (density: xDensity * 2.54, unit: 'cm'),
    _ => null,
  };
}

String? _jpegColorSpace(int components) {
  return switch (components) {
    1 => 'b-w',
    3 => 'srgb',
    4 => 'cmyk',
    _ => null,
  };
}

String? _jpegChromaSubsampling(Uint8List data) {
  final components = data[5];
  if (components != 3 || data.length < 6 + components * 3) {
    return null;
  }
  final ySampling = data[7];
  if (data[10] != 0x11 || data[13] != 0x11) {
    return null;
  }
  final h = ySampling >> 4;
  final v = ySampling & 0x0f;
  if (h == 1 && v == 1) {
    return '4:4:4';
  }
  if (h == 2 && v == 1) {
    return '4:2:2';
  }
  if (h == 2 && v == 2) {
    return '4:2:0';
  }
  return null;
}

final class _JpegFrameInfo {
  const _JpegFrameInfo({
    required this.width,
    required this.height,
    required this.components,
    required this.precision,
    required this.progressive,
    required this.chromaSubsampling,
  });

  final int width;
  final int height;
  final int components;
  final int precision;
  final bool progressive;
  final String? chromaSubsampling;
}
