import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:dsharp/src/codecs/binary_io.dart';
import 'package:dsharp/src/codecs/jpeg_bit_io.dart';
import 'package:test/test.dart';

void main() {
  test('decodes minimal lossless JPEG pixels', () async {
    final image = await ImagePipeline.fromBytes(_losslessJpeg()).toPixelImage();

    expect(image.width, 1);
    expect(image.height, 1);
    expect(image.firstFrameBytes(), <int>[128, 128, 128, 255]);
  });

  test('decodes minimal progressive JPEG pixels', () async {
    final bytes = _progressiveJpeg();
    final metadata = await ImagePipeline.fromBytes(bytes).metadata();
    final image = await ImagePipeline.fromBytes(bytes).toPixelImage();

    expect(metadata.isProgressive, isTrue);
    expect(image.width, 1);
    expect(image.height, 1);
    expect(image.firstFrameBytes(), <int>[129, 129, 129, 255]);
  });

  test('decodes progressive JPEG AC refinement scans', () async {
    final image = await ImagePipeline.fromBytes(
      _progressiveAcRefinementJpeg(),
    ).toPixelImage();
    final red = <int>[
      for (var i = 0; i < image.firstFrameBytes().length; i += 4)
        image.firstFrameBytes()[i],
    ];

    expect(image.width, 8);
    expect(image.height, 1);
    expect(red.toSet(), hasLength(greaterThan(1)));
    expect(red.first, greaterThan(red.last));
  });

  test('encodes progressive JPEG bytes', () async {
    final bytes = await ImagePipeline.fromRawPixels(
      RawPixels(
        bytes: Uint8List.fromList(<int>[
          for (var y = 0; y < 8; y += 1)
            for (var x = 0; x < 8; x += 1) ...[x * 31, y * 31, 128],
        ]),
        width: 8,
        height: 8,
        channels: ChannelCount.three,
      ),
    ).jpeg(const JpegEncoderOptions(progressive: true)).toBytes();
    final metadata = await ImagePipeline.fromBytes(bytes).metadata();
    final image = await ImagePipeline.fromBytes(bytes).toPixelImage();

    expect(_jpegFrameMarker(bytes), 0xc2);
    expect(metadata.isProgressive, isTrue);
    expect(image.width, 8);
    expect(image.height, 8);
    expect(image.firstFrameBytes().length, 8 * 8 * 4);
  });

  test(
    'rejects malformed JPEG structural segments with typed errors',
    () async {
      final cases = <Uint8List>[
        _jpegWith(
          (writer) => _segment(writer, 0xdb, Uint8List.fromList(<int>[0, 1])),
        ),
        _jpegWith(
          (writer) =>
              _segment(writer, 0xc4, Uint8List.fromList(<int>[0, 1, 0])),
        ),
        _jpegWith(
          (writer) => _segment(writer, 0xc0, Uint8List.fromList(<int>[8, 0])),
        ),
        _jpegWith((writer) => _segment(writer, 0xdd, Uint8List(0))),
        _jpegWith((writer) => _segment(writer, 0xda, Uint8List(0))),
        _jpegWith(
          (writer) => _segment(writer, 0xc0, _sofOneComponent(sampling: 0x01)),
        ),
      ];

      for (final bytes in cases) {
        await expectLater(
          ImagePipeline.fromBytes(bytes).toPixelImage(),
          throwsA(isA<InvalidImageException>()),
        );
      }
    },
  );

  test('rejects malformed JPEG scan and table references', () async {
    final cases = <Uint8List>[
      _jpegWith((writer) {
        _segment(writer, 0xdb, _dqtOnes());
        _segment(writer, 0xc0, _sofOneComponent());
        _segment(writer, 0xc4, _dht(0));
        _segment(writer, 0xc4, _dht(1));
        _segment(writer, 0xda, _baselineSos(componentId: 2));
        writer.writeByte(0);
      }),
      _jpegWith((writer) {
        _segment(writer, 0xc0, _sofOneComponent());
        _segment(writer, 0xc4, _dht(0));
        _segment(writer, 0xc4, _dht(1));
        _segment(writer, 0xda, _baselineSos());
        writer.writeByte(0);
      }),
      _jpegWith((writer) {
        _segment(writer, 0xdb, _dqtOnes());
        _segment(writer, 0xc0, _sofOneComponent());
        _segment(writer, 0xda, _baselineSos());
        writer.writeByte(0);
      }),
    ];

    for (final bytes in cases) {
      await expectLater(
        ImagePipeline.fromBytes(bytes).toPixelImage(),
        throwsA(isA<InvalidImageException>()),
      );
    }
  });
}

Uint8List _losslessJpeg() {
  final writer = ByteWriter()
    ..writeByte(0xff)
    ..writeByte(0xd8);
  _segment(
    writer,
    0xc3,
    Uint8List.fromList(<int>[
      8,
      0,
      1,
      0,
      1,
      3,
      1,
      0x11,
      0,
      2,
      0x11,
      0,
      3,
      0x11,
      0,
    ]),
  );
  _segment(
    writer,
    0xc4,
    Uint8List.fromList(<int>[
      0,
      1,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
    ]),
  );
  _segment(
    writer,
    0xda,
    Uint8List.fromList(<int>[3, 1, 0, 2, 0, 3, 0, 1, 0, 0]),
  );
  writer
    ..writeByte(0x1f)
    ..writeByte(0xff)
    ..writeByte(0xd9);
  return writer.toBytes();
}

Uint8List _jpegWith(void Function(ByteWriter writer) writeSegments) {
  final writer = ByteWriter()
    ..writeByte(0xff)
    ..writeByte(0xd8);
  writeSegments(writer);
  return (writer
        ..writeByte(0xff)
        ..writeByte(0xd9))
      .toBytes();
}

void _segment(ByteWriter writer, int marker, Uint8List data) {
  writer
    ..writeByte(0xff)
    ..writeByte(marker)
    ..writeUint16Be(data.length + 2)
    ..writeBytes(data);
}

Uint8List _progressiveJpeg() {
  final writer = ByteWriter()
    ..writeByte(0xff)
    ..writeByte(0xd8);
  _segment(writer, 0xdb, _dqtOnes());
  _segment(
    writer,
    0xc2,
    Uint8List.fromList(<int>[8, 0, 1, 0, 1, 1, 1, 0x11, 0]),
  );
  _segment(writer, 0xc4, _dht(0));
  _segment(writer, 0xc4, _dht(1));
  _segment(writer, 0xda, Uint8List.fromList(<int>[1, 1, 0, 0, 0, 0]));
  writer.writeBytes(
    (JpegBitWriter()
          ..writeSymbol(4)
          ..writeBits(8, 4))
        .finish(),
  );
  _segment(writer, 0xda, Uint8List.fromList(<int>[1, 1, 0, 1, 63, 0]));
  writer.writeBytes((JpegBitWriter()..writeSymbol(0)).finish());
  return (writer
        ..writeByte(0xff)
        ..writeByte(0xd9))
      .toBytes();
}

Uint8List _progressiveAcRefinementJpeg() {
  final writer = ByteWriter()
    ..writeByte(0xff)
    ..writeByte(0xd8);
  _segment(writer, 0xdb, _dqtOnes());
  _segment(
    writer,
    0xc2,
    Uint8List.fromList(<int>[8, 0, 1, 0, 8, 1, 1, 0x11, 0]),
  );
  _segment(writer, 0xc4, _dht(0));
  _segment(writer, 0xc4, _dht(1));
  _segment(writer, 0xda, Uint8List.fromList(<int>[1, 1, 0, 0, 0, 0]));
  writer.writeBytes((JpegBitWriter()..writeSymbol(0)).finish());
  _segment(writer, 0xda, Uint8List.fromList(<int>[1, 1, 0, 1, 1, 1]));
  writer.writeBytes(
    (JpegBitWriter()
          ..writeSymbol(4)
          ..writeBits(8, 4))
        .finish(),
  );
  _segment(writer, 0xda, Uint8List.fromList(<int>[1, 1, 0, 1, 1, 0x10]));
  writer.writeBytes(
    (JpegBitWriter()
          ..writeSymbol(0)
          ..writeBits(1, 1))
        .finish(),
  );
  return (writer
        ..writeByte(0xff)
        ..writeByte(0xd9))
      .toBytes();
}

Uint8List _dqtOnes() {
  return Uint8List.fromList(<int>[0, ...List<int>.filled(64, 1)]);
}

Uint8List _sofOneComponent({int sampling = 0x11}) {
  return Uint8List.fromList(<int>[8, 0, 1, 0, 1, 1, 1, sampling, 0]);
}

Uint8List _baselineSos({int componentId = 1}) {
  return Uint8List.fromList(<int>[1, componentId, 0, 0, 63, 0]);
}

Uint8List _dht(int tableClass) {
  return (ByteWriter()
        ..writeByte(tableClass << 4)
        ..writeBytes(<int>[0, 0, 0, 0, 0, 0, 0, 255, 0, 0, 0, 0, 0, 0, 0, 0])
        ..writeBytes(List<int>.generate(255, (index) => index)))
      .toBytes();
}

int _jpegFrameMarker(Uint8List bytes) {
  var offset = 2;
  while (offset + 4 < bytes.length) {
    while (offset < bytes.length && bytes[offset] == 0xff) {
      offset += 1;
    }
    final marker = bytes[offset++];
    final length = readUint16Be(bytes, offset);
    if (marker >= 0xc0 && marker <= 0xcf && marker != 0xc4) {
      return marker;
    }
    offset += length;
  }
  throw StateError('JPEG frame marker not found.');
}
