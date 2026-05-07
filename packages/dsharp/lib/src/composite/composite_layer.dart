import '../api/exceptions.dart';
import '../geometry/geometry.dart';
import '../pixels/pixel_image.dart';
import 'blend_mode.dart';

/// One overlay image and its compositing options.
final class CompositeLayer {
  /// Creates a composite layer.
  const CompositeLayer({
    required this.image,
    this.blendMode = BlendMode.over,
    this.left,
    this.top,
    this.gravity = Gravity.center,
    this.tile = false,
    this.premultiplied = false,
  });

  /// Overlay image.
  final PixelImage image;

  /// Blend mode.
  final BlendMode blendMode;

  /// Optional left offset.
  final int? left;

  /// Optional top offset.
  final int? top;

  /// Gravity used when exact offsets are not supplied.
  final Gravity gravity;

  /// Whether the overlay should repeat.
  final bool tile;

  /// Whether overlay RGB samples are already premultiplied.
  final bool premultiplied;

  /// Validates placement options.
  void validate() {
    if ((left == null) != (top == null)) {
      throw const OperationValidationException(
        'Composite layer left and top must be supplied together.',
      );
    }
  }
}
