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
import 'gif_palette.dart';
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
    var interlace = 0;
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
        interlace = data[12];
        if (data[10] != 0 || data[11] != 0 || interlace > 1) {
          throw const UnsupportedCodecException(
            'Only standard PNG compression, filtering, and interlace are supported.',
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
    final rgba = interlace == 1
        ? _decodeAdam7(
            inflated,
            width,
            height,
            colorType,
            palette,
            transparency,
          )
        : _decodeScanlines(
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
    if (pngOptions.bitDepth != 8) {
      throw const UnsupportedCodecException(
        'PNG encoding currently supports 8-bit output only.',
      );
    }
    final raw = image.firstFrame.pixels;
    final rgba = rawToRgba(raw);
    if (pngOptions.palette) {
      return _encodePalettePng(raw.width, raw.height, rgba, pngOptions);
    }
    final writer = ByteWriter()..writeBytes(_signature);
    _writeChunk(
      writer,
      'IHDR',
      _ihdr(raw.width, raw.height, interlace: pngOptions.progressive ? 1 : 0),
    );
    final data = _rgbaScanlines(
      raw.width,
      raw.height,
      rgba,
      interlaced: pngOptions.progressive,
    );
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

EncodedImage _encodePalettePng(
  int width,
  int height,
  Uint8List rgba,
  PngEncoderOptions options,
) {
  final palette = GifPalette.fromRgba(rgba);
  final writer = ByteWriter()..writeBytes(PngImageCodec._signature);
  _writeChunk(
    writer,
    'IHDR',
    _ihdr(width, height, colorType: 3, interlace: options.progressive ? 1 : 0),
  );
  _writeChunk(writer, 'PLTE', _pngPaletteBytes(palette));
  final transparency = _pngTransparency(palette);
  if (transparency != null) {
    _writeChunk(writer, 'tRNS', transparency);
  }
  final data = _indexedScanlines(
    width,
    height,
    palette.indices,
    interlaced: options.progressive,
  );
  _writeChunk(
    writer,
    'IDAT',
    options.compressionLevel == 0
        ? zlibEncodeStored(data)
        : zlibEncodeFixed(data),
  );
  _writeChunk(writer, 'IEND', Uint8List(0));
  final bytes = writer.toBytes();
  return EncodedImage(
    bytes: bytes,
    info: OutputInfo(
      format: ImageFormat.png,
      size: bytes.length,
      width: width,
      height: height,
      channels: 4,
    ),
  );
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

Uint8List _decodeAdam7(
  Uint8List inflated,
  int width,
  int height,
  int colorType,
  List<int>? palette,
  List<int>? transparency,
) {
  final channels = _pngChannels(colorType);
  if (channels == 0) {
    throw const UnsupportedCodecException('Unsupported PNG colour type.');
  }
  final output = Uint8List(width * height * 4);
  var sourceOffset = 0;
  for (final pass in _adam7Passes) {
    final passWidth = _passSize(width, pass.start, pass.step);
    final passHeight = _passSize(height, pass.yStart, pass.yStep);
    if (passWidth == 0 || passHeight == 0) {
      continue;
    }
    final rowLength = passWidth * channels;
    var previous = Uint8List(rowLength);
    for (var rowIndex = 0; rowIndex < passHeight; rowIndex += 1) {
      final filter = inflated[sourceOffset++];
      final row = Uint8List.fromList(
        inflated.sublist(sourceOffset, sourceOffset + rowLength),
      );
      _unfilter(row, previous, channels, filter);
      final y = pass.yStart + rowIndex * pass.yStep;
      for (var col = 0; col < passWidth; col += 1) {
        final x = pass.start + col * pass.step;
        _writeRgbaPixel(
          output,
          x,
          y,
          width,
          colorType,
          row,
          col,
          palette,
          transparency,
        );
      }
      previous = row;
      sourceOffset += rowLength;
    }
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
    _writeRgbaPixel(
      output,
      x,
      y,
      width,
      colorType,
      row,
      x,
      palette,
      transparency,
    );
  }
}

void _writeRgbaPixel(
  Uint8List output,
  int x,
  int y,
  int width,
  int colorType,
  Uint8List row,
  int column,
  List<int>? palette,
  List<int>? transparency,
) {
  final target = (y * width + x) * 4;
  final source = switch (colorType) {
    0 || 3 => column,
    2 => column * 3,
    4 => column * 2,
    _ => column * 4,
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

int _pngChannels(int colorType) {
  return switch (colorType) {
    0 => 1,
    2 => 3,
    3 => 1,
    4 => 2,
    6 => 4,
    _ => 0,
  };
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

Uint8List _rgbaScanlines(
  int width,
  int height,
  Uint8List rgba, {
  required bool interlaced,
}) {
  final scanlines = ByteWriter();
  if (!interlaced) {
    final rowLength = width * 4;
    for (var y = 0; y < height; y += 1) {
      scanlines.writeByte(0);
      scanlines.writeBytes(rgba.sublist(y * rowLength, (y + 1) * rowLength));
    }
    return scanlines.toBytes();
  }
  for (final pass in _adam7Passes) {
    final passWidth = _passSize(width, pass.start, pass.step);
    final passHeight = _passSize(height, pass.yStart, pass.yStep);
    if (passWidth == 0 || passHeight == 0) {
      continue;
    }
    for (var row = 0; row < passHeight; row += 1) {
      final y = pass.yStart + row * pass.yStep;
      scanlines.writeByte(0);
      for (var col = 0; col < passWidth; col += 1) {
        final x = pass.start + col * pass.step;
        final source = (y * width + x) * 4;
        scanlines.writeBytes(rgba.sublist(source, source + 4));
      }
    }
  }
  return scanlines.toBytes();
}

Uint8List _indexedScanlines(
  int width,
  int height,
  List<int> indices, {
  required bool interlaced,
}) {
  final scanlines = ByteWriter();
  if (!interlaced) {
    for (var y = 0; y < height; y += 1) {
      scanlines.writeByte(0);
      scanlines.writeBytes(indices.sublist(y * width, (y + 1) * width));
    }
    return scanlines.toBytes();
  }
  for (final pass in _adam7Passes) {
    final passWidth = _passSize(width, pass.start, pass.step);
    final passHeight = _passSize(height, pass.yStart, pass.yStep);
    if (passWidth == 0 || passHeight == 0) {
      continue;
    }
    for (var row = 0; row < passHeight; row += 1) {
      final y = pass.yStart + row * pass.yStep;
      scanlines.writeByte(0);
      for (var col = 0; col < passWidth; col += 1) {
        final x = pass.start + col * pass.step;
        scanlines.writeByte(indices[y * width + x]);
      }
    }
  }
  return scanlines.toBytes();
}

Uint8List _ihdr(int width, int height, {int colorType = 6, int interlace = 0}) {
  return (ByteWriter()
        ..writeUint32Be(width)
        ..writeUint32Be(height)
        ..writeByte(8)
        ..writeByte(colorType)
        ..writeByte(0)
        ..writeByte(0)
        ..writeByte(interlace))
      .toBytes();
}

typedef _Adam7Pass = ({int start, int yStart, int step, int yStep});

const _adam7Passes = <_Adam7Pass>[
  (start: 0, yStart: 0, step: 8, yStep: 8),
  (start: 4, yStart: 0, step: 8, yStep: 8),
  (start: 0, yStart: 4, step: 4, yStep: 8),
  (start: 2, yStart: 0, step: 4, yStep: 4),
  (start: 0, yStart: 2, step: 2, yStep: 4),
  (start: 1, yStart: 0, step: 2, yStep: 2),
  (start: 0, yStart: 1, step: 1, yStep: 2),
];

int _passSize(int size, int start, int step) {
  if (size <= start) {
    return 0;
  }
  return (size - start + step - 1) ~/ step;
}

Uint8List _pngPaletteBytes(GifPalette palette) {
  return Uint8List.fromList(palette.bytes.sublist(0, palette.size * 3));
}

Uint8List? _pngTransparency(GifPalette palette) {
  final transparent = palette.transparentIndex;
  if (transparent == null) {
    return null;
  }
  final bytes = Uint8List(transparent + 1);
  for (var i = 0; i < transparent; i += 1) {
    bytes[i] = 255;
  }
  bytes[transparent] = 0;
  return bytes;
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
