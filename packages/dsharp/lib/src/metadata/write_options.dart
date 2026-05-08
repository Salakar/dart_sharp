import 'dart:typed_data';

import 'xmp_metadata.dart';

/// Metadata write request.
final class MetadataWriteOptions {
  /// Creates metadata write options.
  const MetadataWriteOptions({
    this.keepExif = false,
    this.keepIcc = false,
    this.keepXmp = false,
    this.exif,
    this.iccProfile,
    this.xmp,
    this.withMetadata = false,
    this.density,
    this.orientation,
  });

  /// Keep existing EXIF metadata.
  final bool keepExif;

  /// Keep existing ICC metadata.
  final bool keepIcc;

  /// Keep existing XMP metadata.
  final bool keepXmp;

  /// EXIF metadata to write.
  final Uint8List? exif;

  /// ICC profile to write.
  final Uint8List? iccProfile;

  /// XMP metadata to write.
  final XmpMetadata? xmp;

  /// Request broad metadata preservation.
  final bool withMetadata;

  /// Optional output density in pixels per inch.
  final double? density;

  /// Optional EXIF orientation value.
  final int? orientation;

  /// Whether this request needs metadata writing support.
  bool get isRequested =>
      keepExif ||
      keepIcc ||
      keepXmp ||
      exif != null ||
      iccProfile != null ||
      xmp != null ||
      withMetadata ||
      density != null ||
      orientation != null;

  /// Returns a copy with fields replaced.
  MetadataWriteOptions copyWith({
    bool? keepExif,
    bool? keepIcc,
    bool? keepXmp,
    Uint8List? exif,
    bool clearExif = false,
    Uint8List? iccProfile,
    bool clearIccProfile = false,
    XmpMetadata? xmp,
    bool clearXmp = false,
    bool? withMetadata,
    double? density,
    bool clearDensity = false,
    int? orientation,
    bool clearOrientation = false,
  }) {
    return MetadataWriteOptions(
      keepExif: keepExif ?? this.keepExif,
      keepIcc: keepIcc ?? this.keepIcc,
      keepXmp: keepXmp ?? this.keepXmp,
      exif: clearExif ? null : exif ?? this.exif,
      iccProfile: clearIccProfile ? null : iccProfile ?? this.iccProfile,
      xmp: clearXmp ? null : xmp ?? this.xmp,
      withMetadata: withMetadata ?? this.withMetadata,
      density: clearDensity ? null : density ?? this.density,
      orientation: clearOrientation ? null : orientation ?? this.orientation,
    );
  }
}
