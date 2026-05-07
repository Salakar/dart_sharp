import '../api/exceptions.dart';

/// An RGBA color with 8-bit red, green, blue, and alpha channels.
final class RgbaColor {
  /// Creates an RGBA color.
  const RgbaColor({
    required this.red,
    required this.green,
    required this.blue,
    this.alpha = 255,
  }) : assert(red >= 0 && red <= 255),
       assert(green >= 0 && green <= 255),
       assert(blue >= 0 && blue <= 255),
       assert(alpha >= 0 && alpha <= 255);

  /// Creates an opaque RGB color.
  const RgbaColor.rgb(int red, int green, int blue)
    : this(red: red, green: green, blue: blue);

  /// Transparent black.
  static const RgbaColor transparent = RgbaColor(
    red: 0,
    green: 0,
    blue: 0,
    alpha: 0,
  );

  /// Opaque black.
  static const RgbaColor black = RgbaColor.rgb(0, 0, 0);

  /// Opaque white.
  static const RgbaColor white = RgbaColor.rgb(255, 255, 255);

  /// Red channel.
  final int red;

  /// Green channel.
  final int green;

  /// Blue channel.
  final int blue;

  /// Alpha channel.
  final int alpha;

  /// Creates a color after validating channel ranges at runtime.
  factory RgbaColor.checked({
    required int red,
    required int green,
    required int blue,
    int alpha = 255,
  }) {
    for (final entry in <String, int>{
      'red': red,
      'green': green,
      'blue': blue,
      'alpha': alpha,
    }.entries) {
      if (entry.value < 0 || entry.value > 255) {
        throw OperationValidationException(
          'Expected ${entry.key} to be between 0 and 255.',
        );
      }
    }
    return RgbaColor(red: red, green: green, blue: blue, alpha: alpha);
  }
}
