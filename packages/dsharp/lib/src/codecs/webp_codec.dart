import 'dart:typed_data';

import '../api/exceptions.dart';
import '../pixels/pixel_image.dart';
import 'codec.dart';
import 'image_format.dart';
import 'output.dart';
import 'webp_info.dart';

/// First-party WebP container decoder.
///
/// This validates RIFF/WebP structure and parses image metadata. VP8/VP8L
/// pixel reconstruction is intentionally still reported as unsupported.
final class WebpImageCodec implements ImageCodec {
  /// Creates a WebP codec.
  const WebpImageCodec();

  @override
  ImageFormat get format => ImageFormat.webp;

  @override
  PixelImage decode(Uint8List bytes) {
    final info = readWebpInfo(bytes);
    throw UnsupportedCodecException(
      'WebP ${info.compression.name} pixel reconstruction is not implemented '
      'yet for ${info.width}x${info.height} input.',
    );
  }

  @override
  EncodedImage encode(PixelImage image) {
    throw const UnsupportedCodecException(
      'WebP encode is unsupported until a first-party encoder exists.',
    );
  }
}
