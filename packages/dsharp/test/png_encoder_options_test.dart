import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:dsharp/src/codecs/binary_io.dart';
import 'package:dsharp/src/codecs/deflate_codec.dart';
import 'package:test/test.dart';

void main() {
  test('PNG colors options select indexed output bit depth', () async {
    final raw = _paletteRaw();

    final colors = await ImagePipeline.fromRawPixels(
      raw,
    ).png(const PngEncoderOptions(colors: 4)).toBytes();
    final colours = await ImagePipeline.fromRawPixels(
      raw,
    ).png(const PngEncoderOptions(colours: 4)).toBytes();

    expect(_pngColorType(colors), 3);
    expect(_pngBitDepth(colors), 2);
    expect(_pngColorType(colours), 3);
    expect(_pngBitDepth(colours), 2);
    expect(
      (await ImagePipeline.fromBytes(colors).toPixelImage()).firstFrameBytes(),
      raw.bytes,
    );
  });

  test('PNG colors option validates palette range', () {
    for (final colors in <int>[1, 257]) {
      expect(
        ImagePipeline.fromRawPixels(
          _paletteRaw(),
        ).png(PngEncoderOptions(colors: colors)).toBytes(),
        throwsA(isA<OperationValidationException>()),
      );
    }
  });

  test(
    'PNG palette parity options validate and select indexed output',
    () async {
      final pipeline = ImagePipeline.fromRawPixels(_paletteRaw());

      for (final options in const <PngEncoderOptions>[
        PngEncoderOptions(quality: 0),
        PngEncoderOptions(quality: 90),
        PngEncoderOptions(effort: 1),
        PngEncoderOptions(effort: 10),
        PngEncoderOptions(dither: 0),
        PngEncoderOptions(dither: 0.5),
      ]) {
        final encoded = await pipeline.png(options).toBytes();
        final decoded = await ImagePipeline.fromBytes(encoded).toPixelImage();

        expect(_pngColorType(encoded), 3);
        expect(decoded.firstFrameBytes(), _paletteRaw().bytes);
      }
    },
  );

  test('PNG advanced parity options fail clearly when invalid', () {
    final pipeline = ImagePipeline.fromRawPixels(_paletteRaw());

    for (final options in <PngEncoderOptions>[
      const PngEncoderOptions(quality: 101),
      const PngEncoderOptions(effort: 0),
      const PngEncoderOptions(effort: 11),
      const PngEncoderOptions(dither: -0.1),
      const PngEncoderOptions(dither: 1.1),
    ]) {
      expect(
        pipeline.png(options).toBytes(),
        throwsA(isA<OperationValidationException>()),
      );
    }
  });

  test(
    'PNG adaptiveFiltering writes filtered rows that decode correctly',
    () async {
      final raw = _solidRowsRaw();
      final unfiltered = await ImagePipeline.fromRawPixels(
        raw,
      ).png(const PngEncoderOptions()).toBytes();
      final filtered = await ImagePipeline.fromRawPixels(
        raw,
      ).png(const PngEncoderOptions(adaptiveFiltering: true)).toBytes();

      expect(_pngFilters(unfiltered), everyElement(0));
      expect(_pngFilters(filtered), containsAll(<int>[1, 2]));
      expect(
        (await ImagePipeline.fromBytes(
          filtered,
        ).toPixelImage()).firstFrameBytes(),
        raw.bytes,
      );
    },
  );
}

RawPixels _paletteRaw() {
  return RawPixels(
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
}

RawPixels _solidRowsRaw() {
  return RawPixels(
    bytes: Uint8List.fromList(<int>[
      for (var i = 0; i < 16; i += 1) ...<int>[100, 110, 120, 255],
    ]),
    width: 8,
    height: 2,
    channels: ChannelCount.four,
  );
}

int _pngBitDepth(Uint8List bytes) => bytes[24];

int _pngColorType(Uint8List bytes) => bytes[25];

List<int> _pngFilters(Uint8List bytes) {
  final width = readUint32Be(bytes, 16);
  final height = readUint32Be(bytes, 20);
  final bitDepth = _pngBitDepth(bytes);
  final colorType = _pngColorType(bytes);
  expect(bitDepth, 8);
  expect(colorType, 6);
  final inflated = zlibDecode(_pngIdat(bytes));
  final rowLength = width * 4;
  final filters = <int>[];
  var offset = 0;
  for (var y = 0; y < height; y += 1) {
    filters.add(inflated[offset]);
    offset += rowLength + 1;
  }
  return filters;
}

Uint8List _pngIdat(Uint8List bytes) {
  final idat = <int>[];
  var offset = 8;
  while (offset + 12 <= bytes.length) {
    final length = readUint32Be(bytes, offset);
    final type = String.fromCharCodes(bytes.sublist(offset + 4, offset + 8));
    final start = offset + 8;
    final end = start + length;
    if (type == 'IDAT') {
      idat.addAll(bytes.sublist(start, end));
    } else if (type == 'IEND') {
      break;
    }
    offset = end + 4;
  }
  return Uint8List.fromList(idat);
}
