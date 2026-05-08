@TestOn('vm')
library;

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
      final aliasOutput = File('${directory.path}/alias.png');
      final pathOutput = '${directory.path}/path.png';
      await ImagePipeline.fromRawPixels(
        rawRgba(1, 1, <int>[1, 2, 3, 255]),
      ).png().writeToFile(input);

      final pipeline = await imagePipelineFromFile(input);
      final info = await pipeline.png().writeToFile(output);
      final aliasInfo = await pipeline.png().toFile(aliasOutput);
      final pathInfo = await pipeline.png().toFile(pathOutput);
      final bytes = await output.readAsBytes();
      final aliasBytes = await aliasOutput.readAsBytes();
      final pathBytes = await File(pathOutput).readAsBytes();

      expect(info.format, ImageFormat.png);
      expect(aliasInfo.format, ImageFormat.png);
      expect(pathInfo.format, ImageFormat.png);
      expect(sniffImageFormat(bytes), ImageFormat.png);
      expect(sniffImageFormat(aliasBytes), ImageFormat.png);
      expect(sniffImageFormat(pathBytes), ImageFormat.png);
      expect((await pipeline.metadata()).width, 1);
      expect(
        () => pipeline.png().toFile(Object()),
        throwsA(isA<ArgumentError>()),
      );
    },
  );
}
