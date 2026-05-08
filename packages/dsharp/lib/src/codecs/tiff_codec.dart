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

/// First-party baseline TIFF codec for uncompressed 8-bit chunky images.
final class TiffImageCodec implements ImageCodec {
  /// Creates a TIFF codec.
  const TiffImageCodec();

  @override
  ImageFormat get format => ImageFormat.tiff;

  @override
  PixelImage decode(Uint8List bytes) {
    final endian = _TiffEndian.fromHeader(bytes);
    if (endian == null) {
      throw const UnsupportedCodecException(
        'Only baseline TIFF byte orders are supported.',
      );
    }
    if (endian.readUint16(bytes, 2) != 42) {
      throw const InvalidImageException('Invalid TIFF header.');
    }
    final tags = _readIfd(bytes, endian.readUint32(bytes, 4), endian);
    final width = tags.value(256);
    final height = tags.value(257);
    final compression = tags.value(259);
    final photometric = tags.value(262);
    final stripOffset = tags.value(273);
    final samples = tags.value(277, fallback: 1);
    final byteCount = tags.value(279);
    final predictor = tags.value(317, fallback: 1);
    if (photometric == 3) {
      throw const UnsupportedCodecException(
        'Paletted TIFF decoding is not implemented yet.',
      );
    }
    final strip = bytes.sublist(stripOffset, stripOffset + byteCount);
    final source = switch (compression) {
      1 => strip,
      5 => _tiffLzwDecode(strip),
      8 || 32946 => zlibDecode(Uint8List.fromList(strip)),
      _ => throw const UnsupportedCodecException(
        'Only uncompressed, LZW, and deflate TIFF are supported.',
      ),
    };
    if (predictor == 2) {
      _undoHorizontalPredictor(source, width, height, samples);
    } else if (predictor != 1) {
      throw const UnsupportedCodecException(
        'Only TIFF predictors 1 and 2 are supported.',
      );
    }
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
    if (tiffOptions.compression == TiffCompression.jpeg) {
      throw const UnsupportedCodecException(
        'TIFF JPEG compression is not implemented yet.',
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
    final encodedPixels = switch (tiffOptions.compression) {
      TiffCompression.none => pixels,
      TiffCompression.lzw => _tiffLzwEncode(pixels),
      TiffCompression.deflate => zlibEncodeFixed(pixels),
      TiffCompression.jpeg => throw StateError('unreachable'),
    };
    final compressionTag = switch (tiffOptions.compression) {
      TiffCompression.none => 1,
      TiffCompression.lzw => 5,
      TiffCompression.deflate => 8,
      TiffCompression.jpeg => throw StateError('unreachable'),
    };
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
    _entry(writer, 259, 3, 1, compressionTag);
    _entry(writer, 262, 3, 1, 2);
    _entry(writer, 273, 4, 1, pixelOffset);
    _entry(writer, 277, 3, 1, channels);
    _entry(writer, 278, 4, 1, raw.height);
    _entry(writer, 279, 4, 1, encodedPixels.length);
    _entry(writer, 284, 3, 1, 1);
    writer.writeUint32Le(0);
    for (var i = 0; i < channels; i += 1) {
      writer.writeUint16Le(8);
    }
    if (channels == 4) {
      writer.writeUint16Le(2);
    }
    writer.writeBytes(encodedPixels);
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

_Ifd _readIfd(Uint8List bytes, int offset, _TiffEndian endian) {
  final count = endian.readUint16(bytes, offset);
  final tags = <int, int>{};
  for (var i = 0; i < count; i += 1) {
    final entry = offset + 2 + i * 12;
    final tag = endian.readUint16(bytes, entry);
    final type = endian.readUint16(bytes, entry + 2);
    final itemCount = endian.readUint32(bytes, entry + 4);
    final rawValue = endian.readUint32(bytes, entry + 8);
    if (itemCount == 1) {
      tags[tag] = type == 3 ? endian.readUint16(bytes, entry + 8) : rawValue;
    } else {
      tags[tag] = rawValue;
    }
  }
  return _Ifd(tags);
}

final class _TiffEndian {
  const _TiffEndian._({required this.isBigEndian});

  final bool isBigEndian;

  static _TiffEndian? fromHeader(Uint8List bytes) {
    if (bytes.length < 8) {
      return null;
    }
    if (bytes[0] == 0x49 && bytes[1] == 0x49) {
      return const _TiffEndian._(isBigEndian: false);
    }
    if (bytes[0] == 0x4d && bytes[1] == 0x4d) {
      return const _TiffEndian._(isBigEndian: true);
    }
    return null;
  }

  int readUint16(Uint8List bytes, int offset) {
    return isBigEndian
        ? readUint16Be(bytes, offset)
        : readUint16Le(bytes, offset);
  }

  int readUint32(Uint8List bytes, int offset) {
    return isBigEndian
        ? readUint32Be(bytes, offset)
        : readUint32Le(bytes, offset);
  }
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

Uint8List _tiffLzwDecode(Uint8List bytes) {
  final reader = _MsbBitReader(bytes);
  final out = <int>[];
  final table = _lzwInitialTable();
  var nextCode = 258;
  var codeWidth = 9;
  List<int>? previous;
  while (true) {
    final code = reader.read(codeWidth);
    if (code == null) {
      break;
    }
    if (code == 256) {
      table.setAll(0, _lzwInitialTable());
      nextCode = 258;
      codeWidth = 9;
      previous = null;
      continue;
    }
    if (code == 257) {
      break;
    }
    final entry = code < nextCode && table[code] != null
        ? table[code]!
        : code == nextCode && previous != null
        ? <int>[...previous, previous.first]
        : throw const InvalidImageException('Invalid TIFF LZW code.');
    out.addAll(entry);
    if (previous != null && nextCode < 4096) {
      table[nextCode++] = <int>[...previous, entry.first];
      if (nextCode == (1 << codeWidth) && codeWidth < 12) {
        codeWidth += 1;
      }
    }
    previous = entry;
  }
  return Uint8List.fromList(out);
}

Uint8List _tiffLzwEncode(List<int> bytes) {
  final writer = _MsbBitWriter()..write(256, 9);
  final dictionary = <String, int>{
    for (var i = 0; i < 256; i += 1) String.fromCharCode(i): i,
  };
  var nextCode = 258;
  var codeWidth = 9;
  var current = '';
  for (final byte in bytes) {
    final char = String.fromCharCode(byte);
    final candidate = current + char;
    if (dictionary.containsKey(candidate)) {
      current = candidate;
      continue;
    }
    writer.write(dictionary[current]!, codeWidth);
    if (nextCode < 4096) {
      dictionary[candidate] = nextCode++;
      if (nextCode == (1 << codeWidth) && codeWidth < 12) {
        codeWidth += 1;
      }
    }
    current = char;
  }
  if (current.isNotEmpty) {
    writer.write(dictionary[current]!, codeWidth);
  }
  writer.write(257, codeWidth);
  return writer.finish();
}

List<List<int>?> _lzwInitialTable() {
  return <List<int>?>[
    for (var i = 0; i < 256; i += 1) <int>[i],
    null,
    null,
    for (var i = 258; i < 4096; i += 1) null,
  ];
}

void _undoHorizontalPredictor(
  Uint8List bytes,
  int width,
  int height,
  int samples,
) {
  final rowBytes = width * samples;
  for (var y = 0; y < height; y += 1) {
    final row = y * rowBytes;
    for (var x = samples; x < rowBytes; x += 1) {
      bytes[row + x] = (bytes[row + x] + bytes[row + x - samples]) & 0xff;
    }
  }
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

final class _MsbBitReader {
  _MsbBitReader(this.bytes);

  final Uint8List bytes;
  var _offset = 0;
  var _buffer = 0;
  var _bits = 0;

  int? read(int count) {
    while (_bits < count) {
      if (_offset >= bytes.length) {
        return null;
      }
      _buffer = (_buffer << 8) | bytes[_offset++];
      _bits += 8;
    }
    _bits -= count;
    final value = (_buffer >> _bits) & ((1 << count) - 1);
    _buffer &= _bits == 0 ? 0 : (1 << _bits) - 1;
    return value;
  }
}

final class _MsbBitWriter {
  final _bytes = <int>[];
  var _buffer = 0;
  var _bits = 0;

  void write(int value, int count) {
    for (var bit = count - 1; bit >= 0; bit -= 1) {
      _buffer = (_buffer << 1) | ((value >> bit) & 1);
      _bits += 1;
      if (_bits == 8) {
        _bytes.add(_buffer);
        _buffer = 0;
        _bits = 0;
      }
    }
  }

  Uint8List finish() {
    if (_bits > 0) {
      _bytes.add(_buffer << (8 - _bits));
    }
    return Uint8List.fromList(_bytes);
  }
}
