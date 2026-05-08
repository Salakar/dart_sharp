import 'dart:typed_data';

import '../pixels/pixel_image.dart';
import 'encoder_options.dart';
import 'image_format.dart';
import 'output.dart';

/// Decode and encode behavior for one image format.
abstract interface class ImageCodec {
  /// Format handled by this codec.
  ImageFormat get format;

  /// Decodes encoded bytes into pixels.
  PixelImage decode(Uint8List bytes);

  /// Encodes pixels into this codec's format.
  EncodedImage encode(PixelImage image, {EncoderOptions? options});
}
