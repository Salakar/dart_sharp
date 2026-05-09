part of 'encoded_metadata.dart';

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
