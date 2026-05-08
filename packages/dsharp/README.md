# dsharp

`dsharp` is a pure Dart image processing package for web-safe byte, stream,
raw-pixel, and generated-image workflows. It is inspired by `sharp`, but the
public API is Dart-first and the core library does not import `dart:io`.

Use `package:dsharp/dsharp.dart` on VM and web. Use
`package:dsharp/dsharp_io.dart` only when native file IO is available.

## Supported Today

- Inputs: encoded bytes, `ByteBuffer`, `ByteData`, bounded byte streams, raw
  pixels, decoded `PixelImage`, and generated solid/noise images.
- Codecs: raw plus first-party PNG, JPEG, GIF, TIFF, WebP, PNM, Radiance
  HDR/RGBE, and FITS support without runtime package dependencies. PNG,
  baseline/progressive/lossless JPEG, GIF, TIFF, WebP VP8 lossy
  static/animated, WebP VP8L lossless/near-lossless static/animated,
  PPM/PGM/PBM Netpbm, Radiance HDR/RGBE, FITS, and raw output are implemented.
  WebP metadata, VP8L, VP8 lossy, alpha, and animation decoding are implemented
  for supported bitstreams.
- Operations: resize, extract, extend, trim, flip, flop, rotate, affine,
  alpha/channel operations, filters, convolution, color math, sRGB/b-w
  colorspace conversion, boolean ops, compositing, tiling, frame-aware joins,
  EXIF auto-orient, encoded header metadata reads with XMP/EXIF/ICC payloads,
  and stats.
- Output: typed encoder options, `toBytes`, `toBytesWithInfo`,
  `toImageBytesResult`, format-specific chain methods, WebP animation loop and
  per-frame delay controls, `withMetadata`, and explicit/kept JPEG/PNG/WebP
  XMP/EXIF/ICC metadata writes,
  cancellation, timeout, and VM-only `writeToFile`.

Unsupported native-only or advanced formats such as AVIF, HEIF, JP2, JXL, PDF,
OpenEXR, OpenSlide, Magick, camera raw, native V, deep zoom, and SVG
rasterization fail with typed `UnsupportedCodecException`s.

## Examples

Bytes:

```dart
final png = await ImagePipeline.fromBytes(inputBytes)
    .resize(const ResizeOptions(width: 320))
    .png()
    .toBytes();
```

Stream:

```dart
final source = ImageSource.stream(byteStream, maxBytes: 10 * 1024 * 1024);
final info = await ImagePipeline.fromSource(source).metadata();
```

Raw pixels:

```dart
final raw = RawPixels(
  bytes: pixels,
  width: 64,
  height: 64,
  channels: ChannelCount.four,
);
final jpeg = await ImagePipeline.fromRawPixels(raw).jpeg().toBytes();
```

Composite:

```dart
final output = await ImagePipeline.fromRawPixels(base)
    .composite([
      CompositeLayer(image: PixelImage.fromRawPixels(overlay), left: 8, top: 8),
    ])
    .png()
    .toBytesWithInfo();
```

Metadata and stats:

```dart
final pipeline = ImagePipeline.fromBytes(inputBytes);
final metadata = await pipeline.metadata();
final stats = await pipeline.stats();
```

Native file IO:

```dart
import 'package:dsharp/dsharp_io.dart';

final pipeline = await imagePipelineFromPath('input.png');
await pipeline.resize(const ResizeOptions(width: 256)).png().writeToFile(
  File('output.png'),
);
```

More runnable examples live in `example/`.

## Security Limits

Use `InputSafetyLimits` with byte, stream, raw, decoded, and generated sources
for untrusted input. Raw pixel descriptors validate layout before processing.
Unsupported codecs, malformed images, invalid operations, and cancelled
pipelines throw typed `ImageProcessingException` subclasses.

## Development

```bash
dart pub get
dart run melos bootstrap
dart run melos run format
dart run melos run analyze
dart run melos run test
dart run melos run coverage
```
