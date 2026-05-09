import 'dart:typed_data';

import '../api/exceptions.dart';
import '../pixels/pixel_image.dart';
import '../source/raw_pixels.dart';
import 'binary_io.dart';
import 'codec_pixels.dart';

/// Encodes frames as lossless VP8L WebP images.
Uint8List encodeWebpLossless(PixelImage image) {
  _validateDimensions(image.firstFrame.pixels);
  if (image.isAnimated) {
    return _animatedWebpContainer(image);
  }
  return _webpContainer(_encodeVp8lPayload(image.firstFrame.pixels));
}

Uint8List _encodeVp8lPayload(RawPixels raw) {
  if (raw.width > 16384 || raw.height > 16384) {
    throw const OperationValidationException(
      'WebP dimensions must be at most 16384x16384.',
    );
  }
  final rgba = rawToRgba(raw);
  var hasAlpha = false;
  for (var i = 3; i < rgba.length; i += 4) {
    if (rgba[i] != 255) {
      hasAlpha = true;
      break;
    }
  }
  final bits = _Vp8lBitWriter()
    ..write(raw.width - 1, 14)
    ..write(raw.height - 1, 14)
    ..write(hasAlpha ? 1 : 0, 1)
    ..write(0, 3)
    ..write(0, 1)
    ..write(0, 1)
    ..write(0, 1);
  _writeBytePrefixCode(bits, 280);
  _writeBytePrefixCode(bits, 256);
  _writeBytePrefixCode(bits, 256);
  _writeBytePrefixCode(bits, 256);
  _writeSingleSymbolCode(bits, 0);
  for (var i = 0; i < rgba.length; i += 4) {
    bits
      ..write(_reverseBits(rgba[i + 1], 8), 8)
      ..write(_reverseBits(rgba[i], 8), 8)
      ..write(_reverseBits(rgba[i + 2], 8), 8)
      ..write(_reverseBits(rgba[i + 3], 8), 8);
  }
  return Uint8List.fromList(<int>[0x2f, ...bits.finish()]);
}

Uint8List _animatedWebpContainer(PixelImage image) {
  final width = image.width;
  final height = image.height;
  final content = ByteWriter()
    ..writeAscii('WEBP')
    ..writeAscii('VP8X')
    ..writeUint32Le(10)
    ..writeByte(_hasAnyAlpha(image) ? 0x12 : 0x02)
    ..writeByte(0)
    ..writeByte(0)
    ..writeByte(0);
  _writeUint24Le(content, width - 1);
  _writeUint24Le(content, height - 1);
  _writeChunk(content, 'ANIM', _animationPayload(image.loopCount ?? 0));
  for (final frame in image.frames) {
    _writeChunk(content, 'ANMF', _framePayload(frame));
  }
  final writer = ByteWriter()
    ..writeAscii('RIFF')
    ..writeUint32Le(content.length)
    ..writeBytes(content.toBytes());
  return writer.toBytes();
}

Uint8List _animationPayload(int loopCount) {
  if (loopCount < 0 || loopCount > 0xffff) {
    throw const OperationValidationException(
      'WebP loop count must be 0..65535.',
    );
  }
  final writer = ByteWriter()
    ..writeUint32Le(0)
    ..writeUint16Le(loopCount);
  return writer.toBytes();
}

Uint8List _framePayload(ImageFrame frame) {
  return encodeWebpLosslessAnimationFramePayload(
    frame.pixels,
    x: 0,
    y: 0,
    delay: frame.delay,
  );
}

/// Encodes a VP8L animation frame payload.
Uint8List encodeWebpLosslessAnimationFramePayload(
  RawPixels pixels, {
  required int x,
  required int y,
  required Duration? delay,
}) {
  _validateDimensions(pixels);
  final writer = ByteWriter();
  _writeUint24Le(writer, x ~/ 2);
  _writeUint24Le(writer, y ~/ 2);
  _writeUint24Le(writer, pixels.width - 1);
  _writeUint24Le(writer, pixels.height - 1);
  _writeUint24Le(writer, delay?.inMilliseconds ?? 0);
  writer.writeByte(0x02);
  _writeChunk(writer, 'VP8L', _encodeVp8lPayload(pixels));
  return writer.toBytes();
}

void _validateDimensions(RawPixels raw) {
  if (raw.width > 16384 || raw.height > 16384) {
    throw const OperationValidationException(
      'WebP dimensions must be at most 16384x16384.',
    );
  }
}

bool _hasAnyAlpha(PixelImage image) {
  for (final frame in image.frames) {
    if (_hasAlpha(frame.pixels)) {
      return true;
    }
  }
  return false;
}

bool _hasAlpha(RawPixels raw) {
  if (raw.channels == ChannelCount.two) {
    final bytes = raw.bytes;
    for (var i = 1; i < bytes.length; i += 2) {
      if (bytes[i] != 255) {
        return true;
      }
    }
    return false;
  }
  if (raw.channels != ChannelCount.four) {
    return false;
  }
  final bytes = raw.bytes;
  for (var i = 3; i < bytes.length; i += 4) {
    if (bytes[i] != 255) {
      return true;
    }
  }
  return false;
}

void _writeChunk(ByteWriter writer, String type, Uint8List payload) {
  writer
    ..writeAscii(type)
    ..writeUint32Le(payload.length)
    ..writeBytes(payload);
  if (payload.length.isOdd) {
    writer.writeByte(0);
  }
}

void _writeUint24Le(ByteWriter writer, int value) {
  if (value < 0 || value > 0xffffff) {
    throw const OperationValidationException(
      'WebP 24-bit fields must be 0..16777215.',
    );
  }
  writer
    ..writeByte(value)
    ..writeByte(value >> 8)
    ..writeByte(value >> 16);
}

void _writeBytePrefixCode(_Vp8lBitWriter bits, int alphabetSize) {
  bits.write(0, 1);
  _writeCodeLengthCode(bits);
  if (alphabetSize == 256) {
    bits.write(0, 1);
  } else {
    bits
      ..write(1, 1)
      ..write(3, 3)
      ..write(254, 8);
  }
  for (var i = 0; i < 256; i += 1) {
    bits.write(0, 1);
  }
}

void _writeCodeLengthCode(_Vp8lBitWriter bits) {
  const order = <int>[17, 18, 0, 1, 2, 3, 4, 5, 16, 6, 7, 8];
  bits.write(order.length - 4, 4);
  for (final symbol in order) {
    bits.write(symbol == 8 || symbol == 18 ? 1 : 0, 3);
  }
}

void _writeSingleSymbolCode(_Vp8lBitWriter bits, int symbol) {
  bits
    ..write(1, 1)
    ..write(0, 1);
  if (symbol < 2) {
    bits
      ..write(0, 1)
      ..write(symbol, 1);
  } else {
    bits
      ..write(1, 1)
      ..write(symbol, 8);
  }
}

Uint8List _webpContainer(Uint8List vp8l) {
  final writer = ByteWriter()
    ..writeAscii('RIFF')
    ..writeUint32Le(4 + 8 + vp8l.length + (vp8l.length.isOdd ? 1 : 0))
    ..writeAscii('WEBP')
    ..writeAscii('VP8L')
    ..writeUint32Le(vp8l.length)
    ..writeBytes(vp8l);
  if (vp8l.length.isOdd) {
    writer.writeByte(0);
  }
  return writer.toBytes();
}

final class _Vp8lBitWriter {
  final List<int> _bytes = <int>[];
  var _current = 0;
  var _bits = 0;

  void write(int value, int count) {
    for (var i = 0; i < count; i += 1) {
      _current |= ((value >> i) & 1) << _bits;
      _bits += 1;
      if (_bits == 8) {
        _bytes.add(_current);
        _current = 0;
        _bits = 0;
      }
    }
  }

  Uint8List finish() {
    if (_bits > 0) {
      _bytes.add(_current);
    }
    return Uint8List.fromList(_bytes);
  }
}

int _reverseBits(int value, int count) {
  var reversed = 0;
  for (var i = 0; i < count; i += 1) {
    reversed = (reversed << 1) | ((value >> i) & 1);
  }
  return reversed;
}
