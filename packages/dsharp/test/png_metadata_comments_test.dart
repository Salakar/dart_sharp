import 'dart:convert';
import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:dsharp/src/codecs/binary_io.dart';
import 'package:dsharp/src/codecs/deflate_codec.dart';
import 'package:test/test.dart';

void main() {
  test('reads PNG text comments from metadata chunks', () async {
    final metadata = await ImagePipeline.fromBytes(
      _pngWithTextComments(),
    ).metadata();

    expect(metadata.format, ImageFormat.png);
    expect(metadata.comments, hasLength(3));
    expect(metadata.comments[0].keyword, 'Comment');
    expect(metadata.comments[0].text, 'Created with GIMP');
    expect(metadata.comments[1].keyword, 'Software');
    expect(metadata.comments[1].text, 'dsharp');
    expect(metadata.comments[2].keyword, 'Description');
    expect(metadata.comments[2].text, 'Snowman: \u2603');
    expect(metadata.hasXmp, isTrue);
    expect(metadata.xmpAsString, '<x:xmpmeta />');
  });

  test('PNG metadata comments getter is immutable', () async {
    final metadata = await ImagePipeline.fromBytes(
      _pngWithTextComments(),
    ).metadata();

    expect(
      () => metadata.comments.add(
        const ImageMetadataComment(keyword: 'Other', text: 'ignored'),
      ),
      throwsUnsupportedError,
    );
  });
}

Uint8List _pngWithTextComments() {
  final writer = ByteWriter()
    ..writeBytes(<int>[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  _pngChunk(writer, 'IHDR', <int>[0, 0, 0, 1, 0, 0, 0, 1, 8, 2, 0, 0, 0]);
  _pngChunk(writer, 'tEXt', _text('Comment', 'Created with GIMP'));
  _pngChunk(writer, 'zTXt', _compressedText('Software', 'dsharp'));
  _pngChunk(
    writer,
    'iTXt',
    _internationalText('Description', 'Snowman: \u2603'),
  );
  _pngChunk(
    writer,
    'iTXt',
    _internationalText('XML:com.adobe.xmp', '<x:xmpmeta />'),
  );
  _pngChunk(writer, 'IEND', const <int>[]);
  return writer.toBytes();
}

Uint8List _text(String keyword, String text) {
  return Uint8List.fromList(<int>[
    ...latin1.encode(keyword),
    0,
    ...latin1.encode(text),
  ]);
}

Uint8List _compressedText(String keyword, String text) {
  final compressed = zlibEncodeStored(Uint8List.fromList(latin1.encode(text)));
  return Uint8List.fromList(<int>[
    ...latin1.encode(keyword),
    0,
    0,
    ...compressed,
  ]);
}

Uint8List _internationalText(String keyword, String text) {
  return Uint8List.fromList(<int>[
    ...latin1.encode(keyword),
    0,
    0,
    0,
    0,
    0,
    ...utf8.encode(text),
  ]);
}

void _pngChunk(ByteWriter writer, String type, List<int> data) {
  final typeBytes = ascii.encode(type);
  writer
    ..writeUint32Be(data.length)
    ..writeBytes(typeBytes)
    ..writeBytes(data)
    ..writeUint32Be(crc32(<int>[...typeBytes, ...data]));
}
