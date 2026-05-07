import 'xmp_metadata.dart';

/// Metadata write request.
final class MetadataWriteOptions {
  /// Creates metadata write options.
  const MetadataWriteOptions({
    this.keepExif = false,
    this.keepIcc = false,
    this.keepXmp = false,
    this.xmp,
    this.withMetadata = false,
  });

  /// Keep existing EXIF metadata.
  final bool keepExif;

  /// Keep existing ICC metadata.
  final bool keepIcc;

  /// Keep existing XMP metadata.
  final bool keepXmp;

  /// XMP metadata to write.
  final XmpMetadata? xmp;

  /// Request broad metadata preservation.
  final bool withMetadata;

  /// Whether this request needs metadata writing support.
  bool get isRequested =>
      keepExif || keepIcc || keepXmp || xmp != null || withMetadata;

  /// Returns a copy with fields replaced.
  MetadataWriteOptions copyWith({
    bool? keepExif,
    bool? keepIcc,
    bool? keepXmp,
    XmpMetadata? xmp,
    bool clearXmp = false,
    bool? withMetadata,
  }) {
    return MetadataWriteOptions(
      keepExif: keepExif ?? this.keepExif,
      keepIcc: keepIcc ?? this.keepIcc,
      keepXmp: keepXmp ?? this.keepXmp,
      xmp: clearXmp ? null : xmp ?? this.xmp,
      withMetadata: withMetadata ?? this.withMetadata,
    );
  }
}
