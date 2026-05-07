# Coverage Policy

Initial package-area thresholds:

- API, source, pixel, and codec model files: 80% line coverage.
- Geometry, operations, compositing, and output chain files: 75% line coverage.
- IO adapter, benchmark, and optional compatibility harness files: smoke covered.

Coverage runs should exclude generated golden assets and should treat skipped
optional upstream compatibility tests as neutral. Local reports are produced by:

```sh
dart run melos run coverage
```
