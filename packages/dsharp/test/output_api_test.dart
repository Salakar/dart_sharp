import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

import 'pipeline_test_helpers.dart';

void main() {
  RawPixels raw() => rawRgba(1, 1, <int>[1, 2, 3, 255]);

  test('toBytesWithInfo maps output fields and protects byte lists', () async {
    final animated = PixelImage(
      frames: <ImageFrame>[
        ImageFrame(pixels: raw(), delay: const Duration(milliseconds: 10)),
        ImageFrame(pixels: raw(), delay: const Duration(milliseconds: 20)),
      ],
      loopCount: 2,
    );
    final result = await ImagePipeline.fromPixelImage(
      animated,
    ).toImageBytesResult();
    final copy = result.bytes;
    copy[0] = 99;

    expect(result.bytes[0], 1);
    expect(result.info.format, ImageFormat.raw);
    expect(result.info.size, 4);
    expect(result.info.frames, 2);
    expect(result.info.loopCount, 2);
    expect(result.info.frameDelays, <Duration>[
      const Duration(milliseconds: 10),
      const Duration(milliseconds: 20),
    ]);
    expect(
      () => result.info.frameDelays.add(Duration.zero),
      throwsUnsupportedError,
    );
  });

  test('explicit and chained output formats do not reset each other', () async {
    final pipeline = ImagePipeline.fromRawPixels(raw()).png();
    final png = await pipeline.toBytesWithInfo();
    final rawOutput = await pipeline.toBytesWithInfo(format: ImageFormat.raw);
    final pngAgain = await pipeline.toBytesWithInfo();

    expect(png.info.format, ImageFormat.png);
    expect(rawOutput.info.format, ImageFormat.raw);
    expect(pngAgain.info.format, ImageFormat.png);
  });

  test('format-specific chain methods validate encoder options', () {
    expect(
      ImagePipeline.fromRawPixels(
        raw(),
      ).jpeg(const JpegEncoderOptions(quality: 0)).toBytes(),
      throwsA(isA<OperationValidationException>()),
    );
    expect(
      ImagePipeline.fromRawPixels(
        raw(),
      ).jpeg(const JpegEncoderOptions(chromaSubsampling: '4:2:2')).toBytes(),
      throwsA(isA<OperationValidationException>()),
    );
    expect(
      ImagePipeline.fromRawPixels(
        raw(),
      ).png(const PngEncoderOptions(compressionLevel: 10)).toBytes(),
      throwsA(isA<OperationValidationException>()),
    );
    expect(
      ImagePipeline.fromRawPixels(
        raw(),
      ).gif(const GifEncoderOptions(colors: 1)).toBytes(),
      throwsA(isA<OperationValidationException>()),
    );
    expect(
      ImagePipeline.fromRawPixels(
        raw(),
      ).webp(const WebpEncoderOptions(effort: 7)).toBytes(),
      throwsA(isA<OperationValidationException>()),
    );
  });

  test('unsupported encoder options fail only when selected', () async {
    expect(
      ImagePipeline.fromRawPixels(
        raw(),
      ).jpeg(const JpegEncoderOptions(progressive: true)).toBytes(),
      throwsA(isA<UnsupportedCodecException>()),
    );
    expect(
      ImagePipeline.fromRawPixels(
        raw(),
      ).png(const PngEncoderOptions(bitDepth: 16)).toBytes(),
      throwsA(isA<UnsupportedCodecException>()),
    );
    expect(
      ImagePipeline.fromRawPixels(raw())
          .tiff(const TiffEncoderOptions(compression: TiffCompression.lzw))
          .toBytes(),
      throwsA(isA<UnsupportedCodecException>()),
    );
    expect(
      ImagePipeline.fromRawPixels(
        raw(),
      ).tiff(const TiffEncoderOptions(tile: true)).toBytes(),
      throwsA(isA<UnsupportedCodecException>()),
    );
    expect(
      ImagePipeline.fromRawPixels(
        raw(),
      ).tiff(const TiffEncoderOptions(pyramid: true)).toBytes(),
      throwsA(isA<UnsupportedCodecException>()),
    );

    final pngBytes = await ImagePipeline.fromRawPixels(raw()).png().toBytes();
    final kept = await ImagePipeline.fromBytes(pngBytes)
        .jpeg(const JpegEncoderOptions(progressive: true, force: false))
        .toBytesWithInfo();

    expect(kept.info.format, ImageFormat.png);
  });

  test('force false keeps encoded input format when possible', () async {
    final pngBytes = await ImagePipeline.fromRawPixels(raw()).png().toBytes();
    final kept = await ImagePipeline.fromBytes(
      pngBytes,
    ).jpeg(const JpegEncoderOptions(force: false)).toBytesWithInfo();

    expect(kept.info.format, ImageFormat.png);
  });

  test('unsupported output format and metadata writes fail clearly', () {
    expect(
      ImagePipeline.fromRawPixels(
        raw(),
      ).webp(const WebpEncoderOptions(lossless: false)).toBytes(),
      throwsA(isA<UnsupportedCodecException>()),
    );
    expect(
      ImagePipeline.fromRawPixels(raw()).withMetadata().png().toBytes(),
      throwsA(isA<UnsupportedCodecException>()),
    );
    expect(
      ImagePipeline.fromRawPixels(
        raw(),
      ).withXmpMetadata(XmpMetadata.parse('<xmp />')).png().toBytes(),
      throwsA(isA<UnsupportedCodecException>()),
    );
  });

  test('cancellation token aborts cooperatively', () {
    final token = CancellationToken()..cancel();

    expect(
      ImagePipeline.fromRawPixels(raw()).withCancellationToken(token).toBytes(),
      throwsA(isA<ImageCancellationException>()),
    );
  });
}
