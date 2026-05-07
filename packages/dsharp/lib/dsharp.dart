/// Pure Dart image processing APIs for bytes, streams, raw pixels, and
/// generated images.
///
/// This library is designed for VM and web use. It intentionally does not
/// import `dart:io`; file-based helpers live in `dsharp_io.dart`.
library;

export 'src/api/capabilities.dart';
export 'src/api/exceptions.dart';
export 'src/codecs/codec_registry.dart';
export 'src/codecs/encoder_options.dart';
export 'src/codecs/format_sniffer.dart';
export 'src/codecs/image_format.dart';
export 'src/codecs/output.dart';
export 'src/composite/blend_mode.dart';
export 'src/composite/composite_layer.dart';
export 'src/composite/join_images.dart';
export 'src/geometry/geometry.dart';
export 'src/geometry/resize_geometry.dart';
export 'src/metadata/metadata.dart';
export 'src/metadata/stats.dart';
export 'src/metadata/write_options.dart';
export 'src/metadata/xmp_metadata.dart';
export 'src/operations/operation_options.dart';
export 'src/pipeline/cancellation.dart';
export 'src/pipeline/image_pipeline.dart';
export 'src/pixels/color.dart';
export 'src/pixels/pixel_image.dart';
export 'src/resize/crop_strategy.dart';
export 'src/resize/kernels.dart';
export 'src/source/generated_image.dart';
export 'src/source/image_source.dart';
export 'src/source/input_options.dart';
export 'src/source/raw_pixels.dart';
export 'src/source/text_image.dart';
