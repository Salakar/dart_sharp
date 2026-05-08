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

  test('jpeg encoder chromaSubsampling changes sampling factors', () async {
    final raw = RawPixels(
      bytes: Uint8List.fromList(<int>[
        for (var y = 0; y < 16; y += 1)
          for (var x = 0; x < 16; x += 1) ...[x * 16, y * 16, (x + y) * 8],
      ]),
      width: 16,
      height: 16,
      channels: ChannelCount.three,
    );

    final subsampled = await ImagePipeline.fromRawPixels(raw).jpeg().toBytes();
    final full = await ImagePipeline.fromRawPixels(
      raw,
    ).jpeg(const JpegEncoderOptions(chromaSubsampling: '4:4:4')).toBytes();

    expect(_jpegSofSampling(subsampled), <int>[0x22, 0x11, 0x11]);
    expect(_jpegSofSampling(full), <int>[0x11, 0x11, 0x11]);
    expect(
      (await ImagePipeline.fromBytes(subsampled).toPixelImage()).width,
      16,
    );
    expect((await ImagePipeline.fromBytes(full).toPixelImage()).height, 16);
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

  test('gif codec encodes animated frames', () async {
    final image = PixelImage(
      frames: <ImageFrame>[
        ImageFrame(
          pixels: RawPixels(
            bytes: Uint8List.fromList(<int>[255, 0, 0, 255]),
            width: 1,
            height: 1,
            channels: ChannelCount.four,
          ),
          delay: const Duration(milliseconds: 10),
        ),
        ImageFrame(
          pixels: RawPixels(
            bytes: Uint8List.fromList(<int>[0, 0, 255, 255]),
            width: 1,
            height: 1,
            channels: ChannelCount.four,
          ),
          delay: const Duration(milliseconds: 20),
        ),
      ],
      loopCount: 3,
    );

    final encoded = await ImagePipeline.fromPixelImage(
      image,
    ).gif().toBytesWithInfo();
    final decoded = await ImagePipeline.fromBytes(encoded.bytes).toPixelImage();

    expect(encoded.info.frames, 2);
    expect(encoded.info.loopCount, 3);
    expect(encoded.info.frameDelays, <Duration>[
      const Duration(milliseconds: 10),
      const Duration(milliseconds: 20),
    ]);
    expect(decoded.isAnimated, isTrue);
    expect(decoded.frames.length, 2);
    expect(decoded.loopCount, 3);
    expect(decoded.frames[0].delay, const Duration(milliseconds: 10));
    expect(decoded.frames[1].delay, const Duration(milliseconds: 20));
    expect(decoded.frames[0].pixels.bytes, <int>[255, 0, 0, 255]);
    expect(decoded.frames[1].pixels.bytes, <int>[0, 0, 255, 255]);
  });

  test('gif encoder removes duplicate frames unless kept', () async {
    RawPixels pixel(List<int> bytes) {
      return RawPixels(
        bytes: Uint8List.fromList(bytes),
        width: 1,
        height: 1,
        channels: ChannelCount.four,
      );
    }

    final image = PixelImage(
      frames: <ImageFrame>[
        ImageFrame(
          pixels: pixel(<int>[255, 0, 0, 255]),
          delay: const Duration(milliseconds: 10),
        ),
        ImageFrame(
          pixels: pixel(<int>[255, 0, 0, 255]),
          delay: const Duration(milliseconds: 20),
        ),
        ImageFrame(
          pixels: pixel(<int>[0, 0, 255, 255]),
          delay: const Duration(milliseconds: 30),
        ),
      ],
    );

    final compact = await ImagePipeline.fromPixelImage(image).gif().toBytes();
    final kept = await ImagePipeline.fromPixelImage(
      image,
    ).gif(const GifEncoderOptions(keepDuplicateFrames: true)).toBytes();

    final compactDecoded = await ImagePipeline.fromBytes(
      compact,
    ).toPixelImage();
    final keptDecoded = await ImagePipeline.fromBytes(kept).toPixelImage();

    expect(compactDecoded.frames.length, 2);
    expect(compactDecoded.frames[0].delay, const Duration(milliseconds: 30));
    expect(compactDecoded.frames[1].delay, const Duration(milliseconds: 30));
    expect(keptDecoded.frames.length, 3);
  });

  test('gif encoder progressive option writes interlaced frames', () async {
    final raw = RawPixels(
      bytes: Uint8List.fromList(<int>[
        for (var y = 0; y < 9; y += 1)
          for (var x = 0; x < 2; x += 1) ...[
            y * 24,
            x * 120,
            255 - y * 24,
            255,
          ],
      ]),
      width: 2,
      height: 9,
      channels: ChannelCount.four,
    );

    final encoded = await ImagePipeline.fromRawPixels(
      raw,
    ).gif(const GifEncoderOptions(progressive: true)).toBytes();
    final decoded = await ImagePipeline.fromBytes(encoded).toPixelImage();

    expect(_gifFirstImagePacked(encoded) & 0x40, 0x40);
    expect(decoded.firstFrameBytes(), raw.bytes);
  });

  test('gif encoder colors option limits palette size', () async {
    final raw = RawPixels(
      bytes: Uint8List.fromList(<int>[
        255,
        0,
        0,
        255,
        0,
        255,
        0,
        255,
        0,
        0,
        255,
        255,
        255,
        255,
        255,
        255,
      ]),
      width: 4,
      height: 1,
      channels: ChannelCount.four,
    );

    final encoded = await ImagePipeline.fromRawPixels(
      raw,
    ).gif(const GifEncoderOptions(colors: 2)).toBytes();
    final decoded = await ImagePipeline.fromBytes(encoded).toPixelImage();
    final rgba = decoded.firstFrameBytes();
    final colors = <String>{
      for (var i = 0; i < rgba.length; i += 4)
        '${rgba[i]},${rgba[i + 1]},${rgba[i + 2]},${rgba[i + 3]}',
    };

    expect(colors.length, lessThanOrEqualTo(2));
  });

  test('png encoder palette option writes indexed png', () async {
    final raw = RawPixels(
      bytes: Uint8List.fromList(<int>[
        255,
        0,
        0,
        255,
        0,
        255,
        0,
        255,
        0,
        0,
        255,
        255,
        255,
        255,
        255,
        255,
      ]),
      width: 4,
      height: 1,
      channels: ChannelCount.four,
    );

    final encoded = await ImagePipeline.fromRawPixels(
      raw,
    ).png(const PngEncoderOptions(palette: true)).toBytes();
    final decoded = await ImagePipeline.fromBytes(encoded).toPixelImage();

    expect(_pngColorType(encoded), 3);
    expect(_pngHasChunk(encoded, 'PLTE'), isTrue);
    expect(decoded.firstFrameBytes(), raw.bytes);
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

List<int> _jpegSofSampling(Uint8List bytes) {
  var offset = 2;
  while (offset + 4 <= bytes.length) {
    while (offset < bytes.length && bytes[offset] == 0xff) {
      offset += 1;
    }
    if (offset >= bytes.length) {
      break;
    }
    final marker = bytes[offset++];
    if (marker == 0xd9 || marker == 0xda) {
      break;
    }
    final length = (bytes[offset] << 8) | bytes[offset + 1];
    if (marker == 0xc0) {
      final dataStart = offset + 2;
      final count = bytes[dataStart + 5];
      final sampling = <int>[];
      var componentOffset = dataStart + 6;
      for (var i = 0; i < count; i += 1) {
        sampling.add(bytes[componentOffset + 1]);
        componentOffset += 3;
      }
      return sampling;
    }
    offset += length;
  }
  throw StateError('JPEG SOF0 segment not found.');
}

int _pngColorType(Uint8List bytes) => bytes[25];

bool _pngHasChunk(Uint8List bytes, String type) {
  var offset = 8;
  while (offset + 12 <= bytes.length) {
    final length =
        (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
    final chunkType = String.fromCharCodes(
      bytes.sublist(offset + 4, offset + 8),
    );
    if (chunkType == type) {
      return true;
    }
    offset += length + 12;
  }
  return false;
}

int _gifFirstImagePacked(Uint8List bytes) {
  var offset = 13;
  final packed = bytes[10];
  if ((packed & 0x80) != 0) {
    offset += 3 * (1 << ((packed & 0x07) + 1));
  }
  while (offset < bytes.length) {
    final marker = bytes[offset++];
    if (marker == 0x2c) {
      return bytes[offset + 8];
    }
    if (marker == 0x21) {
      offset += 1;
      while (offset < bytes.length) {
        final size = bytes[offset++];
        if (size == 0) {
          break;
        }
        offset += size;
      }
    }
  }
  throw StateError('GIF image descriptor not found.');
}
