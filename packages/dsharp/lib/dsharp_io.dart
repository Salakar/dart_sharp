/// VM-only file IO helpers for dsharp.
///
/// Import this library only on platforms that support `dart:io`.
library;

import 'dart:io';

import 'dsharp.dart';

/// Creates an image pipeline from a file.
Future<ImagePipeline> imagePipelineFromFile(File file) async {
  return ImagePipeline.fromBytes(await file.readAsBytes());
}

/// Creates an image pipeline from a file path.
Future<ImagePipeline> imagePipelineFromPath(String path) {
  return imagePipelineFromFile(File(path));
}

/// VM-only source helpers.
extension ImageSourceFileIo on ImageSource {
  /// Creates a byte source from a file.
  static Future<ImageSource> file(File file) async {
    return ImageSource.bytes(await file.readAsBytes());
  }
}

/// VM-only pipeline output helpers.
extension ImagePipelineFileIo on ImagePipeline {
  /// Writes encoded output to [file].
  Future<OutputInfo> writeToFile(
    File file, {
    ImageFormat? format,
    CodecRegistry? registry,
    CancellationToken? cancellationToken,
  }) async {
    final resolvedFormat = format ?? _formatFromPath(file.path);
    final encoded = await toBytesWithInfo(
      format: resolvedFormat,
      registry: registry,
      cancellationToken: cancellationToken,
    );
    await file.writeAsBytes(encoded.bytes, flush: true);
    return encoded.info;
  }

  /// Writes encoded output to a file path or [File].
  Future<OutputInfo> toFile(
    Object file, {
    ImageFormat? format,
    CodecRegistry? registry,
    CancellationToken? cancellationToken,
  }) {
    final resolved = switch (file) {
      final File value => value,
      final String value => File(value),
      _ => throw ArgumentError.value(file, 'file', 'Expected a File or path.'),
    };
    return writeToFile(
      resolved,
      format: format,
      registry: registry,
      cancellationToken: cancellationToken,
    );
  }
}

ImageFormat? _formatFromPath(String path) {
  final dot = path.lastIndexOf('.');
  if (dot == -1 || dot == path.length - 1) {
    return null;
  }
  final format = ImageFormat.fromId(path.substring(dot + 1));
  return format == ImageFormat.unknown ? null : format;
}
