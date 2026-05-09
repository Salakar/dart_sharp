import 'dart:math';
import 'dart:typed_data';

import '../api/exceptions.dart';
import '../pixels/pixel_image.dart';
import 'raw_pixels.dart';
import 'text_image.dart';

/// Renders a text descriptor with the built-in web-safe bitmap font.
PixelImage renderTextImage(TextImageRequest request) {
  _validateTextRequest(request);
  final scale = max(1, (request.dpi / 72).round());
  final metrics = _TextMetrics(scale);
  final lines = _wrapText(request, metrics.advance);
  final lineWidths = [for (final line in lines) metrics.measure(line)];
  final naturalWidth = lineWidths.fold<int>(0, max);
  final naturalHeight = lines.isEmpty
      ? metrics.glyphHeight
      : (lines.length - 1) * metrics.lineHeight + metrics.glyphHeight;
  final width = request.width ?? max(1, naturalWidth);
  final height = request.height ?? max(1, naturalHeight);
  final channels = request.hasRgba ? ChannelCount.four : ChannelCount.three;
  final bytes = Uint8List(width * height * channels.value);
  if (!request.hasRgba) {
    bytes.fillRange(0, bytes.length, 255);
  }

  for (var lineIndex = 0; lineIndex < lines.length; lineIndex += 1) {
    final line = lines[lineIndex];
    final lineWidth = lineWidths[lineIndex];
    final y = lineIndex * metrics.lineHeight;
    final x = switch (request.align) {
      TextAlign.left => 0,
      TextAlign.center => ((width - lineWidth) / 2).floor(),
      TextAlign.right => width - lineWidth,
    };
    _drawLine(bytes, width, height, channels, line, max(0, x), y, metrics);
  }

  return PixelImage.fromRawPixels(
    RawPixels(bytes: bytes, width: width, height: height, channels: channels),
  );
}

void _validateTextRequest(TextImageRequest request) {
  if (request.dpi <= 0) {
    throw const OperationValidationException('Text DPI must be positive.');
  }
  final width = request.width;
  if (width != null && width <= 0) {
    throw const OperationValidationException('Text width must be positive.');
  }
  final height = request.height;
  if (height != null && height <= 0) {
    throw const OperationValidationException('Text height must be positive.');
  }
}

List<String> _wrapText(TextImageRequest request, int advance) {
  final maxWidth = request.width;
  final paragraphs = request.text.split('\n');
  if (maxWidth == null || request.wrap == TextWrap.none) {
    return paragraphs;
  }
  final maxChars = max(1, ((maxWidth + 1) / advance).floor());
  final lines = <String>[];
  for (final paragraph in paragraphs) {
    switch (request.wrap) {
      case TextWrap.character:
        lines.addAll(_wrapCharacters(paragraph, maxChars));
      case TextWrap.word:
        lines.addAll(_wrapWords(paragraph, maxChars, splitLongWords: false));
      case TextWrap.wordCharacter:
        lines.addAll(_wrapWords(paragraph, maxChars, splitLongWords: true));
      case TextWrap.none:
        lines.add(paragraph);
    }
  }
  return lines.isEmpty ? <String>[''] : lines;
}

List<String> _wrapCharacters(String text, int maxChars) {
  if (text.isEmpty) {
    return <String>[''];
  }
  final chars = _chars(text);
  return <String>[
    for (var i = 0; i < chars.length; i += maxChars)
      chars.sublist(i, min(chars.length, i + maxChars)).join(),
  ];
}

List<String> _wrapWords(
  String text,
  int maxChars, {
  required bool splitLongWords,
}) {
  if (text.trim().isEmpty) {
    return <String>[''];
  }
  final lines = <String>[];
  var current = '';
  for (final word in text.trim().split(RegExp(r'\s+'))) {
    final pieces = splitLongWords
        ? _wrapCharacters(word, maxChars)
        : <String>[word];
    for (final piece in pieces) {
      final candidate = current.isEmpty ? piece : '$current $piece';
      if (candidate.runes.length <= maxChars || current.isEmpty) {
        current = candidate;
      } else {
        lines.add(current);
        current = piece;
      }
    }
  }
  if (current.isNotEmpty) {
    lines.add(current);
  }
  return lines;
}

List<String> _chars(String text) {
  return <String>[for (final rune in text.runes) String.fromCharCode(rune)];
}

void _drawLine(
  Uint8List bytes,
  int width,
  int height,
  ChannelCount channels,
  String text,
  int x,
  int y,
  _TextMetrics metrics,
) {
  var cursor = x;
  for (final char in _chars(text)) {
    _drawGlyph(bytes, width, height, channels, char, cursor, y, metrics.scale);
    cursor += metrics.advance;
    if (cursor >= width) {
      break;
    }
  }
}

void _drawGlyph(
  Uint8List bytes,
  int width,
  int height,
  ChannelCount channels,
  String char,
  int x,
  int y,
  int scale,
) {
  final glyph = _glyphs[char.toUpperCase()] ?? _glyphs['?']!;
  for (var row = 0; row < 7; row += 1) {
    for (var col = 0; col < 5; col += 1) {
      if (glyph.codeUnitAt(row * 5 + col) != 0x31) {
        continue;
      }
      for (var dy = 0; dy < scale; dy += 1) {
        final py = y + row * scale + dy;
        if (py < 0 || py >= height) {
          continue;
        }
        for (var dx = 0; dx < scale; dx += 1) {
          final px = x + col * scale + dx;
          if (px < 0 || px >= width) {
            continue;
          }
          final out = (py * width + px) * channels.value;
          bytes[out] = 0;
          bytes[out + 1] = 0;
          bytes[out + 2] = 0;
          if (channels == ChannelCount.four) {
            bytes[out + 3] = 255;
          }
        }
      }
    }
  }
}

final class _TextMetrics {
  const _TextMetrics(this.scale);

  final int scale;

  int get glyphHeight => 7 * scale;

  int get advance => 6 * scale;

  int get lineHeight => 8 * scale;

  int measure(String text) {
    final length = text.runes.length;
    return length == 0 ? 0 : length * advance - scale;
  }
}

const _glyphs = <String, String>{
  ' ': '00000000000000000000000000000000000',
  '!': '00100001000010000100001000000000100',
  '?': '01110100010000100010001000000000100',
  '.': '00000000000000000000000000000000100',
  ',': '00000000000000000000000000010001000',
  ':': '00000001000010000000001000010000000',
  ';': '00000001000010000000001000010001000',
  '-': '00000000000000011111000000000000000',
  '_': '00000000000000000000000000000011111',
  '/': '00001000100010001000100010000000000',
  '+': '00000001000010011111001000010000000',
  '0': '01110100011001110101110011000101110',
  '1': '00100011000010000100001000010001110',
  '2': '01110100010000100010001000100011111',
  '3': '11110000010000101110000010000111110',
  '4': '00010001100101010010111110001000010',
  '5': '11111100001111000001000010000111110',
  '6': '01110100001000011110100011000101110',
  '7': '11111000010001000100010000100001000',
  '8': '01110100011000101110100011000101110',
  '9': '01110100011000101111000010000101110',
  'A': '01110100011000111111100011000110001',
  'B': '11110100011000111110100011000111110',
  'C': '01110100011000010000100001000101110',
  'D': '11110100011000110001100011000111110',
  'E': '11111100001000011110100001000011111',
  'F': '11111100001000011110100001000010000',
  'G': '01110100011000010111100011000101110',
  'H': '10001100011000111111100011000110001',
  'I': '01110001000010000100001000010001110',
  'J': '00111000100001000010100101001001100',
  'K': '10001100101010011000101001001010001',
  'L': '10000100001000010000100001000011111',
  'M': '10001110111010110101100011000110001',
  'N': '10001110011010110011100011000110001',
  'O': '01110100011000110001100011000101110',
  'P': '11110100011000111110100001000010000',
  'Q': '01110100011000110001101011001001101',
  'R': '11110100011000111110101001001010001',
  'S': '01111100001000001110000010000111110',
  'T': '11111001000010000100001000010000100',
  'U': '10001100011000110001100011000101110',
  'V': '10001100011000110001100010101000100',
  'W': '10001100011000110101101011101110001',
  'X': '10001100010101000100010101000110001',
  'Y': '10001100010101000100001000010000100',
  'Z': '11111000010001000100010001000011111',
};
