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
    bool progressive = false,
    bool? optimizeScans,
    bool? optimiseScans,
    this.chromaSubsampling = '4:2:0',
    super.force,
  }) : optimizeScans = optimizeScans ?? optimiseScans ?? false,
       progressive = progressive || (optimizeScans ?? optimiseScans ?? false);

  /// Quality from 1 to 100.
  final int quality;

  /// Whether to emit progressive JPEG.
  final bool progressive;

  /// Whether to optimize progressive scan output.
  final bool optimizeScans;

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
    this.adaptiveFiltering = false,
    this.palette = false,
    this.bitDepth = 8,
    int? colors,
    int? colours,
    super.force,
  }) : colors = colors ?? colours;

  /// Zlib compression level from 0 to 9.
  final int compressionLevel;

  /// Whether to use interlace/progressive output.
  final bool progressive;

  /// Whether to adaptively select the best PNG row filter.
  final bool adaptiveFiltering;

  /// Whether to quantize to a palette.
  final bool palette;

  /// Bit depth.
  final int bitDepth;

  /// Optional maximum palette entry count.
  final int? colors;

  /// Whether this output should use a palette.
  bool get usesPalette => palette || colors != null;

  /// Palette bit depth derived from [colors] when provided.
  int get paletteBitDepth {
    final colorCount = colors;
    return colorCount == null
        ? bitDepth
        : _bitDepthForPaletteColors(colorCount);
  }

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
    final colorCount = colors;
    if (colorCount != null && (colorCount < 2 || colorCount > 256)) {
      throw const OperationValidationException('PNG colors must be 2..256.');
    }
  }
}

/// GIF encoder options.
final class GifEncoderOptions extends EncoderOptions {
  /// Creates GIF options.
  const GifEncoderOptions({
    this.reuse = true,
    this.progressive = false,
    int colors = 256,
    int? colours,
    this.keepDuplicateFrames = false,
    int? loopCount,
    int? loop,
    Duration? frameDelay,
    Duration? delay,
    List<Duration>? frameDelays,
    List<Duration>? delays,
    super.force,
  }) : colors = colours ?? colors,
       loopCount = loopCount ?? loop,
       frameDelay = frameDelay ?? delay,
       frameDelays = frameDelays ?? delays ?? const <Duration>[];

  /// Whether to reuse an existing palette where possible.
  final bool reuse;

  /// Whether to write progressive output.
  final bool progressive;

  /// Palette size.
  final int colors;

  /// Whether duplicate frames should be kept.
  final bool keepDuplicateFrames;

  /// Optional animation loop count, where 0 means infinite looping.
  final int? loopCount;

  /// Optional display delay to apply to every encoded animation frame.
  final Duration? frameDelay;

  /// Optional per-frame display delays for encoded animation frames.
  final List<Duration> frameDelays;

  @override
  ImageFormat get format => ImageFormat.gif;

  @override
  void validate() {
    if (colors < 2 || colors > 256) {
      throw const OperationValidationException('GIF colors must be 2..256.');
    }
    final loop = loopCount;
    if (loop != null && (loop < 0 || loop > 0xffff)) {
      throw const OperationValidationException(
        'GIF loop count must be 0..65535.',
      );
    }
    final delay = frameDelay;
    if (delay != null && (delay.isNegative || delay.inMilliseconds > 0xffff)) {
      throw const OperationValidationException(
        'GIF frame delay must be 0..65535 ms.',
      );
    }
    for (final frameDelay in frameDelays) {
      if (frameDelay.isNegative || frameDelay.inMilliseconds > 0xffff) {
        throw const OperationValidationException(
          'GIF frame delay must be 0..65535 ms.',
        );
      }
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
    this.alphaQuality = 100,
    this.lossless = true,
    this.nearLossless = false,
    this.smartSubsample = false,
    this.smartDeblock = false,
    this.preset = 'default',
    this.effort = 4,
    int? loopCount,
    int? loop,
    Duration? frameDelay,
    Duration? delay,
    List<Duration>? frameDelays,
    List<Duration>? delays,
    this.minSize = false,
    this.mixed = false,
    super.force,
  }) : loopCount = loopCount ?? loop,
       frameDelay = frameDelay ?? delay,
       frameDelays = frameDelays ?? delays ?? const <Duration>[];

  /// Quality from 1 to 100.
  final int quality;

  /// Alpha-layer quality from 0 to 100.
  final int alphaQuality;

  /// Whether to encode losslessly.
  final bool lossless;

  /// Whether to request near-lossless preprocessing.
  final bool nearLossless;

  /// Whether to request higher-quality chroma subsampling.
  final bool smartSubsample;

  /// Whether to request automatic deblocking.
  final bool smartDeblock;

  /// Named WebP preprocessing preset.
  final String preset;

  /// Encoder effort from 0 to 6.
  final int effort;

  /// Optional animation loop count, where 0 means infinite looping.
  final int? loopCount;

  /// Optional display delay to apply to every encoded animation frame.
  final Duration? frameDelay;

  /// Optional per-frame display delays for encoded animation frames.
  final List<Duration> frameDelays;

  /// Whether to request minimum-size animation encoding.
  final bool minSize;

  /// Whether to request mixed lossy/lossless animation encoding.
  final bool mixed;

  @override
  ImageFormat get format => ImageFormat.webp;

  @override
  void validate() {
    _quality(quality);
    if (alphaQuality < 0 || alphaQuality > 100) {
      throw const OperationValidationException(
        'WebP alphaQuality must be between 0 and 100.',
      );
    }
    const presets = <String>{
      'default',
      'photo',
      'picture',
      'drawing',
      'icon',
      'text',
    };
    if (!presets.contains(preset)) {
      throw const OperationValidationException(
        'WebP preset must be one of: default, photo, picture, drawing, icon, '
        'text.',
      );
    }
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
    if (delay != null && (delay.isNegative || delay.inMilliseconds > 0xffff)) {
      throw const OperationValidationException(
        'WebP frame delay must be 0..65535 ms.',
      );
    }
    for (final frameDelay in frameDelays) {
      if (frameDelay.isNegative || frameDelay.inMilliseconds > 0xffff) {
        throw const OperationValidationException(
          'WebP frame delay must be 0..65535 ms.',
        );
      }
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

int _bitDepthForPaletteColors(int colors) {
  if (colors <= 2) {
    return 1;
  }
  if (colors <= 4) {
    return 2;
  }
  if (colors <= 16) {
    return 4;
  }
  return 8;
}
