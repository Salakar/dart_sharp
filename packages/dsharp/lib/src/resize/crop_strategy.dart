import '../pixels/pixel_image.dart';

/// Crop strategy contract.
abstract interface class CropStrategy {
  /// Strategy name.
  String get name;

  /// Scores [image] for deterministic crop selection.
  double score(PixelImage image);
}

/// Entropy-based crop strategy.
final class EntropyCropStrategy implements CropStrategy {
  /// Creates an entropy strategy.
  const EntropyCropStrategy();

  @override
  String get name => 'entropy';

  @override
  double score(PixelImage image) {
    final bytes = image.firstFrameBytes();
    if (bytes.isEmpty) {
      return 0;
    }
    final seen = <int>{};
    for (var i = 0; i < bytes.length; i += image.channels.value) {
      seen.add(bytes[i]);
    }
    return seen.length / 256;
  }
}

/// Attention strategy placeholder using entropy until saliency is implemented.
final class AttentionCropStrategy implements CropStrategy {
  /// Creates an attention strategy.
  const AttentionCropStrategy();

  @override
  String get name => 'attention';

  @override
  double score(PixelImage image) {
    return const EntropyCropStrategy().score(image);
  }
}
