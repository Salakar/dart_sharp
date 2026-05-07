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
  factory GifPalette.fromRgba(Uint8List rgba) {
    final colors = <int, int>{};
    final indices = <int>[];
    int? transparent;
    for (var offset = 0; offset < rgba.length; offset += 4) {
      final alpha = rgba[offset + 3];
      final color = alpha < 128
          ? 0
          : (rgba[offset] << 16) | (rgba[offset + 1] << 8) | rgba[offset + 2];
      colors.putIfAbsent(color, () => colors.length);
      final index = colors[color]!;
      if (alpha < 128) {
        transparent = index;
      }
      indices.add(index);
    }
    if (colors.length > 256) {
      throw const UnsupportedCodecException('GIF palette exceeds 256 colours.');
    }
    var tableSize = 2;
    var tablePower = 1;
    while (tableSize < colors.length) {
      tableSize <<= 1;
      tablePower += 1;
    }
    final bytes = Uint8List(tableSize * 3);
    for (final entry in colors.entries) {
      bytes[entry.value * 3] = (entry.key >> 16) & 0xff;
      bytes[entry.value * 3 + 1] = (entry.key >> 8) & 0xff;
      bytes[entry.value * 3 + 2] = entry.key & 0xff;
    }
    return GifPalette(bytes, indices, colors.length, tablePower, transparent);
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
