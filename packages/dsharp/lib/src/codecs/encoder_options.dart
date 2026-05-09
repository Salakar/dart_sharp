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
    bool trellisQuantisation = false,
    bool? trellisQuantization,
    this.overshootDeringing = false,
    int? quantisationTable,
    int? quantizationTable,
    this.mozjpeg = false,
    super.force,
  }) : optimizeScans = optimizeScans ?? optimiseScans ?? false,
       trellisQuantisation = trellisQuantization ?? trellisQuantisation,
       quantizationTable = quantizationTable ?? quantisationTable ?? 0,
       progressive = progressive || (optimizeScans ?? optimiseScans ?? false);

  /// Quality from 1 to 100.
  final int quality;

  /// Whether to emit progressive JPEG.
  final bool progressive;

  /// Whether to optimize progressive scan output.
  final bool optimizeScans;

  /// Chroma subsampling mode.
  final String chromaSubsampling;

  /// Whether to request trellis quantisation.
  ///
  /// `true` currently throws [UnsupportedCodecException].
  final bool trellisQuantisation;

  /// Whether to request overshoot deringing.
  ///
  /// `true` currently throws [UnsupportedCodecException].
  final bool overshootDeringing;

  /// Quantization table selector from 0 to 8.
  ///
  /// Values other than `0` currently throw [UnsupportedCodecException].
  final int quantizationTable;

  /// Whether to request mozjpeg-style defaults.
  ///
  /// `true` currently throws [UnsupportedCodecException].
  final bool mozjpeg;

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
    if (quantizationTable < 0 || quantizationTable > 8) {
      throw const OperationValidationException(
        'JPEG quantizationTable must be 0..8.',
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
    this.quality,
    this.effort,
    this.dither = 1,
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

  /// Optional palette quality request from 0 to 100.
  final int? quality;

  /// Optional palette effort request from 1 to 10.
  final int? effort;

  /// Floyd-Steinberg dithering level from 0 to 1.
  final num dither;

  /// Optional maximum palette entry count.
  final int? colors;

  /// Whether this output should use a palette.
  bool get usesPalette =>
      palette ||
      colors != null ||
      quality != null ||
      effort != null ||
      dither != 1;

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
    final qualityValue = quality;
    if (qualityValue != null && (qualityValue < 0 || qualityValue > 100)) {
      throw const OperationValidationException(
        'PNG quality must be between 0 and 100.',
      );
    }
    final effortValue = effort;
    if (effortValue != null && (effortValue < 1 || effortValue > 10)) {
      throw const OperationValidationException('PNG effort must be 1..10.');
    }
    if (dither < 0 || dither > 1) {
      throw const OperationValidationException(
        'PNG dither must be between 0 and 1.',
      );
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
    this.effort = 7,
    this.dither = 1,
    this.interFrameMaxError = 0,
    this.interPaletteMaxError = 3,
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

  /// Encoder effort from 1 to 10.
  ///
  /// Values other than `7` currently throw [UnsupportedCodecException].
  final int effort;

  /// Floyd-Steinberg dithering level from 0 to 1.
  ///
  /// Values other than `1` currently throw [UnsupportedCodecException].
  final num dither;

  /// Maximum inter-frame transparency error from 0 to 32.
  ///
  /// Values other than `0` currently throw [UnsupportedCodecException].
  final int interFrameMaxError;

  /// Maximum palette reuse error from 0 to 256.
  ///
  /// Values other than `3` currently throw [UnsupportedCodecException].
  final int interPaletteMaxError;

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
    if (effort < 1 || effort > 10) {
      throw const OperationValidationException('GIF effort must be 1..10.');
    }
    if (dither < 0 || dither > 1) {
      throw const OperationValidationException(
        'GIF dither must be between 0 and 1.',
      );
    }
    if (interFrameMaxError < 0 || interFrameMaxError > 32) {
      throw const OperationValidationException(
        'GIF interFrameMaxError must be 0..32.',
      );
    }
    if (interPaletteMaxError < 0 || interPaletteMaxError > 256) {
      throw const OperationValidationException(
        'GIF interPaletteMaxError must be 0..256.',
      );
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

  /// JPEG compression.
  jpeg,

  /// Deflate compression.
  deflate,

  /// PackBits run-length compression.
  packBits,

  /// CCITT Group 4 fax compression.
  ccittFax4,

  /// LZW compression.
  lzw,

  /// WebP compression.
  webp,

  /// Zstandard compression.
  zstd,

  /// JPEG 2000 compression.
  jp2k,
}

/// TIFF compression predictor.
enum TiffPredictor {
  /// No prediction.
  none,

  /// Horizontal differencing.
  horizontal,

  /// Floating-point prediction.
  float,
}

/// TIFF resolution unit.
enum TiffResolutionUnit {
  /// Inches.
  inch,

  /// Centimetres.
  cm,
}

/// TIFF encoder options.
final class TiffEncoderOptions extends EncoderOptions {
  /// Creates TIFF options.
  const TiffEncoderOptions({
    this.quality = 80,
    this.compression = TiffCompression.jpeg,
    int bitDepth = 8,
    int? bitdepth,
    bool bigTiff = false,
    bool? bigtiff,
    this.predictor = TiffPredictor.horizontal,
    this.tile = false,
    this.pyramid = false,
    this.tileWidth = 256,
    this.tileHeight = 256,
    this.xres = 1,
    this.yres = 1,
    this.resolutionUnit = TiffResolutionUnit.inch,
    this.miniswhite = false,
    super.force,
  }) : bitDepth = bitdepth ?? bitDepth,
       bigTiff = bigtiff ?? bigTiff;

  /// Quality from 1 to 100 for lossy compression.
  final int quality;

  /// Compression mode.
  final TiffCompression compression;

  /// Bit depth.
  final int bitDepth;

  /// Whether to write BigTIFF.
  ///
  /// `true` currently throws [UnsupportedCodecException].
  final bool bigTiff;

  /// Compression predictor.
  ///
  /// Values other than [TiffPredictor.horizontal] currently throw
  /// [UnsupportedCodecException].
  final TiffPredictor predictor;

  /// Whether to write tiled TIFF.
  final bool tile;

  /// Whether to write an image pyramid.
  final bool pyramid;

  /// Horizontal tile size.
  ///
  /// Values other than `256` currently throw [UnsupportedCodecException].
  final int tileWidth;

  /// Vertical tile size.
  ///
  /// Values other than `256` currently throw [UnsupportedCodecException].
  final int tileHeight;

  /// Horizontal resolution in pixels per millimetre.
  ///
  /// Values other than `1` currently throw [UnsupportedCodecException].
  final num xres;

  /// Vertical resolution in pixels per millimetre.
  ///
  /// Values other than `1` currently throw [UnsupportedCodecException].
  final num yres;

  /// TIFF resolution unit.
  ///
  /// Values other than [TiffResolutionUnit.inch] currently throw
  /// [UnsupportedCodecException].
  final TiffResolutionUnit resolutionUnit;

  /// Whether to write 1-bit images as miniswhite.
  ///
  /// `true` currently throws [UnsupportedCodecException].
  final bool miniswhite;

  @override
  ImageFormat get format => ImageFormat.tiff;

  @override
  void validate() {
    _quality(quality);
    if (bitDepth != 1 && bitDepth != 2 && bitDepth != 4 && bitDepth != 8) {
      throw const OperationValidationException(
        'TIFF bitDepth must be one of 1, 2, 4, or 8.',
      );
    }
    if (tileWidth <= 0) {
      throw const OperationValidationException(
        'TIFF tileWidth must be greater than zero.',
      );
    }
    if (tileHeight <= 0) {
      throw const OperationValidationException(
        'TIFF tileHeight must be greater than zero.',
      );
    }
    if (xres <= 0) {
      throw const OperationValidationException(
        'TIFF xres must be greater than zero.',
      );
    }
    if (yres <= 0) {
      throw const OperationValidationException(
        'TIFF yres must be greater than zero.',
      );
    }
  }
}

/// WebP encoder options.
final class WebpEncoderOptions extends EncoderOptions {
  /// Creates WebP options.
  const WebpEncoderOptions({
    this.quality = 80,
    this.alphaQuality = 100,
    this.lossless = false,
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

  /// Whether to encode losslessly. Defaults to `false`.
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

  /// Whether to reduce lossy animation size by encoding changed regions.
  final bool minSize;

  /// Whether lossy animation frames may use VP8L when smaller.
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
