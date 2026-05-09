import 'dart:typed_data';

import '../codecs/image_format.dart';
import '../pixels/color.dart';
import '../pixels/pixel_image.dart';
import 'xmp_metadata.dart';

/// Basic metadata for an image or decoded pixel buffer.
final class ImageMetadata {
  /// Creates image metadata.
  const ImageMetadata({
    required this.format,
    required this.width,
    required this.height,
    required this.channels,
    required this.hasAlpha,
    this.size,
    this.frames = 1,
    this.pageHeight,
    this.loopCount,
    List<Duration> frameDelays = const <Duration>[],
    this.density,
    this.background,
    this.chromaSubsampling,
    List<ImageMetadataComment> comments = const <ImageMetadataComment>[],
    bool hasProfile = false,
    bool hasExif = false,
    bool hasXmp = false,
    Uint8List? iccProfile,
    Uint8List? exif,
    this.xmp,
    this.bitDepth,
    this.orientation,
    this.isProgressive = false,
    this.isPalette = false,
  }) : _frameDelays = frameDelays,
       _comments = comments,
       _iccProfile = iccProfile,
       _exif = exif,
       hasProfile = hasProfile || iccProfile != null,
       hasExif = hasExif || exif != null,
       hasXmp = hasXmp || xmp != null;

  /// Encoded or source format.
  final ImageFormat format;

  /// Encoded byte size when known.
  final int? size;

  /// Pixel width.
  final int width;

  /// Pixel height.
  final int height;

  /// Channel count.
  final int channels;

  /// Whether an alpha channel is present.
  final bool hasAlpha;

  /// Number of frames.
  final int frames;

  /// Optional page height for stacked frames.
  final int? pageHeight;

  /// Optional animation loop count.
  final int? loopCount;

  /// Sharp-style page/frame count when multi-frame.
  int? get pages => frames > 1 ? frames : null;

  /// Sharp-style animation loop count.
  int? get loop => loopCount;

  final List<Duration> _frameDelays;

  /// Animation frame delays when known.
  List<Duration> get frameDelays {
    return List<Duration>.unmodifiable(_frameDelays);
  }

  /// Sharp-style frame delays in milliseconds.
  List<int> get delay {
    return List<int>.unmodifiable(
      frameDelays.map((frameDelay) => frameDelay.inMilliseconds),
    );
  }

  /// Optional pixel density in DPI.
  final double? density;

  /// Default encoded background color when present.
  final RgbaColor? background;

  /// Encoded chroma subsampling description when present.
  final String? chromaSubsampling;

  final List<ImageMetadataComment> _comments;

  /// PNG text comments when present.
  List<ImageMetadataComment> get comments {
    return List<ImageMetadataComment>.unmodifiable(_comments);
  }

  /// Whether an ICC or similar color profile is present.
  final bool hasProfile;

  final Uint8List? _iccProfile;

  /// Embedded ICC profile bytes when present and parsed.
  Uint8List? get iccProfile => _copyBytes(_iccProfile);

  /// Whether EXIF metadata is present.
  final bool hasExif;

  final Uint8List? _exif;

  /// Embedded EXIF bytes when present and parsed.
  Uint8List? get exif => _copyBytes(_exif);

  /// Whether XMP metadata is present.
  final bool hasXmp;

  /// Embedded XMP metadata when present and parsed.
  final XmpMetadata? xmp;

  /// Embedded XMP metadata as text when present and parsed.
  String? get xmpAsString => xmp?.xmlText;

  /// Encoded bits per sample when known.
  final int? bitDepth;

  /// Sharp-style bits per sample when known.
  int? get bitsPerSample => bitDepth;

  /// Sharp-style pixel depth description when known.
  String? get depth {
    final bits = bitDepth;
    if (bits == null) {
      return null;
    }
    if (bits <= 8) {
      return 'uchar';
    }
    if (bits <= 16) {
      return 'ushort';
    }
    return null;
  }

  /// EXIF orientation value when present.
  final int? orientation;

  /// Dimensions after applying EXIF orientation.
  ImageDimensions get autoOrient {
    final shouldSwap = switch (orientation) {
      5 || 6 || 7 || 8 => true,
      _ => false,
    };
    return ImageDimensions(
      width: shouldSwap ? height : width,
      height: shouldSwap ? width : height,
    );
  }

  /// Whether the encoded image uses progressive/interlaced storage.
  final bool isProgressive;

  /// Whether the encoded image is palette-based.
  final bool isPalette;

  /// Creates metadata from decoded pixels.
  factory ImageMetadata.fromPixelImage({
    required PixelImage image,
    required ImageFormat format,
    int? size,
  }) {
    return ImageMetadata(
      format: format,
      size: size,
      width: image.width,
      height: image.height,
      channels: image.channels.value,
      hasAlpha: image.channels.value == 2 || image.channels.value == 4,
      frames: image.frames.length,
      pageHeight: image.firstFrame.pixels.pageHeight,
      loopCount: image.loopCount,
      frameDelays: <Duration>[
        for (final frame in image.frames)
          if (frame.delay != null) frame.delay!,
      ],
      bitDepth: 8,
    );
  }
}

/// PNG text metadata.
final class ImageMetadataComment {
  /// Creates PNG text metadata.
  const ImageMetadataComment({required this.keyword, required this.text});

  /// PNG text keyword.
  final String keyword;

  /// PNG text value.
  final String text;
}

/// Pixel dimensions.
final class ImageDimensions {
  /// Creates pixel dimensions.
  const ImageDimensions({required this.width, required this.height});

  /// Pixel width.
  final int width;

  /// Pixel height.
  final int height;
}

Uint8List? _copyBytes(Uint8List? bytes) {
  return bytes == null ? null : Uint8List.fromList(bytes);
}
