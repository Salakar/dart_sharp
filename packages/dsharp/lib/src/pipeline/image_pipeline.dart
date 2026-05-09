import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import '../api/capabilities.dart';
import '../api/exceptions.dart';
import '../codecs/binary_io.dart';
import '../codecs/codec_registry.dart';
import '../codecs/deflate_codec.dart';
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
import '../source/input_options.dart';
import '../source/raw_pixels.dart';
import '../source/text_image.dart';
import '../source/text_renderer.dart';
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
part 'image_pipeline_output_density.dart';
part 'image_pipeline_output_exif.dart';
part 'image_pipeline_output_icc.dart';
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
    InputSafetyLimits inputLimits = const InputSafetyLimits(),
    MetadataWriteOptions metadataWrites = const MetadataWriteOptions(),
  }) : _steps = steps,
       _outputFormat = outputFormat,
       _encoderOptions = encoderOptions,
       _timeout = timeout,
       _cancellationToken = cancellationToken,
       _inputLimits = inputLimits,
       _metadataWrites = metadataWrites;

  /// Creates a pipeline from encoded bytes.
  factory ImagePipeline.fromBytes(
    List<int> bytes, {
    InputSafetyLimits limits = const InputSafetyLimits(),
  }) {
    return ImagePipeline.fromSource(ImageSource.bytes(bytes), limits: limits);
  }

  /// Creates a pipeline from an encoded byte buffer.
  factory ImagePipeline.fromByteBuffer(
    ByteBuffer buffer, {
    InputSafetyLimits limits = const InputSafetyLimits(),
  }) {
    return ImagePipeline.fromSource(
      ImageSource.byteBuffer(buffer),
      limits: limits,
    );
  }

  /// Creates a pipeline from encoded byte data.
  factory ImagePipeline.fromByteData(
    ByteData data, {
    InputSafetyLimits limits = const InputSafetyLimits(),
  }) {
    return ImagePipeline.fromSource(ImageSource.byteData(data), limits: limits);
  }

  /// Creates a pipeline from an encoded byte stream.
  factory ImagePipeline.fromStream(
    Stream<List<int>> stream, {
    int? maxBytes,
    InputSafetyLimits limits = const InputSafetyLimits(),
  }) {
    return ImagePipeline.fromSource(
      ImageSource.stream(stream, maxBytes: maxBytes ?? limits.maxBytes),
      limits: limits,
    );
  }

  /// Creates a pipeline from raw pixels.
  factory ImagePipeline.fromRawPixels(
    RawPixels pixels, {
    InputSafetyLimits limits = const InputSafetyLimits(),
  }) {
    return ImagePipeline.fromSource(ImageSource.raw(pixels), limits: limits);
  }

  /// Creates a pipeline from decoded pixels.
  factory ImagePipeline.fromPixelImage(
    PixelImage image, {
    InputSafetyLimits limits = const InputSafetyLimits(),
  }) {
    return ImagePipeline.fromSource(ImageSource.pixels(image), limits: limits);
  }

  /// Creates a pipeline from a generated image descriptor.
  factory ImagePipeline.create(
    CreateImage image, {
    InputSafetyLimits limits = const InputSafetyLimits(),
  }) {
    return ImagePipeline.fromSource(ImageSource.create(image), limits: limits);
  }

  /// Creates a pipeline from a generated text image descriptor.
  factory ImagePipeline.text(
    TextImageRequest text, {
    InputSafetyLimits limits = const InputSafetyLimits(),
  }) {
    return ImagePipeline.fromSource(ImageSource.text(text), limits: limits);
  }

  /// Creates a pipeline from an arbitrary web-safe source.
  factory ImagePipeline.fromSource(
    ImageSource source, {
    InputSafetyLimits limits = const InputSafetyLimits(),
  }) {
    return ImagePipeline._(
      source: source,
      inputLimits: limits,
      steps: const <PipelineOperation>[],
    );
  }

  /// Source for this pipeline.
  final ImageSource source;

  final List<PipelineOperation> _steps;
  final ImageFormat? _outputFormat;
  final EncoderOptions? _encoderOptions;
  final Duration? _timeout;
  final CancellationToken? _cancellationToken;
  final InputSafetyLimits _inputLimits;
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
      BytesImageSource(:final bytes) => _decodeBytes(codecs, bytes),
      final StreamImageSource source => _decodeBytes(
        codecs,
        await source.collectBytes(),
      ),
      RawImageSource(:final pixels) => _decodeRawPixels(codecs, pixels),
      PixelImageSource(:final image) => _checkedPixelImage(image),
      GeneratedImageSource(:final image) => _createPixels(image),
      TextImageSource(:final text) => renderTextImage(text),
    };
    token?.throwIfCancelled();
    final hasAutoOrient = _steps.any((step) => step is AutoOrientOperation);
    var image = hasAutoOrient
        ? const AutoOrientOperation().applyOrientation(
            decoded,
            _sourceOrientation(),
          )
        : decoded;
    for (final step in _steps) {
      token?.throwIfCancelled();
      if (step is AutoOrientOperation) {
        continue;
      }
      image = step.apply(image);
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

  /// Encodes the processed image and returns bytes using sharp's method name.
  Future<Uint8List> toBuffer({
    ImageFormat? format,
    CodecRegistry? registry,
    CancellationToken? cancellationToken,
  }) {
    return toBytes(
      format: format,
      registry: registry,
      cancellationToken: cancellationToken,
    );
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

  /// Encodes the processed image and returns bytes plus metadata using sharp's
  /// method name.
  Future<ImageBytesResult> toBufferWithInfo({
    ImageFormat? format,
    CodecRegistry? registry,
    CancellationToken? cancellationToken,
  }) {
    return toImageBytesResult(
      format: format,
      registry: registry,
      cancellationToken: cancellationToken,
    );
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
      inputLimits: _inputLimits,
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
      inputLimits: _inputLimits,
      metadataWrites: _metadataWrites,
      steps: List<PipelineOperation>.unmodifiable(<PipelineOperation>[
        ..._steps,
        operation,
      ]),
    );
  }

  ImagePipeline _appendReplacing(
    PipelineOperation operation,
    bool Function(PipelineOperation step) replace,
  ) {
    return ImagePipeline._(
      source: source,
      outputFormat: _outputFormat,
      encoderOptions: _encoderOptions,
      timeout: _timeout,
      cancellationToken: _cancellationToken,
      inputLimits: _inputLimits,
      metadataWrites: _metadataWrites,
      steps: List<PipelineOperation>.unmodifiable(<PipelineOperation>[
        for (final step in _steps)
          if (!replace(step)) step,
        operation,
      ]),
    );
  }

  ImagePipeline _appendBefore(
    PipelineOperation operation,
    bool Function(PipelineOperation step) before,
  ) {
    final updated = <PipelineOperation>[];
    var inserted = false;
    for (final step in _steps) {
      if (!inserted && before(step)) {
        updated.add(operation);
        inserted = true;
      }
      updated.add(step);
    }
    if (!inserted) {
      updated.add(operation);
    }
    return ImagePipeline._(
      source: source,
      outputFormat: _outputFormat,
      encoderOptions: _encoderOptions,
      timeout: _timeout,
      cancellationToken: _cancellationToken,
      inputLimits: _inputLimits,
      metadataWrites: _metadataWrites,
      steps: List<PipelineOperation>.unmodifiable(updated),
    );
  }

  PixelImage _decodeBytes(CodecRegistry codecs, Uint8List bytes) {
    _inputLimits.checkBytes(bytes.length);
    return _checkedPixelImage(codecs.decode(bytes));
  }

  PixelImage _decodeRawPixels(CodecRegistry codecs, RawPixels pixels) {
    _inputLimits.checkImage(
      width: pixels.width,
      height: pixels.height,
      frames: 1,
    );
    return _checkedPixelImage(codecs.decodeRaw(pixels));
  }

  PixelImage _checkedPixelImage(PixelImage image) {
    _inputLimits.checkImage(
      width: image.width,
      height: image.height,
      frames: image.frames.length,
    );
    return image;
  }

  PixelImage _createPixels(CreateImage image) {
    _inputLimits.checkImage(
      width: image.width,
      height: image.height,
      frames: 1,
    );
    final noise = image.noise;
    if (noise != null) {
      return _createNoisePixels(image, noise);
    }
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

  PixelImage _createNoisePixels(CreateImage image, CreateNoise noise) {
    if (image.channels < 1 || image.channels > 4) {
      throw const OperationValidationException(
        'Generated noise images require 1 to 4 channels.',
      );
    }
    _validateCreateNoise(noise);
    final random = Random(noise.seed);
    final bytes = Uint8List(image.width * image.height * image.channels);
    for (var i = 0; i < bytes.length; i += 1) {
      bytes[i] = _gaussianByte(random, noise.mean, noise.sigma);
    }
    return PixelImage.fromRawPixels(
      RawPixels(
        bytes: bytes,
        width: image.width,
        height: image.height,
        channels: ChannelCount.fromInt(image.channels),
        pageHeight: image.pageHeight,
      ),
    );
  }

  void _validateCreateNoise(CreateNoise noise) {
    if (noise.mean.isNaN ||
        !noise.mean.isFinite ||
        noise.mean < 0 ||
        noise.mean > 10000) {
      throw const OperationValidationException(
        'Create noise mean must be between 0 and 10000.',
      );
    }
    if (noise.sigma.isNaN ||
        !noise.sigma.isFinite ||
        noise.sigma < 0 ||
        noise.sigma > 10000) {
      throw const OperationValidationException(
        'Create noise sigma must be between 0 and 10000.',
      );
    }
  }

  int _gaussianByte(Random random, num mean, num sigma) {
    final u1 = max(random.nextDouble(), 1e-12);
    final u2 = random.nextDouble();
    final z = sqrt(-2 * log(u1)) * cos(2 * pi * u2);
    return ((mean + sigma * z).round()).clamp(0, 255).toInt();
  }

  ImageFormat _sourceFormat() {
    return switch (source) {
      BytesImageSource(:final bytes) => sniffImageFormat(bytes),
      StreamImageSource() => ImageFormat.unknown,
      RawImageSource() ||
      PixelImageSource() ||
      GeneratedImageSource() ||
      TextImageSource() => ImageFormat.raw,
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
