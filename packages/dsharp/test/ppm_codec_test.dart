import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

void main() {
  test('sniffs Netpbm image signatures', () {
    expect(sniffImageFormat(_ascii('P6\n1 1\n255\n')), ImageFormat.ppm);
    expect(sniffImageFormat(_ascii('P5\t1 1\n255\n')), ImageFormat.ppm);
    expect(sniffImageFormat(_ascii('P3 1 1 255 0 0 0')), ImageFormat.ppm);
    expect(sniffImageFormat(_ascii('P4\n1 1\n')), ImageFormat.ppm);
    expect(sniffImageFormat(_ascii('P1 1 1 0')), ImageFormat.ppm);
  });

  test('decodes binary PPM with comments', () async {
    final bytes = Uint8List.fromList(<int>[
      ..._ascii('P6\n# generated fixture\n2 1\n255\n'),
      255,
      0,
      0,
      0,
      255,
      0,
    ]);

    final decoded = await ImagePipeline.fromBytes(bytes).toPixelImage();

    expect(decoded.width, 2);
    expect(decoded.height, 1);
    expect(decoded.firstFrameBytes(), <int>[255, 0, 0, 255, 0, 255, 0, 255]);
  });

  test('decodes binary PGM and scales max value', () async {
    final bytes = Uint8List.fromList(<int>[..._ascii('P5\n2 1\n15\n'), 0, 15]);

    final decoded = await ImagePipeline.fromBytes(bytes).toPixelImage();

    expect(decoded.firstFrameBytes(), <int>[0, 0, 0, 255, 255, 255, 255, 255]);
  });

  test('decodes binary PPM with CRLF header separator', () async {
    final bytes = Uint8List.fromList(<int>[
      ..._ascii('P6\r\n2 1\r\n255\r\n'),
      255,
      0,
      0,
      0,
      255,
      0,
    ]);

    final decoded = await ImagePipeline.fromBytes(bytes).toPixelImage();

    expect(decoded.firstFrameBytes(), <int>[255, 0, 0, 255, 0, 255, 0, 255]);
  });

  test('decodes ASCII PPM and PGM variants', () async {
    final ppm = await ImagePipeline.fromBytes(
      _ascii('P3\n2 1\n3\n3 0 0 0 3 0\n'),
    ).toPixelImage();
    final pgm = await ImagePipeline.fromBytes(
      _ascii('P2\n2 1\n3\n0 3\n'),
    ).toPixelImage();

    expect(ppm.firstFrameBytes(), <int>[255, 0, 0, 255, 0, 255, 0, 255]);
    expect(pgm.firstFrameBytes(), <int>[0, 0, 0, 255, 255, 255, 255, 255]);
  });

  test('decodes ASCII and binary PBM variants', () async {
    final ascii = await ImagePipeline.fromBytes(
      _ascii('P1\n3 1\n0 1 0\n'),
    ).toPixelImage();
    final binary = await ImagePipeline.fromBytes(
      Uint8List.fromList(<int>[..._ascii('P4\n3 1\n'), 0x40]),
    ).toPixelImage();
    final padded = await ImagePipeline.fromBytes(
      Uint8List.fromList(<int>[..._ascii('P4\n9 2\n'), 0x80, 0x80, 0, 0x80]),
    ).toPixelImage();

    expect(ascii.firstFrameBytes(), <int>[
      255,
      255,
      255,
      255,
      0,
      0,
      0,
      255,
      255,
      255,
      255,
      255,
    ]);
    expect(binary.firstFrameBytes(), ascii.firstFrameBytes());
    final paddedBytes = padded.firstFrameBytes();
    expect(
      <int>[paddedBytes[0], paddedBytes[32], paddedBytes[36], paddedBytes[68]],
      <int>[0, 0, 255, 0],
    );
  });

  test('encodes PPM through format selection and round trips', () async {
    final raw = RawPixels(
      bytes: Uint8List.fromList(<int>[10, 20, 30, 40, 200, 210, 220, 230]),
      width: 2,
      height: 1,
      channels: ChannelCount.four,
    );

    final encoded = await ImagePipeline.fromRawPixels(
      raw,
    ).toBytesWithInfo(format: ImageFormat.ppm);
    final decoded = await ImagePipeline.fromBytes(encoded.bytes).toPixelImage();

    expect(encoded.info.format, ImageFormat.ppm);
    expect(encoded.info.channels, 3);
    expect(String.fromCharCodes(encoded.bytes.take(11)), 'P6\n2 1\n255\n');
    expect(decoded.firstFrameBytes(), <int>[
      10,
      20,
      30,
      255,
      200,
      210,
      220,
      255,
    ]);
  });

  test('PPM capabilities and format aliases are exposed', () {
    final support = DsharpCapabilities.current.supportFor(ImageFormat.ppm);

    expect(ImageFormat.fromId('pnm'), ImageFormat.ppm);
    expect(ImageFormat.fromId('pgm'), ImageFormat.ppm);
    expect(ImageFormat.fromId('pbm'), ImageFormat.ppm);
    expect(support.canDecode, isTrue);
    expect(support.canEncode, isTrue);
    expect(support.metadata, CodecAvailability.supported);
  });

  test('rejects malformed PPM data with typed exceptions', () async {
    await expectLater(
      ImagePipeline.fromBytes(_ascii('P6\n1 1\n255\n\xff')).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
    await expectLater(
      ImagePipeline.fromBytes(_ascii('P2\n1 1\n3\n4\n')).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
    await expectLater(
      ImagePipeline.fromBytes(_ascii('P1\n1 1\n2\n')).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
    await expectLater(
      ImagePipeline.fromBytes(
        Uint8List.fromList(<int>[..._ascii('P4\n9 1\n'), 0]),
      ).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
  });
}

Uint8List _ascii(String value) => Uint8List.fromList(value.codeUnits);
