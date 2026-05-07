// ignore_for_file: avoid_print

import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';

Future<void> main() async {
  final raw = RawPixels(
    bytes: Uint8List.fromList(<int>[
      255,
      0,
      0,
      255,
      0,
      255,
      0,
      255,
      0,
      0,
      255,
      255,
      255,
      255,
      255,
      255,
    ]),
    width: 2,
    height: 2,
    channels: ChannelCount.four,
  );

  final overlay = PixelImage.fromRawPixels(
    RawPixels(
      bytes: Uint8List.fromList(<int>[0, 0, 0, 128]),
      width: 1,
      height: 1,
      channels: ChannelCount.four,
    ),
  );

  final result = await ImagePipeline.fromRawPixels(raw)
      .resize(const ResizeOptions(width: 8, height: 8, fit: ResizeFit.fill))
      .composite(<CompositeLayer>[
        CompositeLayer(image: overlay, left: 2, top: 2, tile: true),
      ])
      .png()
      .toBytesWithInfo();

  final stats = await ImagePipeline.fromBytes(result.bytes).stats();
  print('${result.info.format.id} ${result.info.width}x${result.info.height}');
  print('red mean ${stats.channels.first.mean.toStringAsFixed(2)}');
}
