import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

import 'pipeline_test_helpers.dart';

void main() {
  RawPixels raw() => rawRgba(1, 1, <int>[1, 2, 3, 255]);

  test('withMetadata density writes JPEG and PNG output density', () async {
    final jpeg = await ImagePipeline.fromRawPixels(
      raw(),
    ).withMetadata(density: 300).jpeg().toBytes();
    final png = await ImagePipeline.fromRawPixels(
      raw(),
    ).withMetadata(density: 96).png().toBytes();

    final jpegMetadata = await ImagePipeline.fromBytes(jpeg).metadata();
    final pngMetadata = await ImagePipeline.fromBytes(png).metadata();

    expect(jpegMetadata.density, 300);
    expect(pngMetadata.density, closeTo(96, 0.05));
  });

  test('withMetadata density validates numeric range', () {
    for (final density in <num>[0, -1, double.nan, double.infinity]) {
      expect(
        () => ImagePipeline.fromRawPixels(raw()).withMetadata(density: density),
        throwsA(isA<OperationValidationException>()),
      );
    }
  });

  test('withMetadata density fails clearly for unsupported output formats', () {
    expect(
      ImagePipeline.fromRawPixels(
        raw(),
      ).withMetadata(density: 72).webp().toBytes(),
      throwsA(isA<UnsupportedCodecException>()),
    );
    expect(
      ImagePipeline.fromRawPixels(
        raw(),
      ).withMetadata(density: 72).gif().toBytes(),
      throwsA(isA<UnsupportedCodecException>()),
    );
  });
}
