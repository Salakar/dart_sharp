import 'dart:convert';
import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

void main() {
  test('decodes 8-bit grayscale FITS images', () async {
    final decoded = await ImagePipeline.fromBytes(
      _fitsBytes(
        cards: <String, Object>{
          'BITPIX': 8,
          'NAXIS': 2,
          'NAXIS1': 2,
          'NAXIS2': 1,
        },
        data: <int>[0, 255],
      ),
    ).toPixelImage();

    expect(decoded.width, 2);
    expect(decoded.height, 1);
    expect(decoded.firstFrameBytes(), <int>[0, 0, 0, 255, 255, 255, 255, 255]);
  });

  test('decodes 16-bit FITS images with BZERO scaling', () async {
    final decoded = await ImagePipeline.fromBytes(
      _fitsBytes(
        cards: <String, Object>{
          'BITPIX': 16,
          'NAXIS': 2,
          'NAXIS1': 2,
          'NAXIS2': 1,
          'BSCALE': 1,
          'BZERO': 32768,
        },
        data: <int>[0x80, 0x00, 0x7f, 0xff],
      ),
    ).toPixelImage();

    expect(decoded.firstFrameBytes(), <int>[0, 0, 0, 255, 255, 255, 255, 255]);
  });

  test('decodes 3-plane RGB FITS images', () async {
    final decoded = await ImagePipeline.fromBytes(
      _fitsBytes(
        cards: <String, Object>{
          'BITPIX': 8,
          'NAXIS': 3,
          'NAXIS1': 2,
          'NAXIS2': 1,
          'NAXIS3': 3,
        },
        data: <int>[10, 20, 30, 40, 50, 60],
      ),
    ).toPixelImage();

    expect(decoded.firstFrameBytes(), <int>[10, 30, 50, 255, 20, 40, 60, 255]);
  });

  test('encodes FITS through format selection and round trips', () async {
    final raw = RawPixels(
      bytes: Uint8List.fromList(<int>[0, 128, 255]),
      width: 3,
      height: 1,
      channels: ChannelCount.one,
    );

    final encoded = await ImagePipeline.fromRawPixels(
      raw,
    ).toBytesWithInfo(format: ImageFormat.fits);
    final decoded = await ImagePipeline.fromBytes(encoded.bytes).toPixelImage();

    expect(encoded.info.format, ImageFormat.fits);
    expect(encoded.info.channels, 1);
    expect(sniffImageFormat(encoded.bytes), ImageFormat.fits);
    expect(decoded.firstFrameBytes(), <int>[
      0,
      0,
      0,
      255,
      128,
      128,
      128,
      255,
      255,
      255,
      255,
      255,
    ]);
  });

  test('FITS capabilities are exposed', () {
    final support = DsharpCapabilities.current.supportFor(ImageFormat.fits);

    expect(support.canDecode, isTrue);
    expect(support.canEncode, isTrue);
    expect(support.metadata, CodecAvailability.supported);
  });

  test('rejects malformed FITS data with typed exceptions', () async {
    await expectLater(
      ImagePipeline.fromBytes(
        Uint8List.fromList('SIMPLE  ='.codeUnits),
      ).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
    await expectLater(
      ImagePipeline.fromBytes(
        _fitsBytes(
          cards: <String, Object>{
            'BITPIX': 8,
            'NAXIS': 2,
            'NAXIS1': 2,
            'NAXIS2': 1,
          },
          data: <int>[1],
          padData: false,
        ),
      ).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
  });
}

Uint8List _fitsBytes({
  required Map<String, Object> cards,
  required List<int> data,
  bool padData = true,
}) {
  final bytes = <int>[
    ..._card('SIMPLE', true),
    for (final entry in cards.entries) ..._card(entry.key, entry.value),
    ...ascii.encode('END'.padRight(80)),
  ];
  while (bytes.length % 2880 != 0) {
    bytes.add(0x20);
  }
  bytes.addAll(data);
  if (padData) {
    while (bytes.length % 2880 != 0) {
      bytes.add(0);
    }
  }
  return Uint8List.fromList(bytes);
}

List<int> _card(String keyword, Object value) {
  final encodedValue = switch (value) {
    bool() => value ? 'T' : 'F',
    num() => value.toString(),
    _ => "'$value'",
  };
  return ascii.encode(
    '${keyword.padRight(8)}= ${encodedValue.padLeft(20)}'.padRight(80),
  );
}
