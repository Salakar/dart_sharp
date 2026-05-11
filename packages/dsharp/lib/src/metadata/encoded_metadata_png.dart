part of 'encoded_metadata.dart';

String _pngColorSpace(int colorType, int bitDepth) {
  return switch (colorType) {
    0 || 4 => bitDepth > 8 ? 'grey16' : 'b-w',
    2 || 6 => bitDepth > 8 ? 'rgb16' : 'srgb',
    _ => 'srgb',
  };
}

List<ImageMetadataComment> _pngTextComments(Uint8List bytes) {
  final comments = <ImageMetadataComment>[];
  var offset = 8;
  while (offset + 12 <= bytes.length) {
    final length = readUint32Be(bytes, offset);
    final type = String.fromCharCodes(bytes.sublist(offset + 4, offset + 8));
    final dataStart = offset + 8;
    final dataEnd = dataStart + length;
    if (dataEnd + 4 > bytes.length) {
      break;
    }
    final data = bytes.sublist(dataStart, dataEnd);
    if (type == 'tEXt' || type == 'zTXt' || type == 'iTXt') {
      final comment = _pngTextComment(type, data);
      if (comment != null) {
        comments.add(comment);
      }
    } else if (type == 'IEND') {
      break;
    }
    offset = dataEnd + 4;
  }
  return comments;
}

ImageMetadataComment? _pngTextComment(String type, Uint8List data) {
  if (data.length > const InputSafetyLimits().maxMetadataBytes) {
    throw const ImageLimitException('PNG text metadata is too large.');
  }
  final keywordEnd = _pngNull(data, 0);
  if (keywordEnd <= 0 || keywordEnd > 79) {
    return null;
  }
  final keyword = latin1.decode(data.sublist(0, keywordEnd));
  return switch (type) {
    'tEXt' => ImageMetadataComment(
      keyword: keyword,
      text: latin1.decode(data.sublist(keywordEnd + 1), allowInvalid: true),
    ),
    'zTXt' => _pngCompressedText(keyword, data, keywordEnd + 1),
    'iTXt' => _pngInternationalText(keyword, data, keywordEnd + 1),
    _ => null,
  };
}

ImageMetadataComment? _pngCompressedText(
  String keyword,
  Uint8List data,
  int offset,
) {
  if (offset >= data.length || data[offset] != 0) {
    return null;
  }
  try {
    final text = zlibDecode(data.sublist(offset + 1));
    return ImageMetadataComment(
      keyword: keyword,
      text: latin1.decode(text, allowInvalid: true),
    );
  } on ImageProcessingException {
    return null;
  }
}

ImageMetadataComment? _pngInternationalText(
  String keyword,
  Uint8List data,
  int offset,
) {
  if (_isPngXmpChunk(data) || offset + 2 > data.length) {
    return null;
  }
  final compressionFlag = data[offset];
  final compressionMethod = data[offset + 1];
  if (compressionFlag > 1 || compressionMethod != 0) {
    return null;
  }
  final languageEnd = _pngNull(data, offset + 2);
  if (languageEnd < 0) {
    return null;
  }
  final translatedEnd = _pngNull(data, languageEnd + 1);
  if (translatedEnd < 0) {
    return null;
  }
  var text = data.sublist(translatedEnd + 1);
  try {
    if (compressionFlag == 1) {
      text = zlibDecode(text);
    }
    return ImageMetadataComment(
      keyword: keyword,
      text: utf8.decode(text, allowMalformed: true),
    );
  } on ImageProcessingException {
    return null;
  }
}

int _pngNull(Uint8List data, int offset) {
  for (var i = offset; i < data.length; i += 1) {
    if (data[i] == 0) {
      return i;
    }
  }
  return -1;
}
