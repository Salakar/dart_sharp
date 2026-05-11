import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

import 'pipeline_test_helpers.dart';

void main() {
  RawPixels raw() => rawRgba(1, 1, <int>[1, 2, 3, 255]);

  test('toFormat accepts sharp-style format strings and id maps', () async {
    final png = await ImagePipeline.fromRawPixels(
      raw(),
    ).toFormat('PNG').toBytesWithInfo();
    final jpeg = await ImagePipeline.fromRawPixels(
      raw(),
    ).toFormat('jpg').toBytesWithInfo();
    final tiff = await ImagePipeline.fromRawPixels(
      raw(),
    ).toFormat(<String, Object?>{'id': 'tif'}).toBytesWithInfo();

    expect(png.info.format, ImageFormat.png);
    expect(jpeg.info.format, ImageFormat.jpeg);
    expect(tiff.info.format, ImageFormat.tiff);
    expect(ImageFormat.fromId('openexr'), ImageFormat.exr);
  });

  test('toFormat accepts exported format support objects', () async {
    final support = ImagePipeline.fromRawPixels(
      raw(),
    ).capabilities.supportFor(ImageFormat.webp);
    final webp = await ImagePipeline.fromRawPixels(
      raw(),
    ).toFormat(support).toBytesWithInfo();

    expect(webp.info.format, ImageFormat.webp);
  });

  test('toFormat validates unsupported and malformed format arguments', () {
    expect(
      () => ImagePipeline.fromRawPixels(raw()).toFormat('zoinks'),
      throwsA(isA<OperationValidationException>()),
    );
    expect(
      () => ImagePipeline.fromRawPixels(
        raw(),
      ).toFormat(<String, Object?>{'format': 'png'}),
      throwsA(isA<OperationValidationException>()),
    );
    expect(
      () => ImagePipeline.fromRawPixels(raw()).toFormat(42),
      throwsA(isA<OperationValidationException>()),
    );
    expect(
      () => ImagePipeline.fromRawPixels(
        raw(),
      ).toFormat('png', options: const JpegEncoderOptions()),
      throwsA(isA<OperationValidationException>()),
    );
  });

  test('unsupported output helpers fail with typed format errors', () async {
    final cases = <({ImageFormat format, ImagePipeline pipeline})>[
      (
        format: ImageFormat.jp2,
        pipeline: ImagePipeline.fromRawPixels(raw()).jp2(),
      ),
      (
        format: ImageFormat.avif,
        pipeline: ImagePipeline.fromRawPixels(raw()).avif(),
      ),
      (
        format: ImageFormat.heif,
        pipeline: ImagePipeline.fromRawPixels(raw()).heif(),
      ),
      (
        format: ImageFormat.jxl,
        pipeline: ImagePipeline.fromRawPixels(raw()).jxl(),
      ),
      (
        format: ImageFormat.deepZoom,
        pipeline: ImagePipeline.fromRawPixels(raw()).tile(),
      ),
    ];

    for (final entry in cases) {
      await expectLater(
        entry.pipeline.toBytes(),
        throwsA(
          isA<UnsupportedCodecException>().having(
            (error) => error.message,
            'message',
            contains('${entry.format.id} encode is unsupported'),
          ),
        ),
        reason: entry.format.id,
      );
    }
  });
}
