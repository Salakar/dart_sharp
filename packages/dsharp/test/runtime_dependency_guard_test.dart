@TestOn('vm')
library;

import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('package has no runtime dependencies', () {
    final pubspec = File('pubspec.yaml').readAsLinesSync();
    final dependencies = _section(pubspec, 'dependencies');

    expect(dependencies, isEmpty);
  });

  test('core library does not import external packages', () {
    final offenders = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !file.path.endsWith('dsharp_io.dart'))
        .expand((file) {
          final lines = file.readAsLinesSync();
          return <String>[
            for (var i = 0; i < lines.length; i += 1)
              if (RegExp(r'''^\s*import\s+['"]package:''').hasMatch(lines[i]))
                '${file.path}:${i + 1}',
          ];
        })
        .toList();

    expect(offenders, isEmpty);
  });
}

List<String> _section(List<String> lines, String name) {
  final entries = <String>[];
  var inSection = false;
  for (final line in lines) {
    if (!line.startsWith(' ') && line.endsWith(':')) {
      inSection = line == '$name:';
      continue;
    }
    if (inSection && line.trim().isNotEmpty && !line.trim().startsWith('#')) {
      entries.add(line.trim());
    }
  }
  return entries;
}
