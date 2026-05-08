import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

import 'pipeline_test_helpers.dart';

void main() {
  test(
    'grayscale, negate, threshold, and gamma preserve expected alpha',
    () async {
      final raw = rawRgba(1, 1, <int>[10, 20, 30, 77]);
      final gray = await pixels(ImagePipeline.fromRawPixels(raw).greyscale());
      final grayDisabled = await pixels(
        ImagePipeline.fromRawPixels(raw).grayscale(false),
      );
      final greyDisabled = await pixels(
        ImagePipeline.fromRawPixels(raw).greyscale(false),
      );
      final negated = await pixels(ImagePipeline.fromRawPixels(raw).negate());
      final negatedAlpha = await pixels(
        ImagePipeline.fromRawPixels(raw).negate(alpha: true),
      );
      final negatedDisabled = await pixels(
        ImagePipeline.fromRawPixels(raw).negate(enabled: false),
      );
      final threshold = await pixels(
        ImagePipeline.fromRawPixels(raw).threshold(20),
      );
      final thresholdTrue = await pixels(
        ImagePipeline.fromRawPixels(raw).threshold(true),
      );
      final thresholdDisabled = await pixels(
        ImagePipeline.fromRawPixels(raw).threshold(false),
      );
      final colorThreshold = await pixels(
        ImagePipeline.fromRawPixels(raw).threshold(20, false),
      );
      final gamma = await pixels(
        ImagePipeline.fromRawPixels(
          rawRgba(1, 1, <int>[64, 64, 64, 77]),
        ).gamma(2),
      );

      expect(firstBytes(gray), <int>[18, 18, 18, 77]);
      expect(firstBytes(grayDisabled), <int>[10, 20, 30, 77]);
      expect(firstBytes(greyDisabled), <int>[10, 20, 30, 77]);
      expect(
        ImagePipeline.fromRawPixels(raw).grayscale(false).operations,
        isEmpty,
      );
      expect(firstBytes(negated), <int>[245, 235, 225, 77]);
      expect(firstBytes(negatedAlpha), <int>[245, 235, 225, 178]);
      expect(firstBytes(negatedDisabled), <int>[10, 20, 30, 77]);
      expect(
        ImagePipeline.fromRawPixels(raw).negate(enabled: false).operations,
        isEmpty,
      );
      expect(firstBytes(threshold), <int>[0, 0, 0, 77]);
      expect(firstBytes(thresholdTrue), <int>[0, 0, 0, 77]);
      expect(firstBytes(thresholdDisabled), <int>[10, 20, 30, 77]);
      expect(
        ImagePipeline.fromRawPixels(raw).threshold(false).operations,
        isEmpty,
      );
      expect(firstBytes(colorThreshold), <int>[0, 255, 255, 77]);
      expect(firstBytes(gamma), <int>[128, 128, 128, 77]);
      expect(
        () => ImagePipeline.fromRawPixels(raw).threshold(-1),
        throwsA(isA<OperationValidationException>()),
      );
      expect(
        () => ImagePipeline.fromRawPixels(raw).threshold(256),
        throwsA(isA<OperationValidationException>()),
      );
      expect(
        () => ImagePipeline.fromRawPixels(raw).threshold(20, 'false'),
        throwsA(isA<OperationValidationException>()),
      );
    },
  );

  test('colourspace methods support sRGB and black-white aliases', () async {
    final bw = await pixels(
      ImagePipeline.fromRawPixels(
        rawRgb(2, 1, <int>[10, 20, 30, 40, 50, 60]),
      ).toColourspace('b-w'),
    );
    final grey = await pixels(
      ImagePipeline.fromRawPixels(
        rawRgb(1, 1, <int>[40, 50, 60]),
      ).pipelineColorspace('greyscale'),
    );
    final srgb = await pixels(
      ImagePipeline.fromRawPixels(
        rawRgb(1, 1, <int>[1, 2, 3]),
      ).toColorspace('srgb'),
    );

    expect(bw.channels, ChannelCount.one);
    expect(firstBytes(bw), <int>[18, 48]);
    expect(grey.channels, ChannelCount.one);
    expect(firstBytes(grey), <int>[48]);
    expect(srgb.channels, ChannelCount.three);
    expect(firstBytes(srgb), <int>[1, 2, 3]);
    expect(
      ImagePipeline.fromRawPixels(
        rawRgb(1, 1, <int>[1, 2, 3]),
      ).toColourspace('cmyk').toPixelImage(),
      throwsA(isA<OperationValidationException>()),
    );
  });

  test(
    'linear, tint, normalize, recomb, modulate, and clahe adjust colors',
    () async {
      final linear = await pixels(
        ImagePipeline.fromRawPixels(
          rawRgb(1, 1, <int>[10, 20, 30]),
        ).linear(const LinearOptions(multiplier: 2, offset: 10)),
      );
      final linearNumbers = await pixels(
        ImagePipeline.fromRawPixels(
          rawRgb(1, 1, <int>[10, 20, 30]),
        ).linear(0.5, 2),
      );
      final linearOffsetOnly = await pixels(
        ImagePipeline.fromRawPixels(
          rawRgb(1, 1, <int>[10, 20, 30]),
        ).linear(null, 10),
      );
      final linearChannels = await pixels(
        ImagePipeline.fromRawPixels(
          rawRgb(1, 1, <int>[10, 20, 30]),
        ).linear(<num>[1, 2, 3], <num>[10, 20, 30]),
      );
      final tinted = await pixels(
        ImagePipeline.fromRawPixels(
          rawRgb(1, 1, <int>[10, 20, 30]),
        ).tint(const RgbaColor(red: 110, green: 20, blue: 230)),
      );
      final normalized = await pixels(
        ImagePipeline.fromRawPixels(
          rawRgba(2, 1, <int>[10, 20, 30, 77, 30, 40, 50, 99]),
        ).normalize(),
      );
      final recombed = await pixels(
        ImagePipeline.fromRawPixels(
          rawRgb(1, 1, <int>[10, 20, 30]),
        ).recomb(const <num>[0, 1, 0, 1, 0, 0, 0, 0, 1]),
      );
      final recombedNested = await pixels(
        ImagePipeline.fromRawPixels(rawRgb(1, 1, <int>[10, 20, 30])).recomb(
          const <List<num>>[
            <num>[0, 1, 0],
            <num>[1, 0, 0],
            <num>[0, 0, 1],
          ],
        ),
      );
      final recombedRgba = await pixels(
        ImagePipeline.fromRawPixels(
          rawRgba(1, 1, <int>[10, 20, 30, 40]),
        ).recomb(const <List<num>>[
          <num>[0, 1, 0, 0],
          <num>[1, 0, 0, 0],
          <num>[0, 0, 1, 0],
          <num>[0, 0, 0, 1],
        ]),
      );
      final modulated = await pixels(
        ImagePipeline.fromRawPixels(
          rawRgb(1, 1, <int>[10, 20, 30]),
        ).modulate(brightness: 2),
      );
      final clahe = await pixels(
        ImagePipeline.fromRawPixels(
          rawGray(2, 1, <int>[10, 200]),
        ).clahe(const ClaheOptions(width: 2, height: 1, maxSlope: 0)),
      );

      expect(firstBytes(linear), <int>[30, 50, 70]);
      expect(firstBytes(linearNumbers), <int>[7, 12, 17]);
      expect(firstBytes(linearOffsetOnly), <int>[20, 30, 40]);
      expect(firstBytes(linearChannels), <int>[20, 60, 120]);
      expect(firstBytes(tinted), <int>[60, 20, 130]);
      expect(firstBytes(normalized), <int>[0, 64, 128, 77, 128, 191, 255, 99]);
      expect(firstBytes(recombed), <int>[20, 10, 30]);
      expect(firstBytes(recombedNested), <int>[20, 10, 30]);
      expect(firstBytes(recombedRgba), <int>[20, 10, 30, 40]);
      expect(firstBytes(modulated), <int>[20, 40, 60]);
      expect(firstBytes(clahe), <int>[128, 255]);
      expect(
        () => ImagePipeline.fromRawPixels(
          rawRgb(1, 1, <int>[10, 20, 30]),
        ).linear(<num>[1, 2], <num>[0]),
        throwsA(isA<OperationValidationException>()),
      );
      expect(
        ImagePipeline.fromRawPixels(
          rawRgb(1, 1, <int>[10, 20, 30]),
        ).linear(<num>[1, 2], <num>[0, 0]).toPixelImage(),
        throwsA(isA<OperationValidationException>()),
      );
      expect(
        () => ImagePipeline.fromRawPixels(
          rawRgb(1, 1, <int>[10, 20, 30]),
        ).recomb(const <num>[1, 2, 3]),
        throwsA(isA<OperationValidationException>()),
      );
    },
  );

  test('boolean image operations support and, or, and eor', () async {
    final left = rawGray(2, 1, <int>[0xF0, 0x0F]);
    final right = PixelImage.fromRawPixels(rawGray(2, 1, <int>[0xAA, 0xAA]));
    final andImage = await pixels(
      ImagePipeline.fromRawPixels(
        left,
      ).boolean(operand: right, operator: BooleanOperator.and),
    );
    final orImage = await pixels(
      ImagePipeline.fromRawPixels(
        left,
      ).boolean(operand: right, operator: BooleanOperator.or),
    );
    final eorImage = await pixels(
      ImagePipeline.fromRawPixels(
        left,
      ).boolean(operand: right, operator: BooleanOperator.eor),
    );

    expect(firstBytes(andImage), <int>[0xA0, 0x0A]);
    expect(firstBytes(orImage), <int>[0xFA, 0xAF]);
    expect(firstBytes(eorImage), <int>[0x5A, 0xA5]);
  });

  test('bandBool reduces channels and boolean validates dimensions', () async {
    final band = await pixels(
      ImagePipeline.fromRawPixels(
        rawRgb(1, 1, <int>[247, 170, 15]),
      ).bandBool(BooleanOperator.and),
    );

    expect(firstBytes(band), <int>[2]);
    expect(
      ImagePipeline.fromRawPixels(rawGray(1, 1, <int>[1]))
          .boolean(
            operand: PixelImage.fromRawPixels(rawGray(2, 1, <int>[1, 2])),
            operator: BooleanOperator.and,
          )
          .toPixelImage(),
      throwsA(isA<OperationValidationException>()),
    );
  });
}
