import '../api/exceptions.dart';
import 'image_format.dart';

/// Base type for encoder options.
sealed class EncoderOptions {
  /// Creates encoder options.
  const EncoderOptions({this.force = true});

  /// Whether this format should be forced over the input format.
  final bool force;

  /// Target format.
  ImageFormat get format;

  /// Validates option ranges.
  void validate();
}

/// JPEG encoder options.
final class JpegEncoderOptions extends EncoderOptions {
  /// Creates JPEG options.
  const JpegEncoderOptions({
    this.quality = 80,
    this.progressive = false,
    this.chromaSubsampling = '4:2:0',
    super.force,
  });

  /// Quality from 1 to 100.
  final int quality;

  /// Whether to emit progressive JPEG.
  final bool progressive;

  /// Chroma subsampling mode.
  final String chromaSubsampling;

  @override
  ImageFormat get format => ImageFormat.jpeg;

  @override
  void validate() {
    _quality(quality);
    if (chromaSubsampling != '4:2:0' && chromaSubsampling != '4:4:4') {
      throw const OperationValidationException(
        'JPEG chromaSubsampling must be 4:2:0 or 4:4:4.',
      );
    }
  }
}

/// PNG encoder options.
final class PngEncoderOptions extends EncoderOptions {
  /// Creates PNG options.
  const PngEncoderOptions({
    this.compressionLevel = 6,
    this.progressive = false,
    this.palette = false,
    this.bitDepth = 8,
    super.force,
  });

  /// Zlib compression level from 0 to 9.
  final int compressionLevel;

  /// Whether to use interlace/progressive output.
  final bool progressive;

  /// Whether to quantize to a palette.
  final bool palette;

  /// Bit depth.
  final int bitDepth;

  @override
  ImageFormat get format => ImageFormat.png;

  @override
  void validate() {
    if (compressionLevel < 0 || compressionLevel > 9) {
      throw const OperationValidationException(
        'PNG compressionLevel must be between 0 and 9.',
      );
    }
    _bitDepth(bitDepth);
  }
}

/// GIF encoder options.
final class GifEncoderOptions extends EncoderOptions {
  /// Creates GIF options.
  const GifEncoderOptions({
    this.reuse = true,
    this.progressive = false,
    this.colors = 256,
    this.keepDuplicateFrames = false,
    super.force,
  });

  /// Whether to reuse an existing palette where possible.
  final bool reuse;

  /// Whether to write progressive output.
  final bool progressive;

  /// Palette size.
  final int colors;

  /// Whether duplicate frames should be kept.
  final bool keepDuplicateFrames;

  @override
  ImageFormat get format => ImageFormat.gif;

  @override
  void validate() {
    if (colors < 2 || colors > 256) {
      throw const OperationValidationException('GIF colors must be 2..256.');
    }
  }
}

/// TIFF compression mode.
enum TiffCompression {
  /// No compression.
  none,

  /// LZW compression.
  lzw,

  /// PackBits run-length compression.
  packBits,

  /// Deflate compression.
  deflate,

  /// JPEG compression.
  jpeg,
}

/// TIFF encoder options.
final class TiffEncoderOptions extends EncoderOptions {
  /// Creates TIFF options.
  const TiffEncoderOptions({
    this.quality = 80,
    this.compression = TiffCompression.none,
    this.bitDepth = 8,
    this.tile = false,
    this.pyramid = false,
    super.force,
  });

  /// Quality from 1 to 100 for lossy compression.
  final int quality;

  /// Compression mode.
  final TiffCompression compression;

  /// Bit depth.
  final int bitDepth;

  /// Whether to write tiled TIFF.
  final bool tile;

  /// Whether to write an image pyramid.
  final bool pyramid;

  @override
  ImageFormat get format => ImageFormat.tiff;

  @override
  void validate() {
    _quality(quality);
    _bitDepth(bitDepth);
  }
}

/// WebP encoder options.
final class WebpEncoderOptions extends EncoderOptions {
  /// Creates WebP options.
  const WebpEncoderOptions({
    this.quality = 80,
    this.lossless = true,
    this.effort = 4,
    this.loopCount,
    this.frameDelay,
    super.force,
  });

  /// Quality from 1 to 100.
  final int quality;

  /// Whether to encode losslessly.
  final bool lossless;

  /// Encoder effort from 0 to 6.
  final int effort;

  /// Optional animation loop count, where 0 means infinite looping.
  final int? loopCount;

  /// Optional display delay to apply to every encoded animation frame.
  final Duration? frameDelay;

  @override
  ImageFormat get format => ImageFormat.webp;

  @override
  void validate() {
    _quality(quality);
    if (effort < 0 || effort > 6) {
      throw const OperationValidationException('WebP effort must be 0..6.');
    }
    final loop = loopCount;
    if (loop != null && (loop < 0 || loop > 0xffff)) {
      throw const OperationValidationException(
        'WebP loop count must be 0..65535.',
      );
    }
    final delay = frameDelay;
    if (delay != null &&
        (delay.isNegative || delay.inMilliseconds > 0xffffff)) {
      throw const OperationValidationException(
        'WebP frame delay must be 0..16777215 ms.',
      );
    }
  }
}

/// Raw encoder options.
final class RawEncoderOptions extends EncoderOptions {
  /// Creates raw options.
  const RawEncoderOptions({super.force});

  @override
  ImageFormat get format => ImageFormat.raw;

  @override
  void validate() {}
}

/// Placeholder options for unsupported future encoders.
final class UnsupportedEncoderOptions extends EncoderOptions {
  /// Creates unsupported encoder options.
  const UnsupportedEncoderOptions({required this.format, super.force});

  @override
  final ImageFormat format;

  @override
  void validate() {}
}

void _quality(int quality) {
  if (quality < 1 || quality > 100) {
    throw const OperationValidationException(
      'Quality must be between 1 and 100.',
    );
  }
}

void _bitDepth(int bitDepth) {
  if (bitDepth != 1 &&
      bitDepth != 2 &&
      bitDepth != 4 &&
      bitDepth != 8 &&
      bitDepth != 16) {
    throw const OperationValidationException(
      'Bit depth must be one of 1, 2, 4, 8, or 16.',
    );
  }
}
