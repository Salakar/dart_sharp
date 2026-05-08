part of 'jpeg_decoder.dart';

void _decodeProgressiveScans(JpegState state) {
  _prepareProgressiveComponents(state);
  for (final scan in state.scans) {
    if (scan.spectralStart == 0 && scan.spectralEnd == 0) {
      if (scan.successiveHigh == 0) {
        _decodeProgressiveDcInitial(state, scan);
      } else {
        _decodeProgressiveDcRefinement(state, scan);
      }
    } else {
      if (scan.components.length != 1) {
        throw const UnsupportedCodecException(
          'Progressive JPEG AC scans must contain one component.',
        );
      }
      if (scan.successiveHigh == 0) {
        _decodeProgressiveAcInitial(state, scan);
      } else {
        _decodeProgressiveAcRefinement(state, scan);
      }
    }
  }
  _writeProgressiveSamples(state);
}

void _prepareProgressiveComponents(JpegState state) {
  final layout = _jpegMcuLayout(state);
  for (final component in state.components) {
    component
      ..width = (state.width * component.h + layout.maxH - 1) ~/ layout.maxH
      ..height = (state.height * component.v + layout.maxV - 1) ~/ layout.maxV
      ..blockCols = layout.mcuCols * component.h
      ..blockRows = layout.mcuRows * component.v
      ..coeffBlocks = List<Int32List>.generate(
        layout.mcuCols * component.h * layout.mcuRows * component.v,
        (_) => Int32List(64),
      );
  }
}

({int maxH, int maxV, int mcuCols, int mcuRows}) _jpegMcuLayout(
  JpegState state,
) {
  final maxH = state.components
      .map((item) => item.h)
      .reduce((a, b) => a > b ? a : b);
  final maxV = state.components
      .map((item) => item.v)
      .reduce((a, b) => a > b ? a : b);
  return (
    maxH: maxH,
    maxV: maxV,
    mcuCols: (state.width + maxH * 8 - 1) ~/ (maxH * 8),
    mcuRows: (state.height + maxV * 8 - 1) ~/ (maxV * 8),
  );
}

void _decodeProgressiveDcInitial(JpegState state, JpegScan scan) {
  for (final component in scan.components) {
    component.predictor = 0;
  }
  _decodeProgressiveBlocks(
    state,
    scan,
    (component, blockX, blockY, reader) {
      final tree = _requiredDcTree(state, component);
      final size = tree.read(reader);
      final diff = jpegExtend(reader.readBits(size), size);
      component.predictor += diff;
      _coeffBlock(component, blockX, blockY)[0] =
          component.predictor << scan.successiveLow;
    },
    onRestart: () {
      for (final component in scan.components) {
        component.predictor = 0;
      }
    },
  );
}

void _decodeProgressiveDcRefinement(JpegState state, JpegScan scan) {
  final bit = 1 << scan.successiveLow;
  _decodeProgressiveBlocks(state, scan, (component, blockX, blockY, reader) {
    if (reader.readBits(1) == 1) {
      _refineCoefficient(_coeffBlock(component, blockX, blockY), 0, bit);
    }
  });
}

void _decodeProgressiveAcInitial(JpegState state, JpegScan scan) {
  var eobRun = 0;
  final bit = 1 << scan.successiveLow;
  _decodeProgressiveBlocks(
    state,
    scan,
    (component, blockX, blockY, reader) {
      final block = _coeffBlock(component, blockX, blockY);
      if (eobRun > 0) {
        eobRun -= 1;
        return;
      }
      final tree = _requiredAcTree(state, component);
      var k = scan.spectralStart;
      while (k <= scan.spectralEnd) {
        final symbol = tree.read(reader);
        final run = symbol >> 4;
        final size = symbol & 0x0f;
        if (size == 0) {
          if (run == 15) {
            k += 16;
            continue;
          }
          eobRun = 1 << run;
          if (run > 0) {
            eobRun += reader.readBits(run);
          }
          eobRun -= 1;
          break;
        }
        k += run;
        if (k <= scan.spectralEnd) {
          block[jpegZigZag[k]] = jpegExtend(reader.readBits(size), size) * bit;
          k += 1;
        }
      }
    },
    onRestart: () {
      eobRun = 0;
    },
  );
}

void _decodeProgressiveAcRefinement(JpegState state, JpegScan scan) {
  var eobRun = 0;
  final bit = 1 << scan.successiveLow;
  _decodeProgressiveBlocks(
    state,
    scan,
    (component, blockX, blockY, reader) {
      final block = _coeffBlock(component, blockX, blockY);
      if (eobRun > 0) {
        _refineAcCoefficients(
          block,
          reader,
          scan.spectralStart,
          scan.spectralEnd,
          bit,
        );
        eobRun -= 1;
        return;
      }
      final tree = _requiredAcTree(state, component);
      var k = scan.spectralStart;
      while (k <= scan.spectralEnd) {
        final symbol = tree.read(reader);
        final run = symbol >> 4;
        final size = symbol & 0x0f;
        if (size == 0) {
          if (run == 15) {
            k = _skipRefinedZeros(block, reader, k, scan.spectralEnd, bit, 16);
            continue;
          }
          eobRun = 1 << run;
          if (run > 0) {
            eobRun += reader.readBits(run);
          }
          _refineAcCoefficients(block, reader, k, scan.spectralEnd, bit);
          eobRun -= 1;
          break;
        }
        if (size != 1) {
          throw const InvalidImageException(
            'Invalid progressive JPEG refinement symbol.',
          );
        }
        final value = jpegExtend(reader.readBits(1), 1) * bit;
        k = _placeRefinedCoefficient(
          block,
          reader,
          k,
          scan.spectralEnd,
          bit,
          run,
          value,
        );
      }
    },
    onRestart: () {
      eobRun = 0;
    },
  );
}

void _decodeProgressiveBlocks(
  JpegState state,
  JpegScan scan,
  void Function(
    JpegComponent component,
    int blockX,
    int blockY,
    JpegBitReader reader,
  )
  decode, {
  void Function()? onRestart,
}) {
  final layout = _jpegMcuLayout(state);
  var segmentIndex = 0;
  var reader = _progressiveReader(state, scan, segmentIndex);
  var restartUnit = 0;
  void restartIfNeeded() {
    if (state.restartInterval == 0 || restartUnit < state.restartInterval) {
      return;
    }
    onRestart?.call();
    segmentIndex += 1;
    reader = _progressiveReader(state, scan, segmentIndex);
    restartUnit = 0;
  }

  if (scan.components.length > 1) {
    for (var my = 0; my < layout.mcuRows; my += 1) {
      for (var mx = 0; mx < layout.mcuCols; mx += 1) {
        restartIfNeeded();
        for (final component in scan.components) {
          for (var vy = 0; vy < component.v; vy += 1) {
            for (var hx = 0; hx < component.h; hx += 1) {
              decode(
                component,
                mx * component.h + hx,
                my * component.v + vy,
                reader,
              );
            }
          }
        }
        restartUnit += 1;
      }
    }
    return;
  }

  final component = scan.components.single;
  for (var by = 0; by < component.blockRows; by += 1) {
    for (var bx = 0; bx < component.blockCols; bx += 1) {
      restartIfNeeded();
      decode(component, bx, by, reader);
      restartUnit += 1;
    }
  }
}

JpegBitReader _progressiveReader(
  JpegState state,
  JpegScan scan,
  int segmentIndex,
) {
  final segments = scan.entropySegments;
  if (state.restartInterval == 0) {
    return JpegBitReader(_concatSegments(segments));
  }
  if (segmentIndex >= segments.length) {
    throw const InvalidImageException('Missing JPEG restart segment.');
  }
  return JpegBitReader(segments[segmentIndex]);
}

Int32List _coeffBlock(JpegComponent component, int blockX, int blockY) {
  return component.coeffBlocks[blockY * component.blockCols + blockX];
}

void _refineCoefficient(Int32List block, int index, int bit) {
  final value = block[index];
  if ((value.abs() & bit) == 0) {
    block[index] = value >= 0 ? value + bit : value - bit;
  }
}

void _refineAcCoefficients(
  Int32List block,
  JpegBitReader reader,
  int start,
  int end,
  int bit,
) {
  for (var k = start; k <= end; k += 1) {
    final index = jpegZigZag[k];
    if (block[index] != 0 && reader.readBits(1) == 1) {
      _refineCoefficient(block, index, bit);
    }
  }
}

int _skipRefinedZeros(
  Int32List block,
  JpegBitReader reader,
  int start,
  int end,
  int bit,
  int zeros,
) {
  var k = start;
  var remaining = zeros;
  while (k <= end && remaining > 0) {
    final index = jpegZigZag[k];
    if (block[index] != 0) {
      if (reader.readBits(1) == 1) {
        _refineCoefficient(block, index, bit);
      }
    } else {
      remaining -= 1;
    }
    k += 1;
  }
  return k;
}

int _placeRefinedCoefficient(
  Int32List block,
  JpegBitReader reader,
  int start,
  int end,
  int bit,
  int zeros,
  int value,
) {
  var k = start;
  var remaining = zeros;
  while (k <= end) {
    final index = jpegZigZag[k];
    if (block[index] != 0) {
      if (reader.readBits(1) == 1) {
        _refineCoefficient(block, index, bit);
      }
    } else if (remaining == 0) {
      block[index] = value;
      return k + 1;
    } else {
      remaining -= 1;
    }
    k += 1;
  }
  return k;
}

void _writeProgressiveSamples(JpegState state) {
  for (final component in state.components) {
    component.samples = Uint8List(component.width * component.height);
    final quant = _requiredQuantTable(state, component);
    for (var by = 0; by < component.blockRows; by += 1) {
      for (var bx = 0; bx < component.blockCols; bx += 1) {
        final source = _coeffBlock(component, bx, by);
        final coeffs = List<int>.generate(
          64,
          (index) => source[index] * quant[index],
        );
        _writeSamples(component, bx, by, jpegIdct(coeffs));
      }
    }
  }
}
