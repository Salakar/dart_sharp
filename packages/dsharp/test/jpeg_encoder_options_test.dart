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
