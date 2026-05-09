import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

void main() {
  test('decodes uncompressed Radiance HDR RGBE pixels', () async {
    final bytes = Uint8List.fromList(<int>[
      ..._ascii('#?RADIANCE\nFORMAT=32-bit_rle_rgbe\n\n-Y 1 +X 2\n'),
      255,
      0,
      0,
      136,
      0,
      128,
      0,
      136,
    ]);

    final decoded = await ImagePipeline.fromBytes(bytes).toPixelImage();

    expect(decoded.width, 2);
    expect(decoded.height, 1);
    expect(decoded.firstFrameBytes(), <int>[255, 0, 0, 255, 0, 128, 0, 255]);
  });

  test('decodes Radiance HDR RLE scanlines', () async {
    final bytes = Uint8List.fromList(<int>[
      ..._ascii('#?RADIANCE\nFORMAT=32-bit_rle_rgbe\n\n-Y 1 +X 8\n'),
      2,
      2,
      0,
      8,
      8,
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      136,
      0,
      136,
      0,
      136,
      136,
    ]);

    final decoded = await ImagePipeline.fromBytes(bytes).toPixelImage();

    expect(_redChannel(decoded.firstFrameBytes()), <int>[
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
    ]);
  });

  test('Radiance HDR aliases and capabilities are exposed', () {
    final support = DsharpCapabilities.current.supportFor(ImageFormat.rad);

    expect(ImageFormat.fromId('hdr'), ImageFormat.rad);
    expect(ImageFormat.fromId('rgbe'), ImageFormat.rad);
    expect(support.canDecode, isTrue);
    expect(support.canEncode, isTrue);
    expect(support.metadata, CodecAvailability.supported);
  });

  test(
    'encodes Radiance HDR through format selection and round trips',
    () async {
      final raw = RawPixels(
        bytes: Uint8List.fromList(<int>[
          1,
          2,
          3,
          4,
          128,
          64,
          32,
          255,
          for (var i = 0; i < 6; i += 1) ...[i + 10, i + 20, i + 30, 255],
        ]),
        width: 8,
        height: 1,
        channels: ChannelCount.four,
      );

      final encoded = await ImagePipeline.fromRawPixels(
        raw,
      ).toBytesWithInfo(format: ImageFormat.rad);
      final decoded = await ImagePipeline.fromBytes(
        encoded.bytes,
      ).toPixelImage();

      expect(encoded.info.format, ImageFormat.rad);
      expect(encoded.info.channels, 3);
      expect(sniffImageFormat(encoded.bytes), ImageFormat.rad);
      expect(decoded.firstFrameBytes(), <int>[
        1,
        2,
        3,
        255,
        128,
        64,
        32,
        255,
        for (var i = 0; i < 6; i += 1) ...[i + 10, i + 20, i + 30, 255],
      ]);
    },
  );

  test('rejects malformed Radiance HDR data with typed exceptions', () async {
    await expectLater(
      ImagePipeline.fromBytes(
        _ascii('#?RADIANCE\n\n-Y 1 +X 1\n'),
      ).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
    await expectLater(
      ImagePipeline.fromBytes(
        Uint8List.fromList(<int>[
          ..._ascii('#?RADIANCE\nFORMAT=32-bit_rle_rgbe\n\n-Y 1 +X 8\n'),
          2,
          2,
          0,
          8,
          136,
        ]),
      ).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
  });
}

Uint8List _ascii(String value) => Uint8List.fromList(value.codeUnits);

List<int> _redChannel(Uint8List bytes) {
  return <int>[
    for (var offset = 0; offset < bytes.length; offset += 4) bytes[offset],
  ];
}
