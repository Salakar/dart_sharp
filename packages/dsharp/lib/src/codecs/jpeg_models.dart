import 'dart:typed_data';

import 'jpeg_bit_io.dart';

/// JPEG frame component.
final class JpegComponent {
  /// Creates a component.
  JpegComponent({
    required this.id,
    required this.h,
    required this.v,
    required this.quantId,
  });

  /// Component identifier.
  final int id;

  /// Horizontal sampling factor.
  final int h;

  /// Vertical sampling factor.
  final int v;

  /// Quantization table identifier.
  final int quantId;

  /// DC Huffman table selector.
  int dcTable = 0;

  /// AC Huffman table selector.
  int acTable = 0;

  /// Last DC predictor.
  int predictor = 0;

  /// Decoded component width.
  int width = 0;

  /// Decoded component height.
  int height = 0;

  /// Decoded samples.
  Uint8List samples = Uint8List(0);
}

/// Parsed JPEG scan data.
final class JpegScan {
  /// Creates scan data.
  JpegScan({required this.components, required this.entropySegments});

  /// Scan components in entropy order.
  final List<JpegComponent> components;

  /// De-stuffed entropy byte segments, split at restart markers.
  final List<Uint8List> entropySegments;
}

/// JPEG parser state.
final class JpegState {
  /// Image width.
  int width = 0;

  /// Image height.
  int height = 0;

  /// Frame components.
  final List<JpegComponent> components = <JpegComponent>[];

  /// Quantization tables.
  final Map<int, List<int>> quant = <int, List<int>>{};

  /// DC Huffman tables.
  final Map<int, JpegHuffmanTree> dcTrees = <int, JpegHuffmanTree>{};

  /// AC Huffman tables.
  final Map<int, JpegHuffmanTree> acTrees = <int, JpegHuffmanTree>{};

  /// Number of MCUs between restart markers, or zero when disabled.
  int restartInterval = 0;

  /// Scan payload.
  JpegScan? scan;
}
