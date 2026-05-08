import 'dart:typed_data';

import '../api/exceptions.dart';
import '../pixels/pixel_image.dart';
import '../source/raw_pixels.dart';
import 'binary_io.dart';
import 'codec.dart';
import 'codec_pixels.dart';
import 'encoder_options.dart';
import 'gif_lzw.dart';
import 'gif_palette.dart';
import 'image_format.dart';
import 'output.dart';

/// First-party GIF89a codec for indexed 8-bit images.
final class GifImageCodec implements ImageCodec {
  /// Creates a GIF codec.
  const GifImageCodec();

  @override
  ImageFormat get format => ImageFormat.gif;

  @override
  PixelImage decode(Uint8List bytes) {
    if (bytes.length < 13 ||
        String.fromCharCodes(bytes.sublist(0, 3)) != 'GIF') {
      throw const InvalidImageException('Invalid GIF signature.');
    }
    final width = readUint16Le(bytes, 6);
    final height = readUint16Le(bytes, 8);
    final packed = bytes[10];
    var offset = 13;
    List<int>? globalPalette;
    if ((packed & 0x80) != 0) {
      final size = 3 * (1 << ((packed & 0x07) + 1));
      if (offset + size > bytes.length) {
        throw const InvalidImageException('Truncated GIF global color table.');
      }
      globalPalette = bytes.sublist(offset, offset + size);
      offset += size;
    }
    final frames = <ImageFrame>[];
    final canvas = Uint8List(width * height * 4);
    var delay = Duration.zero;
    int? transparentIndex;
    var disposalMethod = 0;
    var loopCount = 1;
    while (offset < bytes.length) {
      final marker = bytes[offset++];
      if (marker == 0x3b) {
        break;
      }
      if (marker == 0x21) {
        final result = _readExtension(bytes, offset, loopCount);
        offset = result.offset;
        delay = result.delay ?? delay;
        transparentIndex = result.transparentIndex ?? transparentIndex;
        disposalMethod = result.disposalMethod ?? disposalMethod;
        loopCount = result.loopCount ?? loopCount;
      } else if (marker == 0x2c) {
        final previousCanvas = disposalMethod == 3
            ? Uint8List.fromList(canvas)
            : null;
        final image = _readImage(
          bytes,
          offset,
          width,
          height,
          globalPalette,
          transparentIndex,
          delay,
          canvas,
        );
        offset = image.offset;
        frames.add(image.frame);
        _disposeGifFrame(
          canvas,
          image.bounds,
          screenWidth: width,
          disposalMethod: disposalMethod,
          previousCanvas: previousCanvas,
        );
        delay = Duration.zero;
        transparentIndex = null;
        disposalMethod = 0;
      } else {
        throw const InvalidImageException('Invalid GIF block marker.');
      }
    }
    if (frames.isEmpty) {
      throw const InvalidImageException('GIF contains no image frames.');
    }
    return PixelImage(frames: frames, loopCount: loopCount);
  }

  @override
  EncodedImage encode(PixelImage image, {EncoderOptions? options}) {
    final gifOptions = options is GifEncoderOptions
        ? options
        : const GifEncoderOptions();
    final outputImage = _applyGifAnimationOptions(image, gifOptions);
    final raw = outputImage.firstFrame.pixels;
    final frames = _framesForEncoding(
      outputImage,
      gifOptions.keepDuplicateFrames,
    );
    final palette = GifPalette.fromRgba(
      Uint8List.fromList(<int>[for (final frame in frames) ...frame.rgba]),
      maxColors: gifOptions.colors,
    );
    final minCodeSize = _minCodeSize(palette.size);
    final writer = ByteWriter()
      ..writeAscii('GIF89a')
      ..writeUint16Le(raw.width)
      ..writeUint16Le(raw.height)
      ..writeByte(0xf0 | (palette.tablePower - 1))
      ..writeByte(0)
      ..writeByte(0)
      ..writeBytes(palette.bytes);
    if (outputImage.loopCount != null) {
      _writeLoopExtension(writer, outputImage.loopCount!);
    }
    var indexOffset = 0;
    for (final frame in frames) {
      final pixelCount = frame.image.width * frame.image.height;
      _writeFrame(
        writer,
        frame.image,
        GifPalette(
          palette.bytes,
          palette.indices.sublist(indexOffset, indexOffset + pixelCount),
          palette.size,
          palette.tablePower,
          palette.transparentIndex,
        ),
        minCodeSize,
        interlaced: gifOptions.progressive,
      );
      indexOffset += pixelCount;
    }
    writer.writeByte(0x3b);
    final bytes = writer.toBytes();
    return EncodedImage(
      bytes: bytes,
      info: OutputInfo(
        format: format,
        size: bytes.length,
        width: raw.width,
        height: raw.height,
        channels: 4,
        frames: frames.length,
        loopCount: outputImage.loopCount,
        frameDelays: <Duration>[
          for (final frame in frames)
            if (frame.image.delay != null) frame.image.delay!,
        ],
      ),
    );
  }
}

PixelImage _applyGifAnimationOptions(
  PixelImage image,
  GifEncoderOptions options,
) {
  final frameDelays = options.frameDelays;
  if (options.loopCount == null &&
      options.frameDelay == null &&
      frameDelays.isEmpty) {
    return image;
  }
  if (frameDelays.isNotEmpty && frameDelays.length != image.frames.length) {
    throw const OperationValidationException(
      'GIF frameDelays length must match frame count.',
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

final class _GifFrameData {
  _GifFrameData(this.image, this.rgba);

  final ImageFrame image;
  final Uint8List rgba;
}

List<_GifFrameData> _framesForEncoding(PixelImage image, bool keepDuplicates) {
  final frames = <_GifFrameData>[];
  for (final frame in image.frames) {
    final data = _GifFrameData(frame, rawToRgba(frame.pixels));
    if (!keepDuplicates &&
        frames.isNotEmpty &&
        _sameFramePixels(frames.last, data)) {
      frames[frames.length - 1] = _GifFrameData(
        ImageFrame(
          pixels: frames.last.image.pixels,
          delay: _combinedDelay(frames.last.image.delay, frame.delay),
        ),
        frames.last.rgba,
      );
    } else {
      frames.add(data);
    }
  }
  return frames;
}

bool _sameFramePixels(_GifFrameData a, _GifFrameData b) {
  if (a.image.width != b.image.width ||
      a.image.height != b.image.height ||
      a.rgba.length != b.rgba.length) {
    return false;
  }
  for (var i = 0; i < a.rgba.length; i += 1) {
    if (a.rgba[i] != b.rgba[i]) {
      return false;
    }
  }
  return true;
}

Duration? _combinedDelay(Duration? a, Duration? b) {
  if (a == null) {
    return b;
  }
  if (b == null) {
    return a;
  }
  return a + b;
}

({
  int offset,
  Duration? delay,
  int? transparentIndex,
  int? disposalMethod,
  int? loopCount,
})
_readExtension(Uint8List bytes, int offset, int loopCount) {
  if (offset >= bytes.length) {
    throw const InvalidImageException('Truncated GIF extension.');
  }
  final label = bytes[offset++];
  if (label == 0xf9) {
    if (offset >= bytes.length) {
      throw const InvalidImageException(
        'Truncated GIF graphic control extension.',
      );
    }
    final blockSize = bytes[offset++];
    if (blockSize != 4) {
      throw const InvalidImageException(
        'Invalid GIF graphic control extension.',
      );
    }
    if (offset + blockSize >= bytes.length) {
      throw const InvalidImageException(
        'Truncated GIF graphic control extension.',
      );
    }
    if (bytes[offset + blockSize] != 0) {
      throw const InvalidImageException(
        'Invalid GIF graphic control extension.',
      );
    }
    final packed = bytes[offset];
    final delay = Duration(milliseconds: readUint16Le(bytes, offset + 1) * 10);
    final transparent = (packed & 1) != 0 ? bytes[offset + 3] : null;
    final disposalMethod = (packed >> 2) & 0x07;
    offset += blockSize + 1;
    return (
      offset: offset,
      delay: delay,
      transparentIndex: transparent,
      disposalMethod: disposalMethod,
      loopCount: null,
    );
  }
  int? parsedLoop;
  final data = _readSubBlocks(bytes, offset);
  offset = data.offset;
  if (label == 0xff && data.bytes.length >= 14) {
    final name = String.fromCharCodes(data.bytes.take(11));
    if (name == 'NETSCAPE2.0') {
      parsedLoop = data.bytes[13] << 8 | data.bytes[12];
    }
  }
  return (
    offset: offset,
    delay: null,
    transparentIndex: null,
    disposalMethod: null,
    loopCount: parsedLoop ?? loopCount,
  );
}

({int offset, ImageFrame frame, _GifBounds bounds}) _readImage(
  Uint8List bytes,
  int offset,
  int screenWidth,
  int screenHeight,
  List<int>? globalPalette,
  int? transparentIndex,
  Duration delay,
  Uint8List canvas,
) {
  if (offset + 9 > bytes.length) {
    throw const InvalidImageException('Truncated GIF image descriptor.');
  }
  final left = readUint16Le(bytes, offset);
  final top = readUint16Le(bytes, offset + 2);
  final width = readUint16Le(bytes, offset + 4);
  final height = readUint16Le(bytes, offset + 6);
  final packed = bytes[offset + 8];
  offset += 9;
  final interlaced = (packed & 0x40) != 0;
  var palette = globalPalette;
  if ((packed & 0x80) != 0) {
    final size = 3 * (1 << ((packed & 0x07) + 1));
    if (offset + size > bytes.length) {
      throw const InvalidImageException('Truncated GIF local color table.');
    }
    palette = bytes.sublist(offset, offset + size);
    offset += size;
  }
  if (palette == null) {
    throw const InvalidImageException('GIF image has no palette.');
  }
  if (left + width > screenWidth || top + height > screenHeight) {
    throw const InvalidImageException('GIF frame exceeds logical screen.');
  }
  if (offset >= bytes.length) {
    throw const InvalidImageException('Truncated GIF image data.');
  }
  final minCodeSize = bytes[offset++];
  final blocks = _readSubBlocks(bytes, offset);
  final indices = gifLzwDecode(blocks.bytes, minCodeSize, width * height);
  var indexOffset = 0;
  for (final row in _gifRows(height, interlaced: interlaced)) {
    for (var col = 0; col < width; col += 1) {
      final index = indices[indexOffset++];
      if (index == transparentIndex) {
        continue;
      }
      final paletteOffset = index * 3;
      if (paletteOffset + 2 >= palette.length) {
        throw const InvalidImageException('GIF palette index out of range.');
      }
      final target = ((top + row) * screenWidth + left + col) * 4;
      canvas[target] = palette[paletteOffset];
      canvas[target + 1] = palette[paletteOffset + 1];
      canvas[target + 2] = palette[paletteOffset + 2];
      canvas[target + 3] = 255;
    }
  }
  return (
    offset: blocks.offset,
    bounds: _GifBounds(left, top, width, height),
    frame: ImageFrame(
      pixels: RawPixels(
        bytes: Uint8List.fromList(canvas),
        width: screenWidth,
        height: screenHeight,
        channels: ChannelCount.four,
      ),
      delay: delay == Duration.zero ? null : delay,
    ),
  );
}

final class _GifBounds {
  const _GifBounds(this.left, this.top, this.width, this.height);

  final int left;
  final int top;
  final int width;
  final int height;
}

void _disposeGifFrame(
  Uint8List canvas,
  _GifBounds bounds, {
  required int screenWidth,
  required int disposalMethod,
  required Uint8List? previousCanvas,
}) {
  if (disposalMethod == 2) {
    for (var y = 0; y < bounds.height; y += 1) {
      final start = ((bounds.top + y) * screenWidth + bounds.left) * 4;
      canvas.fillRange(start, start + bounds.width * 4, 0);
    }
  } else if (disposalMethod == 3 && previousCanvas != null) {
    canvas.setAll(0, previousCanvas);
  }
}

({Uint8List bytes, int offset}) _readSubBlocks(Uint8List bytes, int offset) {
  final out = <int>[];
  while (true) {
    if (offset >= bytes.length) {
      throw const InvalidImageException('Truncated GIF data block.');
    }
    final size = bytes[offset++];
    if (size == 0) {
      break;
    }
    if (offset + size > bytes.length) {
      throw const InvalidImageException('Truncated GIF data block.');
    }
    out.addAll(bytes.sublist(offset, offset + size));
    offset += size;
  }
  return (bytes: Uint8List.fromList(out), offset: offset);
}

void _writeLoopExtension(ByteWriter writer, int loopCount) {
  writer
    ..writeByte(0x21)
    ..writeByte(0xff)
    ..writeByte(11)
    ..writeAscii('NETSCAPE2.0')
    ..writeByte(3)
    ..writeByte(1)
    ..writeUint16Le(loopCount)
    ..writeByte(0);
}

void _writeFrame(
  ByteWriter writer,
  ImageFrame frame,
  GifPalette palette,
  int minCodeSize, {
  required bool interlaced,
}) {
  final delay = frame.delay?.inMilliseconds ?? 0;
  final indices = interlaced
      ? _interlacedIndices(palette.indices, frame.width, frame.height)
      : palette.indices;
  writer
    ..writeByte(0x21)
    ..writeByte(0xf9)
    ..writeByte(4)
    ..writeByte(palette.transparentIndex == null ? 0 : 1)
    ..writeUint16Le(delay ~/ 10)
    ..writeByte(palette.transparentIndex ?? 0)
    ..writeByte(0)
    ..writeByte(0x2c)
    ..writeUint16Le(0)
    ..writeUint16Le(0)
    ..writeUint16Le(frame.width)
    ..writeUint16Le(frame.height)
    ..writeByte(interlaced ? 0x40 : 0)
    ..writeByte(minCodeSize);
  _writeSubBlocks(writer, gifLzwEncode(indices, minCodeSize));
}

List<int> _interlacedIndices(List<int> indices, int width, int height) {
  return <int>[
    for (final row in _gifRows(height, interlaced: true))
      ...indices.sublist(row * width, (row + 1) * width),
  ];
}

Iterable<int> _gifRows(int height, {required bool interlaced}) sync* {
  if (!interlaced) {
    for (var row = 0; row < height; row += 1) {
      yield row;
    }
    return;
  }
  const starts = <int>[0, 4, 2, 1];
  const steps = <int>[8, 8, 4, 2];
  for (var pass = 0; pass < starts.length; pass += 1) {
    for (var row = starts[pass]; row < height; row += steps[pass]) {
      yield row;
    }
  }
}

void _writeSubBlocks(ByteWriter writer, Uint8List bytes) {
  for (var offset = 0; offset < bytes.length; offset += 255) {
    final end = offset + 255 > bytes.length ? bytes.length : offset + 255;
    writer
      ..writeByte(end - offset)
      ..writeBytes(bytes.sublist(offset, end));
  }
  writer.writeByte(0);
}

int _minCodeSize(int colors) {
  var bits = 1;
  while ((1 << bits) < colors) {
    bits += 1;
  }
  return bits < 2 ? 2 : bits;
}
