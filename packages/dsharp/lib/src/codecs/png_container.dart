part of 'png_codec.dart';

final class _PngContainer {
  const _PngContainer({
    required this.width,
    required this.height,
    required this.bitDepth,
    required this.colorType,
    required this.interlace,
    required this.idat,
    required this.palette,
    required this.transparency,
  });

  final int width;
  final int height;
  final int bitDepth;
  final int colorType;
  final int interlace;
  final List<int> idat;
  final Uint8List? palette;
  final Uint8List? transparency;
}

_PngContainer _readPngContainer(Uint8List bytes) {
  final idat = <int>[];
  var offset = 8;
  var width = 0;
  var height = 0;
  var bitDepth = 0;
  var colorType = 0;
  var interlace = 0;
  Uint8List? palette;
  Uint8List? transparency;
  var seenHeader = false;
  var seenImageData = false;
  var seenEnd = false;
  var seenNonImageDataAfterIdat = false;

  while (offset + 12 <= bytes.length) {
    final length = readUint32Be(bytes, offset);
    final type = _pngChunkType(bytes, offset + 4);
    final dataStart = offset + 8;
    final dataEnd = dataStart + length;
    if (dataEnd + 4 > bytes.length) {
      throw const InvalidImageException('Truncated PNG chunk.');
    }
    final data = bytes.sublist(dataStart, dataEnd);
    _verifyCrc(type, data, readUint32Be(bytes, dataEnd));
    switch (type) {
      case 'IHDR':
        if (offset != 8 || seenHeader || length != 13) {
          throw const InvalidImageException('Invalid PNG IHDR chunk.');
        }
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
        seenHeader = true;
      case 'PLTE':
        _requireHeaderBefore(type, seenHeader);
        if (seenImageData ||
            palette != null ||
            data.isEmpty ||
            data.length % 3 != 0 ||
            data.length > 768) {
          throw const InvalidImageException('Invalid PNG palette chunk.');
        }
        palette = data;
      case 'tRNS':
        _requireHeaderBefore(type, seenHeader);
        if (seenImageData || transparency != null) {
          throw const InvalidImageException('Invalid PNG transparency chunk.');
        }
        _validateTransparencyChunk(data, colorType, palette);
        transparency = data;
      case 'IDAT':
        _requireHeaderBefore(type, seenHeader);
        if (seenNonImageDataAfterIdat) {
          throw const InvalidImageException(
            'Invalid PNG image data chunk order.',
          );
        }
        if (colorType == 3 && palette == null) {
          throw const InvalidImageException(
            'PNG indexed colour requires PLTE.',
          );
        }
        idat.addAll(data);
        seenImageData = true;
      case 'IEND':
        _requireHeaderBefore(type, seenHeader);
        if (length != 0) {
          throw const InvalidImageException('Invalid PNG IEND chunk.');
        }
        seenEnd = true;
      default:
        _requireHeaderBefore(type, seenHeader);
        if (_isCriticalChunk(type)) {
          throw InvalidImageException('Unsupported PNG critical chunk $type.');
        }
        if (seenImageData) {
          seenNonImageDataAfterIdat = true;
        }
    }
    offset = dataEnd + 4;
    if (seenEnd) {
      break;
    }
  }
  if (!seenEnd) {
    throw const InvalidImageException('PNG missing IEND chunk.');
  }
  return _PngContainer(
    width: width,
    height: height,
    bitDepth: bitDepth,
    colorType: colorType,
    interlace: interlace,
    idat: idat,
    palette: palette,
    transparency: transparency,
  );
}

void _requireHeaderBefore(String type, bool seenHeader) {
  if (!seenHeader) {
    throw InvalidImageException('PNG $type chunk appeared before IHDR.');
  }
}

String _pngChunkType(Uint8List bytes, int offset) {
  for (var i = 0; i < 4; i += 1) {
    final byte = bytes[offset + i];
    final isLetter =
        byte >= 0x41 && byte <= 0x5a || byte >= 0x61 && byte <= 0x7a;
    if (!isLetter) {
      throw const InvalidImageException('Invalid PNG chunk type.');
    }
  }
  return ascii.decode(bytes.sublist(offset, offset + 4));
}

bool _isCriticalChunk(String type) {
  return type.codeUnitAt(0) >= 0x41 && type.codeUnitAt(0) <= 0x5a;
}

void _validateTransparencyChunk(
  Uint8List data,
  int colorType,
  Uint8List? palette,
) {
  if (colorType == 0 && data.length != 2) {
    throw const InvalidImageException('Invalid PNG transparency chunk.');
  }
  if (colorType == 2 && data.length != 6) {
    throw const InvalidImageException('Invalid PNG transparency chunk.');
  }
  if (colorType == 3 &&
      (palette == null || data.length > palette.length ~/ 3)) {
    throw const InvalidImageException('Invalid PNG transparency chunk.');
  }
  if (colorType == 4 || colorType == 6) {
    throw const InvalidImageException('Invalid PNG transparency chunk.');
  }
}

void _checkPngImageData(Uint8List bytes, int offset, int length) {
  if (offset + length > bytes.length) {
    throw const InvalidImageException('Truncated PNG image data.');
  }
}
