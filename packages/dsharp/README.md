<p align="center">
<img src="https://raw.githubusercontent.com/Salakar/dart_sharp/main/packages/dsharp/assets/logo.png" alt="dsharp logo" width="160">
</p>
<h1 align="center">dsharp</h1>
<hr>

## Overview

`dsharp` is a pure Dart image processing package for web-safe byte, stream,
raw-pixel, generated-image, and optional file IO workflows. The core library
does not import `dart:io`.

Use `package:dsharp/dsharp.dart` on VM and web. Use
`package:dsharp/dsharp_io.dart` only when native file IO is available.

## Install

```bash
dart pub add dsharp
```

## Quick Example

```dart
final png = await ImagePipeline.fromBytes(inputBytes)
    .resize(const ResizeOptions(width: 320))
    .png()
    .toBytes();
```

## Supported Features

| Area | Support |
| --- | --- |
| Inputs | Encoded bytes, `ByteBuffer`, `ByteData`, bounded byte streams, raw pixels, decoded `PixelImage`, generated solid/noise images, and deterministic text image descriptors. |
| Core safety | Web-safe core entrypoint with no `dart:io`, typed exceptions, input byte/pixel limits, cancellation tokens, and output timeouts. |
| Decode | Raw, PNG, JPEG, GIF, TIFF, WebP, PPM/PGM/PBM Netpbm, Radiance HDR/RGBE, and FITS. |
| Encode | Raw, PNG, JPEG, GIF, TIFF, WebP, PPM/PGM/PBM Netpbm, Radiance HDR/RGBE, and FITS. |
| Animation | GIF and WebP frame metadata, delays, loops, retained canvas compositing, frame joins, and animated output paths. |
| Metadata | Encoded header metadata, image dimensions, pages/frames, density, orientation, alpha, comments, XMP, EXIF, ICC payload handling, and per-channel stats. |
| Geometry | Resize, fit modes, extract, extend, trim, flip, flop, rotate, affine transforms, crop strategies, and resampling kernels. |
| Pixel operations | Alpha/channel changes, grayscale, negate, normalize, gamma, tint, linear math, modulation, threshold, convolution, blur, sharpen, median, dilate, erode, and boolean operations. |
| Compositing | Ordered overlays, Porter-Duff and artistic blend modes, alpha handling, exact offsets, gravity placement, tiling, and multi-image joins. |
| Output APIs | `toBytes`, `toBytesWithInfo`, `toImageBytesResult`, format-specific chain methods, typed encoder options, and metadata write options. |
| VM-only IO | `imagePipelineFromFile`, `imagePipelineFromPath`, `ImageSource.file`, `writeToFile`, and `toFile` through `package:dsharp/dsharp_io.dart`. |

### Supported Format Matrix

| Format | Decode | Encode | Animation | Metadata |
| --- | --- | --- | --- | --- |
| Raw pixels | Yes | Yes | No | Yes |
| PNG | Yes | Yes | No | Yes |
| JPEG/JPG | Yes | Yes | No | Yes |
| GIF | Yes | Yes | Yes | Yes |
| TIFF/TIF | Yes | Yes | Multi-page | Yes |
| WebP | Yes | Yes | Yes | Yes |
| PPM/PGM/PBM | Yes | Yes | No | Yes |
| Radiance HDR/RGBE | Yes | Yes | No | Yes |
| FITS | Yes | Yes | No | Yes |

Unsupported native-only or advanced formats such as AVIF, HEIF, JP2, JXL, PDF,
OpenEXR, OpenSlide, Magick, camera raw, native V, deep zoom, and SVG
rasterization fail with typed `UnsupportedCodecException`s.

## Usage

### Bytes

```dart
final output = await ImagePipeline.fromBytes(inputBytes)
    .resize(const ResizeOptions(width: 320))
    .webp()
    .toBytesWithInfo();
```

### Stream

```dart
final source = ImageSource.stream(byteStream, maxBytes: 10 * 1024 * 1024);
final info = await ImagePipeline.fromSource(source).metadata();
```

### Raw Pixels

```dart
final raw = RawPixels(
  bytes: pixels,
  width: 64,
  height: 64,
  channels: ChannelCount.four,
);
final jpeg = await ImagePipeline.fromRawPixels(raw).jpeg().toBytes();
```

### Composite

```dart
final output = await ImagePipeline.fromRawPixels(base)
    .composite([
      CompositeLayer(image: PixelImage.fromRawPixels(overlay), left: 8, top: 8),
    ])
    .png()
    .toBytesWithInfo();
```

### Metadata and Stats

```dart
final pipeline = ImagePipeline.fromBytes(inputBytes);
final metadata = await pipeline.metadata();
final stats = await pipeline.stats();
```

### Metadata Writes

```dart
final output = await ImagePipeline.fromBytes(inputBytes)
    .withMetadata(
      MetadataWriteOptions(
        xmp: XmpMetadata.parse('<x:xmpmeta></x:xmpmeta>'),
        keepExif: true,
        keepIcc: true,
      ),
    )
    .png()
    .toBytes();
```

### Cancellation and Timeout

```dart
final token = CancellationToken();
final bytes = await ImagePipeline.fromBytes(inputBytes)
    .timeout(const Duration(seconds: 2))
    .resize(const ResizeOptions(width: 640))
    .jpeg()
    .toBytes(cancellationToken: token);
```

### Native File IO

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

## Contributing

See [CONTRIBUTING.md](https://github.com/Salakar/dart_sharp/blob/main/CONTRIBUTING.md).

## Development

```bash
dart pub get
dart run melos bootstrap
dart run melos run format
dart run melos run analyze
dart run melos run test
dart run melos run coverage
```

## Benchmark Results

| Scenario | Time |
| --- | ---: |
| `jpeg_decode_resize_encode` | 17728.39 us |
| `png_rgba_resize` | 8597.63 us |
| `random_dimension_resize` | 5838.42 us |
| `raw_operation_chain` | 5113.07 us |
| `composite_over` | 5156.09 us |

## License

[Apache 2.0](LICENSE)
