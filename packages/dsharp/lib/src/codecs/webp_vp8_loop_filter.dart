part of 'webp_vp8.dart';

final class _Vp8LoopFilter {
  const _Vp8LoopFilter({
    required this.simple,
    required this.level,
    required this.sharpness,
    required this.adjustmentEnabled,
    required this.referenceDeltas,
    required this.modeDeltas,
  });

  factory _Vp8LoopFilter.read(Vp8BoolDecoder bits) {
    final simple = bits.readBit() == 1;
    final level = bits.readLiteral(6);
    final sharpness = bits.readLiteral(3);
    final adjustmentEnabled = bits.readBit() == 1;
    final referenceDeltas = List<int>.filled(4, 0);
    final modeDeltas = List<int>.filled(4, 0);
    if (adjustmentEnabled && bits.readBit() == 1) {
      for (var i = 0; i < referenceDeltas.length; i += 1) {
        referenceDeltas[i] = _readLoopFilterDelta(bits);
      }
      for (var i = 0; i < modeDeltas.length; i += 1) {
        modeDeltas[i] = _readLoopFilterDelta(bits);
      }
    }
    return _Vp8LoopFilter(
      simple: simple,
      level: level,
      sharpness: sharpness,
      adjustmentEnabled: adjustmentEnabled,
      referenceDeltas: referenceDeltas,
      modeDeltas: modeDeltas,
    );
  }

  final bool simple;
  final int level;
  final int sharpness;
  final bool adjustmentEnabled;
  final List<int> referenceDeltas;
  final List<int> modeDeltas;

  int keyFrameLevel(int baseLevel, int yMode) {
    if (!adjustmentEnabled) {
      return baseLevel;
    }
    var adjusted = baseLevel + referenceDeltas[0];
    // Key frames are intra-only; VP8 applies a mode delta only to B_PRED.
    if (yMode == 4) {
      adjusted += modeDeltas[0];
    }
    return _clampLoopFilterLevel(adjusted);
  }
}

int _readLoopFilterDelta(Vp8BoolDecoder bits) {
  if (bits.readBit() == 0) {
    return 0;
  }
  final magnitude = bits.readLiteral(6);
  return bits.readBit() == 1 ? -magnitude : magnitude;
}

final class _Vp8MacroblockInfo {
  const _Vp8MacroblockInfo({
    required this.segmentId,
    required this.yMode,
    required this.hasCoefficients,
  });

  final int segmentId;
  final int yMode;
  final bool hasCoefficients;

  bool get filtersSubblocks => yMode == 4 || hasCoefficients;
}

final class _Vp8FilterParams {
  const _Vp8FilterParams({
    required this.interiorLimit,
    required this.macroblockEdgeLimit,
    required this.subblockEdgeLimit,
    required this.highEdgeVarianceThreshold,
  });

  factory _Vp8FilterParams.keyFrame(int level, int sharpness) {
    var interiorLimit = level;
    if (sharpness > 0) {
      interiorLimit >>= sharpness > 4 ? 2 : 1;
      final maxInterior = 9 - sharpness;
      if (interiorLimit > maxInterior) {
        interiorLimit = maxInterior;
      }
    }
    if (interiorLimit == 0) {
      interiorLimit = 1;
    }
    final hevThreshold = level >= 40 ? 2 : (level >= 15 ? 1 : 0);
    return _Vp8FilterParams(
      interiorLimit: interiorLimit,
      macroblockEdgeLimit: ((level + 2) * 2) + interiorLimit,
      subblockEdgeLimit: (level * 2) + interiorLimit,
      highEdgeVarianceThreshold: hevThreshold,
    );
  }

  final int interiorLimit;
  final int macroblockEdgeLimit;
  final int subblockEdgeLimit;
  final int highEdgeVarianceThreshold;
}

void _applyVp8LoopFilter(
  _Vp8Planes planes,
  _Vp8LoopFilter filter,
  _Vp8Segmentation segmentation,
  List<_Vp8MacroblockInfo> macroblocks,
) {
  if (filter.level == 0) {
    return;
  }
  for (var mbY = 0; mbY < planes.mbRows; mbY += 1) {
    for (var mbX = 0; mbX < planes.mbCols; mbX += 1) {
      final info = macroblocks[mbY * planes.mbCols + mbX];
      final level = filter.keyFrameLevel(
        segmentation.loopFilterLevel(filter.level, info.segmentId),
        info.yMode,
      );
      if (level == 0) {
        continue;
      }
      final params = _Vp8FilterParams.keyFrame(level, filter.sharpness);
      _filterMacroblock(planes, filter.simple, params, mbX, mbY, info);
    }
  }
}

void _filterMacroblock(
  _Vp8Planes planes,
  bool simple,
  _Vp8FilterParams params,
  int mbX,
  int mbY,
  _Vp8MacroblockInfo info,
) {
  final yX = mbX * 16;
  final yY = mbY * 16;
  if (mbX > 0) {
    _filterVerticalEdge(
      planes.y,
      planes.yWidth,
      yX,
      yY,
      16,
      true,
      simple,
      params,
    );
  }
  if (info.filtersSubblocks) {
    for (final offset in const <int>[4, 8, 12]) {
      _filterVerticalEdge(
        planes.y,
        planes.yWidth,
        yX + offset,
        yY,
        16,
        false,
        simple,
        params,
      );
    }
  }
  if (mbY > 0) {
    _filterHorizontalEdge(
      planes.y,
      planes.yWidth,
      yX,
      yY,
      16,
      true,
      simple,
      params,
    );
  }
  if (info.filtersSubblocks) {
    for (final offset in const <int>[4, 8, 12]) {
      _filterHorizontalEdge(
        planes.y,
        planes.yWidth,
        yX,
        yY + offset,
        16,
        false,
        simple,
        params,
      );
    }
  }
  if (!simple) {
    _filterChromaMacroblock(planes, params, mbX, mbY, info);
  }
}

void _filterChromaMacroblock(
  _Vp8Planes planes,
  _Vp8FilterParams params,
  int mbX,
  int mbY,
  _Vp8MacroblockInfo info,
) {
  final uvX = mbX * 8;
  final uvY = mbY * 8;
  if (mbX > 0) {
    _filterVerticalEdge(
      planes.u,
      planes.uvWidth,
      uvX,
      uvY,
      8,
      true,
      false,
      params,
    );
    _filterVerticalEdge(
      planes.v,
      planes.uvWidth,
      uvX,
      uvY,
      8,
      true,
      false,
      params,
    );
  }
  if (info.filtersSubblocks) {
    _filterVerticalEdge(
      planes.u,
      planes.uvWidth,
      uvX + 4,
      uvY,
      8,
      false,
      false,
      params,
    );
    _filterVerticalEdge(
      planes.v,
      planes.uvWidth,
      uvX + 4,
      uvY,
      8,
      false,
      false,
      params,
    );
  }
  if (mbY > 0) {
    _filterHorizontalEdge(
      planes.u,
      planes.uvWidth,
      uvX,
      uvY,
      8,
      true,
      false,
      params,
    );
    _filterHorizontalEdge(
      planes.v,
      planes.uvWidth,
      uvX,
      uvY,
      8,
      true,
      false,
      params,
    );
  }
  if (info.filtersSubblocks) {
    _filterHorizontalEdge(
      planes.u,
      planes.uvWidth,
      uvX,
      uvY + 4,
      8,
      false,
      false,
      params,
    );
    _filterHorizontalEdge(
      planes.v,
      planes.uvWidth,
      uvX,
      uvY + 4,
      8,
      false,
      false,
      params,
    );
  }
}

void _filterVerticalEdge(
  Uint8List plane,
  int stride,
  int x,
  int y,
  int length,
  bool macroblockEdge,
  bool simple,
  _Vp8FilterParams params,
) {
  for (var i = 0; i < length; i += 1) {
    final edge = (y + i) * stride + x;
    _filterSegment(
      plane,
      edge - 4,
      edge - 3,
      edge - 2,
      edge - 1,
      edge,
      edge + 1,
      edge + 2,
      edge + 3,
      macroblockEdge,
      simple,
      params,
    );
  }
}

void _filterHorizontalEdge(
  Uint8List plane,
  int stride,
  int x,
  int y,
  int length,
  bool macroblockEdge,
  bool simple,
  _Vp8FilterParams params,
) {
  for (var i = 0; i < length; i += 1) {
    final edge = y * stride + x + i;
    _filterSegment(
      plane,
      edge - stride * 4,
      edge - stride * 3,
      edge - stride * 2,
      edge - stride,
      edge,
      edge + stride,
      edge + stride * 2,
      edge + stride * 3,
      macroblockEdge,
      simple,
      params,
    );
  }
}

void _filterSegment(
  Uint8List plane,
  int p3Index,
  int p2Index,
  int p1Index,
  int p0Index,
  int q0Index,
  int q1Index,
  int q2Index,
  int q3Index,
  bool macroblockEdge,
  bool simple,
  _Vp8FilterParams params,
) {
  final edgeLimit = macroblockEdge
      ? params.macroblockEdgeLimit
      : params.subblockEdgeLimit;
  if (simple) {
    _simpleFilter(plane, p1Index, p0Index, q0Index, q1Index, edgeLimit);
  } else if (macroblockEdge) {
    _normalMacroblockFilter(
      plane,
      p3Index,
      p2Index,
      p1Index,
      p0Index,
      q0Index,
      q1Index,
      q2Index,
      q3Index,
      params,
    );
  } else {
    _normalSubblockFilter(
      plane,
      p3Index,
      p2Index,
      p1Index,
      p0Index,
      q0Index,
      q1Index,
      q2Index,
      q3Index,
      params,
    );
  }
}

void _simpleFilter(
  Uint8List plane,
  int p1Index,
  int p0Index,
  int q0Index,
  int q1Index,
  int edgeLimit,
) {
  final p1 = plane[p1Index];
  final p0 = plane[p0Index];
  final q0 = plane[q0Index];
  final q1 = plane[q1Index];
  if ((_absInt(p0 - q0) * 2 + (_absInt(p1 - q1) >> 1)) <= edgeLimit) {
    _commonAdjust(plane, true, p1Index, p0Index, q0Index, q1Index);
  }
}

void _normalSubblockFilter(
  Uint8List plane,
  int p3Index,
  int p2Index,
  int p1Index,
  int p0Index,
  int q0Index,
  int q1Index,
  int q2Index,
  int q3Index,
  _Vp8FilterParams params,
) {
  final p3 = _u2s(plane[p3Index]);
  final p2 = _u2s(plane[p2Index]);
  final p1 = _u2s(plane[p1Index]);
  final p0 = _u2s(plane[p0Index]);
  final q0 = _u2s(plane[q0Index]);
  final q1 = _u2s(plane[q1Index]);
  final q2 = _u2s(plane[q2Index]);
  final q3 = _u2s(plane[q3Index]);
  if (!_filterYes(params, false, p3, p2, p1, p0, q0, q1, q2, q3)) {
    return;
  }
  final hasHighVariance = _highEdgeVariance(
    params.highEdgeVarianceThreshold,
    p1,
    p0,
    q0,
    q1,
  );
  final adjustment =
      (_commonAdjust(
            plane,
            hasHighVariance,
            p1Index,
            p0Index,
            q0Index,
            q1Index,
          ) +
          1) >>
      1;
  if (!hasHighVariance) {
    plane[q1Index] = _s2u(q1 - adjustment);
    plane[p1Index] = _s2u(p1 + adjustment);
  }
}

void _normalMacroblockFilter(
  Uint8List plane,
  int p3Index,
  int p2Index,
  int p1Index,
  int p0Index,
  int q0Index,
  int q1Index,
  int q2Index,
  int q3Index,
  _Vp8FilterParams params,
) {
  final p3 = _u2s(plane[p3Index]);
  final p2 = _u2s(plane[p2Index]);
  final p1 = _u2s(plane[p1Index]);
  final p0 = _u2s(plane[p0Index]);
  final q0 = _u2s(plane[q0Index]);
  final q1 = _u2s(plane[q1Index]);
  final q2 = _u2s(plane[q2Index]);
  final q3 = _u2s(plane[q3Index]);
  if (!_filterYes(params, true, p3, p2, p1, p0, q0, q1, q2, q3)) {
    return;
  }
  if (_highEdgeVariance(params.highEdgeVarianceThreshold, p1, p0, q0, q1)) {
    _commonAdjust(plane, true, p1Index, p0Index, q0Index, q1Index);
    return;
  }
  final w = _signedClamp(_signedClamp(p1 - q1) + 3 * (q0 - p0));
  var adjustment = _signedClamp((27 * w + 63) >> 7);
  plane[q0Index] = _s2u(q0 - adjustment);
  plane[p0Index] = _s2u(p0 + adjustment);
  adjustment = _signedClamp((18 * w + 63) >> 7);
  plane[q1Index] = _s2u(q1 - adjustment);
  plane[p1Index] = _s2u(p1 + adjustment);
  adjustment = _signedClamp((9 * w + 63) >> 7);
  plane[q2Index] = _s2u(q2 - adjustment);
  plane[p2Index] = _s2u(p2 + adjustment);
}

bool _filterYes(
  _Vp8FilterParams params,
  bool macroblockEdge,
  int p3,
  int p2,
  int p1,
  int p0,
  int q0,
  int q1,
  int q2,
  int q3,
) {
  final edgeLimit = macroblockEdge
      ? params.macroblockEdgeLimit
      : params.subblockEdgeLimit;
  return (_absInt(p0 - q0) * 2 + (_absInt(p1 - q1) >> 1)) <= edgeLimit &&
      _absInt(p3 - p2) <= params.interiorLimit &&
      _absInt(p2 - p1) <= params.interiorLimit &&
      _absInt(p1 - p0) <= params.interiorLimit &&
      _absInt(q3 - q2) <= params.interiorLimit &&
      _absInt(q2 - q1) <= params.interiorLimit &&
      _absInt(q1 - q0) <= params.interiorLimit;
}

bool _highEdgeVariance(int threshold, int p1, int p0, int q0, int q1) {
  return _absInt(p1 - p0) > threshold || _absInt(q1 - q0) > threshold;
}

int _commonAdjust(
  Uint8List plane,
  bool useOuterTaps,
  int p1Index,
  int p0Index,
  int q0Index,
  int q1Index,
) {
  final p1 = _u2s(plane[p1Index]);
  final p0 = _u2s(plane[p0Index]);
  final q0 = _u2s(plane[q0Index]);
  final q1 = _u2s(plane[q1Index]);
  var adjustment = _signedClamp(
    (useOuterTaps ? _signedClamp(p1 - q1) : 0) + 3 * (q0 - p0),
  );
  final balanced = _signedClamp(adjustment + 3) >> 3;
  adjustment = _signedClamp(adjustment + 4) >> 3;
  plane[q0Index] = _s2u(q0 - adjustment);
  plane[p0Index] = _s2u(p0 + balanced);
  return adjustment;
}

int _clampLoopFilterLevel(int value) {
  if (value < 0) {
    return 0;
  }
  if (value > 63) {
    return 63;
  }
  return value;
}

int _u2s(int value) => value - 128;

int _s2u(int value) => _signedClamp(value) + 128;

int _signedClamp(int value) {
  if (value < -128) {
    return -128;
  }
  if (value > 127) {
    return 127;
  }
  return value;
}

int _absInt(int value) => value < 0 ? -value : value;
