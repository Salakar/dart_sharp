import 'dart:typed_data';

import '../api/exceptions.dart';
import '../pixels/pixel_image.dart';
import 'binary_io.dart';
import 'codec.dart';
import 'encoder_options.dart';
import 'image_format.dart';
import 'output.dart';
import 'webp_alpha.dart';
import 'webp_animation.dart';
import 'webp_info.dart';
import 'webp_lossless.dart';
import 'webp_lossless_encoder.dart';
import 'webp_vp8.dart';

/// First-party WebP container decoder.
///
/// This validates RIFF/WebP structure, parses metadata, and decodes supported
/// VP8L lossless and VP8 lossy key-frame subsets. Other WebP bitstream
/// features remain explicitly unsupported.
final class WebpImageCodec implements ImageCodec {
  /// Creates a WebP codec.
  const WebpImageCodec();

  @override
  ImageFormat get format => ImageFormat.webp;

  @override
  PixelImage decode(Uint8List bytes) {
    final info = readWebpInfo(bytes);
    if (info.isAnimated) {
      return decodeAnimatedWebp(bytes);
    }
    if (info.compression == WebpCompression.vp8) {
      return PixelImage.fromRawPixels(decodeWebpVp8(bytes));
    }
    if (info.compression == WebpCompression.extended &&
        _containsWebpChunk(bytes, 'VP8 ')) {
      final pixels = decodeWebpVp8(bytes);
      return PixelImage.fromRawPixels(
        info.hasAlpha ? applyWebpAlpha(bytes, pixels) : pixels,
      );
    }
    return PixelImage.fromRawPixels(decodeWebpLossless(bytes));
  }

  @override
  EncodedImage encode(PixelImage image, {EncoderOptions? options}) {
    final webpOptions = options is WebpEncoderOptions
        ? options
        : const WebpEncoderOptions();
    if (!webpOptions.lossless) {
      throw const UnsupportedCodecException(
        'Lossy WebP encoding is not implemented in pure Dart yet.',
      );
    }
    final raw = image.firstFrame.pixels;
    final bytes = encodeWebpLossless(image);
    return EncodedImage(
      bytes: bytes,
      info: OutputInfo(
        format: format,
        size: bytes.length,
        width: raw.width,
        height: raw.height,
        channels: 4,
      ),
    );
  }
}

bool _containsWebpChunk(Uint8List bytes, String target) {
  var offset = 12;
  while (offset + 8 <= bytes.length) {
    final type = String.fromCharCodes(bytes.sublist(offset, offset + 4));
    final length = readUint32Le(bytes, offset + 4);
    final end = offset + 8 + length;
    if (end > bytes.length) {
      return false;
    }
    if (type == target) {
      return true;
    }
    offset = end + (length.isOdd ? 1 : 0);
  }
  return false;
}
