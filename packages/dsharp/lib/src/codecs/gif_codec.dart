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
      globalPalette = bytes.sublist(offset, offset + size);
      offset += size;
    }
    final frames = <ImageFrame>[];
    var delay = Duration.zero;
    int? transparentIndex;
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
        loopCount = result.loopCount ?? loopCount;
      } else if (marker == 0x2c) {
        final image = _readImage(
          bytes,
          offset,
          width,
          height,
          globalPalette,
          transparentIndex,
          delay,
        );
        offset = image.offset;
        frames.add(image.frame);
        delay = Duration.zero;
        transparentIndex = null;
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
    final raw = image.firstFrame.pixels;
    final frameRgba = <Uint8List>[
      for (final frame in image.frames) rawToRgba(frame.pixels),
    ];
    final palette = GifPalette.fromRgba(
      Uint8List.fromList(<int>[for (final rgba in frameRgba) ...rgba]),
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
    if (image.loopCount != null) {
      _writeLoopExtension(writer, image.loopCount!);
    }
    var indexOffset = 0;
    for (var i = 0; i < image.frames.length; i += 1) {
      final frame = image.frames[i];
      final pixelCount = frame.width * frame.height;
      _writeFrame(
        writer,
        frame,
        GifPalette(
          palette.bytes,
          palette.indices.sublist(indexOffset, indexOffset + pixelCount),
          palette.size,
          palette.tablePower,
          palette.transparentIndex,
        ),
        minCodeSize,
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
        frames: image.frames.length,
        loopCount: image.loopCount,
      ),
    );
  }
}

({int offset, Duration? delay, int? transparentIndex, int? loopCount})
_readExtension(Uint8List bytes, int offset, int loopCount) {
  final label = bytes[offset++];
  if (label == 0xf9) {
    final blockSize = bytes[offset++];
    final packed = bytes[offset];
    final delay = Duration(milliseconds: readUint16Le(bytes, offset + 1) * 10);
    final transparent = (packed & 1) != 0 ? bytes[offset + 3] : null;
    offset += blockSize + 1;
    return (
      offset: offset,
      delay: delay,
      transparentIndex: transparent,
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
    loopCount: parsedLoop ?? loopCount,
  );
}

({int offset, ImageFrame frame}) _readImage(
  Uint8List bytes,
  int offset,
  int screenWidth,
  int screenHeight,
  List<int>? globalPalette,
  int? transparentIndex,
  Duration delay,
) {
  final left = readUint16Le(bytes, offset);
  final top = readUint16Le(bytes, offset + 2);
  final width = readUint16Le(bytes, offset + 4);
  final height = readUint16Le(bytes, offset + 6);
  final packed = bytes[offset + 8];
  offset += 9;
  var palette = globalPalette;
  if ((packed & 0x80) != 0) {
    final size = 3 * (1 << ((packed & 0x07) + 1));
    palette = bytes.sublist(offset, offset + size);
    offset += size;
  }
  if (palette == null) {
    throw const InvalidImageException('GIF image has no palette.');
  }
  final minCodeSize = bytes[offset++];
  final blocks = _readSubBlocks(bytes, offset);
  final indices = gifLzwDecode(blocks.bytes, minCodeSize, width * height);
  final canvas = Uint8List(screenWidth * screenHeight * 4);
  for (var i = 0; i < indices.length; i += 1) {
    final x = left + (i % width);
    final y = top + (i ~/ width);
    final index = indices[i];
    final paletteOffset = index * 3;
    final target = (y * screenWidth + x) * 4;
    canvas[target] = palette[paletteOffset];
    canvas[target + 1] = palette[paletteOffset + 1];
    canvas[target + 2] = palette[paletteOffset + 2];
    canvas[target + 3] = index == transparentIndex ? 0 : 255;
  }
  return (
    offset: blocks.offset,
    frame: ImageFrame(
      pixels: RawPixels(
        bytes: canvas,
        width: screenWidth,
        height: screenHeight,
        channels: ChannelCount.four,
      ),
      delay: delay == Duration.zero ? null : delay,
    ),
  );
}

({Uint8List bytes, int offset}) _readSubBlocks(Uint8List bytes, int offset) {
  final out = <int>[];
  while (true) {
    final size = bytes[offset++];
    if (size == 0) {
      break;
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
  int minCodeSize,
) {
  final delay = frame.delay?.inMilliseconds ?? 0;
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
    ..writeByte(0)
    ..writeByte(minCodeSize);
  _writeSubBlocks(writer, gifLzwEncode(palette.indices, minCodeSize));
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
