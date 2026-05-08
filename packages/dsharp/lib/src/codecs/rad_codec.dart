import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import '../api/exceptions.dart';
import '../pixels/pixel_image.dart';
import '../source/input_options.dart';
import '../source/raw_pixels.dart';
import 'binary_io.dart';
import 'codec.dart';
import 'codec_pixels.dart';
import 'encoder_options.dart';
import 'image_format.dart';
import 'output.dart';

/// First-party Radiance HDR RGBE codec.
final class RadImageCodec implements ImageCodec {
  /// Creates a Radiance HDR codec.
  const RadImageCodec();

  @override
  ImageFormat get format => ImageFormat.rad;

  @override
  PixelImage decode(Uint8List bytes) {
    final header = _readRadHeader(bytes);
    const InputSafetyLimits().checkImage(
      width: header.width,
      height: header.height,
      frames: 1,
    );
    final rgba = Uint8List(header.width * header.height * 4);
    var offset = header.rasterOffset;
    for (var scanline = 0; scanline < header.height; scanline += 1) {
      final decoded = _readRgbeScanline(bytes, offset, header.width);
      offset = decoded.offset;
      final y = header.yTopDown ? scanline : header.height - 1 - scanline;
      for (var x = 0; x < header.width; x += 1) {
        final outputX = header.xLeftToRight ? x : header.width - 1 - x;
        final input = x * 4;
        final output = ((y * header.width) + outputX) * 4;
        _writeRgbaFromRgbe(decoded.rgbe, input, rgba, output);
      }
    }
    return PixelImage.fromRawPixels(
      RawPixels(
        bytes: rgba,
        width: header.width,
        height: header.height,
        channels: ChannelCount.four,
      ),
    );
  }

  @override
  EncodedImage encode(PixelImage image, {EncoderOptions? options}) {
    final raw = image.firstFrame.pixels;
    final rgba = rawToRgba(raw);
    final writer = ByteWriter()
      ..writeAscii('#?RADIANCE\n')
      ..writeAscii('FORMAT=32-bit_rle_rgbe\n\n')
      ..writeAscii('-Y ${raw.height} +X ${raw.width}\n');
    final scanline = Uint8List(raw.width * 4);
    for (var y = 0; y < raw.height; y += 1) {
      for (var x = 0; x < raw.width; x += 1) {
        final input = ((y * raw.width) + x) * 4;
        _writeRgbeFromRgb(
          rgba[input],
          rgba[input + 1],
          rgba[input + 2],
          scanline,
          x * 4,
        );
      }
      _writeRgbeScanline(writer, scanline, raw.width);
    }
    final bytes = writer.toBytes();
    return EncodedImage(
      bytes: bytes,
      info: OutputInfo(
        format: format,
        size: bytes.length,
        width: raw.width,
        height: raw.height,
        channels: 3,
      ),
    );
  }
}

_RadHeader _readRadHeader(Uint8List bytes) {
  final scanner = _RadLineScanner(bytes);
  final signature = scanner.nextLine();
  if (signature != '#?RADIANCE' && signature != '#?RGBE') {
    throw const InvalidImageException('Invalid Radiance HDR signature.');
  }
  var hasFormat = false;
  while (true) {
    final line = scanner.nextLine();
    if (line == null) {
      throw const InvalidImageException('Radiance HDR missing resolution.');
    }
    final trimmed = line.trim();
    if (trimmed == 'FORMAT=32-bit_rle_rgbe') {
      hasFormat = true;
      continue;
    }
    final resolution = _parseResolution(trimmed);
    if (resolution != null) {
      if (!hasFormat) {
        throw const InvalidImageException('Radiance HDR missing RGBE format.');
      }
      return _RadHeader(
        width: resolution.width,
        height: resolution.height,
        xLeftToRight: resolution.xLeftToRight,
        yTopDown: resolution.yTopDown,
        rasterOffset: scanner.offset,
      );
    }
  }
}

_RadResolution? _parseResolution(String line) {
  final match = RegExp(
    r'^([+-])([XY])\s+(\d+)\s+([+-])([XY])\s+(\d+)$',
  ).firstMatch(line);
  if (match == null) {
    return null;
  }
  final firstAxis = match.group(2)!;
  final secondAxis = match.group(5)!;
  if (firstAxis != 'Y' || secondAxis != 'X') {
    throw const UnsupportedCodecException(
      'Only Y-major Radiance HDR scanline order is supported.',
    );
  }
  final height = int.parse(match.group(3)!);
  final width = int.parse(match.group(6)!);
  if (width <= 0 || height <= 0) {
    throw const InvalidImageException('Invalid Radiance HDR dimensions.');
  }
  return _RadResolution(
    width: width,
    height: height,
    xLeftToRight: match.group(4)! == '+',
    yTopDown: match.group(1)! == '-',
  );
}

({Uint8List rgbe, int offset}) _readRgbeScanline(
  Uint8List bytes,
  int offset,
  int width,
) {
  if (width >= 8 &&
      width <= 0x7fff &&
      offset + 4 <= bytes.length &&
      bytes[offset] == 2 &&
      bytes[offset + 1] == 2 &&
      (bytes[offset + 2] & 0x80) == 0) {
    final scanlineWidth = (bytes[offset + 2] << 8) | bytes[offset + 3];
    if (scanlineWidth != width) {
      throw const InvalidImageException('Invalid Radiance HDR scanline width.');
    }
    return _readRleScanline(bytes, offset + 4, width);
  }
  final byteCount = width * 4;
  if (offset + byteCount > bytes.length) {
    throw const InvalidImageException('Truncated Radiance HDR raster.');
  }
  return (
    rgbe: Uint8List.fromList(bytes.sublist(offset, offset + byteCount)),
    offset: offset + byteCount,
  );
}

({Uint8List rgbe, int offset}) _readRleScanline(
  Uint8List bytes,
  int offset,
  int width,
) {
  final channels = List<Uint8List>.generate(4, (_) => Uint8List(width));
  var input = offset;
  for (var channel = 0; channel < 4; channel += 1) {
    var x = 0;
    while (x < width) {
      if (input >= bytes.length) {
        throw const InvalidImageException('Truncated Radiance HDR RLE data.');
      }
      final code = bytes[input];
      input += 1;
      if (code == 0) {
        throw const InvalidImageException('Invalid Radiance HDR RLE packet.');
      }
      if (code > 128) {
        final count = code - 128;
        if (input >= bytes.length || x + count > width) {
          throw const InvalidImageException('Invalid Radiance HDR RLE run.');
        }
        channels[channel].fillRange(x, x + count, bytes[input]);
        input += 1;
        x += count;
      } else {
        if (input + code > bytes.length || x + code > width) {
          throw const InvalidImageException(
            'Invalid Radiance HDR RLE literal.',
          );
        }
        channels[channel].setRange(x, x + code, bytes, input);
        input += code;
        x += code;
      }
    }
  }
  final rgbe = Uint8List(width * 4);
  for (var x = 0; x < width; x += 1) {
    final output = x * 4;
    rgbe[output] = channels[0][x];
    rgbe[output + 1] = channels[1][x];
    rgbe[output + 2] = channels[2][x];
    rgbe[output + 3] = channels[3][x];
  }
  return (rgbe: rgbe, offset: input);
}

void _writeRgbaFromRgbe(Uint8List rgbe, int input, Uint8List rgba, int output) {
  final exponent = rgbe[input + 3];
  if (exponent == 0) {
    rgba[output + 3] = 255;
    return;
  }
  final scale = pow(2.0, exponent - 136).toDouble();
  rgba[output] = (rgbe[input] * scale).round().clamp(0, 255);
  rgba[output + 1] = (rgbe[input + 1] * scale).round().clamp(0, 255);
  rgba[output + 2] = (rgbe[input + 2] * scale).round().clamp(0, 255);
  rgba[output + 3] = 255;
}

void _writeRgbeFromRgb(int red, int green, int blue, Uint8List output, int at) {
  final maxValue = max(red, max(green, blue));
  if (maxValue == 0) {
    output[at] = 0;
    output[at + 1] = 0;
    output[at + 2] = 0;
    output[at + 3] = 0;
    return;
  }
  final exponent = (log(maxValue) / ln2).floor() + 1;
  final scale = pow(2.0, exponent - 8).toDouble();
  output[at] = (red / scale).round().clamp(0, 255);
  output[at + 1] = (green / scale).round().clamp(0, 255);
  output[at + 2] = (blue / scale).round().clamp(0, 255);
  output[at + 3] = exponent + 128;
}

void _writeRgbeScanline(ByteWriter writer, Uint8List scanline, int width) {
  if (width < 8 || width > 0x7fff) {
    writer.writeBytes(scanline);
    return;
  }
  writer
    ..writeByte(2)
    ..writeByte(2)
    ..writeByte(width >> 8)
    ..writeByte(width);
  for (var channel = 0; channel < 4; channel += 1) {
    var x = 0;
    while (x < width) {
      final count = min(128, width - x);
      writer.writeByte(count);
      for (var i = 0; i < count; i += 1) {
        writer.writeByte(scanline[((x + i) * 4) + channel]);
      }
      x += count;
    }
  }
}

final class _RadLineScanner {
  _RadLineScanner(this.bytes);

  final Uint8List bytes;
  var offset = 0;

  String? nextLine() {
    if (offset >= bytes.length) {
      return null;
    }
    final start = offset;
    while (offset < bytes.length && bytes[offset] != 0x0a) {
      offset += 1;
    }
    var end = offset;
    if (end > start && bytes[end - 1] == 0x0d) {
      end -= 1;
    }
    if (offset < bytes.length) {
      offset += 1;
    }
    return ascii.decode(bytes.sublist(start, end));
  }
}

final class _RadHeader {
  const _RadHeader({
    required this.width,
    required this.height,
    required this.xLeftToRight,
    required this.yTopDown,
    required this.rasterOffset,
  });

  final int width;
  final int height;
  final bool xLeftToRight;
  final bool yTopDown;
  final int rasterOffset;
}

final class _RadResolution {
  const _RadResolution({
    required this.width,
    required this.height,
    required this.xLeftToRight,
    required this.yTopDown,
  });

  final int width;
  final int height;
  final bool xLeftToRight;
  final bool yTopDown;
}
