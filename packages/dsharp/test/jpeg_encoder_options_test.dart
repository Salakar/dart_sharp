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

  test('JPEG chromaSubsampling metadata reflects encoded output', () async {
    final raw = _gradient();
    final subsampled = await ImagePipeline.fromRawPixels(raw).jpeg().toBytes();
    final full = await ImagePipeline.fromRawPixels(
      raw,
    ).jpeg(const JpegEncoderOptions(chromaSubsampling: '4:4:4')).toBytes();

    expect(
      (await ImagePipeline.fromBytes(subsampled).metadata()).chromaSubsampling,
      '4:2:0',
    );
    expect(
      (await ImagePipeline.fromBytes(full).metadata()).chromaSubsampling,
      '4:4:4',
    );
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

RawPixels _gradient() {
  return RawPixels(
    bytes: Uint8List.fromList(<int>[
      for (var y = 0; y < 16; y += 1)
        for (var x = 0; x < 16; x += 1) ...[x * 16, y * 16, (x + y) * 8],
    ]),
    width: 16,
    height: 16,
    channels: ChannelCount.three,
  );
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
