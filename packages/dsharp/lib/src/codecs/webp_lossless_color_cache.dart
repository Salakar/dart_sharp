part of 'webp_lossless.dart';

final class _ColorCache {
  _ColorCache._(this._bits, this._entries);

  factory _ColorCache.read(_BitReader reader) {
    if (reader.readBits(1) == 0) {
      return _ColorCache._(0, Uint32List(0));
    }
    final bits = reader.readBits(4);
    if (bits < 1 || bits > 11) {
      throw const InvalidImageException('Invalid VP8L color cache size.');
    }
    return _ColorCache._(bits, Uint32List(1 << bits));
  }

  final int _bits;
  final Uint32List _entries;

  int get size => _entries.length;

  int operator [](int index) {
    if (index < 0 || index >= _entries.length) {
      throw const InvalidImageException('Invalid VP8L color cache index.');
    }
    return _entries[index];
  }

  void insert(int argb) {
    if (_entries.isEmpty) {
      return;
    }
    _entries[_cacheIndex(argb, _bits)] = argb & 0xffffffff;
  }
}

int _cacheIndex(int argb, int bits) {
  return ((0x1e35a7bd * (argb & 0xffffffff)) & 0xffffffff) >> (32 - bits);
}

int _argb(int alpha, int red, int green, int blue) {
  return ((alpha & 0xff) << 24) |
      ((red & 0xff) << 16) |
      ((green & 0xff) << 8) |
      (blue & 0xff);
}

int _argbFromRgba(Uint8List bytes, int pixel) {
  final offset = pixel * 4;
  return _argb(
    bytes[offset + 3],
    bytes[offset],
    bytes[offset + 1],
    bytes[offset + 2],
  );
}

void _writeArgbToRgba(Uint8List bytes, int pixel, int argb) {
  final offset = pixel * 4;
  bytes[offset] = (argb >> 16) & 0xff;
  bytes[offset + 1] = (argb >> 8) & 0xff;
  bytes[offset + 2] = argb & 0xff;
  bytes[offset + 3] = (argb >> 24) & 0xff;
}
