import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

import 'pipeline_test_helpers.dart';

void main() {
  PixelImage frameImage(List<List<int>> frames, {int? loopCount}) {
    return PixelImage(
      frames: <ImageFrame>[
        for (var i = 0; i < frames.length; i += 1)
          ImageFrame(
            pixels: rawRgba(1, 1, frames[i]),
            delay: Duration(milliseconds: 10 * (i + 1)),
          ),
      ],
      loopCount: loopCount,
    );
  }

  test(
    'composite preserves animation frame order, delays, and loop count',
    () async {
      final base = frameImage(<List<int>>[
        <int>[1, 0, 0, 255],
        <int>[2, 0, 0, 255],
      ], loopCount: 7);
      final over = frameImage(<List<int>>[
        <int>[9, 0, 0, 255],
        <int>[8, 0, 0, 255],
      ]);

      final image = await pixels(
        ImagePipeline.fromPixelImage(base).composite(<CompositeLayer>[
          CompositeLayer(
            image: over,
            blendMode: BlendMode.source,
            left: 0,
            top: 0,
          ),
        ]),
      );

      expect(image.frames.length, 2);
      expect(image.loopCount, 7);
      expect(image.frames[0].delay, const Duration(milliseconds: 10));
      expect(image.frames[1].delay, const Duration(milliseconds: 20));
      expect(image.frames[0].pixels.bytes, <int>[9, 0, 0, 255]);
      expect(image.frames[1].pixels.bytes, <int>[8, 0, 0, 255]);
    },
  );

  test(
    'boolean operation rejects animated inputs until frame pairing exists',
    () {
      final animated = frameImage(<List<int>>[
        <int>[1, 0, 0, 255],
        <int>[2, 0, 0, 255],
      ]);

      expect(
        ImagePipeline.fromPixelImage(animated)
            .boolean(
              operand: PixelImage.fromRawPixels(
                rawRgba(1, 1, <int>[1, 0, 0, 255]),
              ),
              operator: BooleanOperator.and,
            )
            .toPixelImage(),
        throwsA(isA<OperationValidationException>()),
      );
    },
  );

  test('joinImages creates grids with shim and transparent background', () {
    final joined = joinImages(<PixelImage>[
      PixelImage.fromRawPixels(rawRgba(1, 1, <int>[1, 0, 0, 255])),
      PixelImage.fromRawPixels(
        rawRgba(2, 1, <int>[2, 0, 0, 255, 3, 0, 0, 255]),
      ),
      PixelImage.fromRawPixels(
        rawRgba(1, 2, <int>[4, 0, 0, 255, 5, 0, 0, 255]),
      ),
    ], options: const JoinOptions(across: 2, shim: 1));

    expect(joined.width, 4);
    expect(joined.height, 4);
    expect(redBytes(joined), <int>[
      1,
      0,
      2,
      3,
      0,
      0,
      0,
      0,
      4,
      0,
      0,
      0,
      5,
      0,
      0,
      0,
    ]);
    expect(joined.firstFrameBytes()[7], 0);
  });

  test('joinImages animated flag preserves frames and loop count', () {
    final first = frameImage(<List<int>>[
      <int>[1, 0, 0, 255],
      <int>[2, 0, 0, 255],
    ], loopCount: 3);
    final second = frameImage(<List<int>>[
      <int>[10, 0, 0, 255],
      <int>[20, 0, 0, 255],
    ]);

    final joined = joinImages(<PixelImage>[
      first,
      second,
    ], options: const JoinOptions(across: 2, animated: true));

    expect(joined.frames.length, 2);
    expect(joined.loopCount, 3);
    expect(redBytes(PixelImage(frames: <ImageFrame>[joined.frames[0]])), <int>[
      1,
      10,
    ]);
    expect(redBytes(PixelImage(frames: <ImageFrame>[joined.frames[1]])), <int>[
      2,
      20,
    ]);
  });

  test('joinImages validates options', () {
    expect(
      () => joinImages(<PixelImage>[], options: const JoinOptions(across: 0)),
      throwsA(isA<OperationValidationException>()),
    );
  });
}
