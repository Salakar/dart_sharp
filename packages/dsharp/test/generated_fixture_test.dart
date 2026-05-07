import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

import 'helpers/generated_fixtures.dart';

void main() {
  test('generated alpha grid and gradient are deterministic', () {
    final alpha = GeneratedFixtures.alphaGrid();
    final gradient = GeneratedFixtures.gradient(width: 3, height: 2);

    expect(alpha.width, 2);
    expect(alpha.height, 2);
    expect(alpha.bytes, <int>[
      10,
      0,
      0,
      0,
      20,
      0,
      0,
      85,
      30,
      0,
      0,
      170,
      40,
      0,
      0,
      255,
    ]);
    expect(gradient.width, 3);
    expect(gradient.height, 2);
    expect(gradient.bytes.take(8), <int>[0, 0, 0, 255, 128, 0, 85, 255]);
  });

  test('generated animation preserves delays and loop count', () {
    final animation = GeneratedFixtures.animation();

    expect(animation.frames.length, 2);
    expect(animation.loopCount, 2);
    expect(animation.frames[0].delay, const Duration(milliseconds: 10));
    expect(animation.frames[1].pixels.width, 2);
  });

  test('malformed byte fixtures fail with typed exceptions', () async {
    for (final bytes in GeneratedFixtures.malformedBytes()) {
      expect(
        ImagePipeline.fromBytes(bytes).metadata(),
        throwsA(
          anyOf(
            isA<ImageProcessingException>(),
            isA<UnsupportedCodecException>(),
          ),
        ),
      );
    }
  });
}
