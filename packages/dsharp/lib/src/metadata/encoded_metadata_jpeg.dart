part of 'encoded_metadata.dart';

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
