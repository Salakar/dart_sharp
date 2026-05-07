import 'dart:math';

import '../geometry/geometry.dart';

/// Returns a representative support radius for [kernel].
double kernelRadius(ResizeKernel kernel) {
  return switch (kernel) {
    ResizeKernel.nearest => 0.5,
    ResizeKernel.linear => 1,
    ResizeKernel.cubic || ResizeKernel.mitchell => 2,
    ResizeKernel.lanczos2 => 2,
    ResizeKernel.lanczos3 => 3,
    ResizeKernel.mks2013 || ResizeKernel.mks2021 => 2,
  };
}

/// Returns a deterministic scalar kernel weight.
double kernelWeight(ResizeKernel kernel, double distance) {
  final x = distance.abs();
  return switch (kernel) {
    ResizeKernel.nearest => x < 0.5 ? 1 : 0,
    ResizeKernel.linear => max(0, 1 - x),
    ResizeKernel.cubic || ResizeKernel.mitchell => _triangleCubic(x),
    ResizeKernel.lanczos2 => _lanczos(x, 2),
    ResizeKernel.lanczos3 => _lanczos(x, 3),
    ResizeKernel.mks2013 || ResizeKernel.mks2021 => _triangleCubic(x),
  };
}

double _triangleCubic(double x) {
  if (x >= 2) {
    return 0;
  }
  if (x < 1) {
    return (1.5 * x * x * x) - (2.5 * x * x) + 1;
  }
  return (-0.5 * x * x * x) + (2.5 * x * x) - (4 * x) + 2;
}

double _lanczos(double x, int radius) {
  if (x == 0) {
    return 1;
  }
  if (x >= radius) {
    return 0;
  }
  return _sinc(x) * _sinc(x / radius);
}

double _sinc(double x) {
  final value = pi * x;
  return sin(value) / value;
}
