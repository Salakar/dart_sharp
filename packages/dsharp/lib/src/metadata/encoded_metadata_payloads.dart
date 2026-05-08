import 'dart:convert';
import 'dart:typed_data';

import '../api/exceptions.dart';
import '../codecs/binary_io.dart';
import '../codecs/deflate_codec.dart';
import '../codecs/image_format.dart';
import 'xmp_metadata.dart';

/// Encoded metadata payloads parsed from image containers.
final class EncodedMetadataPayloads {
  /// Creates encoded metadata payloads.
  const EncodedMetadataPayloads({this.iccProfile, this.exif, this.xmp});

  /// Embedded ICC profile bytes.
  final Uint8List? iccProfile;

  /// Embedded EXIF bytes.
  final Uint8List? exif;

  /// Embedded XMP metadata.
  final XmpMetadata? xmp;
}

/// Reads metadata payloads without decoding pixels.
EncodedMetadataPayloads readEncodedMetadataPayloads(
  Uint8List bytes,
  ImageFormat format,
) {
  return switch (format) {
    ImageFormat.png => _pngPayloads(bytes),
    ImageFormat.jpeg => _jpegPayloads(bytes),
    ImageFormat.webp => _webpPayloads(bytes),
    _ => const EncodedMetadataPayloads(),
  };
}

EncodedMetadataPayloads _pngPayloads(Uint8List bytes) {
  if (bytes.length < 33) {
    return const EncodedMetadataPayloads();
  }
  Uint8List? icc;
  Uint8List? exif;
  XmpMetadata? xmp;
  var offset = 8;
  while (offset + 12 <= bytes.length) {
    final length = readUint32Be(bytes, offset);
    final type = ascii.decode(bytes.sublist(offset + 4, offset + 8));
    final dataStart = offset + 8;
    final dataEnd = dataStart + length;
    if (dataEnd + 4 > bytes.length) {
      return EncodedMetadataPayloads(iccProfile: icc, exif: exif, xmp: xmp);
    }
    final data = bytes.sublist(dataStart, dataEnd);
    if (type == 'iCCP') {
      icc ??= _pngIccProfile(data);
    } else if (type == 'eXIf') {
      exif ??= data;
    } else if (type == 'iTXt') {
      xmp ??= _pngXmp(data);
    } else if (type == 'IEND') {
      break;
    }
    offset = dataEnd + 4;
  }
  return EncodedMetadataPayloads(iccProfile: icc, exif: exif, xmp: xmp);
}

Uint8List? _pngIccProfile(Uint8List data) {
  final methodOffset = _skipNullTerminated(data, 0);
  if (methodOffset < 0 ||
      methodOffset >= data.length ||
      data[methodOffset] != 0) {
    return null;
  }
  try {
    return zlibDecode(data.sublist(methodOffset + 1));
  } on ImageProcessingException {
    return null;
  }
}

XmpMetadata? _pngXmp(Uint8List data) {
  final textOffset = _pngXmpTextOffset(data);
  if (textOffset == null) {
    return null;
  }
  try {
    return XmpMetadata(utf8.decode(data.sublist(textOffset)));
  } on FormatException {
    return null;
  }
}

int? _pngXmpTextOffset(Uint8List data) {
  const keyword = 'XML:com.adobe.xmp';
  if (data.length <= keyword.length || data[keyword.length] != 0) {
    return null;
  }
  for (var i = 0; i < keyword.length; i += 1) {
    if (data[i] != keyword.codeUnitAt(i)) {
      return null;
    }
  }
  var offset = keyword.length + 1;
  if (offset + 2 > data.length || data[offset] != 0 || data[offset + 1] != 0) {
    return null;
  }
  offset = _skipNullTerminated(data, offset + 2);
  if (offset < 0) {
    return null;
  }
  offset = _skipNullTerminated(data, offset);
  return offset < 0 ? null : offset;
}

EncodedMetadataPayloads _jpegPayloads(Uint8List bytes) {
  if (bytes.length < 4 || bytes[0] != 0xff || bytes[1] != 0xd8) {
    return const EncodedMetadataPayloads();
  }
  Uint8List? exif;
  XmpMetadata? xmp;
  final iccChunks = <int, Uint8List>{};
  int? iccCount;
  var offset = 2;
  while (offset < bytes.length) {
    if (bytes[offset] != 0xff) {
      break;
    }
    while (offset < bytes.length && bytes[offset] == 0xff) {
      offset += 1;
    }
    if (offset >= bytes.length) {
      break;
    }
    final marker = bytes[offset];
    offset += 1;
    if (marker == 0xda || marker == 0xd9) {
      break;
    }
    if (marker == 0x01 || marker >= 0xd0 && marker <= 0xd7) {
      continue;
    }
    if (offset + 2 > bytes.length) {
      break;
    }
    final length = readUint16Be(bytes, offset);
    final segmentEnd = offset + length;
    if (length < 2 || segmentEnd > bytes.length) {
      break;
    }
    final data = bytes.sublist(offset + 2, segmentEnd);
    if (marker == 0xe1 && _startsWithAscii(data, 'Exif')) {
      exif ??= data;
    } else if (marker == 0xe1 &&
        _startsWithAscii(data, 'http://ns.adobe.com/xap/1.0/') &&
        data.length > 29 &&
        data[28] == 0) {
      try {
        xmp ??= XmpMetadata(utf8.decode(data.sublist(29)));
      } on FormatException {
        // Ignore malformed XMP payloads.
      }
    } else if (marker == 0xe2 && _isJpegIccData(data)) {
      final sequence = data[12];
      final count = data[13];
      if (sequence > 0 &&
          sequence <= count &&
          !iccChunks.containsKey(sequence) &&
          (iccCount == null || iccCount == count)) {
        iccCount = count;
        iccChunks[sequence] = data.sublist(14);
      }
    }
    offset = segmentEnd;
  }
  return EncodedMetadataPayloads(
    iccProfile: _joinJpegIcc(iccChunks, iccCount),
    exif: exif,
    xmp: xmp,
  );
}

EncodedMetadataPayloads _webpPayloads(Uint8List bytes) {
  if (bytes.length < 12) {
    return const EncodedMetadataPayloads();
  }
  final riffEnd = 8 + readUint32Le(bytes, 4);
  Uint8List? icc;
  Uint8List? exif;
  XmpMetadata? xmp;
  var offset = 12;
  while (offset + 8 <= riffEnd && offset + 8 <= bytes.length) {
    final type = ascii.decode(bytes.sublist(offset, offset + 4));
    final length = readUint32Le(bytes, offset + 4);
    final start = offset + 8;
    final end = start + length;
    if (end > riffEnd || end > bytes.length) {
      break;
    }
    final data = bytes.sublist(start, end);
    if (type == 'ICCP') {
      icc ??= data;
    } else if (type == 'EXIF') {
      exif ??= data;
    } else if (type == 'XMP ') {
      try {
        xmp ??= XmpMetadata(utf8.decode(data));
      } on FormatException {
        // Ignore malformed XMP payloads.
      }
    }
    offset = end + (length.isOdd ? 1 : 0);
  }
  return EncodedMetadataPayloads(iccProfile: icc, exif: exif, xmp: xmp);
}

Uint8List? _joinJpegIcc(Map<int, Uint8List> chunks, int? count) {
  if (count == null || count == 0 || chunks.length != count) {
    return null;
  }
  final writer = ByteWriter();
  for (var i = 1; i <= count; i += 1) {
    final chunk = chunks[i];
    if (chunk == null) {
      return null;
    }
    writer.writeBytes(chunk);
  }
  return writer.toBytes();
}

bool _isJpegIccData(Uint8List data) {
  const header = 'ICC_PROFILE';
  if (data.length < header.length + 3 || data[header.length] != 0) {
    return false;
  }
  for (var i = 0; i < header.length; i += 1) {
    if (data[i] != header.codeUnitAt(i)) {
      return false;
    }
  }
  return true;
}

int _skipNullTerminated(Uint8List data, int offset) {
  while (offset < data.length && data[offset] != 0) {
    offset += 1;
  }
  return offset >= data.length ? -1 : offset + 1;
}

bool _startsWithAscii(Uint8List bytes, String text) {
  if (bytes.length < text.length) {
    return false;
  }
  for (var i = 0; i < text.length; i += 1) {
    if (bytes[i] != text.codeUnitAt(i)) {
      return false;
    }
  }
  return true;
}
