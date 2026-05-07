import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

import 'pipeline_test_helpers.dart';

void main() {
  PixelImage overlay(List<int> bytes, {int width = 1, int height = 1}) {
    return PixelImage.fromRawPixels(rawRgba(width, height, bytes));
  }

  Future<List<int>> compositeBytes(BlendMode mode) async {
    final image = await pixels(
      ImagePipeline.fromRawPixels(
        rawRgba(1, 1, <int>[0, 0, 100, 255]),
      ).composite(<CompositeLayer>[
        CompositeLayer(
          image: overlay(<int>[100, 0, 0, 128]),
          blendMode: mode,
          left: 0,
          top: 0,
        ),
      ]),
    );
    return firstBytes(image);
  }

  test('porter-duff blend modes produce hand-computed pixels', () async {
    final expected = <BlendMode, List<int>>{
      BlendMode.clear: <int>[0, 0, 0, 0],
      BlendMode.source: <int>[100, 0, 0, 128],
      BlendMode.over: <int>[50, 0, 50, 255],
      BlendMode.in_: <int>[100, 0, 0, 128],
      BlendMode.out: <int>[0, 0, 0, 0],
      BlendMode.atop: <int>[50, 0, 50, 255],
      BlendMode.dest: <int>[0, 0, 100, 255],
      BlendMode.destOver: <int>[0, 0, 100, 255],
      BlendMode.destIn: <int>[0, 0, 100, 128],
      BlendMode.destOut: <int>[0, 0, 100, 127],
      BlendMode.destAtop: <int>[0, 0, 100, 128],
      BlendMode.xor: <int>[0, 0, 100, 127],
    };

    for (final entry in expected.entries) {
      expect(
        await compositeBytes(entry.key),
        entry.value,
        reason: entry.key.name,
      );
    }
  });

  test('artistic blend modes clamp channels', () async {
    Future<List<int>> run(BlendMode mode) async {
      final image = await pixels(
        ImagePipeline.fromRawPixels(
          rawRgba(1, 1, <int>[100, 100, 100, 255]),
        ).composite(<CompositeLayer>[
          CompositeLayer(
            image: overlay(<int>[50, 200, 100, 255]),
            blendMode: mode,
            left: 0,
            top: 0,
          ),
        ]),
      );
      return firstBytes(image);
    }

    expect(await run(BlendMode.add), <int>[150, 255, 200, 255]);
    expect(await run(BlendMode.saturate), <int>[150, 255, 200, 255]);
    expect(await run(BlendMode.multiply), <int>[20, 78, 39, 255]);
    expect(await run(BlendMode.screen), <int>[130, 222, 161, 255]);
    expect(await run(BlendMode.difference), <int>[50, 100, 0, 255]);
    expect(await run(BlendMode.exclusion), <int>[111, 143, 122, 255]);
  });

  test('gravity, offsets, tiling, and cropped overlays place pixels', () async {
    final base = rawRgba(3, 2, List<int>.filled(3 * 2 * 4, 0));
    final red = overlay(<int>[9, 0, 0, 255]);
    final southeast = await pixels(
      ImagePipeline.fromRawPixels(base).composite(<CompositeLayer>[
        CompositeLayer(image: red, gravity: Gravity.southeast),
      ]),
    );
    final tiled = await pixels(
      ImagePipeline.fromRawPixels(base).composite(<CompositeLayer>[
        CompositeLayer(image: red, left: 0, top: 0, tile: true),
      ]),
    );
    final negative = await pixels(
      ImagePipeline.fromRawPixels(base).composite(<CompositeLayer>[
        CompositeLayer(
          image: overlay(<int>[1, 0, 0, 255, 2, 0, 0, 255], width: 2),
          left: -1,
          top: 0,
        ),
      ]),
    );
    final cropped = await pixels(
      ImagePipeline.fromRawPixels(rawRgba(1, 1, <int>[0, 0, 0, 0])).composite(
        <CompositeLayer>[
          CompositeLayer(
            image: overlay(
              <int>[1, 0, 0, 255, 2, 0, 0, 255, 3, 0, 0, 255, 4, 0, 0, 255],
              width: 2,
              height: 2,
            ),
            left: 0,
            top: 0,
          ),
        ],
      ),
    );

    expect(redBytes(southeast), <int>[0, 0, 0, 0, 0, 9]);
    expect(redBytes(tiled), <int>[9, 9, 9, 9, 9, 9]);
    expect(redBytes(negative), <int>[2, 0, 0, 0, 0, 0]);
    expect(redBytes(cropped), <int>[1]);
  });

  test('invalid composite placement rejects partial offsets', () {
    expect(
      ImagePipeline.fromRawPixels(rawRgba(1, 1, <int>[0, 0, 0, 0])).composite(
        <CompositeLayer>[
          CompositeLayer(image: overlay(<int>[0, 0, 0, 0]), left: 0),
        ],
      ).toPixelImage(),
      throwsA(isA<OperationValidationException>()),
    );
  });
}
