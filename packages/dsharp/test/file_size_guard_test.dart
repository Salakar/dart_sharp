@TestOn('vm')
library;

import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('implementation and test files stay within planned size limits', () {
    final packageRoot = Directory.current;
    final libFiles = _dartFiles(Directory('${packageRoot.path}/lib'));
    final testFiles = _dartFiles(Directory('${packageRoot.path}/test'));

    final oversized = <String>[];
    for (final file in libFiles) {
      final count = file.readAsLinesSync().length;
      if (count > 750) {
        oversized.add('${_relative(packageRoot, file)} has $count lines');
      }
    }
    for (final file in testFiles) {
      final count = file.readAsLinesSync().length;
      if (count > 750) {
        oversized.add('${_relative(packageRoot, file)} has $count lines');
      }
    }

    expect(oversized, isEmpty);
  });
}

Iterable<File> _dartFiles(Directory directory) {
  if (!directory.existsSync()) {
    return const Iterable<File>.empty();
  }
  return directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'));
}

String _relative(Directory root, File file) {
  return file.path.replaceFirst('${root.path}/', '');
}
