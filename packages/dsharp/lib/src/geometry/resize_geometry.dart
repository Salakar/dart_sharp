import 'dart:math';

import '../api/exceptions.dart';
import 'geometry.dart';

/// Resolved resize dimensions.
final class ResolvedResize {
  /// Creates resolved resize geometry.
  const ResolvedResize({required this.width, required this.height});

  /// Output width.
  final int width;

  /// Output height.
  final int height;
}

/// Resolves output dimensions for resize options.
ResolvedResize resolveResize({
  required int sourceWidth,
  required int sourceHeight,
  required ResizeOptions options,
}) {
  final requestedWidth = options.width;
  final requestedHeight = options.height;
  if (requestedWidth == null && requestedHeight == null) {
    return ResolvedResize(width: sourceWidth, height: sourceHeight);
  }
  if ((requestedWidth != null && requestedWidth <= 0) ||
      (requestedHeight != null && requestedHeight <= 0)) {
    throw const OperationValidationException(
      'Resize dimensions must be positive.',
    );
  }

  var width = requestedWidth;
  var height = requestedHeight;
  if (width == null) {
    width = (sourceWidth * (height! / sourceHeight)).round();
  } else if (height == null) {
    height = (sourceHeight * (width / sourceWidth)).round();
  } else if (options.fit == ResizeFit.inside ||
      options.fit == ResizeFit.outside) {
    final widthRatio = width / sourceWidth;
    final heightRatio = height / sourceHeight;
    final ratio = switch (options.fit) {
      ResizeFit.outside => max(widthRatio, heightRatio),
      ResizeFit.inside => min(widthRatio, heightRatio),
      ResizeFit.cover || ResizeFit.contain || ResizeFit.fill => widthRatio,
    };
    width = (sourceWidth * ratio).round();
    height = (sourceHeight * ratio).round();
  }

  if (options.withoutEnlargement &&
      (width > sourceWidth || height > sourceHeight)) {
    return ResolvedResize(width: sourceWidth, height: sourceHeight);
  }
  if (options.withoutReduction &&
      (width < sourceWidth || height < sourceHeight)) {
    return ResolvedResize(width: sourceWidth, height: sourceHeight);
  }
  return ResolvedResize(width: max(1, width), height: max(1, height));
}
