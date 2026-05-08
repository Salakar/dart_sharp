import 'dart:typed_data';

import '../api/exceptions.dart';
import '../source/raw_pixels.dart';
import 'binary_io.dart';
import 'webp_vp8_bool.dart';

part 'webp_vp8_prediction.dart';
part 'webp_vp8_quant.dart';
part 'webp_vp8_residual.dart';

const _kfYModeTree = <int>[-4, 2, 4, 6, 0, -1, -2, -3];
const _kfYModeProb = <int>[145, 156, 163, 128];
const _kfUvModeTree = <int>[0, 2, -1, 4, -2, -3];
const _kfUvModeProb = <int>[142, 114, 183];
const _segmentTree = <int>[2, 4, 0, -1, -2, -3];
const _bModeTree = <int>[
  0,
  2,
  -1,
  4,
  -2,
  6,
  8,
  12,
  -3,
  10,
  -5,
  -6,
  -4,
  14,
  -7,
  16,
  -8,
  -9,
];
const _kfBModeProb = <List<List<int>>>[
  [
    [231, 120, 48, 89, 115, 113, 120, 152, 112],
    [152, 179, 64, 126, 170, 118, 46, 70, 95],
    [175, 69, 143, 80, 85, 82, 72, 155, 103],
    [56, 58, 10, 171, 218, 189, 17, 13, 152],
    [144, 71, 10, 38, 171, 213, 144, 34, 26],
    [114, 26, 17, 163, 44, 195, 21, 10, 173],
    [121, 24, 80, 195, 26, 62, 44, 64, 85],
    [170, 46, 55, 19, 136, 160, 33, 206, 71],
    [63, 20, 8, 114, 114, 208, 12, 9, 226],
    [81, 40, 11, 96, 182, 84, 29, 16, 36],
  ],
  [
    [134, 183, 89, 137, 98, 101, 106, 165, 148],
    [72, 187, 100, 130, 157, 111, 32, 75, 80],
    [66, 102, 167, 99, 74, 62, 40, 234, 128],
    [41, 53, 9, 178, 241, 141, 26, 8, 107],
    [104, 79, 12, 27, 217, 255, 87, 17, 7],
    [74, 43, 26, 146, 73, 166, 49, 23, 157],
    [65, 38, 105, 160, 51, 52, 31, 115, 128],
    [87, 68, 71, 44, 114, 51, 15, 186, 23],
    [47, 41, 14, 110, 182, 183, 21, 17, 194],
    [66, 45, 25, 102, 197, 189, 23, 18, 22],
  ],
  [
    [88, 88, 147, 150, 42, 46, 45, 196, 205],
    [43, 97, 183, 117, 85, 38, 35, 179, 61],
    [39, 53, 200, 87, 26, 21, 43, 232, 171],
    [56, 34, 51, 104, 114, 102, 29, 93, 77],
    [107, 54, 32, 26, 51, 1, 81, 43, 31],
    [39, 28, 85, 171, 58, 165, 90, 98, 64],
    [34, 22, 116, 206, 23, 34, 43, 166, 73],
    [68, 25, 106, 22, 64, 171, 36, 225, 114],
    [34, 19, 21, 102, 132, 188, 16, 76, 124],
    [62, 18, 78, 95, 85, 57, 50, 48, 51],
  ],
  [
    [193, 101, 35, 159, 215, 111, 89, 46, 111],
    [60, 148, 31, 172, 219, 228, 21, 18, 111],
    [112, 113, 77, 85, 179, 255, 38, 120, 114],
    [40, 42, 1, 196, 245, 209, 10, 25, 109],
    [100, 80, 8, 43, 154, 1, 51, 26, 71],
    [88, 43, 29, 140, 166, 213, 37, 43, 154],
    [61, 63, 30, 155, 67, 45, 68, 1, 209],
    [142, 78, 78, 16, 255, 128, 34, 197, 171],
    [41, 40, 5, 102, 211, 183, 4, 1, 221],
    [51, 50, 17, 168, 209, 192, 23, 25, 82],
  ],
  [
    [125, 98, 42, 88, 104, 85, 117, 175, 82],
    [95, 84, 53, 89, 128, 100, 113, 101, 45],
    [75, 79, 123, 47, 51, 128, 81, 171, 1],
    [57, 17, 5, 71, 102, 57, 53, 41, 49],
    [115, 21, 2, 10, 102, 255, 166, 23, 6],
    [38, 33, 13, 121, 57, 73, 26, 1, 85],
    [41, 10, 67, 138, 77, 110, 90, 47, 114],
    [101, 29, 16, 10, 85, 128, 101, 196, 26],
    [57, 18, 10, 102, 102, 213, 34, 20, 43],
    [117, 20, 15, 36, 163, 128, 68, 1, 26],
  ],
  [
    [138, 31, 36, 171, 27, 166, 38, 44, 229],
    [67, 87, 58, 169, 82, 115, 26, 59, 179],
    [63, 59, 90, 180, 59, 166, 93, 73, 154],
    [40, 40, 21, 116, 143, 209, 34, 39, 175],
    [57, 46, 22, 24, 128, 1, 54, 17, 37],
    [47, 15, 16, 183, 34, 223, 49, 45, 183],
    [46, 17, 33, 183, 6, 98, 15, 32, 183],
    [65, 32, 73, 115, 28, 128, 23, 128, 205],
    [40, 3, 9, 115, 51, 192, 18, 6, 223],
    [87, 37, 9, 115, 59, 77, 64, 21, 47],
  ],
  [
    [104, 55, 44, 218, 9, 54, 53, 130, 226],
    [64, 90, 70, 205, 40, 41, 23, 26, 57],
    [54, 57, 112, 184, 5, 41, 38, 166, 213],
    [30, 34, 26, 133, 152, 116, 10, 32, 134],
    [75, 32, 12, 51, 192, 255, 160, 43, 51],
    [39, 19, 53, 221, 26, 114, 32, 73, 255],
    [31, 9, 65, 234, 2, 15, 1, 118, 73],
    [88, 31, 35, 67, 102, 85, 55, 186, 85],
    [56, 21, 23, 111, 59, 205, 45, 37, 192],
    [55, 38, 70, 124, 73, 102, 1, 34, 98],
  ],
  [
    [102, 61, 71, 37, 34, 53, 31, 243, 192],
    [69, 60, 71, 38, 73, 119, 28, 222, 37],
    [68, 45, 128, 34, 1, 47, 11, 245, 171],
    [62, 17, 19, 70, 146, 85, 55, 62, 70],
    [75, 15, 9, 9, 64, 255, 184, 119, 16],
    [37, 43, 37, 154, 100, 163, 85, 160, 1],
    [63, 9, 92, 136, 28, 64, 32, 201, 85],
    [86, 6, 28, 5, 64, 255, 25, 248, 1],
    [56, 8, 17, 132, 137, 255, 55, 116, 128],
    [58, 15, 20, 82, 135, 57, 26, 121, 40],
  ],
  [
    [164, 50, 31, 137, 154, 133, 25, 35, 218],
    [51, 103, 44, 131, 131, 123, 31, 6, 158],
    [86, 40, 64, 135, 148, 224, 45, 183, 128],
    [22, 26, 17, 131, 240, 154, 14, 1, 209],
    [83, 12, 13, 54, 192, 255, 68, 47, 28],
    [45, 16, 21, 91, 64, 222, 7, 1, 197],
    [56, 21, 39, 155, 60, 138, 23, 102, 213],
    [85, 26, 85, 85, 128, 128, 32, 146, 171],
    [18, 11, 7, 63, 144, 171, 4, 4, 246],
    [35, 27, 10, 146, 174, 171, 12, 26, 128],
  ],
  [
    [190, 80, 35, 99, 180, 80, 126, 54, 45],
    [85, 126, 47, 87, 176, 51, 41, 20, 32],
    [101, 75, 128, 139, 118, 146, 116, 128, 85],
    [56, 41, 15, 176, 236, 85, 37, 9, 62],
    [146, 36, 19, 30, 171, 255, 97, 27, 20],
    [71, 30, 17, 119, 118, 255, 17, 18, 138],
    [101, 38, 60, 138, 55, 70, 43, 26, 142],
    [138, 45, 61, 62, 219, 1, 81, 188, 64],
    [32, 41, 20, 117, 151, 142, 20, 21, 163],
    [112, 19, 12, 61, 195, 128, 48, 4, 24],
  ],
];
const _coefficientUpdateProbCodes =
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff'
    '\u00ff\u00b0\u00f6\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00df\u00f1\u00fc\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00f9\u00fd\u00fd\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff'
    '\u00ff\u00ff\u00ff\u00f4\u00fc\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ea\u00fe\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fd\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00f6\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ef\u00fd\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fe\u00ff\u00fe\u00ff\u00ff\u00ff\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00f8\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fb\u00ff\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fd\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fb\u00fe\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fe\u00ff\u00fe\u00ff\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fe\u00fd\u00ff\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fa\u00ff\u00fe\u00ff\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fe\u00ff\u00ff\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00d9\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00e1\u00fc\u00f1\u00fd\u00ff\u00ff\u00fe\u00ff\u00ff\u00ff\u00ff\u00ea\u00fa'
    '\u00f1\u00fa\u00fd\u00ff\u00fd\u00fe\u00ff\u00ff\u00ff\u00ff\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00df\u00fe\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ee'
    '\u00fd\u00fe\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00f8\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00f9\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fd\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00f7\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fd\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fc\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fe\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fd\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fe\u00fd\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fa\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ba\u00fb\u00fa\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ea\u00fb\u00f4\u00fe\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fb\u00fb\u00f3\u00fd\u00fe\u00ff\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00fd\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ec\u00fd\u00fe\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fb\u00fd\u00fd\u00fe\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fe\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fe\u00fe\u00fe'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fe\u00fe'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fe'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00f8\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff'
    '\u00ff\u00ff\u00ff\u00fa\u00fe\u00fc\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00f8\u00fe\u00f9\u00fd\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fd\u00fd\u00ff\u00ff\u00ff\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00f6\u00fd\u00fd\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fc\u00fe\u00fb\u00fe\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fe\u00fc\u00ff\u00ff\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00f8\u00fe\u00fd\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fd\u00ff\u00fe\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fb\u00fe\u00ff\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00f5\u00fb\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fd\u00fd\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fb\u00fd\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fc\u00fd\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fc\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00f9\u00ff\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff'
    '\u00fd\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fa\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff'
    '\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00fe\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff\u00ff';

/// Decodes a simple lossy VP8 WebP image to RGBA pixels.
RawPixels decodeWebpVp8(Uint8List bytes) {
  return decodeWebpVp8Chunk(_findVp8Chunk(bytes));
}

/// Decodes a raw VP8 chunk payload to RGBA pixels.
RawPixels decodeWebpVp8Chunk(Uint8List chunk) {
  final header = _readFrameHeader(chunk);
  final firstEnd = 10 + header.firstPartSize;
  final bits = Vp8BoolDecoder(chunk.sublist(10, firstEnd));
  final frame = _readSupportedFrameHeader(bits);
  final mbNoSkipCoeff = bits.readBit() == 1;
  final probSkipFalse = mbNoSkipCoeff ? bits.readLiteral(8) : 0;
  final coeffPartitions = _readCoeffPartitions(
    chunk,
    firstEnd,
    frame.tokenPartitionCount,
  );
  final planes = _Vp8Planes(header.width, header.height);
  final contexts = _Vp8TokenContexts(planes.mbCols);
  final bModeContexts = _Vp8BModeContexts(planes.mbCols);
  for (var mbY = 0; mbY < planes.mbRows; mbY += 1) {
    contexts.resetLeft();
    bModeContexts.resetLeft();
    final coeffs = coeffPartitions[mbY & (coeffPartitions.length - 1)];
    for (var mbX = 0; mbX < planes.mbCols; mbX += 1) {
      final segmentId = frame.readSegmentId(bits);
      final skipCoeff = mbNoSkipCoeff && bits.readBool(probSkipFalse) == 1;
      final yMode = bits.readTree(_kfYModeTree, _kfYModeProb);
      final bModes = yMode == 4
          ? bModeContexts.readModes(bits, mbX)
          : bModeContexts.setMacroblockMode(mbX, _bModeForYMode(yMode));
      final uvMode = bits.readTree(_kfUvModeTree, _kfUvModeProb);
      planes.predictChroma(mbX, mbY, uvMode);
      if (yMode == 4) {
        if (!skipCoeff) {
          _readBPredResidual(
            coeffs,
            planes,
            contexts,
            mbX,
            mbY,
            frame,
            segmentId,
            bModes,
          );
        } else {
          planes.predictBPredMacroblock(mbX, mbY, bModes);
          contexts.clearMacroblock(mbX);
        }
      } else if (!skipCoeff) {
        planes.predictLumaMacroblock(mbX, mbY, yMode);
        _readResidual(coeffs, planes, contexts, mbX, mbY, frame, segmentId);
      } else {
        planes.predictLumaMacroblock(mbX, mbY, yMode);
        contexts.clearMacroblock(mbX);
      }
    }
  }
  return RawPixels(
    bytes: planes.composeRgba(),
    width: header.width,
    height: header.height,
    channels: ChannelCount.four,
  );
}

_Vp8Header _readFrameHeader(Uint8List chunk) {
  if (chunk.length < 10) {
    throw const InvalidImageException('Truncated VP8 frame header.');
  }
  final tag = chunk[0] | (chunk[1] << 8) | (chunk[2] << 16);
  if ((tag & 1) != 0) {
    throw const UnsupportedCodecException(
      'Only VP8 key frames are supported for WebP still images.',
    );
  }
  if (((tag >> 4) & 1) == 0) {
    throw const InvalidImageException('VP8 key frame is not displayable.');
  }
  final firstPartSize = (tag >> 5) & 0x7ffff;
  if (chunk[3] != 0x9d ||
      chunk[4] != 0x01 ||
      chunk[5] != 0x2a ||
      10 + firstPartSize > chunk.length) {
    throw const InvalidImageException('Invalid VP8 key-frame header.');
  }
  final width = readUint16Le(chunk, 6) & 0x3fff;
  final height = readUint16Le(chunk, 8) & 0x3fff;
  if (width == 0 || height == 0) {
    throw const InvalidImageException('Invalid VP8 dimensions.');
  }
  return _Vp8Header(width: width, height: height, firstPartSize: firstPartSize);
}

_Vp8FrameHeader _readSupportedFrameHeader(Vp8BoolDecoder bits) {
  final colorSpace = bits.readBit();
  bits.readBit();
  if (colorSpace != 0) {
    throw const UnsupportedCodecException('Unsupported VP8 color space.');
  }
  final segmentation = _Vp8Segmentation.read(bits);
  bits.readBit();
  final loopFilterLevel = bits.readLiteral(6);
  bits.readLiteral(3);
  if (bits.readBit() == 1) {
    throw const UnsupportedCodecException(
      'VP8 loop-filter adjustments are not implemented yet.',
    );
  }
  if (loopFilterLevel != 0) {
    throw const UnsupportedCodecException(
      'VP8 loop filtering is not implemented yet.',
    );
  }
  if (segmentation.hasLoopFilterUpdates) {
    throw const UnsupportedCodecException(
      'VP8 segmentation loop-filter updates are not implemented yet.',
    );
  }
  final tokenPartitionCount = 1 << bits.readLiteral(2);
  final qIndex = bits.readLiteral(7);
  final yDcDelta = _readOptionalSigned(bits, 4);
  final y2DcDelta = _readOptionalSigned(bits, 4);
  final y2AcDelta = _readOptionalSigned(bits, 4);
  final uvDcDelta = _readOptionalSigned(bits, 4);
  final uvAcDelta = _readOptionalSigned(bits, 4);
  bits.readBit();
  final yAcProbs = _Vp8LumaAcProbs.defaults();
  final yProbs = _Vp8LumaProbs.defaults();
  final y2Probs = _Vp8Y2Probs.defaults();
  final uvProbs = _Vp8ChromaProbs.defaults();
  for (var plane = 0; plane < 4; plane += 1) {
    for (var band = 0; band < 8; band += 1) {
      for (var context = 0; context < 3; context += 1) {
        for (var node = 0; node < 11; node += 1) {
          if (bits.readBool(
                _coefficientUpdateProbability(plane, band, context, node),
              ) ==
              1) {
            final probability = bits.readLiteral(8);
            if (plane == 0) {
              yAcProbs[band][context][node] = probability;
            }
            if (plane == 1) {
              y2Probs[band][context][node] = probability;
            }
            if (plane == 2) {
              uvProbs[band][context][node] = probability;
            }
            if (plane == 3) {
              yProbs[band][context][node] = probability;
            }
          }
        }
      }
    }
  }
  return _Vp8FrameHeader(
    baseQuantIndex: qIndex,
    yDcDelta: yDcDelta,
    y2DcDelta: y2DcDelta,
    y2AcDelta: y2AcDelta,
    uvDcDelta: uvDcDelta,
    uvAcDelta: uvAcDelta,
    segmentation: segmentation,
    tokenPartitionCount: tokenPartitionCount,
    yAcProbs: yAcProbs,
    yProbs: yProbs,
    y2Probs: y2Probs,
    uvProbs: uvProbs,
  );
}

List<Vp8BoolDecoder> _readCoeffPartitions(
  Uint8List chunk,
  int offset,
  int count,
) {
  if (count == 1) {
    return <Vp8BoolDecoder>[Vp8BoolDecoder(chunk.sublist(offset))];
  }
  final tableEnd = offset + (count - 1) * 3;
  if (tableEnd > chunk.length) {
    throw const InvalidImageException('Truncated VP8 coefficient partitions.');
  }
  final partitions = <Vp8BoolDecoder>[];
  var partitionStart = tableEnd;
  for (var i = 0; i < count - 1; i += 1) {
    final sizeOffset = offset + i * 3;
    final size =
        chunk[sizeOffset] |
        (chunk[sizeOffset + 1] << 8) |
        (chunk[sizeOffset + 2] << 16);
    final partitionEnd = partitionStart + size;
    if (partitionEnd > chunk.length) {
      throw const InvalidImageException('Truncated VP8 coefficient partition.');
    }
    partitions.add(Vp8BoolDecoder(chunk.sublist(partitionStart, partitionEnd)));
    partitionStart = partitionEnd;
  }
  partitions.add(Vp8BoolDecoder(chunk.sublist(partitionStart)));
  return partitions;
}

int _readOptionalSigned(Vp8BoolDecoder bits, int magnitudeBits) {
  if (bits.readBit() == 1) {
    final value = bits.readLiteral(magnitudeBits);
    return bits.readBit() == 1 ? -value : value;
  }
  return 0;
}

int _coefficientUpdateProbability(int plane, int band, int context, int node) {
  return _coefficientUpdateProbCodes.codeUnitAt(
    (((plane * 8 + band) * 3 + context) * 11) + node,
  );
}

Uint8List _findVp8Chunk(Uint8List bytes) {
  if (bytes.length < 20 ||
      String.fromCharCodes(bytes.sublist(0, 4)) != 'RIFF' ||
      String.fromCharCodes(bytes.sublist(8, 12)) != 'WEBP') {
    throw const InvalidImageException('Invalid WebP signature.');
  }
  var offset = 12;
  while (offset + 8 <= bytes.length) {
    final type = String.fromCharCodes(bytes.sublist(offset, offset + 4));
    final length = readUint32Le(bytes, offset + 4);
    final start = offset + 8;
    final end = start + length;
    if (end > bytes.length) {
      throw const InvalidImageException('Truncated WebP chunk.');
    }
    if (type == 'VP8 ') {
      return bytes.sublist(start, end);
    }
    offset = end + (length.isOdd ? 1 : 0);
  }
  throw const UnsupportedCodecException('WebP has no VP8 chunk.');
}

final class _Vp8Header {
  const _Vp8Header({
    required this.width,
    required this.height,
    required this.firstPartSize,
  });

  final int width;
  final int height;
  final int firstPartSize;
}

final class _Vp8FrameHeader {
  const _Vp8FrameHeader({
    required this.baseQuantIndex,
    required this.yDcDelta,
    required this.y2DcDelta,
    required this.y2AcDelta,
    required this.uvDcDelta,
    required this.uvAcDelta,
    required this.segmentation,
    required this.tokenPartitionCount,
    required this.yAcProbs,
    required this.yProbs,
    required this.y2Probs,
    required this.uvProbs,
  });

  final int baseQuantIndex;
  final int yDcDelta;
  final int y2DcDelta;
  final int y2AcDelta;
  final int uvDcDelta;
  final int uvAcDelta;
  final _Vp8Segmentation segmentation;
  final int tokenPartitionCount;
  final _Vp8LumaAcProbs yAcProbs;
  final _Vp8LumaProbs yProbs;
  final _Vp8Y2Probs y2Probs;
  final _Vp8ChromaProbs uvProbs;

  int readSegmentId(Vp8BoolDecoder bits) => segmentation.readSegmentId(bits);

  int yAcQuantIndex(int segmentId) {
    return segmentation.quantIndex(baseQuantIndex, segmentId);
  }

  int yDcQuantIndex(int segmentId) => yAcQuantIndex(segmentId) + yDcDelta;

  int y2DcQuantIndex(int segmentId) => yAcQuantIndex(segmentId) + y2DcDelta;

  int y2AcQuantIndex(int segmentId) => yAcQuantIndex(segmentId) + y2AcDelta;

  int uvDcQuantIndex(int segmentId) => yAcQuantIndex(segmentId) + uvDcDelta;

  int uvAcQuantIndex(int segmentId) => yAcQuantIndex(segmentId) + uvAcDelta;
}

int _bModeForYMode(int yMode) {
  return switch (yMode) {
    0 => 0,
    1 => 2,
    2 => 3,
    3 => 1,
    _ => throw const InvalidImageException('Invalid VP8 luma mode.'),
  };
}

final class _Vp8BModeContexts {
  _Vp8BModeContexts(int mbCols) : _above = List<int>.filled(mbCols * 4, 0);

  final List<int> _above;
  final _left = List<int>.filled(4, 0);

  void resetLeft() {
    _left.fillRange(0, _left.length, 0);
  }

  List<int> readModes(Vp8BoolDecoder bits, int mbX) {
    final modes = List<int>.filled(16, 0);
    for (var block = 0; block < 16; block += 1) {
      final above = block < 4 ? _above[mbX * 4 + block] : modes[block - 4];
      final left = (block & 3) == 0 ? _left[block >> 2] : modes[block - 1];
      modes[block] = bits.readTree(_bModeTree, _kfBModeProb[above][left]);
    }
    _storeMacroblockModes(mbX, modes);
    return modes;
  }

  List<int> setMacroblockMode(int mbX, int mode) {
    final modes = List<int>.filled(16, mode);
    _storeMacroblockModes(mbX, modes);
    return modes;
  }

  void _storeMacroblockModes(int mbX, List<int> modes) {
    for (var i = 0; i < 4; i += 1) {
      _above[mbX * 4 + i] = modes[12 + i];
      _left[i] = modes[i * 4 + 3];
    }
  }
}

final class _Vp8Segmentation {
  const _Vp8Segmentation._({
    required this.enabled,
    required this.updateMap,
    required this.absolute,
    required this.quantizerValues,
    required this.loopFilterValues,
    required this.probabilities,
  });

  factory _Vp8Segmentation.read(Vp8BoolDecoder bits) {
    if (bits.readBit() == 0) {
      return _Vp8Segmentation.disabled();
    }
    final updateMap = bits.readBit() == 1;
    final updateFeatureData = bits.readBit() == 1;
    var absolute = false;
    final quantizerValues = List<int>.filled(4, 0);
    final loopFilterValues = List<int>.filled(4, 0);
    if (updateFeatureData) {
      absolute = bits.readBit() == 1;
      for (var i = 0; i < 4; i += 1) {
        quantizerValues[i] = _readOptionalSigned(bits, 7);
      }
      for (var i = 0; i < 4; i += 1) {
        loopFilterValues[i] = _readOptionalSigned(bits, 6);
      }
    }
    final probabilities = List<int>.filled(3, 255);
    if (updateMap) {
      for (var i = 0; i < probabilities.length; i += 1) {
        if (bits.readBit() == 1) {
          probabilities[i] = bits.readLiteral(8);
        }
      }
    }
    return _Vp8Segmentation._(
      enabled: true,
      updateMap: updateMap,
      absolute: absolute,
      quantizerValues: quantizerValues,
      loopFilterValues: loopFilterValues,
      probabilities: probabilities,
    );
  }

  factory _Vp8Segmentation.disabled() {
    return _Vp8Segmentation._(
      enabled: false,
      updateMap: false,
      absolute: false,
      quantizerValues: List<int>.filled(4, 0),
      loopFilterValues: List<int>.filled(4, 0),
      probabilities: List<int>.filled(3, 255),
    );
  }

  final bool enabled;
  final bool updateMap;
  final bool absolute;
  final List<int> quantizerValues;
  final List<int> loopFilterValues;
  final List<int> probabilities;

  bool get hasLoopFilterUpdates {
    return loopFilterValues.any((value) => value != 0);
  }

  int readSegmentId(Vp8BoolDecoder bits) {
    if (!enabled || !updateMap) {
      return 0;
    }
    return bits.readTree(_segmentTree, probabilities);
  }

  int quantIndex(int baseQuantIndex, int segmentId) {
    if (!enabled) {
      return baseQuantIndex;
    }
    final value = quantizerValues[segmentId];
    return absolute ? value : baseQuantIndex + value;
  }
}
