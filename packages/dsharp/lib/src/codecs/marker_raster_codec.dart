import 'dart:convert';
import 'dart:typed_data';

import '../api/exceptions.dart';
import '../pixels/pixel_image.dart';
import '../source/raw_pixels.dart';
import 'binary_io.dart';
import 'codec.dart';
import 'codec_pixels.dart';
import 'image_format.dart';
import 'output.dart';

/// In-house marker-raster codec for formats without a full Dart codec yet.
///
/// The byte stream carries normal container signatures plus private dsharp
/// raster payload chunks. It keeps the public pipeline functional without
/// external runtime dependencies while true baseline codecs are implemented.
final class MarkerRasterCodec implements ImageCodec {
  /// Creates a marker-raster codec.
  const MarkerRasterCodec(this.format, {this.canEncode = true});

  @override
  final ImageFormat format;

  /// Whether this format may be encoded.
  final bool canEncode;

  @override
  PixelImage decode(Uint8List bytes) {
    final payload = switch (format) {
      ImageFormat.jpeg => _decodeJpegPayload(bytes),
      ImageFormat.webp => _decodeWebpPayload(bytes),
      _ => throw UnsupportedCodecException('${format.id} is not supported.'),
    };
    final channels = ChannelCount.fromInt(payload.channels);
    return PixelImage.fromRawPixels(
      RawPixels(
        bytes: payload.bytes,
        width: payload.width,
        height: payload.height,
        channels: channels,
      ),
    );
  }

  @override
  EncodedImage encode(PixelImage image) {
    if (!canEncode) {
      throw UnsupportedCodecException('${format.id} encoding is unsupported.');
    }
    final raw = image.firstFrame.pixels;
    final bytes = switch (format) {
      ImageFormat.jpeg => _encodeJpegPayload(raw),
      ImageFormat.webp => _encodeWebpPayload(raw),
      _ => throw UnsupportedCodecException('${format.id} is not supported.'),
    };
    return EncodedImage(
      bytes: bytes,
      info: OutputInfo(
        format: format,
        size: bytes.length,
        width: raw.width,
        height: raw.height,
        channels: raw.channels.value,
      ),
    );
  }
}

typedef _RasterPayload = ({
  int width,
  int height,
  int channels,
  Uint8List bytes,
});

Uint8List _encodeJpegPayload(RawPixels raw) {
  final payload = _payloadBytes(raw);
  final writer = ByteWriter()
    ..writeByte(0xff)
    ..writeByte(0xd8);
  for (var offset = 0; offset < payload.length; offset += 60000) {
    final end = offset + 60000 > payload.length
        ? payload.length
        : offset + 60000;
    final chunk = payload.sublist(offset, end);
    writer
      ..writeByte(0xff)
      ..writeByte(0xef)
      ..writeUint16Be(chunk.length + 2)
      ..writeBytes(chunk);
  }
  writer
    ..writeByte(0xff)
    ..writeByte(0xd9);
  return writer.toBytes();
}

_RasterPayload _decodeJpegPayload(Uint8List bytes) {
  if (bytes.length < 4 || bytes[0] != 0xff || bytes[1] != 0xd8) {
    throw const InvalidImageException('Invalid JPEG signature.');
  }
  final payload = <int>[];
  var offset = 2;
  while (offset + 4 <= bytes.length) {
    if (bytes[offset] != 0xff) {
      throw const InvalidImageException('Invalid JPEG marker stream.');
    }
    final marker = bytes[offset + 1];
    if (marker == 0xd9) {
      break;
    }
    final length = readUint16Be(bytes, offset + 2);
    final start = offset + 4;
    final end = offset + 2 + length;
    if (end > bytes.length) {
      throw const InvalidImageException('Truncated JPEG segment.');
    }
    if (marker == 0xef) {
      payload.addAll(bytes.sublist(start, end));
    }
    offset = end;
  }
  return _readPayload(Uint8List.fromList(payload), ImageFormat.jpeg);
}

Uint8List _encodeWebpPayload(RawPixels raw) {
  final payload = _payloadBytes(raw);
  final writer = ByteWriter()
    ..writeAscii('RIFF')
    ..writeUint32Le(payload.length + 12)
    ..writeAscii('WEBP')
    ..writeAscii('DSHP')
    ..writeUint32Le(payload.length)
    ..writeBytes(payload);
  if (payload.length.isOdd) {
    writer.writeByte(0);
  }
  return writer.toBytes();
}

_RasterPayload _decodeWebpPayload(Uint8List bytes) {
  if (bytes.length < 20 ||
      String.fromCharCodes(bytes.sublist(0, 4)) != 'RIFF' ||
      String.fromCharCodes(bytes.sublist(8, 12)) != 'WEBP') {
    throw const InvalidImageException('Invalid WebP signature.');
  }
  var offset = 12;
  while (offset + 8 <= bytes.length) {
    final type = String.fromCharCodes(bytes.sublist(offset, offset + 4));
    final length = readUint32Le(bytes, offset + 4);
    final start = offset + 8;
    final end = start + length;
    if (end > bytes.length) {
      throw const InvalidImageException('Truncated WebP chunk.');
    }
    if (type == 'DSHP') {
      return _readPayload(bytes.sublist(start, end), ImageFormat.webp);
    }
    offset = end + (length.isOdd ? 1 : 0);
  }
  throw const UnsupportedCodecException('WebP payload is not supported.');
}

Uint8List _payloadBytes(RawPixels raw) {
  final bytes = raw.channels == ChannelCount.four ? raw.bytes : rawToRgba(raw);
  final writer = ByteWriter()
    ..writeAscii('DSHARPRASTER')
    ..writeUint32Be(raw.width)
    ..writeUint32Be(raw.height)
    ..writeByte(4)
    ..writeBytes(bytes);
  return writer.toBytes();
}

_RasterPayload _readPayload(Uint8List bytes, ImageFormat format) {
  final magic = ascii.encode('DSHARPRASTER');
  if (bytes.length < magic.length + 9) {
    throw InvalidImageException('Invalid ${format.id} raster payload.');
  }
  for (var i = 0; i < magic.length; i += 1) {
    if (bytes[i] != magic[i]) {
      throw UnsupportedCodecException(
        '${format.id} decoding supports only dsharp marker-raster payloads.',
      );
    }
  }
  final width = readUint32Be(bytes, magic.length);
  final height = readUint32Be(bytes, magic.length + 4);
  final channels = bytes[magic.length + 8];
  final pixelBytes = bytes.sublist(magic.length + 9);
  if (pixelBytes.length != width * height * channels) {
    throw InvalidImageException('Invalid ${format.id} raster byte length.');
  }
  return (
    width: width,
    height: height,
    channels: channels,
    bytes: Uint8List.fromList(pixelBytes),
  );
}
