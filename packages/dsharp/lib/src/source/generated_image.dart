import '../pixels/color.dart';

/// Supported procedural noise generators for created images.
enum CreateNoiseType {
  /// Gaussian-distributed byte samples.
  gaussian,
}

/// Description of procedural noise for a generated image.
final class CreateNoise {
  /// Creates Gaussian noise options.
  const CreateNoise({
    this.type = CreateNoiseType.gaussian,
    this.mean = 128,
    this.sigma = 30,
    this.seed = 0,
  });

  /// Noise distribution type.
  final CreateNoiseType type;

  /// Mean sample value.
  final num mean;

  /// Standard deviation of sample values.
  final num sigma;

  /// Deterministic random seed.
  final int seed;
}

/// Description of an image generated from a solid background or noise.
final class CreateImage {
  /// Creates a generated image descriptor.
  const CreateImage({
    required this.width,
    required this.height,
    required this.channels,
    this.background = RgbaColor.black,
    this.noise,
    this.pageHeight,
  }) : assert(width > 0),
       assert(height > 0);

  /// Pixel width.
  final int width;

  /// Pixel height.
  final int height;

  /// Channel count, usually 3 or 4.
  final int channels;

  /// Fill background for solid images.
  final RgbaColor background;

  /// Optional procedural noise generator.
  final CreateNoise? noise;

  /// Optional page height for vertically stacked frames.
  final int? pageHeight;
}
