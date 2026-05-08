import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

void main() {
  test('cover resize crops with gravity instead of stretching', () async {
    final image = await ImagePipeline.fromRawPixels(_redRamp(4, 2))
        .resize(
          const ResizeOptions(
            width: 2,
            height: 2,
            fit: ResizeFit.cover,
            kernel: ResizeKernel.nearest,
          ),
        )
        .toPixelImage();

    expect(image.width, 2);
    expect(image.height, 2);
    expect(_redChannel(image.firstFrameBytes()), <int>[1, 2, 5, 6]);
  });

  test('contain resize embeds with background and gravity', () async {
    final image = await ImagePipeline.fromRawPixels(_redRamp(4, 2))
        .resize(
          const ResizeOptions(
            width: 4,
            height: 4,
            fit: ResizeFit.contain,
            gravity: Gravity.south,
            kernel: ResizeKernel.nearest,
            background: RgbaColor(red: 9, green: 0, blue: 0),
          ),
        )
        .toPixelImage();

    expect(image.width, 4);
    expect(image.height, 4);
    expect(_redChannel(image.firstFrameBytes()), <int>[
      9,
      9,
      9,
      9,
      9,
      9,
      9,
      9,
      0,
      1,
      2,
      3,
      4,
      5,
      6,
      7,
    ]);
  });

  test('linear kernel interpolates between samples', () async {
    final image =
        await ImagePipeline.fromRawPixels(
              RawPixels(
                bytes: Uint8List.fromList(<int>[0, 255]),
                width: 2,
                height: 1,
                channels: ChannelCount.one,
              ),
            )
            .resize(
              const ResizeOptions(
                width: 3,
                height: 1,
                fit: ResizeFit.fill,
                kernel: ResizeKernel.linear,
              ),
            )
            .toPixelImage();

    expect(image.firstFrameBytes(), <int>[0, 128, 255]);
  });
}

RawPixels _redRamp(int width, int height) {
  final bytes = Uint8List(width * height * 4);
  for (var i = 0; i < width * height; i += 1) {
    final offset = i * 4;
    bytes[offset] = i;
    bytes[offset + 3] = 255;
  }
  return RawPixels(
    bytes: bytes,
    width: width,
    height: height,
    channels: ChannelCount.four,
  );
}

List<int> _redChannel(Uint8List bytes) {
  return <int>[
    for (var offset = 0; offset < bytes.length; offset += 4) bytes[offset],
  ];
}
