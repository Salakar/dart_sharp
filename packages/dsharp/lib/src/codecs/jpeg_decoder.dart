import 'dart:typed_data';

import '../api/exceptions.dart';
import '../source/raw_pixels.dart';
import 'binary_io.dart';
import 'jpeg_bit_io.dart';
import 'jpeg_models.dart';
import 'jpeg_tables.dart';
import 'jpeg_transform.dart';

part 'jpeg_lossless.dart';
part 'jpeg_progressive.dart';

/// Decodes supported JPEG bytes to RGBA pixels.
RawPixels decodeJpegBytes(Uint8List bytes) {
  final state = _parse(bytes);
  if (state.lossless) {
    _decodeLosslessScan(state);
  } else if (state.progressive) {
    _decodeProgressiveScans(state);
  } else {
    _decodeScan(state);
  }
  return RawPixels(
    bytes: _composeRgba(state),
    width: state.width,
    height: state.height,
    channels: ChannelCount.four,
  );
}

JpegState _parse(Uint8List bytes) {
  if (bytes.length < 4 || bytes[0] != 0xff || bytes[1] != 0xd8) {
    throw const InvalidImageException('Invalid JPEG signature.');
  }
  final state = JpegState();
  var offset = 2;
  while (offset < bytes.length) {
    while (offset < bytes.length && bytes[offset] == 0xff) {
      offset += 1;
    }
    if (offset >= bytes.length) {
      break;
    }
    final marker = bytes[offset++];
    if (marker == 0xd9) {
      break;
    }
    if (marker == 0xda) {
      if (offset + 2 > bytes.length) {
        throw const InvalidImageException('Truncated JPEG marker.');
      }
      final length = readUint16Be(bytes, offset);
      if (length < 2 || offset + length > bytes.length) {
        throw const InvalidImageException('Invalid JPEG marker length.');
      }
      final scan = _readSos(state, bytes.sublist(offset + 2, offset + length));
      final entropy = _entropySegments(bytes, offset + length);
      final parsedScan = JpegScan(
        components: scan.components,
        entropySegments: entropy.segments,
        spectralStart: scan.spectralStart,
        spectralEnd: scan.spectralEnd,
        successiveHigh: scan.successiveHigh,
        successiveLow: scan.successiveLow,
      );
      state
        ..scan = parsedScan
        ..scans.add(parsedScan);
      offset = entropy.endOffset;
      if (!state.progressive) {
        break;
      }
      continue;
    }
    if (offset + 2 > bytes.length) {
      throw const InvalidImageException('Truncated JPEG marker.');
    }
    final length = readUint16Be(bytes, offset);
    if (length < 2 || offset + length > bytes.length) {
      throw const InvalidImageException('Invalid JPEG marker length.');
    }
    final data = bytes.sublist(offset + 2, offset + length);
    if (marker == 0xdb) {
      _readDqt(state, data);
    } else if (marker == 0xc4) {
      _readDht(state, data);
    } else if (marker == 0xc0) {
      state.lossless = false;
      state.progressive = false;
      _readSof0(state, data);
    } else if (marker == 0xc2) {
      state.lossless = false;
      state.progressive = true;
      _readSof0(state, data);
    } else if (marker == 0xc3) {
      state.lossless = true;
      _readSof0(state, data);
    } else if (marker == 0xdd) {
      if (data.length != 2) {
        throw const InvalidImageException('Invalid JPEG restart interval.');
      }
      state.restartInterval = readUint16Be(data, 0);
    } else if (marker == 0xee) {
      _readApp14(state, data);
    } else if (marker >= 0xc1 && marker <= 0xcf) {
      throw const UnsupportedCodecException('Unsupported JPEG frame type.');
    }
    offset += length;
  }
  if (state.width <= 0 || state.scan == null) {
    throw const InvalidImageException('Incomplete JPEG image.');
  }
  return state;
}

void _readDqt(JpegState state, Uint8List data) {
  var offset = 0;
  while (offset < data.length) {
    final spec = data[offset++];
    final precision = spec >> 4;
    final id = spec & 0x0f;
    if (precision > 1 || id > 3) {
      throw const InvalidImageException('Invalid JPEG quantization table.');
    }
    final valueBytes = precision == 0 ? 64 : 128;
    if (offset + valueBytes > data.length) {
      throw const InvalidImageException('Truncated JPEG quantization table.');
    }
    final table = List<int>.filled(64, 0);
    for (var i = 0; i < 64; i += 1) {
      final value = precision == 0
          ? data[offset++]
          : readUint16Be(data, offset);
      if (precision != 0) {
        offset += 2;
      }
      table[jpegZigZag[i]] = value;
    }
    state.quant[id] = table;
  }
}

void _readDht(JpegState state, Uint8List data) {
  var offset = 0;
  while (offset < data.length) {
    final spec = data[offset++];
    final tableClass = spec >> 4;
    final id = spec & 0x0f;
    if (tableClass > 1 || id > 3) {
      throw const InvalidImageException('Invalid JPEG Huffman table.');
    }
    if (offset + 16 > data.length) {
      throw const InvalidImageException('Truncated JPEG Huffman table.');
    }
    final counts = data.sublist(offset, offset + 16);
    offset += 16;
    final total = counts.fold<int>(0, (int sum, int value) => sum + value);
    if (total == 0 || total > 256) {
      throw const InvalidImageException('Invalid JPEG Huffman table.');
    }
    if (offset + total > data.length) {
      throw const InvalidImageException('Truncated JPEG Huffman table.');
    }
    final symbols = data.sublist(offset, offset + total);
    offset += total;
    final tree = JpegHuffmanTree(counts, symbols);
    if (tableClass == 0) {
      state.dcTrees[id] = tree;
    } else {
      state.acTrees[id] = tree;
    }
  }
}

void _readSof0(JpegState state, Uint8List data) {
  if (data.length < 6) {
    throw const InvalidImageException('Truncated JPEG frame header.');
  }
  if (data[0] != 8) {
    throw const UnsupportedCodecException('Only 8-bit JPEG is supported.');
  }
  state.precision = data[0];
  state.height = readUint16Be(data, 1);
  state.width = readUint16Be(data, 3);
  final count = data[5];
  if (count != 1 && count != 3 && count != 4) {
    throw const UnsupportedCodecException('Unsupported JPEG component count.');
  }
  if (data.length < 6 + count * 3) {
    throw const InvalidImageException('Truncated JPEG frame components.');
  }
  var offset = 6;
  for (var i = 0; i < count; i += 1) {
    final id = data[offset++];
    final sampling = data[offset++];
    final h = sampling >> 4;
    final v = sampling & 0x0f;
    final quantId = data[offset++];
    if (h == 0 || v == 0 || quantId > 3) {
      throw const InvalidImageException('Invalid JPEG frame component.');
    }
    state.components.add(JpegComponent(id: id, h: h, v: v, quantId: quantId));
  }
}

void _readApp14(JpegState state, Uint8List data) {
  if (data.length < 12 ||
      data[0] != 0x41 ||
      data[1] != 0x64 ||
      data[2] != 0x6f ||
      data[3] != 0x62 ||
      data[4] != 0x65) {
    return;
  }
  state.adobeTransform = data[11];
}

JpegScan _readSos(JpegState state, Uint8List data) {
  if (data.length < 4) {
    throw const InvalidImageException('Truncated JPEG scan header.');
  }
  final count = data[0];
  if (count == 0 || data.length < 1 + count * 2 + 3) {
    throw const InvalidImageException('Truncated JPEG scan components.');
  }
  final components = <JpegComponent>[];
  var offset = 1;
  for (var i = 0; i < count; i += 1) {
    final id = data[offset++];
    final tables = data[offset++];
    final component = _componentById(state, id);
    if (component == null) {
      throw const InvalidImageException(
        'JPEG scan references unknown component.',
      );
    }
    if ((tables >> 4) > 3 || (tables & 0x0f) > 3) {
      throw const InvalidImageException('Invalid JPEG scan table selector.');
    }
    component
      ..dcTable = tables >> 4
      ..acTable = tables & 0x0f;
    components.add(component);
  }
  state.losslessPredictor = data[offset];
  state.pointTransform = data[offset + 2] & 0x0f;
  return JpegScan(
    components: components,
    entropySegments: const <Uint8List>[],
    spectralStart: data[offset],
    spectralEnd: data[offset + 1],
    successiveHigh: data[offset + 2] >> 4,
    successiveLow: data[offset + 2] & 0x0f,
  );
}

JpegComponent? _componentById(JpegState state, int id) {
  for (final component in state.components) {
    if (component.id == id) {
      return component;
    }
  }
  return null;
}

_EntropyScan _entropySegments(Uint8List bytes, int offset) {
  final segments = <Uint8List>[];
  var out = <int>[];
  var i = offset;
  while (i < bytes.length) {
    final value = bytes[i++];
    if (value == 0xff) {
      if (i >= bytes.length) {
        break;
      }
      var markerOffset = i - 1;
      var next = bytes[i++];
      while (next == 0xff && i < bytes.length) {
        markerOffset = i - 1;
        next = bytes[i++];
      }
      if (next == 0x00) {
        out.add(0xff);
      } else if (next >= 0xd0 && next <= 0xd7) {
        segments.add(Uint8List.fromList(out));
        out = <int>[];
      } else {
        if (out.isNotEmpty || segments.isEmpty) {
          segments.add(Uint8List.fromList(out));
        }
        return _EntropyScan(segments, markerOffset);
      }
    } else {
      out.add(value);
    }
  }
  if (out.isNotEmpty || segments.isEmpty) {
    segments.add(Uint8List.fromList(out));
  }
  return _EntropyScan(segments, i);
}

final class _EntropyScan {
  const _EntropyScan(this.segments, this.endOffset);

  final List<Uint8List> segments;
  final int endOffset;
}

void _decodeScan(JpegState state) {
  final maxH = state.components
      .map((item) => item.h)
      .reduce((a, b) => a > b ? a : b);
  final maxV = state.components
      .map((item) => item.v)
      .reduce((a, b) => a > b ? a : b);
  final mcuCols = (state.width + maxH * 8 - 1) ~/ (maxH * 8);
  final mcuRows = (state.height + maxV * 8 - 1) ~/ (maxV * 8);
  for (final component in state.components) {
    component
      ..width = (state.width * component.h + maxH - 1) ~/ maxH
      ..height = (state.height * component.v + maxV - 1) ~/ maxV
      ..samples = Uint8List(component.width * component.height);
  }
  final scan = state.scan!;
  var segmentIndex = 0;
  var reader = _scanReader(state, segmentIndex);
  var restartMcu = 0;
  for (var my = 0; my < mcuRows; my += 1) {
    for (var mx = 0; mx < mcuCols; mx += 1) {
      if (state.restartInterval > 0 && restartMcu == state.restartInterval) {
        _resetPredictors(state);
        segmentIndex += 1;
        reader = _scanReader(state, segmentIndex);
        restartMcu = 0;
      }
      for (final component in scan.components) {
        for (var vy = 0; vy < component.v; vy += 1) {
          for (var hx = 0; hx < component.h; hx += 1) {
            _decodeBlock(
              state,
              reader,
              component,
              mx * component.h + hx,
              my * component.v + vy,
            );
          }
        }
      }
      if (state.restartInterval > 0) {
        restartMcu += 1;
      }
    }
  }
}

JpegBitReader _scanReader(JpegState state, int segmentIndex) {
  final segments = state.scan!.entropySegments;
  if (state.restartInterval == 0) {
    return JpegBitReader(_concatSegments(segments));
  }
  if (segmentIndex >= segments.length) {
    throw const InvalidImageException('Missing JPEG restart segment.');
  }
  return JpegBitReader(segments[segmentIndex]);
}

Uint8List _concatSegments(List<Uint8List> segments) {
  if (segments.length == 1) {
    return segments.single;
  }
  final length = segments.fold<int>(0, (sum, item) => sum + item.length);
  final out = Uint8List(length);
  var offset = 0;
  for (final segment in segments) {
    out.setAll(offset, segment);
    offset += segment.length;
  }
  return out;
}

void _resetPredictors(JpegState state) {
  for (final component in state.components) {
    component.predictor = 0;
  }
}

void _decodeBlock(
  JpegState state,
  JpegBitReader reader,
  JpegComponent component,
  int blockX,
  int blockY,
) {
  final coeffs = List<int>.filled(64, 0);
  final quant = _requiredQuantTable(state, component);
  final dcTree = _requiredDcTree(state, component);
  final acTree = _requiredAcTree(state, component);
  final dcSize = dcTree.read(reader);
  component.predictor += jpegExtend(reader.readBits(dcSize), dcSize);
  coeffs[0] = component.predictor * quant[0];
  var k = 1;
  while (k < 64) {
    final symbol = acTree.read(reader);
    final run = symbol >> 4;
    final size = symbol & 0x0f;
    if (size == 0) {
      if (run == 15) {
        k += 16;
        continue;
      }
      break;
    }
    k += run;
    if (k < 64) {
      final index = jpegZigZag[k++];
      coeffs[index] = jpegExtend(reader.readBits(size), size) * quant[index];
    }
  }
  _writeSamples(component, blockX, blockY, jpegIdct(coeffs));
}

List<int> _requiredQuantTable(JpegState state, JpegComponent component) {
  final table = state.quant[component.quantId];
  if (table == null) {
    throw const InvalidImageException('JPEG missing quantization table.');
  }
  return table;
}

JpegHuffmanTree _requiredDcTree(JpegState state, JpegComponent component) {
  final tree = state.dcTrees[component.dcTable];
  if (tree == null) {
    throw const InvalidImageException('JPEG missing Huffman table.');
  }
  return tree;
}

JpegHuffmanTree _requiredAcTree(JpegState state, JpegComponent component) {
  final tree = state.acTrees[component.acTable];
  if (tree == null) {
    throw const InvalidImageException('JPEG missing Huffman table.');
  }
  return tree;
}

void _writeSamples(
  JpegComponent component,
  int blockX,
  int blockY,
  List<int> block,
) {
  for (var y = 0; y < 8; y += 1) {
    final targetY = blockY * 8 + y;
    if (targetY >= component.height) {
      continue;
    }
    for (var x = 0; x < 8; x += 1) {
      final targetX = blockX * 8 + x;
      if (targetX < component.width) {
        component.samples[targetY * component.width + targetX] =
            block[y * 8 + x];
      }
    }
  }
}

Uint8List _composeRgba(JpegState state) {
  if (state.lossless && state.components.length == 3) {
    return _composeRgbRgba(state);
  }
  if (state.components.length == 4) {
    if (state.adobeTransform != 2) {
      return _composeCmykRgba(state);
    }
    return _composeYcckRgba(state);
  }
  final rgba = Uint8List(state.width * state.height * 4);
  final y = state.components[0];
  final cb = state.components.length > 1 ? state.components[1] : null;
  final cr = state.components.length > 2 ? state.components[2] : null;
  for (var py = 0; py < state.height; py += 1) {
    for (var px = 0; px < state.width; px += 1) {
      final yy = _sample(y, px, py, state.width, state.height);
      final rgb = cb == null || cr == null
          ? (r: yy, g: yy, b: yy)
          : jpegYcbcrToRgb(
              yy,
              _sample(cb, px, py, state.width, state.height),
              _sample(cr, px, py, state.width, state.height),
            );
      final out = (py * state.width + px) * 4;
      rgba[out] = rgb.r;
      rgba[out + 1] = rgb.g;
      rgba[out + 2] = rgb.b;
      rgba[out + 3] = 255;
    }
  }
  return rgba;
}

Uint8List _composeRgbRgba(JpegState state) {
  final rgba = Uint8List(state.width * state.height * 4);
  final r = state.components[0].samples;
  final g = state.components[1].samples;
  final b = state.components[2].samples;
  for (var pixel = 0; pixel < state.width * state.height; pixel += 1) {
    final out = pixel * 4;
    rgba[out] = r[pixel];
    rgba[out + 1] = g[pixel];
    rgba[out + 2] = b[pixel];
    rgba[out + 3] = 255;
  }
  return rgba;
}

Uint8List _composeYcckRgba(JpegState state) {
  final rgba = Uint8List(state.width * state.height * 4);
  final y = state.components[0];
  final cb = state.components[1];
  final cr = state.components[2];
  final k = state.components[3];
  for (var py = 0; py < state.height; py += 1) {
    for (var px = 0; px < state.width; px += 1) {
      final cmy = jpegYcbcrToRgb(
        _sample(y, px, py, state.width, state.height),
        _sample(cb, px, py, state.width, state.height),
        _sample(cr, px, py, state.width, state.height),
      );
      final black = _sample(k, px, py, state.width, state.height);
      final out = (py * state.width + px) * 4;
      rgba[out] = _cmykChannel(cmy.r, black);
      rgba[out + 1] = _cmykChannel(cmy.g, black);
      rgba[out + 2] = _cmykChannel(cmy.b, black);
      rgba[out + 3] = 255;
    }
  }
  return rgba;
}

Uint8List _composeCmykRgba(JpegState state) {
  final rgba = Uint8List(state.width * state.height * 4);
  final c = state.components[0];
  final m = state.components[1];
  final y = state.components[2];
  final k = state.components[3];
  for (var py = 0; py < state.height; py += 1) {
    for (var px = 0; px < state.width; px += 1) {
      final black = _sample(k, px, py, state.width, state.height);
      final out = (py * state.width + px) * 4;
      rgba[out] = _cmykToRgbChannel(
        _sample(c, px, py, state.width, state.height),
        black,
      );
      rgba[out + 1] = _cmykToRgbChannel(
        _sample(m, px, py, state.width, state.height),
        black,
      );
      rgba[out + 2] = _cmykToRgbChannel(
        _sample(y, px, py, state.width, state.height),
        black,
      );
      rgba[out + 3] = 255;
    }
  }
  return rgba;
}

int _cmykChannel(int cmy, int black) {
  return ((255 - cmy) * black + 127) ~/ 255;
}

int _cmykToRgbChannel(int cmy, int black) {
  return ((255 - cmy) * (255 - black) + 127) ~/ 255;
}

int _sample(JpegComponent component, int x, int y, int width, int height) {
  final sx = x * component.width ~/ width;
  final sy = y * component.height ~/ height;
  return component.samples[sy * component.width + sx];
}
