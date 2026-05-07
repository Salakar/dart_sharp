import 'dart:typed_data';

import '../api/capabilities.dart';
import '../api/exceptions.dart';
import '../pixels/pixel_image.dart';
import '../source/raw_pixels.dart';
import 'codec.dart';
import 'format_sniffer.dart';
import 'image_format.dart';
import 'output.dart';
import 'package_image_codec.dart';
import 'raw_codec.dart';
import 'unsupported_codec.dart';

/// Registry of pure Dart image codecs.
final class CodecRegistry {
  /// Creates a codec registry.
  CodecRegistry(Iterable<ImageCodec> codecs)
    : _codecs = Map<ImageFormat, ImageCodec>.unmodifiable({
        for (final codec in codecs) codec.format: codec,
      });

  /// Default registry used by pipelines.
  factory CodecRegistry.defaultRegistry() {
    return CodecRegistry(<ImageCodec>[
      const RawImageCodec(),
      const PackageImageCodec(ImageFormat.png),
      const PackageImageCodec(ImageFormat.jpeg),
      const PackageImageCodec(ImageFormat.gif),
      const PackageImageCodec(ImageFormat.tiff),
      const PackageImageCodec(ImageFormat.webp),
      const UnsupportedImageCodec(
        ImageFormat.avif,
        reason: 'No pure Dart AVIF codec is wired yet.',
      ),
      const UnsupportedImageCodec(
        ImageFormat.heif,
        reason: 'No pure Dart HEIF codec is wired yet.',
      ),
      const UnsupportedImageCodec(
        ImageFormat.jp2,
        reason: 'No pure Dart JPEG 2000 codec is wired yet.',
      ),
      const UnsupportedImageCodec(
        ImageFormat.jxl,
        reason: 'No pure Dart JPEG XL codec is wired yet.',
      ),
      const UnsupportedImageCodec(
        ImageFormat.svg,
        reason: 'SVG rasterization needs a pure Dart renderer.',
      ),
      const UnsupportedImageCodec(
        ImageFormat.pdf,
        reason: 'PDF rasterization is not available in the pure Dart core.',
      ),
      const UnsupportedImageCodec(
        ImageFormat.openSlide,
        reason: 'OpenSlide support depends on native libraries.',
      ),
      const UnsupportedImageCodec(
        ImageFormat.magick,
        reason: 'Magick-backed formats depend on native libraries.',
      ),
      const UnsupportedImageCodec(
        ImageFormat.dcraw,
        reason: 'Camera raw decoding is not implemented in pure Dart.',
      ),
      const UnsupportedImageCodec(
        ImageFormat.fits,
        reason: 'FITS decoding is not implemented in pure Dart.',
      ),
      const UnsupportedImageCodec(
        ImageFormat.rad,
        reason: 'Radiance HDR decoding is not implemented in pure Dart.',
      ),
      const UnsupportedImageCodec(
        ImageFormat.vips,
        reason: 'Native V image data is not part of the pure Dart core.',
      ),
      const UnsupportedImageCodec(
        ImageFormat.deepZoom,
        reason: 'Deep zoom tile output is not implemented yet.',
      ),
    ]);
  }

  final Map<ImageFormat, ImageCodec> _codecs;

  /// Registered codec formats.
  Iterable<ImageFormat> get formats => _codecs.keys;

  /// Returns the codec for [format].
  ImageCodec codecFor(ImageFormat format) {
    final codec = _codecs[format];
    if (codec == null) {
      throw UnsupportedCodecException('${format.id} is not registered.');
    }
    return codec;
  }

  /// Decodes bytes after sniffing the format when [format] is omitted.
  PixelImage decode(Uint8List bytes, {ImageFormat? format}) {
    final resolved = format ?? sniffImageFormat(bytes);
    return codecFor(resolved).decode(bytes);
  }

  /// Decodes raw pixels.
  PixelImage decodeRaw(RawPixels pixels) {
    return const RawImageCodec().decodeRaw(pixels);
  }

  /// Encodes [image] as [format].
  EncodedImage encode(PixelImage image, {required ImageFormat format}) {
    return codecFor(format).encode(image);
  }

  /// Capability table aligned with this registry.
  DsharpCapabilities get capabilities => DsharpCapabilities.current;
}
