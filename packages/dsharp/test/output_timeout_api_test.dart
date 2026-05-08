import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

import 'pipeline_test_helpers.dart';

void main() {
  RawPixels raw() => rawRgba(1, 1, <int>[1, 2, 3, 255]);

  test('timeout accepts sharp-style seconds map', () async {
    final output = await ImagePipeline.fromRawPixels(
      raw(),
    ).timeout(<String, Object?>{'seconds': 1}).toBytesWithInfo();

    expect(output.info.format, ImageFormat.raw);
  });

  test('timeout zero clears the timeout', () async {
    final output = await ImagePipeline.fromRawPixels(raw())
        .timeout(const Duration(milliseconds: 1))
        .timeout(<String, Object?>{'seconds': 0})
        .toBytesWithInfo();

    expect(output.info.size, 4);
  });

  test('timeout validates malformed options', () {
    expect(
      () => ImagePipeline.fromRawPixels(raw()).timeout('fail'),
      throwsA(isA<OperationValidationException>()),
    );
    expect(
      () => ImagePipeline.fromRawPixels(
        raw(),
      ).timeout(<String, Object?>{'seconds': 'fail'}),
      throwsA(isA<OperationValidationException>()),
    );
    expect(
      () => ImagePipeline.fromRawPixels(
        raw(),
      ).timeout(<String, Object?>{'seconds': 3601}),
      throwsA(isA<OperationValidationException>()),
    );
    expect(
      () => ImagePipeline.fromRawPixels(
        raw(),
      ).timeout(const Duration(microseconds: -1)),
      throwsA(isA<OperationValidationException>()),
    );
  });
}
