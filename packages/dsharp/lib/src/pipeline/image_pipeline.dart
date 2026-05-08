import 'dart:convert';
import 'dart:typed_data';

import '../api/capabilities.dart';
import '../api/exceptions.dart';
import '../codecs/binary_io.dart';
import '../codecs/codec_registry.dart';
import '../codecs/encoder_options.dart';
import '../codecs/format_sniffer.dart';
import '../codecs/image_format.dart';
import '../codecs/output.dart';
import '../codecs/webp_info.dart';
import '../composite/composite_layer.dart';
import '../composite/composite_operation.dart';
import '../geometry/geometry.dart';
import '../metadata/encoded_metadata.dart';
import '../metadata/metadata.dart';
import '../metadata/stats.dart';
import '../metadata/write_options.dart';
import '../metadata/xmp_metadata.dart';
import '../operations/affine_operation.dart';
import '../operations/alpha_channel_operations.dart';
import '../operations/boolean_operations.dart';
import '../operations/color_operations.dart';
import '../operations/filter_operations.dart';
import '../operations/geometry_operations.dart';
import '../operations/histogram_operations.dart';
import '../operations/modulate_operation.dart';
import '../operations/operation_options.dart';
import '../operations/transform_operations.dart';
import '../pixels/color.dart';
import '../pixels/pixel_image.dart';
import '../source/generated_image.dart';
import '../source/image_source.dart';
import '../source/raw_pixels.dart';
import 'cancellation.dart';
import 'pipeline_operation.dart';

part 'image_pipeline_alpha.dart';
part 'image_pipeline_boolean.dart';
part 'image_pipeline_color.dart';
part 'image_pipeline_composite.dart';
part 'image_pipeline_filter.dart';
part 'image_pipeline_geometry.dart';
part 'image_pipeline_metadata.dart';
part 'image_pipeline_output.dart';
part 'image_pipeline_output_internals.dart';
part 'image_pipeline_transform.dart';

/// Immutable image processing pipeline.
final class ImagePipeline {
  const ImagePipeline._({
    required this.source,
    required List<PipelineOperation> steps,
    ImageFormat? outputFormat,
    EncoderOptions? encoderOptions,
    Duration? timeout,
    CancellationToken? cancellationToken,
    MetadataWriteOptions metadataWrites = const MetadataWriteOptions(),
  }) : _steps = steps,
       _outputFormat = outputFormat,
       _encoderOptions = encoderOptions,
       _timeout = timeout,
       _cancellationToken = cancellationToken,
       _metadataWrites = metadataWrites;

  /// Creates a pipeline from encoded bytes.
  factory ImagePipeline.fromBytes(Uint8List bytes) {
    return ImagePipeline.fromSource(ImageSource.bytes(bytes));
  }

  /// Creates a pipeline from raw pixels.
  factory ImagePipeline.fromRawPixels(RawPixels pixels) {
    return ImagePipeline.fromSource(ImageSource.raw(pixels));
  }

  /// Creates a pipeline from decoded pixels.
  factory ImagePipeline.fromPixelImage(PixelImage image) {
    return ImagePipeline.fromSource(ImageSource.pixels(image));
  }

  /// Creates a pipeline from a generated image descriptor.
  factory ImagePipeline.create(CreateImage image) {
    return ImagePipeline.fromSource(ImageSource.create(image));
  }

  /// Creates a pipeline from an arbitrary web-safe source.
  factory ImagePipeline.fromSource(ImageSource source) {
    return ImagePipeline._(source: source, steps: const <PipelineOperation>[]);
  }

  /// Source for this pipeline.
  final ImageSource source;

  final List<PipelineOperation> _steps;
  final ImageFormat? _outputFormat;
  final EncoderOptions? _encoderOptions;
  final Duration? _timeout;
  final CancellationToken? _cancellationToken;
  final MetadataWriteOptions _metadataWrites;

  /// Operations recorded on this pipeline.
  List<String> get operations {
    return List<String>.unmodifiable(_steps.map((step) => step.name));
  }

  /// Capability table for this package.
  DsharpCapabilities get capabilities => DsharpCapabilities.current;

  /// Decodes the current source into pixels.
  Future<PixelImage> toPixelImage({
    CodecRegistry? registry,
    CancellationToken? cancellationToken,
  }) async {
    final codecs = registry ?? CodecRegistry.defaultRegistry();
    final token = cancellationToken ?? _cancellationToken;
    token?.throwIfCancelled();
    final decoded = switch (source) {
      BytesImageSource(:final bytes) => codecs.decode(bytes),
      final StreamImageSource source => codecs.decode(
        await source.collectBytes(),
      ),
      RawImageSource(:final pixels) => codecs.decodeRaw(pixels),
      PixelImageSource(:final image) => image,
      GeneratedImageSource(:final image) => _createPixels(image),
      TextImageSource() => throw const UnsupportedCodecException(
        'Text rendering is not implemented yet.',
      ),
    };
    token?.throwIfCancelled();
    var image = decoded;
    final orientation = _steps.any((step) => step is AutoOrientOperation)
        ? _sourceOrientation()
        : null;
    for (final step in _steps) {
      token?.throwIfCancelled();
      image = step is AutoOrientOperation
          ? step.applyOrientation(image, orientation)
          : step.apply(image);
    }
    token?.throwIfCancelled();
    return image;
  }

  /// Encodes the processed image to [format].
  Future<EncodedImage> toBytesWithInfo({
    ImageFormat? format,
    CodecRegistry? registry,
    CancellationToken? cancellationToken,
  }) async {
    return _runWithTimeout(this, () async {
      final codecs = registry ?? CodecRegistry.defaultRegistry();
      final token = cancellationToken ?? _cancellationToken;
      token?.throwIfCancelled();
      final image = await toPixelImage(
        registry: codecs,
        cancellationToken: token,
      );
      token?.throwIfCancelled();
      _validateMetadataWrites(this);
      final resolved = _resolveOutputFormat(this, format);
      final encoded = codecs.encode(
        image,
        format: resolved,
        options: _encoderOptions?.format == resolved ? _encoderOptions : null,
      );
      final withMetadata = _applyMetadataWrites(this, encoded);
      return EncodedImage(
        bytes: withMetadata.bytes,
        info: _outputInfo(withMetadata.info, image),
      );
    });
  }

  /// Encodes the processed image to [format] and returns only bytes.
  Future<Uint8List> toBytes({
    ImageFormat? format,
    CodecRegistry? registry,
    CancellationToken? cancellationToken,
  }) async {
    return (await toBytesWithInfo(
      format: format,
      registry: registry,
      cancellationToken: cancellationToken,
    )).bytes;
  }

  /// Encodes the processed image and returns bytes plus metadata.
  Future<ImageBytesResult> toImageBytesResult({
    ImageFormat? format,
    CodecRegistry? registry,
    CancellationToken? cancellationToken,
  }) async {
    final encoded = await toBytesWithInfo(
      format: format,
      registry: registry,
      cancellationToken: cancellationToken,
    );
    return ImageBytesResult(bytes: encoded.bytes, info: encoded.info);
  }

  /// Computes pixel statistics for the first decoded frame.
  Future<ImageStats> stats({CodecRegistry? registry}) async {
    return ImageStats.fromPixelImage(await toPixelImage(registry: registry));
  }

  /// Returns a new pipeline branch with the same source and operations.
  ImagePipeline clone() {
    return ImagePipeline._(
      source: source,
      steps: List<PipelineOperation>.unmodifiable(_steps),
      outputFormat: _outputFormat,
      encoderOptions: _encoderOptions,
      timeout: _timeout,
      cancellationToken: _cancellationToken,
      metadataWrites: _metadataWrites,
    );
  }

  /// Returns a new pipeline with an internal operation marker.
  ImagePipeline appendOperationForTesting(String operation) {
    return _append(_NoopOperation(operation));
  }

  ImagePipeline _append(PipelineOperation operation) {
    return ImagePipeline._(
      source: source,
      outputFormat: _outputFormat,
      encoderOptions: _encoderOptions,
      timeout: _timeout,
      cancellationToken: _cancellationToken,
      metadataWrites: _metadataWrites,
      steps: List<PipelineOperation>.unmodifiable(<PipelineOperation>[
        ..._steps,
        operation,
      ]),
    );
  }

  PixelImage _createPixels(CreateImage image) {
    if (image.channels != 3 && image.channels != 4) {
      throw const OperationValidationException(
        'Generated images require 3 or 4 channels.',
      );
    }
    final bytes = <int>[];
    for (var i = 0; i < image.width * image.height; i += 1) {
      bytes
        ..add(image.background.red)
        ..add(image.background.green)
        ..add(image.background.blue);
      if (image.channels == 4) {
        bytes.add(image.background.alpha);
      }
    }
    return PixelImage.fromRawPixels(
      RawPixels(
        bytes: Uint8List.fromList(bytes),
        width: image.width,
        height: image.height,
        channels: ChannelCount.fromInt(image.channels),
        pageHeight: image.pageHeight,
      ),
    );
  }

  ImageFormat _sourceFormat() {
    return switch (source) {
      BytesImageSource(:final bytes) => sniffImageFormat(bytes),
      StreamImageSource() => ImageFormat.unknown,
      RawImageSource() ||
      PixelImageSource() ||
      GeneratedImageSource() => ImageFormat.raw,
      TextImageSource() => ImageFormat.unknown,
    };
  }

  int? _sourceSize() {
    return switch (source) {
      BytesImageSource(:final bytes) => bytes.length,
      _ => null,
    };
  }

  int? _sourceOrientation() {
    if (source case BytesImageSource(:final bytes)) {
      final metadata = readEncodedImageMetadata(bytes, sniffImageFormat(bytes));
      return metadata?.orientation;
    }
    return null;
  }
}

final class _NoopOperation implements PipelineOperation {
  const _NoopOperation(this.name);

  @override
  final String name;

  @override
  PixelImage apply(PixelImage image) => image;
}
