import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

void main() {
  test('sniffs common image signatures', () {
    expect(
      sniffImageFormat(Uint8List.fromList(<int>[0xff, 0xd8, 0xff, 0x00])),
      ImageFormat.jpeg,
    );
    expect(
      sniffImageFormat(Uint8List.fromList(<int>[0x89, 0x50, 0x4e, 0x47, 0x00])),
      ImageFormat.png,
    );
    expect(
      sniffImageFormat(Uint8List.fromList('GIF89a'.codeUnits)),
      ImageFormat.gif,
    );
    expect(
      sniffImageFormat(Uint8List.fromList('II*\x00'.codeUnits)),
      ImageFormat.tiff,
    );
    expect(
      sniffImageFormat(Uint8List.fromList('RIFFxxxxWEBP'.codeUnits)),
      ImageFormat.webp,
    );
    expect(sniffImageFormat(Uint8List(0)), ImageFormat.unknown);
  });

  test('raw codec round trips pixels through pipeline', () async {
    final image = ImagePipeline.create(
      const CreateImage(
        width: 2,
        height: 1,
        channels: 4,
        background: RgbaColor(red: 10, green: 20, blue: 30, alpha: 40),
      ),
    );

    final output = await image.toBytesWithInfo();

    expect(output.info.format, ImageFormat.raw);
    expect(output.info.width, 2);
    expect(output.info.height, 1);
    expect(output.info.channels, 4);
    expect(output.bytes, <int>[10, 20, 30, 40, 10, 20, 30, 40]);
  });

  test('png codec encodes and decodes generated pixels', () async {
    final pipeline = ImagePipeline.create(
      const CreateImage(
        width: 1,
        height: 1,
        channels: 4,
        background: RgbaColor(red: 255, green: 0, blue: 0),
      ),
    );

    final encoded = await pipeline.toBytesWithInfo(format: ImageFormat.png);
    final decoded = await ImagePipeline.fromBytes(encoded.bytes).toPixelImage();

    expect(encoded.info.format, ImageFormat.png);
    expect(encoded.bytes.length, greaterThan(0));
    expect(decoded.width, 1);
    expect(decoded.height, 1);
    expect(decoded.firstFrameBytes().take(4), <int>[255, 0, 0, 255]);
  });

  test('png encoder compressionLevel changes the zlib stream', () async {
    final raw = RawPixels(
      bytes: Uint8List.fromList(<int>[
        for (var i = 0; i < 16; i += 1) ...[i * 8, 255 - i * 8, i * 4, 255],
      ]),
      width: 4,
      height: 4,
      channels: ChannelCount.four,
    );

    final stored = await ImagePipeline.fromRawPixels(
      raw,
    ).png(const PngEncoderOptions(compressionLevel: 0)).toBytes();
    final fixed = await ImagePipeline.fromRawPixels(
      raw,
    ).png(const PngEncoderOptions(compressionLevel: 6)).toBytes();

    expect(stored, isNot(fixed));
    expect(
      (await ImagePipeline.fromBytes(stored).toPixelImage()).firstFrameBytes(),
      raw.bytes,
    );
    expect(
      (await ImagePipeline.fromBytes(fixed).toPixelImage()).firstFrameBytes(),
      raw.bytes,
    );
  });

  test('jpeg codec encodes decodable bytes', () async {
    final encoded = await ImagePipeline.create(
      const CreateImage(
        width: 2,
        height: 2,
        channels: 3,
        background: RgbaColor.rgb(255, 255, 255),
      ),
    ).toBytesWithInfo(format: ImageFormat.jpeg);

    final decoded = await ImagePipeline.fromBytes(encoded.bytes).toPixelImage();

    expect(encoded.info.format, ImageFormat.jpeg);
    expect(sniffImageFormat(encoded.bytes), ImageFormat.jpeg);
    expect(decoded.width, 2);
    expect(decoded.height, 2);
    expect(decoded.firstFrameBytes().take(3), everyElement(greaterThan(230)));
  });

  test('jpeg encoder quality option changes encoded bytes', () async {
    final pixels = <int>[
      for (var y = 0; y < 8; y += 1)
        for (var x = 0; x < 8; x += 1) ...[x * 31, y * 31, (x + y) * 15],
    ];
    final raw = RawPixels(
      bytes: Uint8List.fromList(pixels),
      width: 8,
      height: 8,
      channels: ChannelCount.three,
    );

    final low = await ImagePipeline.fromRawPixels(
      raw,
    ).jpeg(const JpegEncoderOptions(quality: 20)).toBytes();
    final high = await ImagePipeline.fromRawPixels(
      raw,
    ).jpeg(const JpegEncoderOptions(quality: 90)).toBytes();

    expect(low, isNot(high));
    expect(sniffImageFormat(low), ImageFormat.jpeg);
    expect(sniffImageFormat(high), ImageFormat.jpeg);
  });

  test('gif codec encodes decodable bytes', () async {
    final encoded = await ImagePipeline.create(
      const CreateImage(
        width: 1,
        height: 1,
        channels: 4,
        background: RgbaColor(red: 0, green: 255, blue: 0),
      ),
    ).toBytesWithInfo(format: ImageFormat.gif);

    final decoded = await ImagePipeline.fromBytes(encoded.bytes).toPixelImage();

    expect(encoded.info.format, ImageFormat.gif);
    expect(decoded.width, 1);
    expect(decoded.height, 1);
  });

  test('tiff codec encodes decodable bytes', () async {
    final encoded = await ImagePipeline.create(
      const CreateImage(
        width: 1,
        height: 1,
        channels: 4,
        background: RgbaColor(red: 0, green: 0, blue: 255),
      ),
    ).toBytesWithInfo(format: ImageFormat.tiff);

    final decoded = await ImagePipeline.fromBytes(encoded.bytes).toPixelImage();

    expect(encoded.info.format, ImageFormat.tiff);
    expect(decoded.width, 1);
    expect(decoded.height, 1);
  });

  test('webp codec encodes decodable VP8L bytes', () async {
    final encoded = await ImagePipeline.create(
      const CreateImage(
        width: 2,
        height: 1,
        channels: 4,
        background: RgbaColor(red: 10, green: 20, blue: 30, alpha: 40),
      ),
    ).toBytesWithInfo(format: ImageFormat.webp);

    final decoded = await ImagePipeline.fromBytes(encoded.bytes).toPixelImage();

    expect(encoded.info.format, ImageFormat.webp);
    expect(sniffImageFormat(encoded.bytes), ImageFormat.webp);
    expect(decoded.width, 2);
    expect(decoded.height, 1);
    expect(decoded.firstFrameBytes(), <int>[10, 20, 30, 40, 10, 20, 30, 40]);
  });

  test('unsupported codecs fail with typed exceptions', () async {
    final registry = CodecRegistry.defaultRegistry();
    for (final format in <ImageFormat>[
      ImageFormat.avif,
      ImageFormat.heif,
      ImageFormat.jp2,
      ImageFormat.jxl,
      ImageFormat.svg,
      ImageFormat.pdf,
      ImageFormat.openSlide,
      ImageFormat.magick,
      ImageFormat.dcraw,
      ImageFormat.fits,
      ImageFormat.rad,
      ImageFormat.vips,
      ImageFormat.deepZoom,
    ]) {
      expect(
        () => registry.codecFor(format).decode(Uint8List.fromList(<int>[1])),
        throwsA(isA<UnsupportedCodecException>()),
      );
    }

    await expectLater(
      ImagePipeline.fromBytes(
        Uint8List.fromList(<int>[
          0,
          0,
          0,
          12,
          102,
          116,
          121,
          112,
          97,
          118,
          105,
          102,
        ]),
      ).toPixelImage(),
      throwsA(isA<UnsupportedCodecException>()),
    );
  });
}
