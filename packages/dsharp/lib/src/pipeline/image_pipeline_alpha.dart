part of 'image_pipeline.dart';

/// Alpha and channel pipeline operations.
extension ImagePipelineAlpha on ImagePipeline {
  /// Ensures an alpha channel.
  ImagePipeline ensureAlpha([int alpha = 255]) {
    return _append(EnsureAlphaOperation(alpha));
  }

  /// Removes alpha.
  ImagePipeline removeAlpha() {
    return _append(const RemoveAlphaOperation());
  }

  /// Flattens alpha against [background].
  ImagePipeline flatten([RgbaColor background = RgbaColor.black]) {
    return _append(FlattenOperation(background));
  }

  /// Extracts [channel] as grayscale.
  ImagePipeline extractChannel(Object channel) {
    return _append(ExtractChannelOperation(channel));
  }

  /// Joins a one-channel image as an additional channel.
  ImagePipeline joinChannel(PixelImage channel) {
    return _append(JoinChannelOperation(channel));
  }

  /// Makes white pixels transparent.
  ImagePipeline unflatten() {
    return _append(const UnflattenOperation());
  }

  /// Premultiplies RGB samples by alpha.
  ImagePipeline premultiplyAlpha() {
    return _append(const PremultiplyAlphaOperation());
  }

  /// Converts premultiplied RGB samples back to straight alpha.
  ImagePipeline unpremultiplyAlpha() {
    return _append(const UnpremultiplyAlphaOperation());
  }
}
