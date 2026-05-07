import 'dart:io';

import 'package:dsharp/dsharp.dart';
import 'package:dsharp/dsharp_io.dart';
import 'package:test/test.dart';

import 'pipeline_test_helpers.dart';

void main() {
  test(
    'dsharp_io reads and writes files without entering core exports',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'dsharp_io_test_',
      );
      addTearDown(() async {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      });
      final input = File('${directory.path}/input.png');
      final output = File('${directory.path}/output.png');
      await ImagePipeline.fromRawPixels(
        rawRgba(1, 1, <int>[1, 2, 3, 255]),
      ).png().writeToFile(input);

      final pipeline = await imagePipelineFromFile(input);
      final info = await pipeline.png().writeToFile(output);
      final bytes = await output.readAsBytes();

      expect(info.format, ImageFormat.png);
      expect(sniffImageFormat(bytes), ImageFormat.png);
      expect((await pipeline.metadata()).width, 1);
    },
  );
}
