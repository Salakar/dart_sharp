import 'dart:convert';
import 'dart:typed_data';

import '../api/exceptions.dart';
import '../pixels/pixel_image.dart';
import '../source/input_options.dart';
import '../source/raw_pixels.dart';
import 'binary_io.dart';
import 'codec.dart';
import 'codec_pixels.dart';
import 'deflate_codec.dart';
import 'encoder_options.dart';
import 'gif_palette.dart';
import 'image_format.dart';
import 'output.dart';

part 'png_samples.dart';

/// First-party PNG codec for interlaced, palette, and truecolour images.
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
    if (width <= 0 || height <= 0) {
      throw const InvalidImageException('Invalid PNG dimensions.');
    }
    const InputSafetyLimits().checkImage(
      width: width,
      height: height,
      frames: 1,
    );
    if (!_supportsPngBitDepth(colorType, bitDepth)) {
      throw const UnsupportedCodecException(
        'Unsupported PNG colour type or bit depth.',
      );
    }
    final inflated = zlibDecode(Uint8List.fromList(idat));
    final rgba = interlace == 1
        ? _decodeAdam7(
            inflated,
            width,
            height,
            bitDepth,
            colorType,
            palette,
            transparency,
          )
        : _decodeScanlines(
            inflated,
            width,
            height,
            bitDepth,
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
    if (!pngOptions.usesPalette &&
        !_supportsPaletteBitDepth(pngOptions.bitDepth)) {
      throw const UnsupportedCodecException(
        'PNG grayscale encoding supports bit depths 1, 2, 4, and 8.',
      );
    }
    if (pngOptions.usesPalette &&
        !_supportsPaletteBitDepth(pngOptions.paletteBitDepth)) {
      throw const UnsupportedCodecException(
        'PNG palette encoding supports bit depths 1, 2, 4, and 8.',
      );
    }
    final raw = image.firstFrame.pixels;
    final rgba = rawToRgba(raw);
    if (pngOptions.usesPalette) {
      return _encodePalettePng(raw.width, raw.height, rgba, pngOptions);
    }
    if (pngOptions.bitDepth < 8) {
      return _encodeGrayscalePng(raw.width, raw.height, rgba, pngOptions);
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
  final bitDepth = options.paletteBitDepth;
  final palette = GifPalette.fromRgba(rgba, maxColors: 1 << bitDepth);
  final writer = ByteWriter()..writeBytes(PngImageCodec._signature);
  _writeChunk(
    writer,
    'IHDR',
    _ihdr(
      width,
      height,
      bitDepth: bitDepth,
      colorType: 3,
      interlace: options.progressive ? 1 : 0,
    ),
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
    bitDepth: bitDepth,
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

EncodedImage _encodeGrayscalePng(
  int width,
  int height,
  Uint8List rgba,
  PngEncoderOptions options,
) {
  final writer = ByteWriter()..writeBytes(PngImageCodec._signature);
  _writeChunk(
    writer,
    'IHDR',
    _ihdr(
      width,
      height,
      bitDepth: options.bitDepth,
      colorType: 0,
      interlace: options.progressive ? 1 : 0,
    ),
  );
  final data = _grayscaleScanlines(
    width,
    height,
    rgba,
    bitDepth: options.bitDepth,
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
      channels: 1,
    ),
  );
}

Uint8List _decodeScanlines(
  Uint8List inflated,
  int width,
  int height,
  int bitDepth,
  int colorType,
  List<int>? palette,
  List<int>? transparency,
) {
  final channels = _pngChannels(colorType);
  if (channels == 0) {
    throw const UnsupportedCodecException('Unsupported PNG colour type.');
  }
  final rowLength = _scanlineBytes(width, channels, bitDepth);
  final bpp = _filterBytesPerPixel(channels, bitDepth);
  final output = Uint8List(width * height * 4);
  var sourceOffset = 0;
  var previous = Uint8List(rowLength);
  for (var y = 0; y < height; y += 1) {
    final filter = inflated[sourceOffset++];
    final row = Uint8List.fromList(
      inflated.sublist(sourceOffset, sourceOffset + rowLength),
    );
    _unfilter(row, previous, bpp, filter);
    final samples = bitDepth < 8 ? _unpackSamples(row, width, bitDepth) : row;
    _writeRgbaRow(
      output,
      y,
      width,
      bitDepth,
      colorType,
      samples,
      palette,
      transparency,
    );
    previous = row;
    sourceOffset += rowLength;
  }
  return output;
}

Uint8List _decodeAdam7(
  Uint8List inflated,
  int width,
  int height,
  int bitDepth,
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
    final rowLength = _scanlineBytes(passWidth, channels, bitDepth);
    final bpp = _filterBytesPerPixel(channels, bitDepth);
    var previous = Uint8List(rowLength);
    for (var rowIndex = 0; rowIndex < passHeight; rowIndex += 1) {
      final filter = inflated[sourceOffset++];
      final row = Uint8List.fromList(
        inflated.sublist(sourceOffset, sourceOffset + rowLength),
      );
      _unfilter(row, previous, bpp, filter);
      final samples = bitDepth < 8
          ? _unpackSamples(row, passWidth, bitDepth)
          : row;
      final y = pass.yStart + rowIndex * pass.yStep;
      for (var col = 0; col < passWidth; col += 1) {
        final x = pass.start + col * pass.step;
        _writeRgbaPixel(
          output,
          x,
          y,
          width,
          bitDepth,
          colorType,
          samples,
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
  required int bitDepth,
  required bool interlaced,
}) {
  final scanlines = ByteWriter();
  if (!interlaced) {
    for (var y = 0; y < height; y += 1) {
      scanlines.writeByte(0);
      _writeIndexedRow(scanlines, indices, y * width, width, bitDepth);
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
      final rowIndices = <int>[
        for (var col = 0; col < passWidth; col += 1)
          indices[y * width + pass.start + col * pass.step],
      ];
      _writeIndexedRow(scanlines, rowIndices, 0, passWidth, bitDepth);
    }
  }
  return scanlines.toBytes();
}

Uint8List _grayscaleScanlines(
  int width,
  int height,
  Uint8List rgba, {
  required int bitDepth,
  required bool interlaced,
}) {
  final scanlines = ByteWriter();
  if (!interlaced) {
    for (var y = 0; y < height; y += 1) {
      scanlines.writeByte(0);
      final samples = <int>[
        for (var x = 0; x < width; x += 1)
          _grayscaleSample(rgba, y * width + x, bitDepth),
      ];
      _writeIndexedRow(scanlines, samples, 0, width, bitDepth);
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
      final rowBase = y * width + pass.start;
      scanlines.writeByte(0);
      final samples = <int>[
        for (var col = 0; col < passWidth; col += 1)
          _grayscaleSample(rgba, rowBase + col * pass.step, bitDepth),
      ];
      _writeIndexedRow(scanlines, samples, 0, passWidth, bitDepth);
    }
  }
  return scanlines.toBytes();
}

int _grayscaleSample(Uint8List rgba, int pixel, int bitDepth) {
  final offset = pixel * 4;
  if (rgba[offset + 3] != 255) {
    throw const UnsupportedCodecException('Opaque pixels required.');
  }
  final gray =
      (rgba[offset] * 299 + rgba[offset + 1] * 587 + rgba[offset + 2] * 114) ~/
      1000;
  return (gray * ((1 << bitDepth) - 1) + 127) ~/ 255;
}

void _writeIndexedRow(
  ByteWriter writer,
  List<int> indices,
  int offset,
  int width,
  int bitDepth,
) {
  if (bitDepth == 8) {
    writer.writeBytes(indices.sublist(offset, offset + width));
    return;
  }
  final mask = (1 << bitDepth) - 1;
  var byte = 0;
  var bits = 0;
  for (var i = 0; i < width; i += 1) {
    byte = (byte << bitDepth) | (indices[offset + i] & mask);
    bits += bitDepth;
    if (bits == 8) {
      writer.writeByte(byte);
      byte = 0;
      bits = 0;
    }
  }
  if (bits > 0) {
    writer.writeByte(byte << (8 - bits));
  }
}

Uint8List _ihdr(
  int width,
  int height, {
  int bitDepth = 8,
  int colorType = 6,
  int interlace = 0,
}) {
  return (ByteWriter()
        ..writeUint32Be(width)
        ..writeUint32Be(height)
        ..writeByte(bitDepth)
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
