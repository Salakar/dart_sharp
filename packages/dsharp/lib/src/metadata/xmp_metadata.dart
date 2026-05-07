import '../api/exceptions.dart';

/// Parsed XMP/XML metadata payload.
final class XmpMetadata {
  /// Creates an XMP metadata value.
  const XmpMetadata(this.xmlText);

  /// Original XML text.
  final String xmlText;

  /// Parses and validates XML metadata.
  factory XmpMetadata.parse(String xmlText) {
    if (!_isWellFormedXml(xmlText)) {
      throw const InvalidImageException('Invalid XMP XML metadata.');
    }
    return XmpMetadata(xmlText);
  }
}

bool _isWellFormedXml(String xmlText) {
  final tags = RegExp(r'<[^!?][^>]*>');
  final stack = <String>[];
  for (final match in tags.allMatches(xmlText)) {
    final token = match.group(0)!;
    if (token.startsWith('</')) {
      final name = _tagName(token, closing: true);
      if (stack.isEmpty || stack.removeLast() != name) {
        return false;
      }
    } else if (!token.endsWith('/>')) {
      final name = _tagName(token);
      if (name.isEmpty) {
        return false;
      }
      stack.add(name);
    }
  }
  return stack.isEmpty && tags.hasMatch(xmlText);
}

String _tagName(String token, {bool closing = false}) {
  final start = closing ? 2 : 1;
  var end = start;
  while (end < token.length) {
    final unit = token.codeUnitAt(end);
    final isName =
        (unit >= 65 && unit <= 90) ||
        (unit >= 97 && unit <= 122) ||
        (unit >= 48 && unit <= 57) ||
        unit == 45 ||
        unit == 58 ||
        unit == 95;
    if (!isName) {
      break;
    }
    end += 1;
  }
  return token.substring(start, end);
}
