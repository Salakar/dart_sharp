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
