@TestOn('vm')
library;

import 'dart:io';

import 'package:test/test.dart';

void main() {
  test(
    'core library and exported implementation files do not import dart:io',
    () {
      final packageRoot = Directory.current;
      final libRoot = Directory('${packageRoot.path}/lib');

      expect(_dartIoImportOffenders(packageRoot, libRoot), isEmpty);
    },
  );

  test('scanner catches imports but ignores documentation mentions', () {
    final temp = Directory.systemTemp.createTempSync('dsharp_io_guard_');
    try {
      final lib = Directory('${temp.path}/lib')..createSync();
      File('${lib.path}/safe.dart').writeAsStringSync(
        "/// Mentions dart:io without importing it.\nlibrary;\n",
      );
      File(
        '${lib.path}/unsafe.dart',
      ).writeAsStringSync("import 'dart:io';\n\nvoid main() {}\n");

      expect(_dartIoImportOffenders(temp, lib), <String>['lib/unsafe.dart']);
    } finally {
      temp.deleteSync(recursive: true);
    }
  });
}

List<String> _dartIoImportOffenders(Directory packageRoot, Directory libRoot) {
  final ioImport = RegExp(r'''^\s*import\s+['"]dart:io['"]''');
  final files = libRoot
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .where((file) => !file.path.endsWith('dsharp_io.dart'));
  final offenders = <String>[];
  for (final file in files) {
    final lines = file.readAsLinesSync();
    if (lines.any(ioImport.hasMatch)) {
      offenders.add(file.path.replaceFirst('${packageRoot.path}/', ''));
    }
  }
  offenders.sort();
  return offenders;
}
