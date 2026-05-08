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
  for (var mbY = 0; mbY < planes.mbRows; mbY += 1) {
    contexts.resetLeft();
    final coeffs = coeffPartitions[mbY & (coeffPartitions.length - 1)];
    for (var mbX = 0; mbX < planes.mbCols; mbX += 1) {
      final segmentId = frame.readSegmentId(bits);
      final skipCoeff = mbNoSkipCoeff && bits.readBool(probSkipFalse) == 1;
      final yMode = bits.readTree(_kfYModeTree, _kfYModeProb);
      if (yMode == 4) {
        throw const UnsupportedCodecException(
          'VP8 B_PRED luma prediction is not implemented yet.',
        );
      }
      final uvMode = bits.readTree(_kfUvModeTree, _kfUvModeProb);
      planes.predictMacroblock(mbX, mbY, yMode, uvMode);
      if (!skipCoeff) {
        _readResidual(coeffs, planes, contexts, mbX, mbY, frame, segmentId);
      } else {
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
  _readOptionalSigned(bits, 4);
  final y2DcDelta = _readOptionalSigned(bits, 4);
  final y2AcDelta = _readOptionalSigned(bits, 4);
  final uvDcDelta = _readOptionalSigned(bits, 4);
  final uvAcDelta = _readOptionalSigned(bits, 4);
  bits.readBit();
  final yAcProbs = _Vp8LumaAcProbs.defaults();
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
          }
        }
      }
    }
  }
  return _Vp8FrameHeader(
    baseQuantIndex: qIndex,
    y2DcDelta: y2DcDelta,
    y2AcDelta: y2AcDelta,
    uvDcDelta: uvDcDelta,
    uvAcDelta: uvAcDelta,
    segmentation: segmentation,
    tokenPartitionCount: tokenPartitionCount,
    yAcProbs: yAcProbs,
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
    required this.y2DcDelta,
    required this.y2AcDelta,
    required this.uvDcDelta,
    required this.uvAcDelta,
    required this.segmentation,
    required this.tokenPartitionCount,
    required this.yAcProbs,
    required this.y2Probs,
    required this.uvProbs,
  });

  final int baseQuantIndex;
  final int y2DcDelta;
  final int y2AcDelta;
  final int uvDcDelta;
  final int uvAcDelta;
  final _Vp8Segmentation segmentation;
  final int tokenPartitionCount;
  final _Vp8LumaAcProbs yAcProbs;
  final _Vp8Y2Probs y2Probs;
  final _Vp8ChromaProbs uvProbs;

  int readSegmentId(Vp8BoolDecoder bits) => segmentation.readSegmentId(bits);

  int yAcQuantIndex(int segmentId) {
    return segmentation.quantIndex(baseQuantIndex, segmentId);
  }

  int y2DcQuantIndex(int segmentId) => yAcQuantIndex(segmentId) + y2DcDelta;

  int y2AcQuantIndex(int segmentId) => yAcQuantIndex(segmentId) + y2AcDelta;

  int uvDcQuantIndex(int segmentId) => yAcQuantIndex(segmentId) + uvDcDelta;

  int uvAcQuantIndex(int segmentId) => yAcQuantIndex(segmentId) + uvAcDelta;
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
