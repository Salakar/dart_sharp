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

/// First-party baseline TIFF codec for uncompressed 8-bit chunky images.
final class TiffImageCodec implements ImageCodec {
  /// Creates a TIFF codec.
  const TiffImageCodec();

  @override
  ImageFormat get format => ImageFormat.tiff;

  @override
  PixelImage decode(Uint8List bytes) {
    if (bytes.length < 8 || bytes[0] != 0x49 || bytes[1] != 0x49) {
      throw const UnsupportedCodecException(
        'Only little-endian baseline TIFF is supported.',
      );
    }
    if (readUint16Le(bytes, 2) != 42) {
      throw const InvalidImageException('Invalid TIFF header.');
    }
    final tags = _readIfd(bytes, readUint32Le(bytes, 4));
    final width = tags.value(256);
    final height = tags.value(257);
    final compression = tags.value(259);
    final photometric = tags.value(262);
    final stripOffset = tags.value(273);
    final samples = tags.value(277, fallback: 1);
    final byteCount = tags.value(279);
    if (compression != 1 || photometric == 3) {
      throw const UnsupportedCodecException(
        'Only uncompressed non-paletted TIFF is supported.',
      );
    }
    final source = bytes.sublist(stripOffset, stripOffset + byteCount);
    final rgba = _toRgba(source, width, height, samples, photometric);
    return PixelImage.fromRawPixels(
      RawPixels(
        bytes: Uint8List.fromList(rgba),
        width: width,
        height: height,
        channels: ChannelCount.four,
      ),
    );
  }

  @override
  EncodedImage encode(PixelImage image, {EncoderOptions? options}) {
    final tiffOptions = options is TiffEncoderOptions
        ? options
        : const TiffEncoderOptions();
    if (tiffOptions.compression != TiffCompression.none) {
      throw const UnsupportedCodecException(
        'TIFF encoding currently supports uncompressed output only.',
      );
    }
    if (tiffOptions.bitDepth != 8) {
      throw const UnsupportedCodecException(
        'TIFF encoding currently supports 8-bit output only.',
      );
    }
    if (tiffOptions.tile) {
      throw const UnsupportedCodecException(
        'Tiled TIFF encoding is not implemented yet.',
      );
    }
    if (tiffOptions.pyramid) {
      throw const UnsupportedCodecException(
        'TIFF pyramid encoding is not implemented yet.',
      );
    }
    if (tiffOptions.quality != 80) {
      throw const UnsupportedCodecException(
        'TIFF quality is only meaningful for compressed output.',
      );
    }
    final raw = image.firstFrame.pixels;
    final channels = raw.channels == ChannelCount.three ? 3 : 4;
    final pixels = channels == 3 ? rawToRgb(raw) : rawToRgba(raw);
    const entryCount = 10;
    const ifdOffset = 8;
    final bitsOffset = ifdOffset + 2 + entryCount * 12 + 4;
    final extraOffset = bitsOffset + channels * 2;
    final pixelOffset = extraOffset + (channels == 4 ? 2 : 0);
    final writer = ByteWriter()
      ..writeAscii('II')
      ..writeUint16Le(42)
      ..writeUint32Le(ifdOffset)
      ..writeUint16Le(entryCount);
    _entry(writer, 256, 4, 1, raw.width);
    _entry(writer, 257, 4, 1, raw.height);
    _entry(writer, 258, 3, channels, bitsOffset);
    _entry(writer, 259, 3, 1, 1);
    _entry(writer, 262, 3, 1, 2);
    _entry(writer, 273, 4, 1, pixelOffset);
    _entry(writer, 277, 3, 1, channels);
    _entry(writer, 278, 4, 1, raw.height);
    _entry(writer, 279, 4, 1, pixels.length);
    _entry(writer, 284, 3, 1, 1);
    writer.writeUint32Le(0);
    for (var i = 0; i < channels; i += 1) {
      writer.writeUint16Le(8);
    }
    if (channels == 4) {
      writer.writeUint16Le(2);
    }
    writer.writeBytes(pixels);
    final bytes = writer.toBytes();
    return EncodedImage(
      bytes: bytes,
      info: OutputInfo(
        format: format,
        size: bytes.length,
        width: raw.width,
        height: raw.height,
        channels: channels,
      ),
    );
  }
}

final class _Ifd {
  _Ifd(this.tags);

  final Map<int, int> tags;

  int value(int tag, {int? fallback}) {
    final value = tags[tag];
    if (value == null) {
      if (fallback != null) {
        return fallback;
      }
      throw InvalidImageException('Missing TIFF tag $tag.');
    }
    return value;
  }
}

_Ifd _readIfd(Uint8List bytes, int offset) {
  final count = readUint16Le(bytes, offset);
  final tags = <int, int>{};
  for (var i = 0; i < count; i += 1) {
    final entry = offset + 2 + i * 12;
    final tag = readUint16Le(bytes, entry);
    final type = readUint16Le(bytes, entry + 2);
    final itemCount = readUint32Le(bytes, entry + 4);
    final rawValue = readUint32Le(bytes, entry + 8);
    if (itemCount == 1) {
      tags[tag] = type == 3 ? readUint16Le(bytes, entry + 8) : rawValue;
    } else {
      tags[tag] = rawValue;
    }
  }
  return _Ifd(tags);
}

List<int> _toRgba(
  List<int> source,
  int width,
  int height,
  int samples,
  int photometric,
) {
  final output = Uint8List(width * height * 4);
  for (var pixel = 0; pixel < width * height; pixel += 1) {
    final src = pixel * samples;
    final dst = pixel * 4;
    if (samples == 1) {
      final gray = photometric == 0 ? 255 - source[src] : source[src];
      output[dst] = gray;
      output[dst + 1] = gray;
      output[dst + 2] = gray;
      output[dst + 3] = 255;
    } else if (samples >= 3) {
      output[dst] = source[src];
      output[dst + 1] = source[src + 1];
      output[dst + 2] = source[src + 2];
      output[dst + 3] = samples >= 4 ? source[src + 3] : 255;
    } else {
      throw const UnsupportedCodecException('Unsupported TIFF sample layout.');
    }
  }
  return output;
}

void _entry(ByteWriter writer, int tag, int type, int count, int value) {
  writer
    ..writeUint16Le(tag)
    ..writeUint16Le(type)
    ..writeUint32Le(count);
  if (type == 3 && count == 1) {
    writer
      ..writeUint16Le(value)
      ..writeUint16Le(0);
  } else {
    writer.writeUint32Le(value);
  }
}
