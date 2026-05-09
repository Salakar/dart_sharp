import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

void main() {
  test('JPEG optimizeScans aliases force progressive output', () async {
    final optimize = await ImagePipeline.fromRawPixels(
      _raw(),
    ).jpeg(const JpegEncoderOptions(optimizeScans: true)).toBytes();
    final optimise = await ImagePipeline.fromRawPixels(
      _raw(),
    ).jpeg(const JpegEncoderOptions(optimiseScans: true)).toBytes();

    expect(
      (await ImagePipeline.fromBytes(optimize).metadata()).isProgressive,
      isTrue,
    );
    expect(
      (await ImagePipeline.fromBytes(optimise).metadata()).isProgressive,
      isTrue,
    );
  });

  test('JPEG advanced parity options fail clearly when unsupported', () async {
    final pipeline = ImagePipeline.fromRawPixels(_raw());

    for (final options in <JpegEncoderOptions>[
      const JpegEncoderOptions(trellisQuantisation: true),
      const JpegEncoderOptions(trellisQuantization: true),
      const JpegEncoderOptions(overshootDeringing: true),
      const JpegEncoderOptions(quantisationTable: 3),
      const JpegEncoderOptions(quantizationTable: 3),
      const JpegEncoderOptions(mozjpeg: true),
    ]) {
      expect(
        pipeline.jpeg(options).toBytes(),
        throwsA(isA<UnsupportedCodecException>()),
      );
    }

    expect(
      pipeline.jpeg(const JpegEncoderOptions(quantizationTable: -1)).toBytes(),
      throwsA(isA<OperationValidationException>()),
    );
    expect(
      pipeline.jpeg(const JpegEncoderOptions(quantizationTable: 9)).toBytes(),
      throwsA(isA<OperationValidationException>()),
    );
  });
}

RawPixels _raw() {
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
    width: 2,
    height: 2,
    channels: ChannelCount.four,
  );
}
