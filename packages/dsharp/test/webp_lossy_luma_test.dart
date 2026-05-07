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
