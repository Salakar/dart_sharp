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
}
