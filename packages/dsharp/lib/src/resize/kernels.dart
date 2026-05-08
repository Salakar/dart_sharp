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
    ResizeKernel.mks2013 => 2.5,
    ResizeKernel.mks2021 => 4.5,
  };
}

/// Returns a deterministic scalar kernel weight.
double kernelWeight(ResizeKernel kernel, double distance) {
  final x = distance.abs();
  return switch (kernel) {
    ResizeKernel.nearest => x < 0.5 ? 1 : 0,
    ResizeKernel.linear => max(0, 1 - x),
    ResizeKernel.cubic => _catmullRom(x),
    ResizeKernel.mitchell => _mitchell(x),
    ResizeKernel.lanczos2 => _lanczos(x, 2),
    ResizeKernel.lanczos3 => _lanczos(x, 3),
    ResizeKernel.mks2013 => _mks2013(x),
    ResizeKernel.mks2021 => _mks2021(x),
  };
}

double _catmullRom(double x) {
  if (x >= 2) {
    return 0;
  }
  if (x < 1) {
    return (1.5 * x * x * x) - (2.5 * x * x) + 1;
  }
  return (-0.5 * x * x * x) + (2.5 * x * x) - (4 * x) + 2;
}

double _mitchell(double x) {
  const b = 1 / 3;
  const c = 1 / 3;
  if (x >= 2) {
    return 0;
  }
  final x2 = x * x;
  final x3 = x2 * x;
  if (x < 1) {
    return (((12 - (9 * b) - (6 * c)) * x3) +
            ((-18 + (12 * b) + (6 * c)) * x2) +
            (6 - (2 * b))) /
        6;
  }
  return (((-b - (6 * c)) * x3) +
          (((6 * b) + (30 * c)) * x2) +
          (((-12 * b) - (48 * c)) * x) +
          (8 * b) +
          (24 * c)) /
      6;
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

double _mks2013(double x) {
  if (x < 0.5) {
    return 1.0625 - (1.75 * x * x);
  }
  if (x < 1.5) {
    return 0.5 * (x - 1.5) * (x - 2.25);
  }
  if (x < 2.5) {
    final offset = 2.5 - x;
    return -0.125 * offset * offset;
  }
  return 0;
}

double _mks2021(double x) {
  if (x < 0.5) {
    return (577 / 576) - ((239 / 144) * x * x);
  }
  if (x < 1.5) {
    return (35 / 36) * (x - 1) * (x - (239 / 140));
  }
  if (x < 2.5) {
    return (1 / 6) * (x - 2) * ((65 / 24) - x);
  }
  if (x < 3.5) {
    return (1 / 36) * (x - 3) * (x - 3.75);
  }
  if (x < 4.5) {
    final offset = x - 4.5;
    return (-1 / 288) * offset * offset;
  }
  return 0;
}

double _sinc(double x) {
  final value = pi * x;
  return sin(value) / value;
}
