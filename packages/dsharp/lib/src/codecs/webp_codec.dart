import 'dart:typed_data';

import '../api/exceptions.dart';
import '../pixels/pixel_image.dart';
import 'codec.dart';
import 'image_format.dart';
import 'output.dart';
import 'webp_animation.dart';
import 'webp_info.dart';
import 'webp_lossless.dart';

/// First-party WebP container decoder.
///
/// This validates RIFF/WebP structure, parses metadata, and decodes a first
/// VP8L lossless subset. Other WebP bitstream features remain explicitly
/// unsupported.
final class WebpImageCodec implements ImageCodec {
  /// Creates a WebP codec.
  const WebpImageCodec();

  @override
  ImageFormat get format => ImageFormat.webp;

  @override
  PixelImage decode(Uint8List bytes) {
    final info = readWebpInfo(bytes);
    if (info.isAnimated) {
      return decodeAnimatedWebpLossless(bytes);
    }
    if (info.compression == WebpCompression.vp8) {
      throw UnsupportedCodecException(
        'WebP ${info.compression.name} pixel reconstruction is not implemented '
        'yet for ${info.width}x${info.height} input.',
      );
    }
    return PixelImage.fromRawPixels(decodeWebpLossless(bytes));
  }

  @override
  EncodedImage encode(PixelImage image) {
    throw const UnsupportedCodecException(
      'WebP encode is unsupported until a first-party encoder exists.',
    );
  }
}
