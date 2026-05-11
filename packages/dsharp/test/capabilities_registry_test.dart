import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:dsharp/src/codecs/unsupported_codec.dart';
import 'package:test/test.dart';

void main() {
  test('registry and capabilities cover the same known formats', () {
    final registry = CodecRegistry.defaultRegistry();
    final capabilities = registry.capabilities;
    final knownFormats = ImageFormat.values
        .where((format) => format != ImageFormat.unknown)
        .toSet();

    expect(registry.formats.toSet(), knownFormats);
    expect(
      capabilities.formats.map((support) => support.format).toSet(),
      knownFormats,
    );

    for (final format in knownFormats) {
      final support = capabilities.supportFor(format);
      final codec = registry.codecFor(format);
      final hasImplementedCodec = codec is! UnsupportedImageCodec;

      expect(
        support.canDecode || support.canEncode,
        hasImplementedCodec,
        reason: '${format.id} capability support must match its codec.',
      );
      if (codec is UnsupportedImageCodec) {
        expect(codec.reason, support.reason, reason: format.id);
      }
    }
  });

  test('unsupported registry codecs reject encode and decode consistently', () {
    final registry = CodecRegistry.defaultRegistry();
    final image = PixelImage.fromRawPixels(
      RawPixels(
        bytes: Uint8List.fromList(<int>[0, 0, 0, 255]),
        width: 1,
        height: 1,
        channels: ChannelCount.four,
      ),
    );
    final formats = ImageFormat.values.where(
      (format) =>
          format != ImageFormat.unknown &&
          registry.codecFor(format) is UnsupportedImageCodec,
    );

    for (final format in formats) {
      expect(
        () => registry.decode(Uint8List(0), format: format),
        throwsA(
          isA<UnsupportedCodecException>().having(
            (error) => error.message,
            'message',
            contains('${format.id} decode is unsupported'),
          ),
        ),
        reason: format.id,
      );
      expect(
        () => registry.encode(image, format: format),
        throwsA(
          isA<UnsupportedCodecException>().having(
            (error) => error.message,
            'message',
            contains('${format.id} encode is unsupported'),
          ),
        ),
        reason: format.id,
      );
    }
  });

  test('unknown format remains unregistered and unsupported', () {
    final registry = CodecRegistry.defaultRegistry();
    final support = DsharpCapabilities.current.supportFor(ImageFormat.unknown);

    expect(support.input, CodecAvailability.unsupported);
    expect(support.output, CodecAvailability.unsupported);
    expect(support.reason, 'Unknown image format.');
    expect(
      () => registry.codecFor(ImageFormat.unknown),
      throwsA(
        isA<UnsupportedCodecException>().having(
          (error) => error.message,
          'message',
          contains('unknown is not registered'),
        ),
      ),
    );
    expect(
      () => registry.decode(Uint8List(0)),
      throwsA(
        isA<UnsupportedCodecException>().having(
          (error) => error.message,
          'message',
          contains('unknown is not registered'),
        ),
      ),
    );
  });
}
