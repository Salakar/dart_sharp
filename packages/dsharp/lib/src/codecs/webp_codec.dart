import 'dart:typed_data';

import '../api/exceptions.dart';
import '../pixels/pixel_image.dart';
import '../source/raw_pixels.dart';
import 'binary_io.dart';
import 'codec.dart';
import 'codec_pixels.dart';
import 'encoder_options.dart';
import 'image_format.dart';
import 'output.dart';
import 'webp_alpha.dart';
import 'webp_animation.dart';
import 'webp_info.dart';
import 'webp_lossless.dart';
import 'webp_lossless_encoder.dart';
import 'webp_riff.dart';
import 'webp_vp8.dart';

/// First-party WebP container decoder.
///
/// This validates RIFF/WebP structure, parses metadata, and decodes supported
/// VP8L lossless and VP8 lossy key-frame subsets. Other WebP bitstream
/// features remain explicitly unsupported.
final class WebpImageCodec implements ImageCodec {
  /// Creates a WebP codec.
  const WebpImageCodec();

  @override
  ImageFormat get format => ImageFormat.webp;

  @override
  PixelImage decode(Uint8List bytes) {
    final info = readWebpInfo(bytes);
    if (info.isAnimated) {
      return decodeAnimatedWebp(bytes);
    }
    if (info.compression == WebpCompression.vp8) {
      return PixelImage.fromRawPixels(decodeWebpVp8(bytes));
    }
    if (info.compression == WebpCompression.extended &&
        _containsWebpChunk(bytes, 'VP8 ')) {
      final pixels = decodeWebpVp8(bytes);
      return PixelImage.fromRawPixels(
        info.hasAlpha ? applyWebpAlpha(bytes, pixels) : pixels,
      );
    }
    return PixelImage.fromRawPixels(decodeWebpLossless(bytes));
  }

  @override
  EncodedImage encode(PixelImage image, {EncoderOptions? options}) {
    final webpOptions = options is WebpEncoderOptions
        ? options
        : const WebpEncoderOptions();
    _rejectUnsupportedWebpOptions(webpOptions);
    var outputImage = _applyAnimationOptions(image, webpOptions);
    if (!webpOptions.lossless && !webpOptions.nearLossless) {
      final raw = outputImage.firstFrame.pixels;
      final bytes = outputImage.isAnimated
          ? encodeAnimatedWebpVp8(
              outputImage,
              quality: webpOptions.quality,
              alphaQuality: webpOptions.alphaQuality,
              minimizeSize: webpOptions.minSize,
              mixed: webpOptions.mixed,
            )
          : encodeWebpVp8(
              raw,
              quality: webpOptions.quality,
              alphaQuality: webpOptions.alphaQuality,
            );
      return EncodedImage(
        bytes: bytes,
        info: OutputInfo(
          format: format,
          size: bytes.length,
          width: raw.width,
          height: raw.height,
          channels: 4,
          frames: outputImage.frames.length,
          loopCount: outputImage.loopCount,
          frameDelays: <Duration>[
            for (final frame in outputImage.frames)
              if (frame.delay != null) frame.delay!,
          ],
        ),
      );
    }
    if (webpOptions.nearLossless) {
      outputImage = _applyNearLossless(outputImage, webpOptions.quality);
    }
    final raw = outputImage.firstFrame.pixels;
    final bytes = encodeWebpLossless(outputImage);
    return EncodedImage(
      bytes: bytes,
      info: OutputInfo(
        format: format,
        size: bytes.length,
        width: raw.width,
        height: raw.height,
        channels: 4,
        frames: outputImage.frames.length,
        loopCount: outputImage.loopCount,
        frameDelays: <Duration>[
          for (final frame in outputImage.frames)
            if (frame.delay != null) frame.delay!,
        ],
      ),
    );
  }
}

void _rejectUnsupportedWebpOptions(WebpEncoderOptions options) {
  if (options.smartSubsample) {
    throw const UnsupportedCodecException(
      'WebP smartSubsample is not implemented yet.',
    );
  }
  if (options.smartDeblock) {
    throw const UnsupportedCodecException(
      'WebP smartDeblock is not implemented yet.',
    );
  }
  if (options.preset != 'default') {
    throw const UnsupportedCodecException(
      'WebP preset is not implemented yet.',
    );
  }
  if (options.effort != 4) {
    throw const UnsupportedCodecException(
      'WebP effort is not implemented yet.',
    );
  }
}

PixelImage _applyAnimationOptions(
  PixelImage image,
  WebpEncoderOptions options,
) {
  final frameDelays = options.frameDelays;
  if (options.loopCount == null &&
      options.frameDelay == null &&
      frameDelays.isEmpty) {
    return image;
  }
  if (frameDelays.isNotEmpty && frameDelays.length != image.frames.length) {
    throw const OperationValidationException(
      'WebP frameDelays length must match frame count.',
    );
  }
  final frames = image.frames;
  return PixelImage(
    frames: <ImageFrame>[
      for (var index = 0; index < frames.length; index += 1)
        ImageFrame(
          pixels: frames[index].pixels,
          delay: frameDelays.isNotEmpty
              ? frameDelays[index]
              : options.frameDelay ?? frames[index].delay,
        ),
    ],
    loopCount: options.loopCount ?? image.loopCount,
  );
}

PixelImage _applyNearLossless(PixelImage image, int quality) {
  if (quality == 100) {
    return image;
  }
  return PixelImage(
    frames: <ImageFrame>[
      for (final frame in image.frames)
        ImageFrame(
          pixels: _nearLosslessPixels(frame.pixels, quality),
          delay: frame.delay,
        ),
    ],
    loopCount: image.loopCount,
  );
}

RawPixels _nearLosslessPixels(RawPixels raw, int quality) {
  final step = _nearLosslessStep(quality);
  final rgba = rawToRgba(raw);
  for (var offset = 0; offset < rgba.length; offset += 4) {
    rgba[offset] = _quantizeNearLossless(rgba[offset], step);
    rgba[offset + 1] = _quantizeNearLossless(rgba[offset + 1], step);
    rgba[offset + 2] = _quantizeNearLossless(rgba[offset + 2], step);
  }
  return RawPixels(
    bytes: rgba,
    width: raw.width,
    height: raw.height,
    channels: ChannelCount.four,
  );
}

int _nearLosslessStep(int quality) {
  final halfStep = ((100 - quality) + 7) ~/ 8;
  return halfStep * 2 + 1;
}

int _quantizeNearLossless(int value, int step) {
  final quantized = ((value + (step >> 1)) ~/ step) * step;
  if (quantized < 0) {
    return 0;
  }
  return quantized > 255 ? 255 : quantized;
}

bool _containsWebpChunk(Uint8List bytes, String target) {
  final riffEnd = webpRiffEnd(bytes);
  var offset = 12;
  while (offset + 8 <= riffEnd) {
    final type = String.fromCharCodes(bytes.sublist(offset, offset + 4));
    final length = readUint32Le(bytes, offset + 4);
    final end = webpChunkPayloadEnd(bytes, offset, riffEnd);
    if (type == target) {
      return true;
    }
    offset = webpNextChunkOffset(
      bytes,
      payloadEnd: end,
      payloadLength: length,
      containerEnd: riffEnd,
    );
  }
  if (offset != riffEnd) {
    return false;
  }
  return false;
}
