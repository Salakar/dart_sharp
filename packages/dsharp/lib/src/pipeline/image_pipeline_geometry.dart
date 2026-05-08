part of 'image_pipeline.dart';

/// Geometry pipeline operations.
extension ImagePipelineGeometry on ImagePipeline {
  /// Adds a resize operation.
  ///
  /// Accepts either a [ResizeOptions] value, sharp-style positional dimensions,
  /// or positional dimensions plus [ResizeOptions].
  ImagePipeline resize([
    Object? widthOrOptions,
    Object? heightOrOptions,
    ResizeOptions? options,
  ]) {
    return _appendReplacing(
      ResizeOperation(
        _resolveResizeOptions(widthOrOptions, heightOrOptions, options),
      ),
      (step) => step is ResizeOperation,
    );
  }

  /// Adds an extract operation.
  ImagePipeline extract(Region region) {
    return _append(ExtractOperation(region));
  }

  /// Adds an extend operation.
  ImagePipeline extend(ExtendOptions options) {
    return _append(ExtendOperation(options));
  }

  /// Adds a trim operation.
  ImagePipeline trim([TrimOptions options = const TrimOptions()]) {
    return _append(TrimOperation(options));
  }
}

ResizeOptions _resolveResizeOptions(
  Object? widthOrOptions,
  Object? heightOrOptions,
  ResizeOptions? options,
) {
  if (widthOrOptions is ResizeOptions) {
    if (heightOrOptions != null || options != null) {
      throw const OperationValidationException(
        'Resize options cannot be combined with additional arguments.',
      );
    }
    return widthOrOptions;
  }

  final width = _resizeDimension(widthOrOptions, 'width');
  var height = _resizeDimension(heightOrOptions, 'height');
  var base = options ?? const ResizeOptions();
  if (heightOrOptions is ResizeOptions) {
    if (options != null) {
      throw const OperationValidationException(
        'Resize options were provided more than once.',
      );
    }
    height = null;
    base = heightOrOptions;
  }

  return ResizeOptions(
    width: base.width ?? width,
    height: base.height ?? height,
    fit: base.fit,
    gravity: base.gravity,
    kernel: base.kernel,
    background: base.background,
    withoutEnlargement: base.withoutEnlargement,
    withoutReduction: base.withoutReduction,
  );
}

int? _resizeDimension(Object? value, String name) {
  if (value == null || value is ResizeOptions) {
    return null;
  }
  if (value is int) {
    return value;
  }
  throw OperationValidationException('Resize $name must be an integer.');
}
