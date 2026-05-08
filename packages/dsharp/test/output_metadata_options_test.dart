import 'dart:typed_data';

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

  test('withMetadata orientation writes EXIF orientation', () async {
    final outputs = <Uint8List>[
      await ImagePipeline.fromRawPixels(
        raw(),
      ).withMetadata(orientation: 6).jpeg().toBytes(),
      await ImagePipeline.fromRawPixels(
        raw(),
      ).withMetadata(orientation: 6).png().toBytes(),
      await ImagePipeline.fromRawPixels(
        raw(),
      ).withMetadata(orientation: 6).webp().toBytes(),
    ];

    for (final output in outputs) {
      final metadata = await ImagePipeline.fromBytes(output).metadata();
      expect(metadata.hasExif, isTrue);
      expect(metadata.orientation, 6);
    }
  });

  test(
    'withMetadata orientation overrides existing EXIF orientation',
    () async {
      final source = await ImagePipeline.fromRawPixels(
        raw(),
      ).withMetadata(orientation: 6).jpeg().toBytes();
      final output = await ImagePipeline.fromBytes(
        source,
      ).withMetadata(orientation: 3).png().toBytes();

      final metadata = await ImagePipeline.fromBytes(output).metadata();
      expect(metadata.hasExif, isTrue);
      expect(metadata.orientation, 3);
    },
  );

  test('withMetadata orientation validates numeric range', () {
    for (final orientation in <int>[0, -1, 9]) {
      expect(
        () => ImagePipeline.fromRawPixels(
          raw(),
        ).withMetadata(orientation: orientation),
        throwsA(isA<OperationValidationException>()),
      );
    }
  });

  test(
    'withMetadata orientation fails clearly for unsupported output formats',
    () {
      expect(
        ImagePipeline.fromRawPixels(
          raw(),
        ).withMetadata(orientation: 1).gif().toBytes(),
        throwsA(isA<UnsupportedCodecException>()),
      );
    },
  );
}
