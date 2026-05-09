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

  test('TIFF advanced parity options fail clearly when unsupported', () {
    final pipeline = ImagePipeline.fromRawPixels(_raw());

    for (final options in <TiffEncoderOptions>[
      const TiffEncoderOptions(bitDepth: 1),
      const TiffEncoderOptions(bitdepth: 4),
      const TiffEncoderOptions(bigTiff: true),
      const TiffEncoderOptions(bigtiff: true),
      const TiffEncoderOptions(predictor: TiffPredictor.none),
      const TiffEncoderOptions(tile: true),
      const TiffEncoderOptions(pyramid: true),
      const TiffEncoderOptions(tileWidth: 128),
      const TiffEncoderOptions(tileHeight: 128),
      const TiffEncoderOptions(miniswhite: true),
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
