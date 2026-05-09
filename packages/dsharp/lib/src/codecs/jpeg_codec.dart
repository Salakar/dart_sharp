import 'dart:typed_data';

import '../api/exceptions.dart';
import '../pixels/pixel_image.dart';
import 'codec.dart';
import 'encoder_options.dart';
import 'image_format.dart';
import 'jpeg_decoder.dart';
import 'jpeg_encoder.dart';
import 'output.dart';

/// First-party JPEG codec.
final class JpegImageCodec implements ImageCodec {
  /// Creates a JPEG codec.
  const JpegImageCodec();

  @override
  ImageFormat get format => ImageFormat.jpeg;

  @override
  PixelImage decode(Uint8List bytes) {
    return PixelImage.fromRawPixels(decodeJpegBytes(bytes));
  }

  @override
  EncodedImage encode(PixelImage image, {EncoderOptions? options}) {
    final jpegOptions = options is JpegEncoderOptions
        ? options
        : const JpegEncoderOptions();
    _rejectUnsupportedJpegOptions(jpegOptions);
    final raw = image.firstFrame.pixels;
    final bytes = encodeJpegBytes(
      raw,
      quality: jpegOptions.quality,
      chromaSubsampling: jpegOptions.chromaSubsampling,
      progressive: jpegOptions.progressive,
    );
    return EncodedImage(
      bytes: bytes,
      info: OutputInfo(
        format: format,
        size: bytes.length,
        width: raw.width,
        height: raw.height,
        channels: 3,
      ),
    );
  }
}

void _rejectUnsupportedJpegOptions(JpegEncoderOptions options) {
  if (options.trellisQuantisation) {
    throw const UnsupportedCodecException(
      'JPEG trellisQuantisation is not implemented yet.',
    );
  }
  if (options.overshootDeringing) {
    throw const UnsupportedCodecException(
      'JPEG overshootDeringing is not implemented yet.',
    );
  }
  if (options.quantizationTable != 0) {
    throw const UnsupportedCodecException(
      'JPEG quantizationTable is not implemented yet.',
    );
  }
  if (options.mozjpeg) {
    throw const UnsupportedCodecException(
      'JPEG mozjpeg options are not implemented yet.',
    );
  }
}
