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

  /// Whether this request needs metadata writing support.
  bool get isRequested =>
      keepExif ||
      keepIcc ||
      keepXmp ||
      exif != null ||
      iccProfile != null ||
      xmp != null ||
      withMetadata;

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
  }) {
    return MetadataWriteOptions(
      keepExif: keepExif ?? this.keepExif,
      keepIcc: keepIcc ?? this.keepIcc,
      keepXmp: keepXmp ?? this.keepXmp,
      exif: clearExif ? null : exif ?? this.exif,
      iccProfile: clearIccProfile ? null : iccProfile ?? this.iccProfile,
      xmp: clearXmp ? null : xmp ?? this.xmp,
      withMetadata: withMetadata ?? this.withMetadata,
    );
  }
}
