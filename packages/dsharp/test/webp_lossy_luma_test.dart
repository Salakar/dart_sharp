import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

import 'helpers/webp_lossy_fixture.dart';

void main() {
  test('applies supported VP8 luma AC residual magnitudes', () async {
    final cases = <(int, List<int>)>[
      (1, <int>[129, 128, 128, 127]),
      (2, <int>[129, 129, 128, 127]),
      (3, <int>[130, 129, 127, 126]),
      (4, <int>[131, 129, 127, 126]),
    ];

    for (final (coefficient, row) in cases) {
      final bytes = lumaAcResidualVp8Webp(
        width: 4,
        height: 4,
        coefficient: coefficient,
      );

      final image = await ImagePipeline.fromBytes(bytes).toPixelImage();
      final rgba = image.firstFrameBytes();

      expect(
        [for (var i = 0; i < 4; i++) rgba[i * 4]],
        row,
        reason: 'coefficient $coefficient row 0',
      );
      expect(
        [for (var i = 0; i < 4; i++) rgba[16 + i * 4]],
        row,
        reason: 'coefficient $coefficient row 1',
      );
    }
  });

  test('applies supported VP8 luma AC category magnitudes', () async {
    const coefficients = <int>[
      5,
      6,
      7,
      10,
      11,
      18,
      19,
      34,
      35,
      66,
      67,
      2048,
      -6,
    ];

    for (final coefficient in coefficients) {
      final bytes = lumaAcResidualVp8Webp(
        width: 4,
        height: 4,
        coefficient: coefficient,
      );

      final image = await ImagePipeline.fromBytes(bytes).toPixelImage();
      final rgba = image.firstFrameBytes();
      final row = _expectedFirstAcRow(coefficient);

      expect(
        [for (var i = 0; i < 4; i++) rgba[i * 4]],
        row,
        reason: 'coefficient $coefficient row 0',
      );
      expect(
        [for (var i = 0; i < 4; i++) rgba[16 + i * 4]],
        row,
        reason: 'coefficient $coefficient row 1',
      );
    }
  });

  test('applies VP8 luma AC zero runs before coefficients', () async {
    final bytes = lumaAcResidualVp8Webp(
      width: 4,
      height: 4,
      coefficientIndex: 2,
    );

    final image = await ImagePipeline.fromBytes(bytes).toPixelImage();
    final rgba = image.firstFrameBytes();

    expect(
      [for (var i = 0; i < 4; i++) rgba[i * 4]],
      <int>[129, 129, 129, 129],
    );
    expect(
      [for (var row = 0; row < 4; row++) rgba[row * 16]],
      <int>[129, 128, 128, 127],
    );
  });

  test('applies VP8 luma AC coefficient probability updates', () async {
    final firstBandBytes = lumaAcResidualVp8Webp(
      width: 4,
      height: 4,
      yAcBandOneEobProbability: 128,
    );

    final firstBandImage = await ImagePipeline.fromBytes(
      firstBandBytes,
    ).toPixelImage();
    final firstBandRgba = firstBandImage.firstFrameBytes();

    expect(
      [for (var i = 0; i < 4; i++) firstBandRgba[i * 4]],
      <int>[129, 128, 128, 127],
    );

    final bytes = lumaAcResidualVp8Webp(
      width: 4,
      height: 4,
      coefficientIndex: 2,
      yAcBandTwoEobProbability: 128,
    );

    final image = await ImagePipeline.fromBytes(bytes).toPixelImage();
    final rgba = image.firstFrameBytes();

    expect(
      [for (var i = 0; i < 4; i++) rgba[i * 4]],
      <int>[129, 129, 129, 129],
    );
    expect(
      [for (var row = 0; row < 4; row++) rgba[row * 16]],
      <int>[129, 128, 128, 127],
    );
  });

  test('applies multiple VP8 luma AC coefficients in one block', () async {
    final bytes = lumaAcResidualVp8Webp(
      width: 4,
      height: 4,
      coefficient: 2,
      secondCoefficient: -1,
      secondCoefficientIndex: 2,
    );

    final image = await ImagePipeline.fromBytes(bytes).toPixelImage();
    final rgba = image.firstFrameBytes();
    final expected = _expectedDctBlock({1: 2, 4: -1});

    for (var row = 0; row < 4; row += 1) {
      expect(
        [for (var col = 0; col < 4; col += 1) rgba[(row * 4 + col) * 4]],
        expected[row],
        reason: 'row $row',
      );
    }
  });
}

List<int> _expectedFirstAcRow(int coefficient) {
  const cospi8Sqrt2Minus1 = 20091;
  const sinpi8Sqrt2 = 35468;
  final scaled = coefficient * 4;
  final c = (scaled * sinpi8Sqrt2) >> 16;
  final d = scaled + ((scaled * cospi8Sqrt2Minus1) >> 16);
  return <int>[
    _clipSample(128 + ((d + 4) >> 3)),
    _clipSample(128 + ((c + 4) >> 3)),
    _clipSample(128 + (((-c) + 4) >> 3)),
    _clipSample(128 + (((-d) + 4) >> 3)),
  ];
}

int _clipSample(int value) => value < 0 ? 0 : (value > 255 ? 255 : value);

List<List<int>> _expectedDctBlock(Map<int, int> coefficients) {
  const cospi8Sqrt2Minus1 = 20091;
  const sinpi8Sqrt2 = 35468;
  final coeffs = List<int>.filled(16, 0);
  for (final entry in coefficients.entries) {
    coeffs[entry.key] = entry.value * 4;
  }
  final tmp = List<int>.filled(16, 0);
  for (var i = 0; i < 4; i += 1) {
    final a1 = coeffs[i] + coeffs[8 + i];
    final b1 = coeffs[i] - coeffs[8 + i];
    final c1 =
        ((coeffs[4 + i] * sinpi8Sqrt2) >> 16) -
        coeffs[12 + i] -
        ((coeffs[12 + i] * cospi8Sqrt2Minus1) >> 16);
    final d1 =
        coeffs[4 + i] +
        ((coeffs[4 + i] * cospi8Sqrt2Minus1) >> 16) +
        ((coeffs[12 + i] * sinpi8Sqrt2) >> 16);
    tmp[i] = a1 + d1;
    tmp[12 + i] = a1 - d1;
    tmp[4 + i] = b1 + c1;
    tmp[8 + i] = b1 - c1;
  }
  return [
    for (var row = 0; row < 4; row += 1)
      [
        for (var col = 0; col < 4; col += 1)
          _clipSample(128 + ((_dctRowSample(tmp, row, col) + 4) >> 3)),
      ],
  ];
}

int _dctRowSample(List<int> tmp, int row, int col) {
  const cospi8Sqrt2Minus1 = 20091;
  const sinpi8Sqrt2 = 35468;
  final base = row * 4;
  final a1 = tmp[base] + tmp[base + 2];
  final b1 = tmp[base] - tmp[base + 2];
  final c1 =
      ((tmp[base + 1] * sinpi8Sqrt2) >> 16) -
      tmp[base + 3] -
      ((tmp[base + 3] * cospi8Sqrt2Minus1) >> 16);
  final d1 =
      tmp[base + 1] +
      ((tmp[base + 1] * cospi8Sqrt2Minus1) >> 16) +
      ((tmp[base + 3] * sinpi8Sqrt2) >> 16);
  return switch (col) {
    0 => a1 + d1,
    1 => b1 + c1,
    2 => b1 - c1,
    _ => a1 - d1,
  };
}
