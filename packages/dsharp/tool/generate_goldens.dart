import 'dart:io';

import 'package:dsharp/dsharp.dart';

import '../test/helpers/generated_fixtures.dart';

Future<void> main() async {
  final directory = Directory('test/goldens');
  if (!directory.existsSync()) {
    directory.createSync(recursive: true);
  }
  final bytes = await ImagePipeline.fromRawPixels(
    GeneratedFixtures.alphaGrid(),
  ).png().toBytes();
  await File(
    '${directory.path}/alpha_grid.png',
  ).writeAsBytes(bytes, flush: true);
}
