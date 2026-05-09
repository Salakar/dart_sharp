import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

void main() {
  test('WebP defaults to lossy VP8 output', () async {
    expect(const WebpEncoderOptions().lossless, isFalse);

    final encoded = await ImagePipeline.fromRawPixels(
      _rgb(<int>[255, 0, 0]),
    ).webp().toBytesWithInfo();
    final decoded = await ImagePipeline.fromBytes(encoded.bytes).toPixelImage();

    expect(encoded.info.format, ImageFormat.webp);
    expect(String.fromCharCodes(encoded.bytes.sublist(12, 16)), 'VP8 ');
    expect(decoded.width, 1);
    expect(decoded.height, 1);
  });

  test('WebP lossless option writes VP8L output', () async {
    final encoded = await ImagePipeline.fromRawPixels(
      _rgb(<int>[255, 0, 0]),
    ).webp(const WebpEncoderOptions(lossless: true)).toBytes();

    expect(String.fromCharCodes(encoded.sublist(12, 16)), 'VP8L');
  });
}

RawPixels _rgb(List<int> bytes) {
  return RawPixels(
    bytes: Uint8List.fromList(bytes),
    width: 1,
    height: 1,
    channels: ChannelCount.three,
  );
}
