import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:dsharp/src/codecs/binary_io.dart';
import 'package:dsharp/src/codecs/gif_lzw.dart';
import 'package:test/test.dart';

void main() {
  test('composites partial GIF frames on retained canvas', () async {
    final image = await ImagePipeline.fromBytes(
      _gif(<_GifFrame>[
        const _GifFrame(width: 2, height: 1, indices: <int>[1, 1]),
        const _GifFrame(left: 1, width: 1, height: 1, indices: <int>[2]),
      ]),
    ).toPixelImage();

    expect(image.frames[0].pixels.bytes, _rgba(<int>[1, 1]));
    expect(image.frames[1].pixels.bytes, _rgba(<int>[1, 2]));
  });

  test('clears GIF disposal-background frame bounds', () async {
    final image = await ImagePipeline.fromBytes(
      _gif(<_GifFrame>[
        const _GifFrame(width: 2, height: 1, indices: <int>[1, 1]),
        const _GifFrame(
          left: 1,
          width: 1,
          height: 1,
          indices: <int>[2],
          disposalMethod: 2,
        ),
        const _GifFrame(width: 1, height: 1, indices: <int>[3]),
      ]),
    ).toPixelImage();

    expect(image.frames[1].pixels.bytes, _rgba(<int>[1, 2]));
    expect(image.frames[2].pixels.bytes, _rgba(<int>[3, 0]));
  });

  test('restores previous canvas for GIF disposal-previous frames', () async {
    final image = await ImagePipeline.fromBytes(
      _gif(<_GifFrame>[
        const _GifFrame(width: 2, height: 1, indices: <int>[1, 1]),
        const _GifFrame(
          left: 1,
          width: 1,
          height: 1,
          indices: <int>[2],
          disposalMethod: 3,
        ),
        const _GifFrame(width: 1, height: 1, indices: <int>[3]),
      ]),
    ).toPixelImage();

    expect(image.frames[1].pixels.bytes, _rgba(<int>[1, 2]));
    expect(image.frames[2].pixels.bytes, _rgba(<int>[3, 1]));
  });

  test('leaves GIF transparent pixels unchanged', () async {
    final image = await ImagePipeline.fromBytes(
      _gif(<_GifFrame>[
        const _GifFrame(width: 2, height: 1, indices: <int>[1, 1]),
        const _GifFrame(
          width: 2,
          height: 1,
          indices: <int>[0, 2],
          transparentIndex: 0,
        ),
      ]),
    ).toPixelImage();

    expect(image.frames[1].pixels.bytes, _rgba(<int>[1, 2]));
  });

  test('GIF animation options override loop count and frame delays', () async {
    final encoded = await ImagePipeline.fromPixelImage(_animation(loopCount: 2))
        .gif(
          const GifEncoderOptions(
            loopCount: 3,
            frameDelays: <Duration>[
              Duration(milliseconds: 40),
              Duration(milliseconds: 60),
            ],
          ),
        )
        .toBytesWithInfo();
    final decoded = await ImagePipeline.fromBytes(encoded.bytes).toPixelImage();

    expect(encoded.info.loopCount, 3);
    expect(encoded.info.frameDelays, <Duration>[
      const Duration(milliseconds: 40),
      const Duration(milliseconds: 60),
    ]);
    expect(decoded.loopCount, 3);
    expect(decoded.frames[0].delay, const Duration(milliseconds: 40));
    expect(decoded.frames[1].delay, const Duration(milliseconds: 60));
  });

  test('GIF frameDelay repeats one delay across animation frames', () async {
    final bytes = await ImagePipeline.fromPixelImage(_animation())
        .gif(const GifEncoderOptions(frameDelay: Duration(milliseconds: 50)))
        .toBytes();
    final decoded = await ImagePipeline.fromBytes(bytes).toPixelImage();

    expect(decoded.frames[0].delay, const Duration(milliseconds: 50));
    expect(decoded.frames[1].delay, const Duration(milliseconds: 50));
  });

  test('GIF loop and delay aliases map to animation metadata', () async {
    final bytes = await ImagePipeline.fromPixelImage(_animation())
        .gif(
          const GifEncoderOptions(loop: 4, delay: Duration(milliseconds: 70)),
        )
        .toBytes();
    final decoded = await ImagePipeline.fromBytes(bytes).toPixelImage();

    expect(decoded.loopCount, 4);
    expect(decoded.frames[0].delay, const Duration(milliseconds: 70));
    expect(decoded.frames[1].delay, const Duration(milliseconds: 70));
  });

  test('GIF colours alias maps to palette size', () async {
    final raw = _twoColorRaw();
    final bytes = await ImagePipeline.fromRawPixels(
      raw,
    ).gif(const GifEncoderOptions(colours: 2)).toBytes();
    final decoded = await ImagePipeline.fromBytes(bytes).toPixelImage();

    expect(_gifGlobalColorCount(bytes), 2);
    expect(decoded.firstFrameBytes(), raw.bytes);
  });

  test('GIF animation option ranges are validated', () {
    expect(
      ImagePipeline.fromPixelImage(
        _animation(),
      ).gif(const GifEncoderOptions(loopCount: -1)).toBytes(),
      throwsA(isA<OperationValidationException>()),
    );
    expect(
      ImagePipeline.fromPixelImage(_animation())
          .gif(
            const GifEncoderOptions(
              frameDelay: Duration(milliseconds: 0x10000),
            ),
          )
          .toBytes(),
      throwsA(isA<OperationValidationException>()),
    );
    expect(
      ImagePipeline.fromPixelImage(_animation())
          .gif(
            const GifEncoderOptions(
              frameDelays: <Duration>[Duration(milliseconds: 10)],
            ),
          )
          .toBytes(),
      throwsA(isA<OperationValidationException>()),
    );
  });

  test('rejects malformed GIF containers with typed errors', () async {
    final cases = <Uint8List>[
      _gifHeader(globalColorTable: true),
      _gifWithTruncatedGraphicControlExtension(),
      _gifWithTruncatedImageDescriptor(),
      _gifWithTruncatedImageDataBlock(),
      _gifWithoutPalette(),
      _gif(<_GifFrame>[
        const _GifFrame(left: 2, width: 1, height: 1, indices: <int>[1]),
      ]),
    ];

    for (final bytes in cases) {
      await expectLater(
        ImagePipeline.fromBytes(bytes).toPixelImage(),
        throwsA(isA<InvalidImageException>()),
      );
    }
  });

  test('rejects malformed GIF metadata color tables', () async {
    await expectLater(
      ImagePipeline.fromBytes(_gifHeader(globalColorTable: true)).metadata(),
      throwsA(isA<InvalidImageException>()),
    );
    await expectLater(
      ImagePipeline.fromBytes(_gifWithTruncatedLocalColorTable()).metadata(),
      throwsA(isA<InvalidImageException>()),
    );
  });

  test('rejects GIF palette indices outside the active color table', () async {
    await expectLater(
      ImagePipeline.fromBytes(_gifWithPaletteIndices(<int>[2])).toPixelImage(),
      throwsA(isA<InvalidImageException>()),
    );
  });

  test('rejects invalid GIF LZW code streams', () {
    expect(
      () => gifLzwDecode(Uint8List.fromList(<int>[0x06]), 2, 1),
      throwsA(isA<InvalidImageException>()),
    );
    expect(
      () => gifLzwDecode(_lzwCodes(<int>[4, 0, 7], 3), 2, 2),
      throwsA(isA<InvalidImageException>()),
    );
    expect(
      () => gifLzwDecode(Uint8List.fromList(<int>[0]), 1, 1),
      throwsA(isA<InvalidImageException>()),
    );
  });
}

PixelImage _animation({int? loopCount}) {
  return PixelImage(
    frames: <ImageFrame>[
      ImageFrame(
        pixels: _solid(255, 0, 0),
        delay: const Duration(milliseconds: 10),
      ),
      ImageFrame(
        pixels: _solid(0, 255, 0),
        delay: const Duration(milliseconds: 20),
      ),
    ],
    loopCount: loopCount,
  );
}

RawPixels _solid(int red, int green, int blue) {
  return RawPixels(
    bytes: Uint8List.fromList(<int>[red, green, blue, 255]),
    width: 1,
    height: 1,
    channels: ChannelCount.four,
  );
}

RawPixels _twoColorRaw() {
  return RawPixels(
    bytes: Uint8List.fromList(<int>[255, 0, 0, 255, 0, 255, 0, 255]),
    width: 2,
    height: 1,
    channels: ChannelCount.four,
  );
}

int _gifGlobalColorCount(Uint8List bytes) {
  final packed = bytes[10];
  return 1 << ((packed & 0x07) + 1);
}

Uint8List _gifHeader({bool globalColorTable = false}) {
  final writer = ByteWriter()
    ..writeAscii('GIF89a')
    ..writeUint16Le(1)
    ..writeUint16Le(1)
    ..writeByte(globalColorTable ? 0x80 : 0)
    ..writeByte(0)
    ..writeByte(0);
  return writer.toBytes();
}

ByteWriter _gifWithTwoColorTable() {
  return ByteWriter()
    ..writeAscii('GIF89a')
    ..writeUint16Le(1)
    ..writeUint16Le(1)
    ..writeByte(0x80)
    ..writeByte(0)
    ..writeByte(0)
    ..writeBytes(const <int>[0, 0, 0, 255, 255, 255]);
}

Uint8List _gifWithTruncatedGraphicControlExtension() {
  final writer = _gifWithTwoColorTable()
    ..writeByte(0x21)
    ..writeByte(0xf9)
    ..writeByte(4)
    ..writeByte(0)
    ..writeByte(0)
    ..writeByte(0);
  return writer.toBytes();
}

Uint8List _gifWithTruncatedImageDescriptor() {
  final writer = _gifWithTwoColorTable()
    ..writeByte(0x2c)
    ..writeByte(0);
  return writer.toBytes();
}

Uint8List _gifWithTruncatedImageDataBlock() {
  final writer = _gifWithTwoColorTable();
  _writeImageDescriptor(writer, localPacked: 0);
  writer
    ..writeByte(2)
    ..writeByte(2)
    ..writeByte(0);
  return writer.toBytes();
}

Uint8List _gifWithTruncatedLocalColorTable() {
  final writer = ByteWriter()
    ..writeAscii('GIF89a')
    ..writeUint16Le(1)
    ..writeUint16Le(1)
    ..writeByte(0)
    ..writeByte(0)
    ..writeByte(0);
  _writeImageDescriptor(writer, localPacked: 0x80);
  writer.writeBytes(const <int>[0, 0, 0]);
  return writer.toBytes();
}

Uint8List _gifWithoutPalette() {
  final writer = ByteWriter()
    ..writeAscii('GIF89a')
    ..writeUint16Le(1)
    ..writeUint16Le(1)
    ..writeByte(0)
    ..writeByte(0)
    ..writeByte(0);
  _writeImageDescriptor(writer, localPacked: 0);
  return writer.toBytes();
}

Uint8List _gifWithPaletteIndices(List<int> indices) {
  final lzw = gifLzwEncode(indices, 2);
  final writer = _gifWithTwoColorTable();
  _writeImageDescriptor(writer, localPacked: 0);
  writer
    ..writeByte(2)
    ..writeByte(lzw.length)
    ..writeBytes(lzw)
    ..writeByte(0)
    ..writeByte(0x3b);
  return writer.toBytes();
}

void _writeImageDescriptor(ByteWriter writer, {required int localPacked}) {
  writer
    ..writeByte(0x2c)
    ..writeUint16Le(0)
    ..writeUint16Le(0)
    ..writeUint16Le(1)
    ..writeUint16Le(1)
    ..writeByte(localPacked);
}

Uint8List _lzwCodes(List<int> codes, int codeSize) {
  final bytes = <int>[];
  var current = 0;
  var bits = 0;
  for (final code in codes) {
    var value = code;
    for (var bit = 0; bit < codeSize; bit += 1) {
      current |= (value & 1) << bits;
      value >>= 1;
      bits += 1;
      if (bits == 8) {
        bytes.add(current);
        current = 0;
        bits = 0;
      }
    }
  }
  if (bits > 0) {
    bytes.add(current);
  }
  return Uint8List.fromList(bytes);
}

final class _GifFrame {
  const _GifFrame({
    this.left = 0,
    required this.width,
    required this.height,
    required this.indices,
    this.transparentIndex,
    this.disposalMethod = 1,
  });

  final int left;
  final int width;
  final int height;
  final List<int> indices;
  final int? transparentIndex;
  final int disposalMethod;
}

Uint8List _gif(List<_GifFrame> frames) {
  final writer = ByteWriter()
    ..writeAscii('GIF89a')
    ..writeUint16Le(2)
    ..writeUint16Le(1)
    ..writeByte(0xf1)
    ..writeByte(0)
    ..writeByte(0)
    ..writeBytes(const <int>[0, 0, 0, 255, 0, 0, 0, 0, 255, 0, 255, 0]);
  for (final frame in frames) {
    _writeGraphicControl(writer, frame);
    final lzw = gifLzwEncode(frame.indices, 2);
    writer
      ..writeByte(0x2c)
      ..writeUint16Le(frame.left)
      ..writeUint16Le(0)
      ..writeUint16Le(frame.width)
      ..writeUint16Le(frame.height)
      ..writeByte(0)
      ..writeByte(2)
      ..writeByte(lzw.length)
      ..writeBytes(lzw)
      ..writeByte(0);
  }
  writer.writeByte(0x3b);
  return writer.toBytes();
}

void _writeGraphicControl(ByteWriter writer, _GifFrame frame) {
  writer
    ..writeByte(0x21)
    ..writeByte(0xf9)
    ..writeByte(4)
    ..writeByte(
      (frame.disposalMethod << 2) | (frame.transparentIndex == null ? 0 : 1),
    )
    ..writeUint16Le(1)
    ..writeByte(frame.transparentIndex ?? 0)
    ..writeByte(0);
}

List<int> _rgba(List<int> indices) {
  return <int>[
    for (final index in indices)
      ...switch (index) {
        0 => <int>[0, 0, 0, 0],
        1 => <int>[255, 0, 0, 255],
        2 => <int>[0, 0, 255, 255],
        _ => <int>[0, 255, 0, 255],
      },
  ];
}
