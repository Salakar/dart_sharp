import 'dart:io';

import 'package:dsharp/dsharp.dart';
import 'package:test/test.dart';

import 'helpers/generated_fixtures.dart';

void main() {
  test('generated alpha-grid PNG matches checked golden', () async {
    final golden = File('test/goldens/alpha_grid.png');
    if (!golden.existsSync()) {
      markTestSkipped(
        'Run dart run tool/generate_goldens.dart to create goldens.',
      );
      return;
    }

    final generated = await ImagePipeline.fromRawPixels(
      GeneratedFixtures.alphaGrid(),
    ).png().toBytes();

    expect(generated, await golden.readAsBytes());
    expect(sniffImageFormat(generated), ImageFormat.png);
  });
}
