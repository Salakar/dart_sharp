import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../api/exceptions.dart';
import '../pixels/pixel_image.dart';
import '../source/raw_pixels.dart';
import 'codec.dart';
import 'image_format.dart';
import 'output.dart';

/// Codec backed by the pure Dart `image` package.
final class PackageImageCodec implements ImageCodec {
  /// Creates a package-backed codec for [format].
  const PackageImageCodec(this.format);

  @override
  final ImageFormat format;

  @override
  PixelImage decode(Uint8List bytes) {
    final img.Image? decoded;
    try {
      decoded = switch (format) {
        ImageFormat.png => img.decodePng(bytes),
        ImageFormat.jpeg => img.decodeJpg(bytes),
        ImageFormat.gif => img.decodeGif(bytes),
        ImageFormat.tiff => img.decodeTiff(bytes),
        ImageFormat.webp => img.decodeWebP(bytes),
        _ => img.decodeImage(bytes),
      };
    } catch (error) {
      throw InvalidImageException(
        'Unable to decode ${format.id} image bytes.',
        cause: error,
      );
    }
    if (decoded == null) {
      throw InvalidImageException('Unable to decode ${format.id} image bytes.');
    }
    return _fromPackageImage(decoded);
  }

  @override
  EncodedImage encode(PixelImage image) {
    final packageImage = _toPackageImage(image);
    final bytes = switch (format) {
      ImageFormat.png => img.encodePng(packageImage),
      ImageFormat.jpeg => img.encodeJpg(packageImage, quality: 100),
      ImageFormat.gif => img.encodeGif(packageImage),
      ImageFormat.tiff => img.encodeTiff(packageImage),
      _ => throw UnsupportedCodecException(
        '${format.id} encoding is not available through this backend.',
      ),
    };
    return EncodedImage(
      bytes: bytes,
      info: OutputInfo(
        format: format,
        size: bytes.length,
        width: image.width,
        height: image.height,
        channels: image.channels.value,
      ),
    );
  }

  PixelImage _fromPackageImage(img.Image image) {
    final frames = <ImageFrame>[];
    for (final frame in image.frames) {
      final rgba = frame.getBytes(order: img.ChannelOrder.rgba);
      frames.add(
        ImageFrame(
          pixels: RawPixels(
            bytes: rgba,
            width: frame.width,
            height: frame.height,
            channels: ChannelCount.four,
          ),
          delay: frame.frameDuration > 0
              ? Duration(milliseconds: frame.frameDuration)
              : null,
        ),
      );
    }
    return PixelImage(frames: frames);
  }

  img.Image _toPackageImage(PixelImage image) {
    final raw = image.firstFrame.pixels;
    return img.Image.fromBytes(
      width: raw.width,
      height: raw.height,
      bytes: raw.bytes.buffer,
      numChannels: raw.channels.value,
      order: switch (raw.channels) {
        ChannelCount.one => img.ChannelOrder.red,
        ChannelCount.two => img.ChannelOrder.grayAlpha,
        ChannelCount.three => img.ChannelOrder.rgb,
        ChannelCount.four => img.ChannelOrder.rgba,
      },
    );
  }
}
