import 'dart:typed_data';

import '../pixels/pixel_image.dart';
import '../source/raw_pixels.dart';
import 'codec.dart';
import 'image_format.dart';
import 'output.dart';

/// Codec for raw pixel bytes.
final class RawImageCodec implements ImageCodec {
  /// Creates a raw codec.
  const RawImageCodec();

  @override
  ImageFormat get format => ImageFormat.raw;

  @override
  PixelImage decode(Uint8List bytes) {
    throw UnsupportedError('Raw decoding requires a RawPixels descriptor.');
  }

  /// Decodes a raw descriptor.
  PixelImage decodeRaw(RawPixels pixels) {
    return PixelImage.fromRawPixels(pixels);
  }

  @override
  EncodedImage encode(PixelImage image) {
    final bytes = image.firstFrameBytes();
    return EncodedImage(
      bytes: bytes,
      info: OutputInfo(
        format: ImageFormat.raw,
        size: bytes.length,
        width: image.width,
        height: image.height,
        channels: image.channels.value,
      ),
    );
  }
}
