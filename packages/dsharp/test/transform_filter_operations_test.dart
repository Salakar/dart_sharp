import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

import 'pipeline_test_helpers.dart';

void main() {
  RawPixels raw2x2() {
    return rawRgba(2, 2, <int>[
      1,
      0,
      0,
      255,
      2,
      0,
      0,
      255,
      3,
      0,
      0,
      255,
      4,
      0,
      0,
      255,
    ]);
  }

  test(
    'flip, flop, and right-angle rotate move pixels deterministically',
    () async {
      final flipped = await pixels(
        ImagePipeline.fromRawPixels(raw2x2()).flip(),
      );
      final flopped = await pixels(
        ImagePipeline.fromRawPixels(raw2x2()).flop(),
      );
      final rotated = await pixels(
        ImagePipeline.fromRawPixels(raw2x2()).rotate(90),
      );

      expect(redBytes(flipped), <int>[3, 4, 1, 2]);
      expect(redBytes(flopped), <int>[2, 1, 4, 3]);
      expect(redBytes(rotated), <int>[3, 1, 4, 2]);
    },
  );

  test(
    'autoOrient hook records operation and leaves pixels unchanged',
    () async {
      final pipeline = ImagePipeline.fromRawPixels(raw2x2()).autoOrient();
      final image = await pixels(pipeline);

      expect(pipeline.operations, <String>['autoOrient']);
      expect(redBytes(image), <int>[1, 2, 3, 4]);
    },
  );

  test(
    'arbitrary rotate expands bounds and affine validates matrices',
    () async {
      final rotated = await pixels(
        ImagePipeline.fromRawPixels(raw2x2()).rotate(45),
      );
      final affine = await pixels(
        ImagePipeline.fromRawPixels(
          raw2x2(),
        ).affine(const AffineOptions(a: 2, b: 0, c: 0, d: 2)),
      );

      expect(rotated.width, 3);
      expect(rotated.height, 3);
      expect(affine.width, 4);
      expect(affine.height, 4);
      expect(
        ImagePipeline.fromRawPixels(
          raw2x2(),
        ).affine(const AffineOptions(a: 1, b: 1, c: 1, d: 1)).toPixelImage(),
        throwsA(isA<OperationValidationException>()),
      );
    },
  );

  test('operation ordering is preserved with resize and extract', () async {
    final rotateThenExtract = await pixels(
      ImagePipeline.fromRawPixels(
        raw2x2(),
      ).rotate(90).extract(const Region(left: 0, top: 0, width: 1, height: 1)),
    );
    final extractThenRotate = await pixels(
      ImagePipeline.fromRawPixels(
        raw2x2(),
      ).extract(const Region(left: 0, top: 0, width: 1, height: 1)).rotate(90),
    );

    expect(firstBytes(rotateThenExtract), <int>[3, 0, 0, 255]);
    expect(firstBytes(extractThenRotate), <int>[1, 0, 0, 255]);
  });

  test('blur, median, dilate, and erode handle tiny edge pixels', () async {
    final raw = rawGray(3, 3, <int>[0, 0, 0, 0, 255, 0, 0, 0, 0]);
    final blurred = await pixels(ImagePipeline.fromRawPixels(raw).blur());
    final median = await pixels(ImagePipeline.fromRawPixels(raw).median());
    final dilated = await pixels(ImagePipeline.fromRawPixels(raw).dilate());
    final eroded = await pixels(ImagePipeline.fromRawPixels(raw).erode());

    expect(firstBytes(blurred)[4], 28);
    expect(firstBytes(median)[4], 0);
    expect(firstBytes(dilated)[0], 255);
    expect(firstBytes(eroded)[4], 0);
  });

  test('convolve supports scale and rejects invalid kernels', () async {
    final raw = rawGray(1, 1, <int>[20]);
    final convolved = await pixels(
      ImagePipeline.fromRawPixels(raw).convolve(
        const ConvolutionKernel(
          width: 1,
          height: 1,
          values: <num>[2],
          scale: 2,
        ),
      ),
    );

    expect(firstBytes(convolved), <int>[20]);
    expect(
      ImagePipeline.fromRawPixels(raw)
          .convolve(
            const ConvolutionKernel(width: 2, height: 1, values: <num>[1, 1]),
          )
          .toPixelImage(),
      throwsA(isA<OperationValidationException>()),
    );
  });
}
