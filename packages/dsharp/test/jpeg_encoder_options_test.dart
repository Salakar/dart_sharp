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

  test('JPEG mozjpeg option enables progressive output', () async {
    final bytes = await ImagePipeline.fromRawPixels(
      _raw(),
    ).jpeg(const JpegEncoderOptions(mozjpeg: true)).toBytes();

    expect(
      (await ImagePipeline.fromBytes(bytes).metadata()).isProgressive,
      isTrue,
    );
  });

  test('JPEG optimizeCoding aliases are accepted', () async {
    for (final options in const <JpegEncoderOptions>[
      JpegEncoderOptions(optimizeCoding: false),
      JpegEncoderOptions(optimiseCoding: false),
    ]) {
      final bytes = await ImagePipeline.fromRawPixels(
        _raw(),
      ).jpeg(options).toBytes();

      expect(
        (await ImagePipeline.fromBytes(bytes).metadata()).format,
        ImageFormat.jpeg,
      );
    }
  });

  test('JPEG advanced parity options validate and encode', () async {
    final pipeline = ImagePipeline.fromRawPixels(_raw());

    for (final options in const <JpegEncoderOptions>[
      JpegEncoderOptions(trellisQuantisation: true),
      JpegEncoderOptions(trellisQuantization: true),
      JpegEncoderOptions(overshootDeringing: true),
      JpegEncoderOptions(quantisationTable: 3),
      JpegEncoderOptions(quantizationTable: 3),
      JpegEncoderOptions(mozjpeg: true),
    ]) {
      final bytes = await pipeline.jpeg(options).toBytes();

      expect(
        (await ImagePipeline.fromBytes(bytes).metadata()).format,
        ImageFormat.jpeg,
      );
    }
  });

  test('JPEG advanced parity options fail clearly when invalid', () {
    final pipeline = ImagePipeline.fromRawPixels(_raw());

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
