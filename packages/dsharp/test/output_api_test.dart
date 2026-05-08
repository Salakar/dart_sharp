import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:dsharp/src/codecs/binary_io.dart';
import 'package:dsharp/src/codecs/deflate_codec.dart';
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
      ).png(const PngEncoderOptions(bitDepth: 16)).toBytes(),
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

  test('writes explicit XMP metadata to JPEG, PNG, and WebP output', () async {
    final xmp = XmpMetadata.parse('<xmp><title>Test</title></xmp>');
    final jpeg = await ImagePipeline.fromRawPixels(
      raw(),
    ).withXmpMetadata(xmp).jpeg().toBytesWithInfo();
    final png = await ImagePipeline.fromRawPixels(
      raw(),
    ).withXmpMetadata(xmp).png().toBytesWithInfo();
    final webp = await ImagePipeline.fromRawPixels(
      raw(),
    ).withXmpMetadata(xmp).webp().toBytesWithInfo();
    final jpegMetadata = await ImagePipeline.fromBytes(jpeg.bytes).metadata();
    final pngMetadata = await ImagePipeline.fromBytes(png.bytes).metadata();
    final webpMetadata = await ImagePipeline.fromBytes(webp.bytes).metadata();

    expect(jpeg.info.format, ImageFormat.jpeg);
    expect(jpeg.info.size, jpeg.bytes.length);
    expect(jpegMetadata.hasXmp, isTrue);
    expect(png.info.format, ImageFormat.png);
    expect(png.info.size, png.bytes.length);
    expect(pngMetadata.hasXmp, isTrue);
    expect(webp.info.format, ImageFormat.webp);
    expect(webp.info.size, webp.bytes.length);
    expect(webpMetadata.width, 1);
    expect(webpMetadata.height, 1);
    expect(webpMetadata.hasXmp, isTrue);
  });

  test('keeps XMP metadata across supported encoded outputs', () async {
    final xmp = XmpMetadata.parse('<xmp><title>Kept</title></xmp>');
    final jpegSource = await ImagePipeline.fromRawPixels(
      raw(),
    ).withXmpMetadata(xmp).jpeg().toBytes();
    final pngSource = await ImagePipeline.fromRawPixels(
      raw(),
    ).withXmpMetadata(xmp).png().toBytes();
    final webpSource = await ImagePipeline.fromRawPixels(
      raw(),
    ).withXmpMetadata(xmp).webp().toBytes();

    final keptWebp = await ImagePipeline.fromBytes(
      jpegSource,
    ).keepXmp().webp().toBytes();
    final keptJpeg = await ImagePipeline.fromBytes(
      pngSource,
    ).keepXmp().jpeg().toBytes();
    final keptPng = await ImagePipeline.fromBytes(
      webpSource,
    ).keepXmp().png().toBytes();

    expect((await ImagePipeline.fromBytes(keptWebp).metadata()).hasXmp, isTrue);
    expect((await ImagePipeline.fromBytes(keptJpeg).metadata()).hasXmp, isTrue);
    expect((await ImagePipeline.fromBytes(keptPng).metadata()).hasXmp, isTrue);
  });

  test('keeps EXIF metadata across supported encoded outputs', () async {
    final jpegSource = _withJpegExif(
      await ImagePipeline.fromRawPixels(raw()).jpeg().toBytes(),
    );
    final pngSource = _withPngExif(
      await ImagePipeline.fromRawPixels(raw()).png().toBytes(),
    );
    final webpSource = _withWebpExif(
      await ImagePipeline.fromRawPixels(raw()).webp().toBytes(),
      width: 1,
      height: 1,
    );

    final keptWebp = await ImagePipeline.fromBytes(
      jpegSource,
    ).keepExif().webp().toBytes();
    final keptJpeg = await ImagePipeline.fromBytes(
      pngSource,
    ).keepExif().jpeg().toBytes();
    final keptPng = await ImagePipeline.fromBytes(
      webpSource,
    ).keepExif().png().toBytes();

    final webpMetadata = await ImagePipeline.fromBytes(keptWebp).metadata();
    final jpegMetadata = await ImagePipeline.fromBytes(keptJpeg).metadata();
    final pngMetadata = await ImagePipeline.fromBytes(keptPng).metadata();
    expect(webpMetadata.hasExif, isTrue);
    expect(webpMetadata.orientation, 6);
    expect(jpegMetadata.hasExif, isTrue);
    expect(jpegMetadata.orientation, 6);
    expect(pngMetadata.hasExif, isTrue);
    expect(pngMetadata.orientation, 6);
  });

  test('keeps ICC profiles across supported encoded outputs', () async {
    final profile = Uint8List.fromList(<int>[1, 3, 3, 7, 9, 11]);
    final jpegSource = _withJpegIcc(
      await ImagePipeline.fromRawPixels(raw()).jpeg().toBytes(),
      profile,
    );
    final pngSource = _withPngIcc(
      await ImagePipeline.fromRawPixels(raw()).png().toBytes(),
      profile,
    );
    final webpSource = _withWebpIcc(
      await ImagePipeline.fromRawPixels(raw()).webp().toBytes(),
      profile,
      width: 1,
      height: 1,
    );

    final keptWebp = await ImagePipeline.fromBytes(
      jpegSource,
    ).keepIccProfile().webp().toBytes();
    final keptJpeg = await ImagePipeline.fromBytes(
      pngSource,
    ).keepIccProfile().jpeg().toBytes();
    final keptPng = await ImagePipeline.fromBytes(
      webpSource,
    ).keepIccProfile().png().toBytes();

    expect(
      (await ImagePipeline.fromBytes(keptWebp).metadata()).hasProfile,
      isTrue,
    );
    expect(
      (await ImagePipeline.fromBytes(keptJpeg).metadata()).hasProfile,
      isTrue,
    );
    expect(
      (await ImagePipeline.fromBytes(keptPng).metadata()).hasProfile,
      isTrue,
    );
    expect(_webpChunk(keptWebp, 'ICCP'), profile);
    expect(_jpegIccProfile(keptJpeg), profile);
    expect(_pngIccProfile(keptPng), profile);
  });

  test(
    'withMetadata keeps supported metadata across encoded outputs',
    () async {
      final xmp = XmpMetadata.parse('<xmp><title>All</title></xmp>');
      final profile = Uint8List.fromList(<int>[2, 4, 6, 8]);
      final jpegSource = _withJpegIcc(
        _withJpegExif(
          await ImagePipeline.fromRawPixels(
            raw(),
          ).withXmpMetadata(xmp).jpeg().toBytes(),
        ),
        profile,
      );
      final pngSource = _withPngIcc(
        _withPngExif(
          await ImagePipeline.fromRawPixels(
            raw(),
          ).withXmpMetadata(xmp).png().toBytes(),
        ),
        profile,
      );
      final webpSource = _withWebpMetadata(
        await ImagePipeline.fromRawPixels(raw()).webp().toBytes(),
        profile: profile,
        exif: _exifTiffOrientation(6),
        xmp: xmp.xmlText,
        width: 1,
        height: 1,
      );

      final keptWebp = await ImagePipeline.fromBytes(
        jpegSource,
      ).withMetadata().webp().toBytes();
      final keptJpeg = await ImagePipeline.fromBytes(
        pngSource,
      ).withMetadata().jpeg().toBytes();
      final keptPng = await ImagePipeline.fromBytes(
        webpSource,
      ).withMetadata().png().toBytes();

      for (final bytes in <Uint8List>[keptWebp, keptJpeg, keptPng]) {
        final metadata = await ImagePipeline.fromBytes(bytes).metadata();
        expect(metadata.hasProfile, isTrue);
        expect(metadata.hasExif, isTrue);
        expect(metadata.hasXmp, isTrue);
        expect(metadata.orientation, 6);
      }
      expect(_webpChunk(keptWebp, 'ICCP'), profile);
      expect(_jpegIccProfile(keptJpeg), profile);
      expect(_pngIccProfile(keptPng), profile);
    },
  );

  test('unsupported output format and metadata writes fail clearly', () async {
    expect(
      ImagePipeline.fromRawPixels(
        raw(),
      ).webp(const WebpEncoderOptions(lossless: false)).toBytes(),
      throwsA(isA<UnsupportedCodecException>()),
    );
    expect(
      ImagePipeline.fromRawPixels(
        raw(),
      ).withXmpMetadata(XmpMetadata.parse('<xmp />')).gif().toBytes(),
      throwsA(isA<UnsupportedCodecException>()),
    );
    final jpegWithXmp = await ImagePipeline.fromRawPixels(
      raw(),
    ).withXmpMetadata(XmpMetadata.parse('<xmp />')).jpeg().toBytes();
    await expectLater(
      ImagePipeline.fromBytes(jpegWithXmp).keepXmp().gif().toBytes(),
      throwsA(isA<UnsupportedCodecException>()),
    );
    final jpegWithExif = _withJpegExif(
      await ImagePipeline.fromRawPixels(raw()).jpeg().toBytes(),
    );
    await expectLater(
      ImagePipeline.fromBytes(jpegWithExif).keepExif().gif().toBytes(),
      throwsA(isA<UnsupportedCodecException>()),
    );
    final jpegWithIcc = _withJpegIcc(
      await ImagePipeline.fromRawPixels(raw()).jpeg().toBytes(),
      Uint8List.fromList(<int>[1, 2, 3]),
    );
    await expectLater(
      ImagePipeline.fromBytes(jpegWithIcc).keepIccProfile().gif().toBytes(),
      throwsA(isA<UnsupportedCodecException>()),
    );
    final jpegWithMetadata = _withJpegIcc(
      _withJpegExif(
        await ImagePipeline.fromRawPixels(
          raw(),
        ).withXmpMetadata(XmpMetadata.parse('<xmp />')).jpeg().toBytes(),
      ),
      Uint8List.fromList(<int>[1, 2, 3]),
    );
    await expectLater(
      ImagePipeline.fromBytes(jpegWithMetadata).withMetadata().gif().toBytes(),
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

Uint8List _withJpegExif(Uint8List jpeg) {
  final writer = ByteWriter()
    ..writeByte(0xff)
    ..writeByte(0xd8);
  _jpegSegment(writer, 0xe1, <int>[
    ...<int>[0x45, 0x78, 0x69, 0x66, 0, 0],
    ..._exifTiffOrientation(6),
  ]);
  writer.writeBytes(jpeg.sublist(2));
  return writer.toBytes();
}

Uint8List _withJpegIcc(Uint8List jpeg, Uint8List profile) {
  final writer = ByteWriter()
    ..writeByte(0xff)
    ..writeByte(0xd8);
  _jpegSegment(writer, 0xe2, <int>[
    ...'ICC_PROFILE'.codeUnits,
    0,
    1,
    1,
    ...profile,
  ]);
  writer.writeBytes(jpeg.sublist(2));
  return writer.toBytes();
}

Uint8List _withPngExif(Uint8List png) {
  final writer = ByteWriter()..writeBytes(png.sublist(0, 8));
  var offset = 8;
  var inserted = false;
  while (offset + 12 <= png.length) {
    final length = readUint32Be(png, offset);
    final type = String.fromCharCodes(png.sublist(offset + 4, offset + 8));
    final dataStart = offset + 8;
    final dataEnd = dataStart + length;
    final chunkEnd = dataEnd + 4;
    if (type == 'IDAT' && !inserted) {
      _pngChunk(writer, 'eXIf', _exifTiffOrientation(6));
      inserted = true;
    }
    writer.writeBytes(png.sublist(offset, chunkEnd));
    offset = chunkEnd;
  }
  return writer.toBytes();
}

Uint8List _withPngIcc(Uint8List png, Uint8List profile) {
  final writer = ByteWriter()..writeBytes(png.sublist(0, 8));
  var offset = 8;
  var inserted = false;
  while (offset + 12 <= png.length) {
    final length = readUint32Be(png, offset);
    final type = String.fromCharCodes(png.sublist(offset + 4, offset + 8));
    final dataStart = offset + 8;
    final dataEnd = dataStart + length;
    final chunkEnd = dataEnd + 4;
    if (type == 'IDAT' && !inserted) {
      _pngChunk(
        writer,
        'iCCP',
        Uint8List.fromList(<int>[
          ...'test'.codeUnits,
          0,
          0,
          ...zlibEncodeStored(profile),
        ]),
      );
      inserted = true;
    }
    writer.writeBytes(png.sublist(offset, chunkEnd));
    offset = chunkEnd;
  }
  return writer.toBytes();
}

Uint8List _withWebpExif(
  Uint8List webp, {
  required int width,
  required int height,
}) {
  final content = ByteWriter()
    ..writeAscii('WEBP')
    ..writeAscii('VP8X')
    ..writeUint32Le(10)
    ..writeByte(0x08)
    ..writeByte(0)
    ..writeByte(0)
    ..writeByte(0);
  _writeUint24Le(content, width - 1);
  _writeUint24Le(content, height - 1);
  _riffChunk(content, 'EXIF', _exifTiffOrientation(6));
  _riffChunk(content, 'VP8L', _webpChunk(webp, 'VP8L'));
  final writer = ByteWriter()
    ..writeAscii('RIFF')
    ..writeUint32Le(content.length)
    ..writeBytes(content.toBytes());
  return writer.toBytes();
}

Uint8List _withWebpIcc(
  Uint8List webp,
  Uint8List profile, {
  required int width,
  required int height,
}) {
  final content = ByteWriter()
    ..writeAscii('WEBP')
    ..writeAscii('VP8X')
    ..writeUint32Le(10)
    ..writeByte(0x20)
    ..writeByte(0)
    ..writeByte(0)
    ..writeByte(0);
  _writeUint24Le(content, width - 1);
  _writeUint24Le(content, height - 1);
  _riffChunk(content, 'ICCP', profile);
  _riffChunk(content, 'VP8L', _webpChunk(webp, 'VP8L'));
  final writer = ByteWriter()
    ..writeAscii('RIFF')
    ..writeUint32Le(content.length)
    ..writeBytes(content.toBytes());
  return writer.toBytes();
}

Uint8List _withWebpMetadata(
  Uint8List webp, {
  required Uint8List profile,
  required Uint8List exif,
  required String xmp,
  required int width,
  required int height,
}) {
  final content = ByteWriter()
    ..writeAscii('WEBP')
    ..writeAscii('VP8X')
    ..writeUint32Le(10)
    ..writeByte(0x2c)
    ..writeByte(0)
    ..writeByte(0)
    ..writeByte(0);
  _writeUint24Le(content, width - 1);
  _writeUint24Le(content, height - 1);
  _riffChunk(content, 'ICCP', profile);
  _riffChunk(content, 'EXIF', exif);
  _riffChunk(content, 'XMP ', xmp.codeUnits);
  _riffChunk(content, 'VP8L', _webpChunk(webp, 'VP8L'));
  final writer = ByteWriter()
    ..writeAscii('RIFF')
    ..writeUint32Le(content.length)
    ..writeBytes(content.toBytes());
  return writer.toBytes();
}

Uint8List? _jpegIccProfile(Uint8List jpeg) {
  var offset = 2;
  while (offset + 4 <= jpeg.length) {
    if (jpeg[offset] != 0xff) {
      return null;
    }
    while (offset < jpeg.length && jpeg[offset] == 0xff) {
      offset += 1;
    }
    if (offset >= jpeg.length) {
      return null;
    }
    final marker = jpeg[offset];
    offset += 1;
    if (marker == 0xda || marker == 0xd9) {
      return null;
    }
    final length = readUint16Be(jpeg, offset);
    final end = offset + length;
    final data = jpeg.sublist(offset + 2, end);
    if (marker == 0xe2 &&
        data.length >= 14 &&
        String.fromCharCodes(data.sublist(0, 11)) == 'ICC_PROFILE') {
      return data.sublist(14);
    }
    offset = end;
  }
  return null;
}

Uint8List? _pngIccProfile(Uint8List png) {
  var offset = 8;
  while (offset + 12 <= png.length) {
    final length = readUint32Be(png, offset);
    final type = String.fromCharCodes(png.sublist(offset + 4, offset + 8));
    final dataStart = offset + 8;
    final dataEnd = dataStart + length;
    final data = png.sublist(dataStart, dataEnd);
    if (type == 'iCCP') {
      var method = 0;
      while (method < data.length && data[method] != 0) {
        method += 1;
      }
      if (method + 1 >= data.length || data[method + 1] != 0) {
        return null;
      }
      return zlibDecode(data.sublist(method + 2));
    }
    offset = dataEnd + 4;
  }
  return null;
}

Uint8List _webpChunk(Uint8List bytes, String target) {
  var offset = 12;
  while (offset + 8 <= bytes.length) {
    final type = String.fromCharCodes(bytes.sublist(offset, offset + 4));
    final length = readUint32Le(bytes, offset + 4);
    final start = offset + 8;
    final end = start + length;
    if (type == target) {
      return bytes.sublist(start, end);
    }
    offset = end + (length.isOdd ? 1 : 0);
  }
  throw StateError('Missing $target chunk.');
}

void _riffChunk(ByteWriter writer, String type, Iterable<int> data) {
  final payload = Uint8List.fromList(List<int>.from(data));
  writer
    ..writeAscii(type)
    ..writeUint32Le(payload.length)
    ..writeBytes(payload);
  if (payload.length.isOdd) {
    writer.writeByte(0);
  }
}

void _pngChunk(ByteWriter writer, String type, Uint8List data) {
  final typeBytes = type.codeUnits;
  writer
    ..writeUint32Be(data.length)
    ..writeBytes(typeBytes)
    ..writeBytes(data)
    ..writeUint32Be(crc32(<int>[...typeBytes, ...data]));
}

void _jpegSegment(ByteWriter writer, int marker, List<int> data) {
  writer
    ..writeByte(0xff)
    ..writeByte(marker)
    ..writeUint16Be(data.length + 2)
    ..writeBytes(data);
}

void _writeUint24Le(ByteWriter writer, int value) {
  writer
    ..writeByte(value)
    ..writeByte(value >> 8)
    ..writeByte(value >> 16);
}

Uint8List _exifTiffOrientation(int orientation) {
  final writer = ByteWriter()
    ..writeAscii('II')
    ..writeUint16Le(42)
    ..writeUint32Le(8)
    ..writeUint16Le(1)
    ..writeUint16Le(0x0112)
    ..writeUint16Le(3)
    ..writeUint32Le(1)
    ..writeUint16Le(orientation)
    ..writeUint16Le(0)
    ..writeUint32Le(0);
  return writer.toBytes();
}
