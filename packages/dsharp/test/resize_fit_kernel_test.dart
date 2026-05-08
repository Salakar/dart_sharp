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

  test('kernel helpers expose distinct MKS and Mitchell weights', () {
    expect(kernelRadius(ResizeKernel.mks2013), 2.5);
    expect(kernelRadius(ResizeKernel.mks2021), 4.5);
    expect(kernelWeight(ResizeKernel.cubic, 0), 1);
    expect(kernelWeight(ResizeKernel.mitchell, 0), closeTo(8 / 9, 1e-12));
    expect(kernelWeight(ResizeKernel.mks2013, 0), closeTo(1.0625, 1e-12));
    expect(kernelWeight(ResizeKernel.mks2013, 1.5), closeTo(-0.125, 1e-12));
    expect(kernelWeight(ResizeKernel.mks2013, 2), closeTo(-0.03125, 1e-12));
    expect(kernelWeight(ResizeKernel.mks2021, 0), closeTo(577 / 576, 1e-12));
    expect(kernelWeight(ResizeKernel.mks2021, 1.5), closeTo(-29 / 288, 1e-12));
    expect(kernelWeight(ResizeKernel.mks2021, 3.5), closeTo(-1 / 288, 1e-12));
    expect(kernelWeight(ResizeKernel.mks2021, 4), closeTo(-1 / 1152, 1e-12));
  });

  test(
    'MKS kernels fall back to cubic interpolation when upsampling',
    () async {
      final raw = RawPixels(
        bytes: Uint8List.fromList(<int>[0, 64, 255]),
        width: 3,
        height: 1,
        channels: ChannelCount.one,
      );

      Future<Uint8List> resizeWith(ResizeKernel kernel) async {
        final image = await ImagePipeline.fromRawPixels(raw)
            .resize(
              ResizeOptions(
                width: 7,
                height: 1,
                fit: ResizeFit.fill,
                kernel: kernel,
              ),
            )
            .toPixelImage();
        return image.firstFrameBytes();
      }

      final cubic = await resizeWith(ResizeKernel.cubic);

      expect(await resizeWith(ResizeKernel.mitchell), cubic);
      expect(await resizeWith(ResizeKernel.mks2013), cubic);
      expect(await resizeWith(ResizeKernel.mks2021), cubic);
    },
  );
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
