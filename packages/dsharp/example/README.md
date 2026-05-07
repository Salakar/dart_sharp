# Examples

- `web_safe.dart` uses only `package:dsharp/dsharp.dart` and is suitable for VM
  or web-compatible code.
- `io_adapter.dart` imports `package:dsharp/dsharp_io.dart` for native file IO.

Run from `packages/dsharp/`:

```sh
dart run example/web_safe.dart
dart run example/io_adapter.dart
```
