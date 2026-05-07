# Contributing

Thanks for helping improve `dsharp`.

## Local setup

1. Install the Dart SDK.
2. Run `dart pub get` at the repository root.
3. Run `dart run melos bootstrap`.

## Required checks

Run these before opening a pull request:

```bash
dart run melos run format
dart run melos run analyze
dart run melos run test
```

Public APIs require Dartdoc and tests. Keep implementation files under 300 lines and test files under 250 lines unless a plan task explicitly justifies an exception.

## Clean-room policy

The ignored `sharp_clone/` directory is reference material for observable
behavior only. Do not copy source, comments, documentation, tests, or fixtures
from it into tracked package files unless a dedicated license review task says
that specific material can be copied.

Prefer independently generated fixtures under `packages/dsharp/test/fixtures/`.
Compatibility tests may read ignored upstream fixtures when they are present on
a local machine, but those files must remain untracked by default.

Before adding a package dependency, record its license, platform support, web
compatibility, and whether it imports `dart:io` in code reachable from
`package:dsharp/dsharp.dart`.
