import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
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

int _pngBitDepth(Uint8List bytes) => bytes[24];

int _pngColorType(Uint8List bytes) => bytes[25];
