# Dependency Review

This package has no runtime dependencies. `packages/dsharp/pubspec.yaml`
contains only `dev_dependencies`, and `test/runtime_dependency_guard_test.dart`
fails if a runtime dependency or core `package:` import is introduced.

Rejected runtime candidates:

- `image`: replaced by first-party codec and pixel implementations.
- `archive`: not used; future deep-zoom/container output must be in-house or
  explicitly reviewed before the no-runtime-dependency rule changes.
- `xml`: replaced by a small in-house XMP well-formedness validator.
- `vector_math`: not used; affine and matrix operations are implemented with
  package-local value types and math.
