import 'dart:math';
import 'dart:typed_data';

import '../api/exceptions.dart';
import '../operations/pixel_helpers.dart';
import '../pixels/color.dart';
import '../pixels/pixel_image.dart';
import '../source/raw_pixels.dart';

/// Horizontal alignment inside join cells.
enum HorizontalAlign {
  /// Align left.
  left,

  /// Align center.
  center,

  /// Align right.
  right,
}

/// Vertical alignment inside join cells.
enum VerticalAlign {
  /// Align top.
  top,

  /// Align middle.
  center,

  /// Align bottom.
  bottom,
}

/// Options for joining images into a grid.
final class JoinOptions {
  /// Creates join options.
  const JoinOptions({
    this.across = 1,
    this.shim = 0,
    this.background = RgbaColor.transparent,
    this.horizontalAlign = HorizontalAlign.left,
    this.verticalAlign = VerticalAlign.top,
    this.animated = false,
  });

  /// Number of images per row.
  final int across;

  /// Gap between joined images.
  final int shim;

  /// Background fill.
  final RgbaColor background;

  /// Horizontal cell alignment.
  final HorizontalAlign horizontalAlign;

  /// Vertical cell alignment.
  final VerticalAlign verticalAlign;

  /// Whether to preserve and join animation frames.
  final bool animated;

  /// Validates options.
  void validate() {
    if (across <= 0) {
      throw const OperationValidationException('Join across must be positive.');
    }
    if (shim < 0) {
      throw const OperationValidationException(
        'Join shim must be non-negative.',
      );
    }
  }
}

/// Joins images into a grid and returns decoded pixels.
PixelImage joinImages(
  List<PixelImage> images, {
  JoinOptions options = const JoinOptions(),
}) {
  options.validate();
  if (images.isEmpty) {
    throw const OperationValidationException(
      'Expected at least one image to join.',
    );
  }
  final layout = _layout(images, options);
  final frameCount = options.animated
      ? images.map((image) => image.frames.length).reduce(max)
      : 1;
  return PixelImage(
    frames: <ImageFrame>[
      for (var frame = 0; frame < frameCount; frame += 1)
        ImageFrame(
          pixels: _joinFrame(images, options, layout, frame),
          delay: images
              .first
              .frames[min(frame, images.first.frames.length - 1)]
              .delay,
        ),
    ],
    loopCount: options.animated ? images.first.loopCount : null,
  );
}

_JoinLayout _layout(List<PixelImage> images, JoinOptions options) {
  final columns = min(options.across, images.length);
  final rows = (images.length + columns - 1) ~/ columns;
  final columnWidths = List<int>.filled(columns, 0);
  final rowHeights = List<int>.filled(rows, 0);
  for (var i = 0; i < images.length; i += 1) {
    final column = i % columns;
    final row = i ~/ columns;
    columnWidths[column] = max(columnWidths[column], images[i].width);
    rowHeights[row] = max(rowHeights[row], images[i].height);
  }
  return _JoinLayout(
    columns: columns,
    columnWidths: columnWidths,
    rowHeights: rowHeights,
    width:
        columnWidths.reduce((a, b) => a + b) + (options.shim * (columns - 1)),
    height: rowHeights.reduce((a, b) => a + b) + (options.shim * (rows - 1)),
  );
}

RawPixels _joinFrame(
  List<PixelImage> images,
  JoinOptions options,
  _JoinLayout layout,
  int frame,
) {
  final output = Uint8List(layout.width * layout.height * 4);
  _fill(output, options.background);
  for (var i = 0; i < images.length; i += 1) {
    final raw = _frame(images[i], frame);
    final column = i % layout.columns;
    final row = i ~/ layout.columns;
    final cellLeft =
        _sum(layout.columnWidths, column) + (column * options.shim);
    final cellTop = _sum(layout.rowHeights, row) + (row * options.shim);
    final left =
        cellLeft +
        _horizontalOffset(layout.columnWidths[column], raw.width, options);
    final top =
        cellTop + _verticalOffset(layout.rowHeights[row], raw.height, options);
    _copy(raw, output, layout.width, left, top);
  }
  return RawPixels(
    bytes: output,
    width: layout.width,
    height: layout.height,
    channels: ChannelCount.four,
  );
}

RawPixels _frame(PixelImage image, int frame) {
  if (image.isAnimated && frame < image.frames.length) {
    return image.frames[frame].pixels;
  }
  return image.firstFrame.pixels;
}

void _fill(Uint8List output, RgbaColor color) {
  for (var i = 0; i < output.length; i += 4) {
    output[i] = color.red;
    output[i + 1] = color.green;
    output[i + 2] = color.blue;
    output[i + 3] = color.alpha;
  }
}

void _copy(
  RawPixels raw,
  Uint8List output,
  int outputWidth,
  int left,
  int top,
) {
  final input = raw.bytes;
  for (var y = 0; y < raw.height; y += 1) {
    for (var x = 0; x < raw.width; x += 1) {
      final source = ((y * raw.width) + x) * raw.channels.value;
      final target = (((top + y) * outputWidth) + left + x) * 4;
      final color = readColor(input, source, raw.channels.value);
      output[target] = color.red;
      output[target + 1] = color.green;
      output[target + 2] = color.blue;
      output[target + 3] = color.alpha;
    }
  }
}

int _horizontalOffset(int cellWidth, int width, JoinOptions options) {
  return switch (options.horizontalAlign) {
    HorizontalAlign.left => 0,
    HorizontalAlign.center => (cellWidth - width) ~/ 2,
    HorizontalAlign.right => cellWidth - width,
  };
}

int _verticalOffset(int cellHeight, int height, JoinOptions options) {
  return switch (options.verticalAlign) {
    VerticalAlign.top => 0,
    VerticalAlign.center => (cellHeight - height) ~/ 2,
    VerticalAlign.bottom => cellHeight - height,
  };
}

int _sum(List<int> values, int end) {
  var total = 0;
  for (var i = 0; i < end; i += 1) {
    total += values[i];
  }
  return total;
}

final class _JoinLayout {
  const _JoinLayout({
    required this.columns,
    required this.columnWidths,
    required this.rowHeights,
    required this.width,
    required this.height,
  });

  final int columns;
  final List<int> columnWidths;
  final List<int> rowHeights;
  final int width;
  final int height;
}
