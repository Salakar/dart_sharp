// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:typed_data';

import 'package:dsharp/dsharp.dart';
import 'package:dsharp/dsharp_io.dart';

Future<void> main() async {
  final directory = await Directory.systemTemp.createTemp('dsharp_example_');
  final input = File('${directory.path}/input.png');
  final output = File('${directory.path}/output.jpg');

  await ImagePipeline.fromRawPixels(
    RawPixels(
      bytes: Uint8List.fromList(<int>[40, 80, 160, 255]),
      width: 1,
      height: 1,
      channels: ChannelCount.four,
    ),
  ).png().writeToFile(input);

  final pipeline = await imagePipelineFromFile(input);
  final info = await pipeline
      .resize(const ResizeOptions(width: 16, height: 16, fit: ResizeFit.fill))
      .jpeg()
      .writeToFile(output);

  print('${output.path} ${info.width}x${info.height}');
}
