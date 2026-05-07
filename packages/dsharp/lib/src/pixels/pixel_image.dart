import 'dart:typed_data';

import '../api/exceptions.dart';
import '../source/raw_pixels.dart';

/// One decoded image frame.
final class ImageFrame {
  /// Creates an image frame from raw pixels.
  const ImageFrame({required this.pixels, this.delay});

  /// Raw frame pixels.
  final RawPixels pixels;

  /// Optional display delay for animated images.
  final Duration? delay;

  /// Frame width.
  int get width => pixels.width;

  /// Frame height.
  int get height => pixels.height;
}

/// Decoded pixel image with one or more frames.
final class PixelImage {
  /// Creates a decoded pixel image from frames.
  PixelImage({required Iterable<ImageFrame> frames, this.loopCount})
    : _frames = List<ImageFrame>.unmodifiable(frames) {
    if (_frames.isEmpty) {
      throw const InvalidImageException('Expected at least one image frame.');
    }
    final first = _frames.first;
    for (final frame in _frames.skip(1)) {
      if (frame.width != first.width || frame.height != first.height) {
        throw const InvalidImageException(
          'Expected all image frames to have matching dimensions.',
        );
      }
    }
  }

  /// Creates a single-frame image from raw pixels.
  factory PixelImage.fromRawPixels(RawPixels pixels) {
    return PixelImage(frames: <ImageFrame>[ImageFrame(pixels: pixels)]);
  }

  final List<ImageFrame> _frames;

  /// Image frames.
  List<ImageFrame> get frames => List<ImageFrame>.unmodifiable(_frames);

  /// Optional animation loop count.
  final int? loopCount;

  /// Primary frame.
  ImageFrame get firstFrame => _frames.first;

  /// Pixel width.
  int get width => firstFrame.width;

  /// Pixel height.
  int get height => firstFrame.height;

  /// Channel count.
  ChannelCount get channels => firstFrame.pixels.channels;

  /// Whether this image has multiple frames.
  bool get isAnimated => _frames.length > 1;

  /// Returns a defensive copy of the first frame bytes.
  Uint8List firstFrameBytes() => firstFrame.pixels.bytes;
}
