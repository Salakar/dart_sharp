# Benchmarks

Run:

```sh
dart run benchmark/dsharp_benchmark.dart
```

The suite reports microseconds per operation for:

- JPEG decode -> resize -> JPEG encode.
- PNG/RGBA premultiply -> resize -> PNG encode.
- Random dimension resize.
- Raw operation chain.
- Composite overlay.

These benchmarks track pure Dart throughput and elapsed time only; they do not
assert parity with native libvips performance.
