import 'package:dsharp/dsharp.dart';
import 'package:dsharp/src/operations/transform_operations.dart';
import 'package:test/test.dart';

import 'pipeline_test_helpers.dart';

void main() {
  test('auto-orient operation maps EXIF orientations', () {
    final source = PixelImage.fromRawPixels(
      rawRgba(2, 3, <int>[
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
        5,
        0,
        0,
        255,
        6,
        0,
        0,
        255,
      ]),
    );
    const operation = AutoOrientOperation();
    final cases = <int, _ExpectedOrientation>{
      1: _ExpectedOrientation(2, 3, <int>[1, 2, 3, 4, 5, 6]),
      2: _ExpectedOrientation(2, 3, <int>[2, 1, 4, 3, 6, 5]),
      3: _ExpectedOrientation(2, 3, <int>[6, 5, 4, 3, 2, 1]),
      4: _ExpectedOrientation(2, 3, <int>[5, 6, 3, 4, 1, 2]),
      5: _ExpectedOrientation(3, 2, <int>[1, 3, 5, 2, 4, 6]),
      6: _ExpectedOrientation(3, 2, <int>[5, 3, 1, 6, 4, 2]),
      7: _ExpectedOrientation(3, 2, <int>[6, 4, 2, 5, 3, 1]),
      8: _ExpectedOrientation(3, 2, <int>[2, 4, 6, 1, 3, 5]),
    };

    for (final entry in cases.entries) {
      final image = operation.applyOrientation(source, entry.key);

      expect(
        image.width,
        entry.value.width,
        reason: 'orientation ${entry.key}',
      );
      expect(
        image.height,
        entry.value.height,
        reason: 'orientation ${entry.key}',
      );
      expect(
        redBytes(image),
        entry.value.red,
        reason: 'orientation ${entry.key}',
      );
    }
  });
}

final class _ExpectedOrientation {
  const _ExpectedOrientation(this.width, this.height, this.red);

  final int width;
  final int height;
  final List<int> red;
}
