import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

import 'helpers/generated_fixtures.dart';

void main() {
  test('malformed headers and random bytes fail without hangs', () async {
    for (final bytes in GeneratedFixtures.malformedBytes()) {
      expect(
        ImagePipeline.fromBytes(bytes).toPixelImage(),
        throwsA(
          anyOf(
            isA<ImageProcessingException>(),
            isA<UnsupportedCodecException>(),
          ),
        ),
      );
    }
  });

  test(
    'oversized and invalid descriptors fail before allocation-heavy work',
    () {
      expect(
        () => RawPixels(
          bytes: Uint8List(3),
          width: 65535,
          height: 65535,
          channels: ChannelCount.four,
        ),
        throwsA(isA<InvalidImageException>()),
      );
      expect(
        () => XmpMetadata.parse('<xmp><broken></xmp>'),
        throwsA(isA<InvalidImageException>()),
      );
    },
  );

  test('stream byte limits reject excessive fuzz input', () {
    final stream = Stream<List<int>>.fromIterable(<List<int>>[
      GeneratedFixtures.rawBuffer(8, seed: 1),
      GeneratedFixtures.rawBuffer(8, seed: 2),
    ]);

    final source =
        ImageSource.stream(stream, maxBytes: 12) as StreamImageSource;

    expect(source.collectBytes(), throwsA(isA<ImageLimitException>()));
  });
}
