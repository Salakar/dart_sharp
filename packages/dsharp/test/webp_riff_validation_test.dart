import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

import 'helpers/webp_lossy_fixture.dart';

void main() {
  test('rejects WebP RIFF sizes shorter than the WEBP body', () async {
    final bytes = solidVp8Webp(width: 1, height: 1);
    _writeU32(bytes, 4, 0);

    await expectLater(
      ImagePipeline.fromBytes(bytes).metadata(),
      throwsA(
        isA<InvalidImageException>().having(
          (error) => error.message,
          'message',
          contains('Invalid WebP signature'),
        ),
      ),
    );
    await expectLater(
      ImagePipeline.fromBytes(bytes).toPixelImage(),
      throwsA(
        isA<InvalidImageException>().having(
          (error) => error.message,
          'message',
          contains('Invalid WebP signature'),
        ),
      ),
    );
  });
}

void _writeU32(Uint8List bytes, int offset, int value) {
  bytes[offset] = value & 0xff;
  bytes[offset + 1] = (value >> 8) & 0xff;
  bytes[offset + 2] = (value >> 16) & 0xff;
  bytes[offset + 3] = (value >> 24) & 0xff;
}
