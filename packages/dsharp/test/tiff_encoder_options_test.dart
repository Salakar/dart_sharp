import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:dsharp/src/codecs/binary_io.dart';
import 'package:test/test.dart';

void main() {
  test('TIFF defaults to JPEG compression like sharp', () async {
    final encoded = await ImagePipeline.fromRawPixels(
      _solidRaw(),
    ).tiff().toBytesWithInfo();

    expect(encoded.info.format, ImageFormat.tiff);
    expect(encoded.info.channels, 3);
    expect(_tiffShortTagValue(encoded.bytes, 259), 7);
  });

  test('TIFF encoder writes LZW and Deflate compression', () async {
    final raw = _raw();

    for (final entry in <(TiffCompression, int)>[
      (TiffCompression.lzw, 5),
      (TiffCompression.deflate, 8),
    ]) {
      final encoded = await ImagePipeline.fromRawPixels(
        raw,
      ).tiff(TiffEncoderOptions(compression: entry.$1)).toBytes();
      final decoded = await ImagePipeline.fromBytes(encoded).toPixelImage();

      expect(_tiffShortTagValue(encoded, 259), entry.$2);
      expect(decoded.firstFrameBytes(), raw.bytes);
    }
  });

  test('TIFF encoder writes resolution tags', () async {
    final encoded = await ImagePipeline.fromRawPixels(_raw())
        .tiff(
          const TiffEncoderOptions(
            compression: TiffCompression.none,
            xres: 2,
            yres: 3,
            resolutionUnit: TiffResolutionUnit.cm,
          ),
        )
        .toBytes();
    final metadata = await ImagePipeline.fromBytes(encoded).metadata();

    expect(_tiffShortTagValue(encoded, 296), 3);
    expect(_tiffRationalTagValue(encoded, 282), closeTo(20, 0.0001));
    expect(_tiffRationalTagValue(encoded, 283), closeTo(30, 0.0001));
    expect(metadata.density, closeTo(50.8, 0.0001));
  });

  test('TIFF encoder writes one-channel grayscale output', () async {
    final raw = _grayOneRaw(<int>[0, 85, 170, 255]);
    final encoded = await ImagePipeline.fromRawPixels(raw)
        .tiff(
          const TiffEncoderOptions(
            compression: TiffCompression.none,
            predictor: TiffPredictor.none,
          ),
        )
        .toBytesWithInfo();
    final decoded = await ImagePipeline.fromBytes(encoded.bytes).toPixelImage();

    expect(encoded.info.channels, 1);
    expect(_tiffShortTagValue(encoded.bytes, 258), 8);
    expect(_tiffShortTagValue(encoded.bytes, 262), 1);
    expect(_tiffShortTagValue(encoded.bytes, 277), 1);
    expect(decoded.firstFrameBytes(), _grayRgba(<int>[0, 85, 170, 255]));
  });

  test('TIFF encoder writes predictor tags for LZW output', () async {
    final raw = _raw();
    final horizontal = await ImagePipeline.fromRawPixels(raw)
        .tiff(const TiffEncoderOptions(compression: TiffCompression.lzw))
        .toBytes();
    final none = await ImagePipeline.fromRawPixels(raw)
        .tiff(
          const TiffEncoderOptions(
            compression: TiffCompression.lzw,
            predictor: TiffPredictor.none,
          ),
        )
        .toBytes();

    expect(_tiffShortTagValue(horizontal, 317), 2);
    expect(_tiffShortTagValue(none, 317), 1);
    expect(
      (await ImagePipeline.fromBytes(
        horizontal,
      ).toPixelImage()).firstFrameBytes(),
      raw.bytes,
    );
    expect(
      (await ImagePipeline.fromBytes(none).toPixelImage()).firstFrameBytes(),
      raw.bytes,
    );
    expect(horizontal, isNot(none));
  });

  test('TIFF accepts inert tile sizing and miniswhite options', () async {
    final raw = _raw();
    final encoded = await ImagePipeline.fromRawPixels(raw)
        .tiff(
          const TiffEncoderOptions(
            compression: TiffCompression.none,
            tileWidth: 512,
            tileHeight: 512,
            miniswhite: true,
          ),
        )
        .toBytes();
    final decoded = await ImagePipeline.fromBytes(encoded).toPixelImage();

    expect(_tiffShortTagValue(encoded, 259), 1);
    expect(_tiffShortTagValue(encoded, 262), 2);
    expect(decoded.firstFrameBytes(), raw.bytes);
  });

  test('TIFF encoder writes alpha extra sample tag', () async {
    final raw = _raw();
    final encoded = await ImagePipeline.fromRawPixels(raw)
        .tiff(const TiffEncoderOptions(compression: TiffCompression.none))
        .toBytes();
    final decoded = await ImagePipeline.fromBytes(encoded).toPixelImage();

    expect(_tiffShortTagValue(encoded, 277), 4);
    expect(_tiffShortTagValue(encoded, 338), 2);
    expect(decoded.firstFrameBytes(), raw.bytes);
  });

  test('TIFF encoder writes low-bit grayscale output', () async {
    for (final entry in <(int, RawPixels)>[
      (1, _grayRaw(<int>[0, 255, 0, 255])),
      (2, _grayRaw(<int>[0, 85, 170, 255])),
      (4, _grayRaw(<int>[0, 17, 170, 255])),
    ]) {
      final encoded = await ImagePipeline.fromRawPixels(entry.$2)
          .tiff(
            TiffEncoderOptions(
              compression: TiffCompression.none,
              bitDepth: entry.$1,
              predictor: TiffPredictor.none,
            ),
          )
          .toBytesWithInfo();
      final decoded = await ImagePipeline.fromBytes(
        encoded.bytes,
      ).toPixelImage();

      expect(encoded.info.channels, 1);
      expect(_tiffShortTagValue(encoded.bytes, 258), entry.$1);
      expect(_tiffShortTagValue(encoded.bytes, 262), 1);
      expect(_tiffShortTagValue(encoded.bytes, 277), 1);
      expect(decoded.firstFrameBytes(), entry.$2.bytes);
    }
  });

  test('TIFF encoder writes miniswhite low-bit grayscale output', () async {
    final raw = _grayRaw(<int>[0, 255, 0, 255]);
    final encoded = await ImagePipeline.fromRawPixels(raw)
        .tiff(
          const TiffEncoderOptions(
            compression: TiffCompression.none,
            bitDepth: 1,
            miniswhite: true,
            predictor: TiffPredictor.none,
          ),
        )
        .toBytes();
    final decoded = await ImagePipeline.fromBytes(encoded).toPixelImage();

    expect(_tiffShortTagValue(encoded, 258), 1);
    expect(_tiffShortTagValue(encoded, 262), 0);
    expect(decoded.firstFrameBytes(), raw.bytes);
  });

  test('TIFF low-bit grayscale output works with compression', () async {
    final raw = _grayRaw(<int>[0, 85, 170, 255]);
    final encoded = await ImagePipeline.fromRawPixels(raw)
        .tiff(
          const TiffEncoderOptions(
            compression: TiffCompression.lzw,
            bitDepth: 2,
          ),
        )
        .toBytes();
    final decoded = await ImagePipeline.fromBytes(encoded).toPixelImage();

    expect(_tiffShortTagValue(encoded, 258), 2);
    expect(_tiffShortTagValue(encoded, 259), 5);
    expect(decoded.firstFrameBytes(), raw.bytes);
  });

  test('TIFF advanced parity options fail clearly when unsupported', () {
    final pipeline = ImagePipeline.fromRawPixels(_raw());

    for (final options in <TiffEncoderOptions>[
      const TiffEncoderOptions(bitDepth: 1),
      const TiffEncoderOptions(bitdepth: 4),
      const TiffEncoderOptions(bigTiff: true),
      const TiffEncoderOptions(bigtiff: true),
      const TiffEncoderOptions(predictor: TiffPredictor.float),
      const TiffEncoderOptions(tile: true),
      const TiffEncoderOptions(pyramid: true),
      const TiffEncoderOptions(compression: TiffCompression.ccittFax4),
      const TiffEncoderOptions(compression: TiffCompression.webp),
      const TiffEncoderOptions(compression: TiffCompression.zstd),
      const TiffEncoderOptions(compression: TiffCompression.jp2k),
      const TiffEncoderOptions(
        compression: TiffCompression.deflate,
        quality: 90,
      ),
    ]) {
      expect(
        pipeline.tiff(options).toBytes(),
        throwsA(isA<UnsupportedCodecException>()),
      );
    }

    for (final options in <TiffEncoderOptions>[
      const TiffEncoderOptions(bitDepth: 16),
      const TiffEncoderOptions(tileWidth: 0),
      const TiffEncoderOptions(tileHeight: 0),
      const TiffEncoderOptions(xres: 0),
      const TiffEncoderOptions(yres: 0),
    ]) {
      expect(
        pipeline.tiff(options).toBytes(),
        throwsA(isA<OperationValidationException>()),
      );
    }
  });

  test('TIFF encoder writes JPEG compression', () async {
    final raw = _solidRaw();
    final encoded = await ImagePipeline.fromRawPixels(raw)
        .tiff(
          const TiffEncoderOptions(
            compression: TiffCompression.jpeg,
            quality: 100,
          ),
        )
        .toBytesWithInfo();
    final decoded = await ImagePipeline.fromBytes(encoded.bytes).toPixelImage();
    final rgba = decoded.firstFrameBytes();

    expect(encoded.info.format, ImageFormat.tiff);
    expect(encoded.info.channels, 3);
    expect(_tiffShortTagValue(encoded.bytes, 259), 7);
    expect(_tiffShortTagValue(encoded.bytes, 262), 6);
    expect(decoded.width, raw.width);
    expect(decoded.height, raw.height);
    for (var offset = 0; offset < rgba.length; offset += 4) {
      expect(rgba[offset], closeTo(90, 2));
      expect(rgba[offset + 1], closeTo(120, 2));
      expect(rgba[offset + 2], closeTo(150, 2));
      expect(rgba[offset + 3], 255);
    }
  });
}

RawPixels _raw() {
  return RawPixels(
    bytes: Uint8List.fromList(<int>[
      for (final rgba in <List<int>>[
        <int>[0, 10, 20, 255],
        <int>[40, 50, 60, 255],
        <int>[80, 90, 100, 255],
        <int>[120, 130, 140, 255],
      ])
        ...rgba,
    ]),
    width: 4,
    height: 1,
    channels: ChannelCount.four,
  );
}

RawPixels _solidRaw() {
  return RawPixels(
    bytes: Uint8List.fromList(<int>[
      for (var i = 0; i < 16; i += 1) ...<int>[90, 120, 150, 255],
    ]),
    width: 4,
    height: 4,
    channels: ChannelCount.four,
  );
}

RawPixels _grayRaw(List<int> values) {
  return RawPixels(
    bytes: Uint8List.fromList(<int>[
      for (final value in values) ...<int>[value, value, value, 255],
    ]),
    width: values.length,
    height: 1,
    channels: ChannelCount.four,
  );
}

RawPixels _grayOneRaw(List<int> values) {
  return RawPixels(
    bytes: Uint8List.fromList(values),
    width: values.length,
    height: 1,
    channels: ChannelCount.one,
  );
}

List<int> _grayRgba(List<int> values) {
  return <int>[
    for (final value in values) ...<int>[value, value, value, 255],
  ];
}

int _tiffShortTagValue(Uint8List bytes, int tag) {
  final ifdOffset = readUint32Le(bytes, 4);
  final count = readUint16Le(bytes, ifdOffset);
  for (var i = 0; i < count; i += 1) {
    final entry = ifdOffset + 2 + i * 12;
    if (readUint16Le(bytes, entry) == tag) {
      return readUint16Le(bytes, entry + 8);
    }
  }
  throw StateError('Missing TIFF tag $tag.');
}

double _tiffRationalTagValue(Uint8List bytes, int tag) {
  final ifdOffset = readUint32Le(bytes, 4);
  final count = readUint16Le(bytes, ifdOffset);
  for (var i = 0; i < count; i += 1) {
    final entry = ifdOffset + 2 + i * 12;
    if (readUint16Le(bytes, entry) == tag) {
      final valueOffset = readUint32Le(bytes, entry + 8);
      final numerator = readUint32Le(bytes, valueOffset);
      final denominator = readUint32Le(bytes, valueOffset + 4);
      return numerator / denominator;
    }
  }
  throw StateError('Missing TIFF tag $tag.');
}
