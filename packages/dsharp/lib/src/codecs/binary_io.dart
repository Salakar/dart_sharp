import 'dart:convert';
import 'dart:typed_data';

/// Growable byte writer for image container encoders.
final class ByteWriter {
  final List<int> _bytes = <int>[];

  /// Current byte offset.
  int get length => _bytes.length;

  /// Writes one byte.
  void writeByte(int value) => _bytes.add(value & 0xff);

  /// Writes bytes.
  void writeBytes(Iterable<int> values) {
    for (final value in values) {
      writeByte(value);
    }
  }

  /// Writes ASCII text.
  void writeAscii(String value) => writeBytes(ascii.encode(value));

  /// Writes a big-endian 16-bit integer.
  void writeUint16Be(int value) {
    writeByte(value >> 8);
    writeByte(value);
  }

  /// Writes a little-endian 16-bit integer.
  void writeUint16Le(int value) {
    writeByte(value);
    writeByte(value >> 8);
  }

  /// Writes a big-endian 32-bit integer.
  void writeUint32Be(int value) {
    writeByte(value >> 24);
    writeByte(value >> 16);
    writeByte(value >> 8);
    writeByte(value);
  }

  /// Writes a little-endian 32-bit integer.
  void writeUint32Le(int value) {
    writeByte(value);
    writeByte(value >> 8);
    writeByte(value >> 16);
    writeByte(value >> 24);
  }

  /// Returns the written bytes.
  Uint8List toBytes() => Uint8List.fromList(_bytes);
}

/// Reads a big-endian 16-bit integer.
int readUint16Be(Uint8List bytes, int offset) {
  return (bytes[offset] << 8) | bytes[offset + 1];
}

/// Reads a little-endian 16-bit integer.
int readUint16Le(Uint8List bytes, int offset) {
  return bytes[offset] | (bytes[offset + 1] << 8);
}

/// Reads a big-endian 32-bit integer.
int readUint32Be(Uint8List bytes, int offset) {
  return (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];
}

/// Reads a little-endian 32-bit integer.
int readUint32Le(Uint8List bytes, int offset) {
  return bytes[offset] |
      (bytes[offset + 1] << 8) |
      (bytes[offset + 2] << 16) |
      (bytes[offset + 3] << 24);
}

/// Returns a defensive byte slice.
Uint8List byteSlice(Uint8List bytes, int start, int end) {
  return Uint8List.fromList(bytes.sublist(start, end));
}

/// CRC-32 used by PNG chunks.
int crc32(Iterable<int> values) {
  var crc = 0xffffffff;
  for (final value in values) {
    crc ^= value & 0xff;
    for (var i = 0; i < 8; i += 1) {
      final mask = -(crc & 1);
      crc = (crc >> 1) ^ (0xedb88320 & mask);
    }
  }
  return (crc ^ 0xffffffff) & 0xffffffff;
}

/// Adler-32 used by zlib-wrapped deflate streams.
int adler32(Iterable<int> values) {
  const mod = 65521;
  var a = 1;
  var b = 0;
  for (final value in values) {
    a = (a + (value & 0xff)) % mod;
    b = (b + a) % mod;
  }
  return ((b << 16) | a) & 0xffffffff;
}
