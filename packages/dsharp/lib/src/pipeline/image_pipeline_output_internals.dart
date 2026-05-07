part of 'image_pipeline.dart';

ImagePipeline _copyPipelineWith(
  ImagePipeline pipeline, {
  ImageFormat? outputFormat,
  bool clearOutputFormat = false,
  EncoderOptions? encoderOptions,
  bool clearEncoderOptions = false,
  Duration? timeout,
  bool clearTimeout = false,
  CancellationToken? cancellationToken,
  bool clearCancellationToken = false,
  MetadataWriteOptions? metadataWrites,
}) {
  return ImagePipeline._(
    source: pipeline.source,
    steps: pipeline._steps,
    outputFormat: clearOutputFormat
        ? null
        : outputFormat ?? pipeline._outputFormat,
    encoderOptions: clearEncoderOptions
        ? null
        : encoderOptions ?? pipeline._encoderOptions,
    timeout: clearTimeout ? null : timeout ?? pipeline._timeout,
    cancellationToken: clearCancellationToken
        ? null
        : cancellationToken ?? pipeline._cancellationToken,
    metadataWrites: metadataWrites ?? pipeline._metadataWrites,
  );
}

Future<T> _runWithTimeout<T>(ImagePipeline pipeline, Future<T> Function() run) {
  final timeout = pipeline._timeout;
  if (timeout == null) {
    return run();
  }
  return run().timeout(
    timeout,
    onTimeout: () {
      throw ImageCancellationException(
        'Image pipeline timed out after ${timeout.inMilliseconds} ms.',
      );
    },
  );
}

ImageFormat _resolveOutputFormat(
  ImagePipeline pipeline,
  ImageFormat? explicitFormat,
) {
  if (explicitFormat != null) {
    return explicitFormat;
  }
  final options = pipeline._encoderOptions;
  if (options != null) {
    options.validate();
    if (!options.force) {
      final sourceFormat = pipeline._sourceFormat();
      if (sourceFormat != ImageFormat.unknown &&
          sourceFormat != ImageFormat.raw) {
        return sourceFormat;
      }
    }
    return options.format;
  }
  return pipeline._outputFormat ?? ImageFormat.raw;
}

void _validateMetadataWrites(ImagePipeline pipeline) {
  if (pipeline._metadataWrites.isRequested) {
    throw const UnsupportedCodecException(
      'Metadata writing is not implemented for pure Dart encoders yet.',
    );
  }
}

OutputInfo _outputInfo(OutputInfo info, PixelImage image) {
  return OutputInfo(
    format: info.format,
    size: info.size,
    width: info.width,
    height: info.height,
    channels: info.channels,
    premultiplied:
        info.premultiplied ||
        image.firstFrame.pixels.premultiplication ==
            Premultiplication.premultiplied,
    cropOffsetLeft: info.cropOffsetLeft,
    cropOffsetTop: info.cropOffsetTop,
    trimOffsetLeft: info.trimOffsetLeft,
    trimOffsetTop: info.trimOffsetTop,
    frames: image.frames.length,
    pageHeight: image.firstFrame.pixels.pageHeight,
    loopCount: image.loopCount,
    frameDelays: <Duration>[
      for (final frame in image.frames)
        if (frame.delay != null) frame.delay!,
    ],
    textAutofitDpi: info.textAutofitDpi,
  );
}
