import 'dart:convert';
import 'dart:typed_data';

import '../api/exceptions.dart';
import '../pixels/pixel_image.dart';
import '../source/raw_pixels.dart';
import 'binary_io.dart';
import 'codec.dart';
import 'codec_pixels.dart';
import 'deflate_codec.dart';
import 'encoder_options.dart';
import 'image_format.dart';
import 'output.dart';

/// First-party PNG codec for non-interlaced 8-bit images.
final class PngImageCodec implements ImageCodec {
  /// Creates a PNG codec.
  const PngImageCodec();

  static final Uint8List _signature = Uint8List.fromList(<int>[
    0x89,
    0x50,
    0x4e,
    0x47,
    0x0d,
    0x0a,
    0x1a,
    0x0a,
  ]);

  @override
  ImageFormat get format => ImageFormat.png;

  @override
  PixelImage decode(Uint8List bytes) {
    if (bytes.length < 33 || !_matchesSignature(bytes)) {
      throw const InvalidImageException('Invalid PNG signature.');
    }
    final idat = <int>[];
    var offset = 8;
    var width = 0;
    var height = 0;
    var bitDepth = 0;
    var colorType = 0;
    List<int>? palette;
    List<int>? transparency;
    while (offset + 12 <= bytes.length) {
      final length = readUint32Be(bytes, offset);
      final type = ascii.decode(bytes.sublist(offset + 4, offset + 8));
      final dataStart = offset + 8;
      final dataEnd = dataStart + length;
      if (dataEnd + 4 > bytes.length) {
        throw const InvalidImageException('Truncated PNG chunk.');
      }
      final data = bytes.sublist(dataStart, dataEnd);
      _verifyCrc(type, data, readUint32Be(bytes, dataEnd));
      if (type == 'IHDR') {
        width = readUint32Be(data, 0);
        height = readUint32Be(data, 4);
        bitDepth = data[8];
        colorType = data[9];
        if (data[10] != 0 || data[11] != 0 || data[12] != 0) {
          throw const UnsupportedCodecException(
            'Only standard non-interlaced PNG images are supported.',
          );
        }
      } else if (type == 'PLTE') {
        palette = data;
      } else if (type == 'tRNS') {
        transparency = data;
      } else if (type == 'IDAT') {
        idat.addAll(data);
      } else if (type == 'IEND') {
        break;
      }
      offset = dataEnd + 4;
    }
    if (width <= 0 || height <= 0 || bitDepth != 8) {
      throw const UnsupportedCodecException('Only 8-bit PNG images supported.');
    }
    final inflated = zlibDecode(Uint8List.fromList(idat));
    final rgba = _decodeScanlines(
      inflated,
      width,
      height,
      colorType,
      palette,
      transparency,
    );
    return PixelImage.fromRawPixels(
      RawPixels(
        bytes: rgba,
        width: width,
        height: height,
        channels: ChannelCount.four,
      ),
    );
  }

  @override
  EncodedImage encode(PixelImage image, {EncoderOptions? options}) {
    final pngOptions = options is PngEncoderOptions
        ? options
        : const PngEncoderOptions();
    final raw = image.firstFrame.pixels;
    final rgba = rawToRgba(raw);
    final scanlines = ByteWriter();
    final rowLength = raw.width * 4;
    for (var y = 0; y < raw.height; y += 1) {
      scanlines.writeByte(0);
      scanlines.writeBytes(rgba.sublist(y * rowLength, (y + 1) * rowLength));
    }
    final writer = ByteWriter()..writeBytes(_signature);
    _writeChunk(writer, 'IHDR', _ihdr(raw.width, raw.height));
    final data = scanlines.toBytes();
    _writeChunk(
      writer,
      'IDAT',
      pngOptions.compressionLevel == 0
          ? zlibEncodeStored(data)
          : zlibEncodeFixed(data),
    );
    _writeChunk(writer, 'IEND', Uint8List(0));
    final bytes = writer.toBytes();
    return EncodedImage(
      bytes: bytes,
      info: OutputInfo(
        format: format,
        size: bytes.length,
        width: raw.width,
        height: raw.height,
        channels: 4,
      ),
    );
  }

  bool _matchesSignature(Uint8List bytes) {
    for (var i = 0; i < _signature.length; i += 1) {
      if (bytes[i] != _signature[i]) {
        return false;
      }
    }
    return true;
  }
}

Uint8List _decodeScanlines(
  Uint8List inflated,
  int width,
  int height,
  int colorType,
  List<int>? palette,
  List<int>? transparency,
) {
  final channels = switch (colorType) {
    0 => 1,
    2 => 3,
    3 => 1,
    4 => 2,
    6 => 4,
    _ => 0,
  };
  if (channels == 0) {
    throw const UnsupportedCodecException('Unsupported PNG colour type.');
  }
  final rowLength = width * channels;
  final output = Uint8List(width * height * 4);
  var sourceOffset = 0;
  var previous = Uint8List(rowLength);
  for (var y = 0; y < height; y += 1) {
    final filter = inflated[sourceOffset++];
    final row = Uint8List.fromList(
      inflated.sublist(sourceOffset, sourceOffset + rowLength),
    );
    _unfilter(row, previous, channels, filter);
    _writeRgbaRow(output, y, width, colorType, row, palette, transparency);
    previous = row;
    sourceOffset += rowLength;
  }
  return output;
}

void _unfilter(Uint8List row, Uint8List previous, int bpp, int filter) {
  for (var i = 0; i < row.length; i += 1) {
    final left = i >= bpp ? row[i - bpp] : 0;
    final up = previous[i];
    final upLeft = i >= bpp ? previous[i - bpp] : 0;
    row[i] = switch (filter) {
      0 => row[i],
      1 => (row[i] + left) & 0xff,
      2 => (row[i] + up) & 0xff,
      3 => (row[i] + ((left + up) >> 1)) & 0xff,
      4 => (row[i] + _paeth(left, up, upLeft)) & 0xff,
      _ => throw const InvalidImageException('Invalid PNG filter type.'),
    };
  }
}

void _writeRgbaRow(
  Uint8List output,
  int y,
  int width,
  int colorType,
  Uint8List row,
  List<int>? palette,
  List<int>? transparency,
) {
  for (var x = 0; x < width; x += 1) {
    final target = (y * width + x) * 4;
    final source = switch (colorType) {
      0 || 3 => x,
      2 => x * 3,
      4 => x * 2,
      _ => x * 4,
    };
    if (colorType == 0) {
      output[target] = row[source];
      output[target + 1] = row[source];
      output[target + 2] = row[source];
      output[target + 3] = 255;
    } else if (colorType == 3) {
      final index = row[source];
      final paletteOffset = index * 3;
      if (palette == null || paletteOffset + 2 >= palette.length) {
        throw const InvalidImageException('Invalid PNG palette index.');
      }
      output[target] = palette[paletteOffset];
      output[target + 1] = palette[paletteOffset + 1];
      output[target + 2] = palette[paletteOffset + 2];
      output[target + 3] = index < (transparency?.length ?? 0)
          ? transparency![index]
          : 255;
    } else {
      output[target] = row[source];
      output[target + 1] = row[source + 1];
      output[target + 2] = colorType == 4 ? row[source] : row[source + 2];
      output[target + 3] = switch (colorType) {
        4 => row[source + 1],
        6 => row[source + 3],
        _ => 255,
      };
    }
  }
}

int _paeth(int left, int up, int upLeft) {
  final p = left + up - upLeft;
  final pa = (p - left).abs();
  final pb = (p - up).abs();
  final pc = (p - upLeft).abs();
  if (pa <= pb && pa <= pc) {
    return left;
  }
  return pb <= pc ? up : upLeft;
}

Uint8List _ihdr(int width, int height) {
  return (ByteWriter()
        ..writeUint32Be(width)
        ..writeUint32Be(height)
        ..writeByte(8)
        ..writeByte(6)
        ..writeByte(0)
        ..writeByte(0)
        ..writeByte(0))
      .toBytes();
}

void _writeChunk(ByteWriter writer, String type, Uint8List data) {
  final typeBytes = ascii.encode(type);
  writer
    ..writeUint32Be(data.length)
    ..writeBytes(typeBytes)
    ..writeBytes(data)
    ..writeUint32Be(crc32(<int>[...typeBytes, ...data]));
}

void _verifyCrc(String type, Uint8List data, int expected) {
  final actual = crc32(<int>[...ascii.encode(type), ...data]);
  if (actual != expected) {
    throw const InvalidImageException('Invalid PNG chunk CRC.');
  }
}
