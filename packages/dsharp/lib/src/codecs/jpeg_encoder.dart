import 'dart:convert';
import 'dart:typed_data';

import '../source/raw_pixels.dart';
import 'binary_io.dart';
import 'codec_pixels.dart';
import 'jpeg_bit_io.dart';
import 'jpeg_tables.dart';
import 'jpeg_transform.dart';

/// Encodes pixels as baseline sequential JPEG bytes.
Uint8List encodeJpegBytes(
  RawPixels raw, {
  int quality = 80,
  String chromaSubsampling = '4:2:0',
}) {
  final rgb = rawToRgb(raw);
  final lumaQuant = jpegScaledQuantTable(jpegStandardLumaQuant, quality);
  final chromaQuant = jpegScaledQuantTable(jpegStandardChromaQuant, quality);
  final writer = ByteWriter()
    ..writeByte(0xff)
    ..writeByte(0xd8);
  _segment(writer, 0xe0, _jfif());
  _segment(writer, 0xdb, _dqt(0, lumaQuant));
  _segment(writer, 0xdb, _dqt(1, chromaQuant));
  _segment(writer, 0xc0, _sof(raw.width, raw.height, chromaSubsampling));
  _segment(writer, 0xc4, _dht(0, 0));
  _segment(writer, 0xc4, _dht(1, 0));
  _segment(writer, 0xda, _sos());
  writer.writeBytes(
    _entropy(
      rgb,
      raw.width,
      raw.height,
      lumaQuant,
      chromaQuant,
      chromaSubsampling,
    ),
  );
  writer
    ..writeByte(0xff)
    ..writeByte(0xd9);
  return writer.toBytes();
}

Uint8List _entropy(
  Uint8List rgb,
  int width,
  int height,
  List<int> lumaQuant,
  List<int> chromaQuant,
  String chromaSubsampling,
) {
  if (chromaSubsampling == '4:2:0') {
    return _entropy420(rgb, width, height, lumaQuant, chromaQuant);
  }
  return _entropy444(rgb, width, height, lumaQuant, chromaQuant);
}

Uint8List _entropy444(
  Uint8List rgb,
  int width,
  int height,
  List<int> lumaQuant,
  List<int> chromaQuant,
) {
  final bits = JpegBitWriter();
  final predictors = List<int>.filled(3, 0);
  final blocksX = (width + 7) ~/ 8;
  final blocksY = (height + 7) ~/ 8;
  for (var by = 0; by < blocksY; by += 1) {
    for (var bx = 0; bx < blocksX; bx += 1) {
      final planes = _blockPlanes(rgb, width, height, bx, by);
      predictors[0] = _writeBlock(
        bits,
        jpegFdct(planes[0], lumaQuant),
        predictors[0],
      );
      predictors[1] = _writeBlock(
        bits,
        jpegFdct(planes[1], chromaQuant),
        predictors[1],
      );
      predictors[2] = _writeBlock(
        bits,
        jpegFdct(planes[2], chromaQuant),
        predictors[2],
      );
    }
  }
  return bits.finish();
}

Uint8List _entropy420(
  Uint8List rgb,
  int width,
  int height,
  List<int> lumaQuant,
  List<int> chromaQuant,
) {
  final bits = JpegBitWriter();
  final predictors = List<int>.filled(3, 0);
  final mcuCols = (width + 15) ~/ 16;
  final mcuRows = (height + 15) ~/ 16;
  for (var my = 0; my < mcuRows; my += 1) {
    for (var mx = 0; mx < mcuCols; mx += 1) {
      for (var vy = 0; vy < 2; vy += 1) {
        for (var hx = 0; hx < 2; hx += 1) {
          predictors[0] = _writeBlock(
            bits,
            jpegFdct(
              _lumaBlock(rgb, width, height, mx * 2 + hx, my * 2 + vy),
              lumaQuant,
            ),
            predictors[0],
          );
        }
      }
      final chroma = _chroma420Block(rgb, width, height, mx, my);
      predictors[1] = _writeBlock(
        bits,
        jpegFdct(chroma[0], chromaQuant),
        predictors[1],
      );
      predictors[2] = _writeBlock(
        bits,
        jpegFdct(chroma[1], chromaQuant),
        predictors[2],
      );
    }
  }
  return bits.finish();
}

List<List<int>> _blockPlanes(
  Uint8List rgb,
  int width,
  int height,
  int bx,
  int by,
) {
  final y = List<int>.filled(64, 0);
  final cb = List<int>.filled(64, 0);
  final cr = List<int>.filled(64, 0);
  for (var yy = 0; yy < 8; yy += 1) {
    final py = _clampIndex(by * 8 + yy, height - 1);
    for (var xx = 0; xx < 8; xx += 1) {
      final px = _clampIndex(bx * 8 + xx, width - 1);
      final color = _ycbcrAt(rgb, width, px, py);
      final index = yy * 8 + xx;
      y[index] = color.y;
      cb[index] = color.cb;
      cr[index] = color.cr;
    }
  }
  return <List<int>>[y, cb, cr];
}

List<int> _lumaBlock(Uint8List rgb, int width, int height, int bx, int by) {
  final y = List<int>.filled(64, 0);
  for (var yy = 0; yy < 8; yy += 1) {
    final py = _clampIndex(by * 8 + yy, height - 1);
    for (var xx = 0; xx < 8; xx += 1) {
      final px = _clampIndex(bx * 8 + xx, width - 1);
      y[yy * 8 + xx] = _ycbcrAt(rgb, width, px, py).y;
    }
  }
  return y;
}

List<List<int>> _chroma420Block(
  Uint8List rgb,
  int width,
  int height,
  int mx,
  int my,
) {
  final cb = List<int>.filled(64, 0);
  final cr = List<int>.filled(64, 0);
  for (var yy = 0; yy < 8; yy += 1) {
    for (var xx = 0; xx < 8; xx += 1) {
      var cbSum = 0;
      var crSum = 0;
      for (var dy = 0; dy < 2; dy += 1) {
        final py = _clampIndex(my * 16 + yy * 2 + dy, height - 1);
        for (var dx = 0; dx < 2; dx += 1) {
          final px = _clampIndex(mx * 16 + xx * 2 + dx, width - 1);
          final color = _ycbcrAt(rgb, width, px, py);
          cbSum += color.cb;
          crSum += color.cr;
        }
      }
      final index = yy * 8 + xx;
      cb[index] = (cbSum + 2) >> 2;
      cr[index] = (crSum + 2) >> 2;
    }
  }
  return <List<int>>[cb, cr];
}

({int y, int cb, int cr}) _ycbcrAt(Uint8List rgb, int width, int x, int y) {
  final source = (y * width + x) * 3;
  return jpegRgbToYcbcr(rgb[source], rgb[source + 1], rgb[source + 2]);
}

int _clampIndex(int value, int max) {
  if (value < 0) {
    return 0;
  }
  return value > max ? max : value;
}

int _writeBlock(JpegBitWriter bits, List<int> coeffs, int previousDc) {
  final dc = coeffs[0];
  _writeValue(bits, dc - previousDc, 0);
  var run = 0;
  for (var k = 1; k < 64; k += 1) {
    final value = coeffs[jpegZigZag[k]];
    if (value == 0) {
      run += 1;
      continue;
    }
    while (run > 15) {
      bits.writeSymbol(0xf0);
      run -= 16;
    }
    _writeValue(bits, value, run);
    run = 0;
  }
  if (run > 0) {
    bits.writeSymbol(0);
  }
  return dc;
}

void _writeValue(JpegBitWriter bits, int value, int run) {
  final size = jpegCategory(value);
  bits.writeSymbol((run << 4) | size);
  if (size > 0) {
    bits.writeBits(jpegAdditionalBits(value, size), size);
  }
}

Uint8List _jfif() {
  return Uint8List.fromList(<int>[
    ...ascii.encode('JFIF'),
    0,
    1,
    1,
    0,
    0,
    1,
    0,
    1,
    0,
    0,
  ]);
}

Uint8List _dqt(int id, List<int> table) {
  final writer = ByteWriter()..writeByte(id);
  for (final index in jpegZigZag) {
    writer.writeByte(table[index]);
  }
  return writer.toBytes();
}

Uint8List _sof(int width, int height, String chromaSubsampling) {
  final ySampling = chromaSubsampling == '4:2:0' ? 0x22 : 0x11;
  return (ByteWriter()
        ..writeByte(8)
        ..writeUint16Be(height)
        ..writeUint16Be(width)
        ..writeByte(3)
        ..writeByte(1)
        ..writeByte(ySampling)
        ..writeByte(0)
        ..writeByte(2)
        ..writeByte(0x11)
        ..writeByte(1)
        ..writeByte(3)
        ..writeByte(0x11)
        ..writeByte(1))
      .toBytes();
}

Uint8List _dht(int tableClass, int id) {
  final writer = ByteWriter()
    ..writeByte((tableClass << 4) | id)
    ..writeBytes(<int>[0, 0, 0, 0, 0, 0, 0, 255, 0, 0, 0, 0, 0, 0, 0, 0])
    ..writeBytes(List<int>.generate(255, (int index) => index));
  return writer.toBytes();
}

Uint8List _sos() {
  return Uint8List.fromList(<int>[3, 1, 0x00, 2, 0x00, 3, 0x00, 0, 63, 0]);
}

void _segment(ByteWriter writer, int marker, Uint8List data) {
  writer
    ..writeByte(0xff)
    ..writeByte(marker)
    ..writeUint16Be(data.length + 2)
    ..writeBytes(data);
}
