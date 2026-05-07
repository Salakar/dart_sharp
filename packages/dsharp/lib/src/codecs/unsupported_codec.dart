import 'dart:typed_data';

import '../api/exceptions.dart';
import '../pixels/pixel_image.dart';
import 'codec.dart';
import 'image_format.dart';
import 'output.dart';

/// Codec placeholder for intentionally unsupported formats.
final class UnsupportedImageCodec implements ImageCodec {
  /// Creates an unsupported codec.
  const UnsupportedImageCodec(this.format, {required this.reason});

  @override
  final ImageFormat format;

  /// Explanation presented to callers.
  final String reason;

  @override
  PixelImage decode(Uint8List bytes) {
    throw UnsupportedCodecException(
      '${format.id} decode is unsupported. $reason',
    );
  }

  @override
  EncodedImage encode(PixelImage image) {
    throw UnsupportedCodecException(
      '${format.id} encode is unsupported. $reason',
    );
  }
}
