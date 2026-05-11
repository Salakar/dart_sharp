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

  test('decodes floating point FITS images with explicit ranges', () async {
    final float32 = ByteData(8)
      ..setFloat32(0, -1)
      ..setFloat32(4, 1);
    final float64 = ByteData(16)
      ..setFloat64(0, -1)
      ..setFloat64(8, 1);

    for (final entry in <({int bitpix, ByteData data})>[
      (bitpix: -32, data: float32),
      (bitpix: -64, data: float64),
    ]) {
      final decoded = await ImagePipeline.fromBytes(
        _fitsBytes(
          cards: <String, Object>{
            'BITPIX': entry.bitpix,
            'NAXIS': 2,
            'NAXIS1': 2,
            'NAXIS2': 1,
            'DATAMIN': -1.0,
            'DATAMAX': 1.0,
          },
          data: entry.data.buffer.asUint8List().toList(),
        ),
      ).toPixelImage();

      expect(decoded.firstFrameBytes(), <int>[
        0,
        0,
        0,
        255,
        255,
        255,
        255,
        255,
      ], reason: 'BITPIX ${entry.bitpix}');
    }
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

  test('rejects unsupported FITS header shapes with typed errors', () async {
    final unsupportedAxisCount = _fitsBytes(
      cards: <String, Object>{
        'BITPIX': 8,
        'NAXIS': 4,
        'NAXIS1': 1,
        'NAXIS2': 1,
      },
      data: <int>[0],
    );
    final unsupportedPlaneCount = _fitsBytes(
      cards: <String, Object>{
        'BITPIX': 8,
        'NAXIS': 3,
        'NAXIS1': 1,
        'NAXIS2': 1,
        'NAXIS3': 2,
      },
      data: <int>[0, 0],
    );
    final unsupportedBitDepth = _fitsBytes(
      cards: <String, Object>{
        'BITPIX': 12,
        'NAXIS': 2,
        'NAXIS1': 1,
        'NAXIS2': 1,
      },
      data: <int>[0],
    );

    for (final bytes in <Uint8List>[
      unsupportedAxisCount,
      unsupportedPlaneCount,
      unsupportedBitDepth,
    ]) {
      await expectLater(
        ImagePipeline.fromBytes(bytes).toPixelImage(),
        throwsA(isA<UnsupportedCodecException>()),
      );
    }
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
