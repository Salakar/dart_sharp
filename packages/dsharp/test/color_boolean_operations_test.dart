import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

import 'pipeline_test_helpers.dart';

void main() {
  test(
    'grayscale, negate, threshold, and gamma preserve expected alpha',
    () async {
      final raw = rawRgba(1, 1, <int>[10, 20, 30, 77]);
      final gray = await pixels(ImagePipeline.fromRawPixels(raw).greyscale());
      final negated = await pixels(ImagePipeline.fromRawPixels(raw).negate());
      final threshold = await pixels(
        ImagePipeline.fromRawPixels(raw).threshold(20),
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
      expect(firstBytes(negated), <int>[245, 235, 225, 77]);
      expect(firstBytes(threshold), <int>[0, 0, 0, 77]);
      expect(firstBytes(colorThreshold), <int>[0, 255, 255, 77]);
      expect(firstBytes(gamma), <int>[128, 128, 128, 77]);
    },
  );

  test(
    'linear, tint, normalize, recomb, modulate, and clahe adjust colors',
    () async {
      final linear = await pixels(
        ImagePipeline.fromRawPixels(
          rawRgb(1, 1, <int>[10, 20, 30]),
        ).linear(const LinearOptions(multiplier: 2, offset: 10)),
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
      expect(firstBytes(tinted), <int>[60, 20, 130]);
      expect(firstBytes(normalized), <int>[0, 64, 128, 77, 128, 191, 255, 99]);
      expect(firstBytes(recombed), <int>[20, 10, 30]);
      expect(firstBytes(modulated), <int>[20, 40, 60]);
      expect(firstBytes(clahe), <int>[128, 255]);
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
