import 'package:xml/xml.dart' as xml;

import '../api/exceptions.dart';

/// Parsed XMP/XML metadata payload.
final class XmpMetadata {
  /// Creates an XMP metadata value.
  const XmpMetadata(this.xmlText);

  /// Original XML text.
  final String xmlText;

  /// Parses and validates XML metadata.
  factory XmpMetadata.parse(String xmlText) {
    try {
      xml.XmlDocument.parse(xmlText);
    } on Object catch (error) {
      throw InvalidImageException('Invalid XMP XML metadata.', cause: error);
    }
    return XmpMetadata(xmlText);
  }
}
