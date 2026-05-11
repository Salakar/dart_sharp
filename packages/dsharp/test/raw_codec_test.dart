import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:dsharp/src/codecs/raw_codec.dart';
import 'package:test/test.dart';

void main() {
  test('raw byte decode requires a descriptor', () {
    expect(
      () => const RawImageCodec().decode(Uint8List.fromList(<int>[1, 2, 3])),
      throwsA(
        isA<UnsupportedCodecException>().having(
          (error) => error.message,
          'message',
          contains('Raw decoding requires a RawPixels descriptor'),
        ),
      ),
    );
  });

  test('raw descriptor decode preserves dimensions and channels', () {
    final image = const RawImageCodec().decodeRaw(
      RawPixels(
        bytes: Uint8List.fromList(<int>[1, 2, 3, 4, 5, 6]),
        width: 2,
        height: 1,
        channels: ChannelCount.three,
      ),
    );

    expect(image.width, 2);
    expect(image.height, 1);
    expect(image.channels, ChannelCount.three);
    expect(image.firstFrameBytes(), <int>[1, 2, 3, 4, 5, 6]);
  });

  test('raw encode returns first-frame bytes and output info', () {
    final image = PixelImage.fromRawPixels(
      RawPixels(
        bytes: Uint8List.fromList(<int>[9, 8, 7, 6]),
        width: 2,
        height: 1,
        channels: ChannelCount.two,
      ),
    );

    final encoded = const RawImageCodec().encode(image);

    expect(encoded.bytes, <int>[9, 8, 7, 6]);
    expect(encoded.info.format, ImageFormat.raw);
    expect(encoded.info.width, 2);
    expect(encoded.info.height, 1);
    expect(encoded.info.channels, 2);
    expect(encoded.info.size, 4);
  });
}
