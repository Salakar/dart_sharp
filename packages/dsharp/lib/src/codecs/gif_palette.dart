import 'dart:typed_data';

import '../api/exceptions.dart';

/// Palette and index stream used by the GIF encoder.
final class GifPalette {
  /// Creates a palette.
  GifPalette(
    this.bytes,
    this.indices,
    this.size,
    this.tablePower,
    this.transparentIndex,
  );

  /// Builds a palette from RGBA pixels.
  factory GifPalette.fromRgba(Uint8List rgba, {int maxColors = 256}) {
    if (maxColors < 2 || maxColors > 256) {
      throw const OperationValidationException('GIF colors must be 2..256.');
    }
    final hasTransparent = _hasTransparentPixels(rgba);
    final opaqueLimit = hasTransparent ? maxColors - 1 : maxColors;
    final colors = <int, int>{};
    final palette = <int>[];
    final indices = <int>[];
    final transparent = hasTransparent ? 0 : null;
    for (var offset = 0; offset < rgba.length; offset += 4) {
      final alpha = rgba[offset + 3];
      if (alpha < 128) {
        indices.add(transparent!);
        continue;
      }
      final color =
          (rgba[offset] << 16) | (rgba[offset + 1] << 8) | rgba[offset + 2];
      final cached = colors[color];
      if (cached != null) {
        indices.add(cached);
        continue;
      }
      final index = palette.length < opaqueLimit
          ? _addColor(colors, palette, color, hasTransparent)
          : _nearestColorIndex(color, palette, hasTransparent);
      colors[color] = index;
      indices.add(index);
    }
    var tableSize = 2;
    var tablePower = 1;
    final usedColors = palette.length + (hasTransparent ? 1 : 0);
    while (tableSize < usedColors) {
      tableSize <<= 1;
      tablePower += 1;
    }
    final bytes = Uint8List(tableSize * 3);
    final base = hasTransparent ? 1 : 0;
    for (var i = 0; i < palette.length; i += 1) {
      final color = palette[i];
      final offset = (base + i) * 3;
      bytes[offset] = (color >> 16) & 0xff;
      bytes[offset + 1] = (color >> 8) & 0xff;
      bytes[offset + 2] = color & 0xff;
    }
    return GifPalette(bytes, indices, usedColors, tablePower, transparent);
  }

  /// Palette bytes padded to a power-of-two GIF table.
  final Uint8List bytes;

  /// Per-pixel palette indices.
  final List<int> indices;

  /// Number of used colours.
  final int size;

  /// GIF table size power value.
  final int tablePower;

  /// Transparent palette index, if any.
  final int? transparentIndex;
}

bool _hasTransparentPixels(Uint8List rgba) {
  for (var offset = 3; offset < rgba.length; offset += 4) {
    if (rgba[offset] < 128) {
      return true;
    }
  }
  return false;
}

int _addColor(
  Map<int, int> colors,
  List<int> palette,
  int color,
  bool hasTransparent,
) {
  final index = palette.length + (hasTransparent ? 1 : 0);
  palette.add(color);
  colors[color] = index;
  return index;
}

int _nearestColorIndex(int color, List<int> palette, bool hasTransparent) {
  var bestIndex = 0;
  var bestDistance = 1 << 62;
  for (var i = 0; i < palette.length; i += 1) {
    final candidate = palette[i];
    final distance =
        _square(((color >> 16) & 0xff) - ((candidate >> 16) & 0xff)) +
        _square(((color >> 8) & 0xff) - ((candidate >> 8) & 0xff)) +
        _square((color & 0xff) - (candidate & 0xff));
    if (distance < bestDistance) {
      bestDistance = distance;
      bestIndex = i;
    }
  }
  return bestIndex + (hasTransparent ? 1 : 0);
}

int _square(int value) => value * value;
