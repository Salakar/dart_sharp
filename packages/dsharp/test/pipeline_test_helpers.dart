import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';

RawPixels rawGray(int width, int height, List<int> bytes) {
  return RawPixels(
    bytes: Uint8List.fromList(bytes),
    width: width,
    height: height,
    channels: ChannelCount.one,
  );
}

RawPixels rawRgb(int width, int height, List<int> bytes) {
  return RawPixels(
    bytes: Uint8List.fromList(bytes),
    width: width,
    height: height,
    channels: ChannelCount.three,
  );
}

RawPixels rawRgba(int width, int height, List<int> bytes) {
  return RawPixels(
    bytes: Uint8List.fromList(bytes),
    width: width,
    height: height,
    channels: ChannelCount.four,
  );
}

Future<PixelImage> pixels(ImagePipeline pipeline) => pipeline.toPixelImage();

List<int> firstBytes(PixelImage image) => image.firstFrameBytes().toList();

List<int> redBytes(PixelImage image) {
  final bytes = image.firstFrameBytes();
  return <int>[
    for (var i = 0; i < bytes.length; i += image.channels.value) bytes[i],
  ];
}
