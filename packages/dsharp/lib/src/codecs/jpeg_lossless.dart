part of 'jpeg_decoder.dart';

void _decodeLosslessScan(JpegState state) {
  if (state.pointTransform > 7) {
    throw UnsupportedCodecException(
      'Unsupported lossless JPEG point transform ${state.pointTransform}.',
    );
  }
  for (final component in state.components) {
    if (component.h != 1 || component.v != 1) {
      throw const UnsupportedCodecException(
        'Subsampled lossless JPEG is not supported.',
      );
    }
    component
      ..width = state.width
      ..height = state.height
      ..samples = Uint8List(state.width * state.height);
  }
  final scan = state.scan!;
  var segmentIndex = 0;
  var reader = _scanReader(state, segmentIndex);
  var restartMcu = 0;
  final rawSamples = <JpegComponent, Uint16List>{
    for (final component in state.components)
      component: Uint16List(state.width * state.height),
  };
  for (var y = 0; y < state.height; y += 1) {
    for (var x = 0; x < state.width; x += 1) {
      if (state.restartInterval > 0 && restartMcu == state.restartInterval) {
        _resetPredictors(state);
        segmentIndex += 1;
        reader = _scanReader(state, segmentIndex);
        restartMcu = 0;
      }
      for (final component in scan.components) {
        final samples = rawSamples[component]!;
        final table = _requiredDcTree(state, component);
        final size = table.read(reader);
        final diff = jpegExtend(reader.readBits(size), size);
        final predictor = _losslessPredictor(state, samples, x, y);
        final value = predictor + diff;
        final index = y * state.width + x;
        samples[index] = value.clamp(0, 0xffff);
        component.samples[index] = _losslessOutputSample(
          value,
          state.pointTransform,
        );
      }
      if (state.restartInterval > 0) {
        restartMcu += 1;
      }
    }
  }
}

int _losslessPredictor(JpegState state, Uint16List samples, int x, int y) {
  final initial = 1 << (state.precision - state.pointTransform - 1);
  if (x == 0 && y == 0) {
    return initial;
  }
  if (y == 0) {
    return samples[x - 1];
  }
  final above = samples[(y - 1) * state.width + x];
  if (x == 0) {
    return above;
  }
  final left = samples[y * state.width + x - 1];
  final upperLeft = samples[(y - 1) * state.width + x - 1];
  return switch (state.losslessPredictor) {
    1 => left,
    2 => above,
    3 => upperLeft,
    4 => left + above - upperLeft,
    5 => left + ((above - upperLeft) >> 1),
    6 => above + ((left - upperLeft) >> 1),
    7 => (left + above) >> 1,
    _ => throw UnsupportedCodecException(
      'Unsupported lossless JPEG predictor ${state.losslessPredictor}.',
    ),
  };
}

int _losslessOutputSample(int value, int pointTransform) {
  final shifted = value << pointTransform;
  if (shifted < 0) {
    return 0;
  }
  if (shifted > 255) {
    return 255;
  }
  return shifted;
}
