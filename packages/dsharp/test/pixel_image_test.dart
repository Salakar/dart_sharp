import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

void main() {
  RawPixels raw({
    int width = 1,
    int height = 1,
    List<int> bytes = const <int>[1, 2, 3, 4],
  }) {
    return RawPixels(
      bytes: Uint8List.fromList(bytes),
      width: width,
      height: height,
      channels: ChannelCount.four,
    );
  }

  test('single-frame pixel image exposes dimensions and channels', () {
    final image = PixelImage.fromRawPixels(raw());

    expect(image.width, 1);
    expect(image.height, 1);
    expect(image.channels, ChannelCount.four);
    expect(image.isAnimated, isFalse);
    expect(image.firstFrameBytes(), <int>[1, 2, 3, 4]);
  });

  test('pixel image defensively exposes frames', () {
    final image = PixelImage.fromRawPixels(raw());

    expect(
      () => image.frames.add(ImageFrame(pixels: raw())),
      throwsUnsupportedError,
    );
  });

  test('pixel image requires at least one frame', () {
    expect(
      () => PixelImage(frames: const <ImageFrame>[]),
      throwsA(isA<InvalidImageException>()),
    );
  });

  test('pixel image rejects mismatched frame dimensions', () {
    final frameA = ImageFrame(pixels: raw());
    final frameB = ImageFrame(
      pixels: raw(width: 2, bytes: const <int>[1, 2, 3, 4, 5, 6, 7, 8]),
    );

    expect(
      () => PixelImage(frames: <ImageFrame>[frameA, frameB]),
      throwsA(isA<InvalidImageException>()),
    );
  });
}
