import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

void main() {
  RawPixels raw2x2() {
    return RawPixels(
      bytes: Uint8List.fromList(<int>[
        1,
        0,
        0,
        255,
        2,
        0,
        0,
        255,
        3,
        0,
        0,
        255,
        4,
        0,
        0,
        255,
      ]),
      width: 2,
      height: 2,
      channels: ChannelCount.four,
    );
  }

  test('resolves resize dimensions for common modes', () {
    final fixedWidth = resolveResize(
      sourceWidth: 20,
      sourceHeight: 10,
      options: const ResizeOptions(width: 10),
    );
    final inside = resolveResize(
      sourceWidth: 20,
      sourceHeight: 10,
      options: const ResizeOptions(width: 8, height: 8, fit: ResizeFit.inside),
    );

    expect(fixedWidth.width, 10);
    expect(fixedWidth.height, 5);
    expect(inside.width, 8);
    expect(inside.height, 4);
  });

  test('resize operation changes dimensions', () async {
    final image = await ImagePipeline.fromRawPixels(raw2x2())
        .resize(const ResizeOptions(width: 1, height: 1, fit: ResizeFit.fill))
        .toPixelImage();

    expect(image.width, 1);
    expect(image.height, 1);
    expect(image.firstFrameBytes(), <int>[1, 0, 0, 255]);
  });

  test('last resize call wins', () async {
    final image = await ImagePipeline.fromRawPixels(raw2x2())
        .resize(const ResizeOptions(width: 1, height: 1, fit: ResizeFit.fill))
        .resize(const ResizeOptions(width: 2, height: 2, fit: ResizeFit.fill))
        .toPixelImage();

    expect(image.width, 2);
    expect(image.height, 2);
    expect(image.firstFrameBytes(), orderedEquals(raw2x2().bytes));
  });

  test('resize accepts sharp-style positional arguments', () async {
    final widthOnly = await ImagePipeline.fromRawPixels(
      raw2x2(),
    ).resize(1).toPixelImage();
    final heightOnly = await ImagePipeline.fromRawPixels(
      raw2x2(),
    ).resize(null, 1).toPixelImage();
    final explicit = await ImagePipeline.fromRawPixels(
      raw2x2(),
    ).resize(1, 2, const ResizeOptions(fit: ResizeFit.fill)).toPixelImage();
    final optionsPriority = await ImagePipeline.fromRawPixels(
      raw2x2(),
    ).resize(1, 1, const ResizeOptions(width: 2, height: 2)).toPixelImage();

    expect(widthOnly.width, 1);
    expect(widthOnly.height, 1);
    expect(heightOnly.width, 1);
    expect(heightOnly.height, 1);
    expect(explicit.width, 1);
    expect(explicit.height, 2);
    expect(optionsPriority.width, 2);
    expect(optionsPriority.height, 2);
    expect(
      () => ImagePipeline.fromRawPixels(raw2x2()).resize('1'),
      throwsA(isA<OperationValidationException>()),
    );
  });

  test('extract operation crops a region', () async {
    final image = await ImagePipeline.fromRawPixels(raw2x2())
        .extract(const Region(left: 1, top: 1, width: 1, height: 1))
        .toPixelImage();

    expect(image.width, 1);
    expect(image.height, 1);
    expect(image.firstFrameBytes(), <int>[4, 0, 0, 255]);
  });

  test('extend operation supports background fill', () async {
    final image = await ImagePipeline.fromRawPixels(raw2x2())
        .extend(
          const ExtendOptions(
            insets: Insets(top: 1),
            background: RgbaColor(red: 9, green: 0, blue: 0),
          ),
        )
        .toPixelImage();

    expect(image.width, 2);
    expect(image.height, 3);
    expect(image.firstFrameBytes().take(4), <int>[9, 0, 0, 255]);
  });

  test('extend accepts sharp-style all-edge integer', () async {
    final image = await ImagePipeline.fromRawPixels(
      raw2x2(),
    ).extend(1).toPixelImage();
    final insetImage = await ImagePipeline.fromRawPixels(
      raw2x2(),
    ).extend(const Insets(left: 1)).toPixelImage();

    expect(image.width, 4);
    expect(image.height, 4);
    expect(image.firstFrameBytes().take(4), <int>[0, 0, 0, 255]);
    expect(insetImage.width, 3);
    expect(
      () => ImagePipeline.fromRawPixels(raw2x2()).extend('1'),
      throwsA(isA<OperationValidationException>()),
    );
  });

  test('extend operation supports edge copy mode', () async {
    final image = await ImagePipeline.fromRawPixels(raw2x2())
        .extend(
          const ExtendOptions(insets: Insets(left: 1), mode: ExtendMode.copy),
        )
        .toPixelImage();

    expect(image.width, 3);
    expect(image.firstFrameBytes().take(4), <int>[1, 0, 0, 255]);
  });

  test('trim removes matching border', () async {
    final raw = RawPixels(
      bytes: Uint8List.fromList(<int>[
        0,
        0,
        0,
        255,
        0,
        0,
        0,
        255,
        0,
        0,
        0,
        255,
        0,
        0,
        0,
        255,
        5,
        0,
        0,
        255,
        0,
        0,
        0,
        255,
        0,
        0,
        0,
        255,
        0,
        0,
        0,
        255,
        0,
        0,
        0,
        255,
      ]),
      width: 3,
      height: 3,
      channels: ChannelCount.four,
    );

    final image = await ImagePipeline.fromRawPixels(raw).trim().toPixelImage();

    expect(image.width, 1);
    expect(image.height, 1);
    expect(image.firstFrameBytes(), <int>[5, 0, 0, 255]);
  });

  test('kernel helpers provide deterministic weights', () {
    expect(kernelRadius(ResizeKernel.lanczos3), 3);
    expect(kernelWeight(ResizeKernel.nearest, 0), 1);
    expect(kernelWeight(ResizeKernel.linear, 2), 0);
  });

  test('crop strategies expose deterministic scores', () async {
    final image = await ImagePipeline.fromRawPixels(raw2x2()).toPixelImage();

    expect(const EntropyCropStrategy().name, 'entropy');
    expect(const EntropyCropStrategy().score(image), greaterThan(0));
    expect(
      const AttentionCropStrategy().score(image),
      const EntropyCropStrategy().score(image),
    );
  });
}
