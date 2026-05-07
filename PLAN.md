# dsharp Pure Dart Image Processing Port Plan

## 1. Scope, Identity, and Non-Negotiables

### 1.1 Package Identity

- Source package: `sharp`, cloned read-only at `sharp_clone/`.
- Source repository: `https://github.com/lovell/sharp`.
- Source version observed in `sharp_clone/package.json`: `0.34.5`.
- Target Dart package: `dsharp`, located at `packages/dsharp/`.
- Target repository URL currently scaffolded as a placeholder: `https://github.com/mike-diarmid/dsharp`.
- License owner for this repository: `Mike Diarmid`.
- Target license: Apache 2.0 in root `LICENSE`.

### 1.2 User Requirements

- Implement in pure Dart.
- Do not use native bindings, FFI, Node bindings, platform binaries, shelling out to external tools, or bundled WASM/native image engines.
- The core public library must not rely on `dart:io`.
- The package must support web-safe inputs such as `Uint8List`, `ByteBuffer`, `ByteData`, typed lists, and `Stream<List<int>>`.
- Native Dart IO should be supported through an optional adapter library that imports `dart:io`, not through the main `dsharp.dart` entrypoint.
- Behavior parity is the goal. Source-code parity is not the goal.

### 1.3 Clean-Room and Naming Rules

- Treat `sharp_clone/` as read-only behavioral reference material.
- Do not copy upstream JS, C++, tests, docs, comments, or fixture bytes into tracked package code unless a later licensing review explicitly records why copying is allowed and needed.
- Use upstream source, generated docs, tests, and fixtures to discover public behavior, validation rules, edge cases, and expected outputs.
- Implementation code, code comments, API docs, examples, and package internals must not mention the source package name.
- The only public mention of the source package name is the short inspiration/compatibility blurb in `README.md`, which is symlinked from the repository root to `packages/dsharp/README.md`.
- Prefer Dart-native names and typed APIs over JS compatibility spellings. Add compatibility aliases only when they materially improve migration.

### 1.4 Feasibility Boundary

The source package is a JavaScript facade over a native `libvips` pipeline. A pure Dart, web-safe package cannot transparently reuse that engine. Full parity therefore requires a staged reimplementation of:

- Image format sniffing, decoding, encoding, metadata reading/writing, and animated/multi-page frame handling.
- Pixel buffers and color/depth models.
- Geometry, resampling kernels, filtering, color/channel operations, compositing, and output packaging.
- Security limits for untrusted image data.
- Golden fixture, fuzz, and performance infrastructure.

Features that depend on native-only ecosystems in the source package, such as OpenSlide, ImageMagick/Magick loaders, PDF rasterization, native Pango text rendering, AVIF/HEIF, JP2, and JXL, must be explicitly represented in the support matrix. They must report `unsupported` until a pure Dart implementation or pure Dart dependency exists.

## 2. Current Workspace State

### 2.1 Root Files

- `pubspec.yaml` defines the private melos workspace `dsharp_workspace`.
- `melos.yaml` includes `packages/**` and scripts for `analyze`, `format`, `test`, and `coverage`.
- `analysis_options.yaml` enables strict casts, strict inference, strict raw types, `public_member_api_docs`, and related lint rules.
- `DART_GUIDELINES.md` requires strong typing, named parameters, immutable data where practical, Dart 3 sealed classes and class modifiers where appropriate, and no casual `dynamic`.
- `LICENSE` is Apache 2.0.
- `README.md` is a symlink to `packages/dsharp/README.md`.
- `.gitignore` ignores `sharp_clone/`, `.dart_tool/`, `.melos_tool/`, `build/`, `coverage/`, and `doc/api/`.
- `.github/workflows/ci.yml` runs `dart pub get`, `dart run melos bootstrap`, format, analyze, and tests.
- `.github/ISSUE_TEMPLATE/*` and `.github/PULL_REQUEST_TEMPLATE.md` exist and should be expanded as the package matures.

### 2.2 Package Files

- `packages/dsharp/pubspec.yaml` contains the target package metadata and no
  runtime dependencies. Only dev dependencies are allowed.
- `packages/dsharp/lib/dsharp.dart` exports the web-safe core API.
- `packages/dsharp/test/dsharp_test.dart` verifies package identity and
  capability behavior.
- `packages/dsharp/example/README.md` and `packages/dsharp/benchmark/README.md`
  describe runnable examples and benchmark commands.
- `packages/dsharp/CHANGELOG.md` starts at `0.0.0`.

### 2.3 Upstream Reference Files Inspected

- Public API and types: `sharp_clone/lib/index.d.ts`.
- JS facade modules: `sharp_clone/lib/index.js`, `constructor.js`, `input.js`, `resize.js`, `composite.js`, `operation.js`, `colour.js`, `channel.js`, `output.js`, `utility.js`, `is.js`, `libvips.js`, `sharp.js`.
- Native pipeline and structures: `sharp_clone/src/common.h`, `common.cc`, `pipeline.h`, `pipeline.cc`, `operations.h`, `operations.cc`, `metadata.*`, `stats.*`, `utilities.*`, `sharp.cc`.
- Docs: `sharp_clone/docs/src/content/docs/api-*.md`, `performance.md`, `install.md`, and changelog files.
- Tests: `sharp_clone/test/unit.mjs`, `sharp_clone/test/unit/*.js`, `sharp_clone/test/types/sharp.test-d.ts`.
- Benchmarks: `sharp_clone/test/bench/perf.js`, `parallel.js`, `random.js`.
- Fixtures: `sharp_clone/test/fixtures/**`, including source and expected images.

## 3. Upstream Feature Inventory

### 3.1 Constructor and Input

Reference: `sharp_clone/lib/constructor.js`, `sharp_clone/lib/input.js`, `sharp_clone/docs/src/content/docs/api-constructor.md`, `sharp_clone/test/unit/io.js`.

Observed behavior:

- Constructor accepts no input for stream-style pipelines, a single input, or an array of inputs to join.
- Input forms include filesystem path strings, Node `Buffer`, `ArrayBuffer`, typed arrays, raw pixel arrays, create descriptors, text descriptors, and image arrays.
- Options include `failOn`, deprecated `failOnError`, `limitInputPixels`, `unlimited`, `autoOrient`, `sequentialRead`, `density`, `ignoreIcc`, `pages`, `page`, `animated`, `raw`, `create`, `text`, `join`, `tiff`, `svg`, `pdf`, `openSlide`, and `jp2`.
- Raw input requires width, height, and channels and supports depth inference from typed array class, premultiplication, and page height.
- Create input supports width, height, 3 or 4 channels, background, Gaussian noise, and page height.
- Text input supports text, font, font file, width, height, alignment, justification, DPI, RGBA, spacing, and wrapping.
- Join input supports across, animated, shim, background, horizontal alignment, and vertical alignment.
- Validation errors are immediate for invalid arguments and async for decode/process failures.

Dart target:

- Main library accepts `ImageSource.bytes(Uint8List)`, `ImageSource.byteBuffer(ByteBuffer)`, `ImageSource.byteData(ByteData)`, `ImageSource.stream(Stream<List<int>>)`, `ImageSource.raw(RawPixels)`, `ImageSource.create(CreateImage)`, and `ImageSource.text(TextImageRequest)` when text rendering is implemented.
- Main library must not accept filesystem paths as generic strings. File input belongs in `dsharp_io.dart`.
- `Stream<List<int>>` may buffer in phase 1 but must enforce byte limits and expose a future streaming decoder path.
- Raw pixel inputs must be typed via `RawPixels`, `PixelDepth`, `ChannelCount`, `PixelLayout`, and `Premultiplication`.
- Constructor options become typed `DecodeOptions`, `InputSafetyLimits`, and format-specific input option classes.

### 3.2 Format and Codec Surface

Reference: `sharp_clone/lib/index.d.ts`, `sharp_clone/lib/output.js`, `sharp_clone/src/common.h`, `sharp_clone/docs/src/content/docs/api-output.md`, `sharp_clone/docs/src/content/docs/install.md`.

Observed format names:

- `jpeg`, `jpg`, `png`, `webp`, `gif`, `avif`, `heif`, `tiff`, `tif`, `jp2`, `jxl`, `raw`, `svg`, `pdf`, `openslide`, `magick`, `dcraw`, `exr`, `fits`, `ppm`, `rad`, `v`, `dz`, and `input`.
- Source package exposes runtime `format` support based on native loader/saver availability.
- Prebuilt native support focuses on JPEG, PNG, WebP, AVIF, TIFF, GIF, and SVG input. Some formats require global native libraries.
- WebAssembly support in the source package is experimental, browser use is unsupported, native text rendering is unsupported, and tile output is unsupported.

Dart target support matrix:

- Tier 1 required for the first useful package: raw pixels, PNG read/write, JPEG read/write, GIF read/write including animation where supported by the selected pure Dart backend, TIFF read/write where backend support is adequate, and WebP read if pure Dart support is available.
- Tier 2: WebP write, APNG, ICC/EXIF/XMP preservation, animated frame timing/looping, deep zoom tile packaging, and color-management accuracy.
- Tier 3 unsupported until pure Dart implementations exist: AVIF, HEIF/HEIC, JP2/JPEG 2000, JXL/JPEG XL, PDF rasterization, OpenSlide, Magick, DCRAW/RAW camera formats, FITS, RAD, and complete SVG rasterization.
- The public API must expose `CodecSupport` and `FormatRegistry` so unsupported formats fail predictably with `UnsupportedCodecException` rather than pretending support exists.
- Runtime codec dependencies are not permitted. PNG, baseline JPEG, GIF, and
  TIFF behavior must stay behind first-party codec interfaces. WebP remains
  explicitly unsupported until a complete first-party decoder exists.

### 3.3 Metadata and Statistics

Reference: `sharp_clone/lib/index.d.ts`, `sharp_clone/src/metadata.cc`, `sharp_clone/src/stats.cc`, `sharp_clone/docs/src/content/docs/api-input.md`, `sharp_clone/test/unit/metadata.js`, `sharp_clone/test/unit/stats.js`.

Observed metadata fields:

- Format, encoded size, width, height, auto-oriented width/height, color space, channel count, pixel depth, density, chroma subsampling, progressive/palette flags, bits per sample, pages, page height, loop, frame delay, primary page, profile presence, alpha presence, EXIF, ICC, IPTC, XMP, XMP as string, Photoshop TIFF tag, HEIF compression, background, levels, sub-IFDs, resolution unit, Magick format, and comments.

Observed statistics:

- Per-channel min, max, sum, squared sum, mean, standard deviation, min/max coordinates.
- Global opacity, entropy, sharpness, and dominant RGB color.

Dart target:

- Public immutable `ImageMetadata`, `FrameMetadata`, `ImageProfileMetadata`, `ImageComment`, `ChannelStats`, and `ImageStats` classes.
- Metadata parsing must work without full pixel decode when possible, but can fall back to decode in early phases.
- Metadata writing is separate from metadata reading and implemented only for formats that can preserve/update it reliably.
- Stats are computed from decoded pixels with deterministic rounding rules and documented complexity.

### 3.4 Resize, Extract, Extend, and Trim

Reference: `sharp_clone/lib/resize.js`, `sharp_clone/src/pipeline.cc`, `sharp_clone/docs/src/content/docs/api-resize.md`, `sharp_clone/test/unit/resize*.js`, `extract.js`, `extend.js`, `trim.js`.

Observed behavior:

- `resize(width, height, options)` and `resize(options)` support width, height, fit, position/gravity/strategy, background, kernel, `withoutEnlargement`, `withoutReduction`, and `fastShrinkOnLoad`.
- Fit modes: cover, contain, fill, inside, outside.
- Position/gravity values: north, northeast, east, southeast, south, southwest, west, northwest, center/centre, plus object-position style values.
- Crop strategies: entropy and attention.
- Kernels: nearest, linear, cubic, mitchell, lanczos2, lanczos3, mks2013, mks2021.
- Only one resize takes effect; previous resize options are ignored.
- Extract can happen before resize, after resize, or both depending on call order.
- Extend supports a single pixel count or per-edge counts, background/copy/repeat/mirror modes, and multi-page handling.
- Trim removes borders similar to a background color with threshold and line-art options and reports trim offsets.

Dart target:

- Implement deterministic `ResizeGeometry` first, with unit tests for every fit, position, and rounding case before pixel resampling.
- Implement kernels as pure functions with explicit support radius and tests against small synthetic images.
- Implement crop strategy scoring as separate entropy and attention modules.
- Represent extraction and resize order explicitly in an immutable operation list.
- `fastShrinkOnLoad` becomes an optimization hint only. It must never change output dimensions or correctness.

### 3.5 Operations

Reference: `sharp_clone/lib/operation.js`, `sharp_clone/src/operations.h`, `sharp_clone/src/operations.cc`, `sharp_clone/test/unit/{rotate,affine,sharpen,median,blur,dilate,erode,gamma,negate,normalize,clahe,convolve,threshold,boolean,linear,recomb,modulate,unflatten}.js`.

Observed operations:

- Geometry: rotate, auto-orient, flip, flop, affine.
- Filters: sharpen, median, blur, dilate, erode, convolve.
- Alpha/color math: flatten, unflatten, gamma, negate, normalise/normalize, CLAHE, threshold, linear, recomb, modulate.
- Boolean operations: per-image boolean with operand and per-channel `bandbool`.
- Validation covers numeric ranges, matrix shape, booleans, kernels, and unsupported multi-page behavior.

Dart target:

- Each operation gets a typed options class and a dedicated module under `lib/src/operations/`.
- Pixel operations work against a common `PixelImage` abstraction rather than backend-specific objects.
- Use integer fast paths for 8-bit images and floating-point paths where color depth requires it.
- Preserve alpha premultiplication rules and document when operations treat alpha separately.
- Implement operation-order tests from synthetic fixtures before large golden fixture parity.

### 3.6 Channel and Color APIs

Reference: `sharp_clone/lib/channel.js`, `sharp_clone/lib/colour.js`, `sharp_clone/docs/src/content/docs/api-channel.md`, `api-colour.md`, `sharp_clone/test/unit/{alpha,extractChannel,joinChannel,bandbool,tint,colourspace}.js`.

Observed behavior:

- Channel APIs: remove alpha, ensure alpha, extract channel, join channels, band boolean.
- Color APIs: tint, greyscale/grayscale, pipeline colourspace/colorspace, output colourspace/colorspace.
- Color spaces include sRGB, RGB, RGB16, CMYK, LAB, HSV, XYZ, and others through native `libvips`.
- ICC behavior is intertwined with metadata and output conversion.

Dart target:

- Public enum names should use American-neutral Dart naming where possible, with aliases only if helpful: `ColorSpace`, `toColorSpace`, `pipelineColorSpace`, and `greyscale`/`grayscale` aliases.
- Implement sRGB, linear RGB, grayscale, alpha, and basic CMYK conversions first.
- Mark LAB/XYZ/ICC-managed conversions as unsupported until a pure Dart color-management path is implemented and verified.
- Add explicit `Color` and `RgbaColor` value types rather than accepting loosely typed maps.

### 3.7 Compositing

Reference: `sharp_clone/lib/composite.js`, `sharp_clone/docs/src/content/docs/api-composite.md`, `sharp_clone/test/unit/composite.js`.

Observed behavior:

- Ordered overlays.
- Inputs may be bytes, path, create, text, or raw descriptors.
- Placement by gravity or exact top/left offset. Top and left must be provided together.
- Tile option repeats overlay.
- Premultiplied option affects alpha handling.
- Blend modes: clear, source, over, in, out, atop, dest, dest-over, dest-in, dest-out, dest-atop, xor, add, saturate, multiply, screen, overlay, darken, lighten, colour-dodge/color-dodge, colour-burn/color-burn, hard-light, soft-light, difference, exclusion.

Dart target:

- Use `CompositeLayer` with typed `ImageSource`, `BlendMode`, `Gravity`, `Offset`, `isTiled`, and `isPremultiplied`.
- Implement Porter-Duff modes first, then artistic blend modes.
- Add alpha and premultiplication golden tests for every blend mode on tiny fixtures.

### 3.8 Output and Encoders

Reference: `sharp_clone/lib/output.js`, `sharp_clone/lib/index.d.ts`, `sharp_clone/docs/src/content/docs/api-output.md`, `sharp_clone/test/unit/{jpeg,png,webp,gif,tiff,avif,heif,jp2,jxl,raw,toFormat,toBuffer,tile,timeout}.js`.

Observed behavior:

- Output to file, buffer, or streams.
- Format can be inferred from file extension or explicitly set with `toFormat`, `jpeg`, `png`, `webp`, `gif`, `avif`, `heif`, `jp2`, `jxl`, `tiff`, or `raw`.
- Output options include quality, progressive/interlace, chroma subsampling, lossless, effort, palette, dithering, bit depth, compression, tiling, animation loop/delay, and force flags.
- Metadata controls include keep/set/merge EXIF, keep/set ICC profile, keep/set XMP, and `withMetadata`.
- Tile output supports deep zoom/image pyramids and zip containers.
- Timeout aborts processing.

Dart target:

- Main output APIs: `toBytes()`, `toBytesWithInfo()`, `toPixelImage()`, `metadata()`, and `stats()`.
- IO output APIs: `writeToFile(File)` and path convenience methods only in `dsharp_io.dart`.
- Encoders must have typed option classes: `JpegEncoderOptions`, `PngEncoderOptions`, `GifEncoderOptions`, `TiffEncoderOptions`, `WebpEncoderOptions`, `RawEncoderOptions`, and unsupported placeholder options for future formats.
- `timeout` should use cooperative cancellation via `CancellationToken` and operation checkpoints rather than isolate termination.
- Raw output returns typed raw pixels and optional encoded byte views.

### 3.9 Utility Surface

Reference: `sharp_clone/lib/utility.js`, `sharp_clone/src/utilities.cc`, `sharp_clone/docs/src/content/docs/api-utility.md`, `sharp_clone/test/unit/util.js`, `libvips.js`.

Observed behavior:

- `format`, `versions`, `interpolators`, `gravity`, `strategy`, `kernel`, `fit`, and `bool` constants.
- `cache`, `concurrency`, `counters`, `simd`, `block`, and `unblock`.
- Runtime support is tied to native engine capabilities.

Dart target:

- Expose `DsharpCapabilities` or `ImageProcessingCapabilities` with codec and operation support.
- Expose enum constants instead of JS objects.
- `cache` is not a global native operation cache in phase 1. Prefer explicit caches inside codec/operation internals.
- `concurrency` and `counters` only make sense if isolate-based processing is added. Until then, provide no global mutable concurrency API or expose read-only single-worker counters.
- `simd` is unsupported in pure Dart. Do not expose a misleading toggle.
- `block`/`unblock` become an optional `OperationPolicy` passed to a pipeline, not global process state.

### 3.10 Tests, Fixtures, and Benchmarks

Reference: `sharp_clone/test/unit.mjs`, `sharp_clone/test/unit/*.js`, `sharp_clone/test/fixtures/**`, `sharp_clone/test/bench/*.js`.

Observed categories:

- Unit categories cover median, tile, stats, negate, JP2, CLAHE, noise, convolve, join, text, WebP, JPEG, channel insertion, alpha, dilation, erosion, buffer output, modulate, trim, format selection, failOn, channel extraction, rotation, extraction, normalization, JXL, AVIF, timeout, unflatten, tint, boolean, sharpen, utilities, HEIF, raw, fixtures, native binary behavior, recomb, TIFF, gamma, linear, metadata, composite, affine, colorspace, threshold, resize, extend, clone, PNG, GIF, SVG, resize-contain, blur, resize-cover, IO, and bandbool.
- Benchmarks compare JPEG and PNG resize throughput, random dimension resizing, and parallel calls.
- Fixture tree contains source images, corrupted/truncated examples, profiles, animated images, raw-ish fixtures, and many expected outputs.

Dart target:

- Do not copy fixtures into tracked files by default. Generate independent synthetic fixtures first.
- For compatibility checks, tests may read ignored `sharp_clone/test/fixtures/**` locally when present, and CI can skip those tests unless fixtures are supplied through a separate legal review artifact.
- Add deterministic generated fixtures under `packages/dsharp/test/fixtures/generated/`.
- Add golden outputs for tiny inputs where expected bytes or pixels can be generated from first principles.
- Add property/fuzz tests for geometry, pixel bounds, parser robustness, commutativity/idempotency where applicable, and malformed input handling.

## 4. Target Dart Architecture

### 4.1 Library Entrypoints

- `packages/dsharp/lib/dsharp.dart`: web-safe public API. Allowed core SDK imports include `dart:async`, `dart:math`, `dart:typed_data`, and other web-safe SDK libraries. This file and everything it exports must not import `dart:io`.
- `packages/dsharp/lib/dsharp_io.dart`: optional native IO adapter. This entrypoint may import `dart:io` and must document that it is not available on web.
- `packages/dsharp/lib/src/**`: private implementation. Keep files under 300 lines by splitting by feature.

### 4.2 Proposed Source Layout

```text
packages/dsharp/lib/
  dsharp.dart
  dsharp_io.dart
  src/
    api/
      capabilities.dart
      exceptions.dart
      image_pipeline.dart
      image_result.dart
      operation_policy.dart
    source/
      image_source.dart
      byte_source.dart
      raw_pixels.dart
      generated_source.dart
      stream_source.dart
    io/
      file_source.dart
      file_sink.dart
    pixels/
      pixel_image.dart
      pixel_depth.dart
      pixel_format.dart
      color.dart
      color_space.dart
      frame.dart
    codecs/
      codec.dart
      codec_registry.dart
      format.dart
      image_backend.dart
      png_codec.dart
      jpeg_codec.dart
      gif_codec.dart
      tiff_codec.dart
      webp_codec.dart
      raw_codec.dart
      unsupported_codec.dart
    pipeline/
      pipeline_operation.dart
      pipeline_executor.dart
      operation_order.dart
      cancellation.dart
    geometry/
      resize_geometry.dart
      gravity.dart
      region.dart
      affine_matrix.dart
    resize/
      kernels.dart
      resampler.dart
      entropy_crop.dart
      attention_crop.dart
    operations/
      alpha.dart
      boolean.dart
      channel.dart
      color_adjust.dart
      composite.dart
      convolution.dart
      filters.dart
      transform.dart
    metadata/
      metadata.dart
      exif.dart
      icc.dart
      xmp.dart
      stats.dart
```

### 4.3 Public API Shape

The core API should be immutable and chainable:

```dart
final result = await ImagePipeline.fromBytes(inputBytes)
    .resize(width: 320, height: 240, fit: ResizeFit.cover)
    .flatten(background: const RgbaColor.rgb(255, 255, 255))
    .png(const PngEncoderOptions(compressionLevel: 6))
    .toBytesWithInfo();
```

Required public types:

- `ImagePipeline`: immutable chain builder and execution owner.
- `ImageSource`: sealed class for bytes, streams, raw pixels, generated images, text images, and future platform adapters.
- `PixelImage`: decoded frame or image buffer with immutable metadata and controlled mutable internal implementation.
- `RawPixels`: typed raw input/output plus width, height, channels, depth, premultiplication, and page height.
- `ImageFormat`: enum or extension type for known formats and unknown/custom identifiers.
- `CodecSupport`: input/output support, animation support, metadata support, and web availability.
- `ImageMetadata`, `OutputInfo`, `ImageStats`, `ChannelStats`.
- Options classes for every public operation and encoder.
- Domain exceptions: `ImageProcessingException`, `InvalidImageException`, `UnsupportedCodecException`, `ImageLimitException`, `OperationValidationException`, and `ImageCancellationException`.

### 4.4 IO Adapter Shape

`dsharp_io.dart` must be the only public library that imports `dart:io`.

```dart
import 'package:dsharp/dsharp.dart';
import 'package:dsharp/dsharp_io.dart';

final result = await ImagePipeline.fromFile(File('input.jpg'))
    .resize(width: 720)
    .jpeg(const JpegEncoderOptions(quality: 80))
    .writeToFile(File('output.jpg'));
```

Rules:

- Main library accepts bytes and streams, not file paths.
- IO extensions delegate to `ImageSource.bytes` or streaming sources internally.
- Tests must assert that `packages/dsharp/lib/dsharp.dart` and all transitively exported core files do not import `dart:io`.

### 4.5 Dependency Strategy

- Do not add runtime dependencies. The package must remain usable with only the
  Dart SDK at runtime.
- `package:image`, `archive`, `xml`, `vector_math`, and similar packages are not
  allowed in `dependencies`.
- Dev dependencies are allowed for tests, lints, and benchmarks.
- Keep codec, metadata, compression, archive, and matrix behavior behind
  package-local interfaces so future in-house implementations can replace
  internals without public API churn.

### 4.6 Processing Model

- Decode input into `PixelImage` frames.
- Normalize metadata and safety limits before pixel operations.
- Execute a typed operation list in deterministic order.
- Encode output through a selected codec, returning `Uint8List` and `OutputInfo`.
- Support cancellation through cooperative checkpoints.
- Avoid global mutable settings except read-only capabilities. Per-pipeline options are preferred.

## 5. Feature Implementation Plan

### 5.1 Foundation

- Replace the empty public entrypoint with typed exports.
- Add package docs that explain pure Dart scope, web-safe core, optional IO adapter, and unsupported codec semantics.
- Add analyzer guard tests for no `dart:io` imports in the core library.
- Add source file size checks and test file size checks.
- Replace scaffold smoke test with package identity and capability tests.

### 5.2 Codec Foundation

- Implement `ImageFormat` sniffing from magic bytes and optional metadata.
- Implement `Codec` and `CodecRegistry` with static capability data.
- Add raw pixel codec first because it is deterministic and does not depend on compressed formats.
- Implement first-party raw, PNG, baseline JPEG, GIF, and TIFF codec paths
  without runtime dependencies. Keep WebP registered as unsupported until a
  complete first-party decoder exists.
- Add unsupported codec implementations for AVIF, HEIF, JP2, JXL, PDF, OpenSlide, Magick, DCRAW, FITS, RAD, SVG rasterization, and deep zoom until pure Dart support exists.
- Add malformed input tests and input size limits before enabling decode APIs.

### 5.3 Pixel and Metadata Model

- Implement `PixelImage`, `ImageFrame`, `PixelFormat`, `PixelDepth`, and channel-count validation.
- Support 8-bit RGB/RGBA/grayscale first, then 16-bit and floating-point paths.
- Implement metadata classes and a metadata extraction pipeline.
- Preserve unknown metadata chunks as opaque typed values only where safe.
- Add stats computation with deterministic rounding and tests for tiny known images.

### 5.4 Geometry and Resampling

- Implement `Region`, `Gravity`, `Position`, `ResizeFit`, `ResizeKernel`, and `ResizeGeometry`.
- Add exact output dimension tests for fixed width, fixed height, cover, contain, fill, inside, outside, `withoutEnlargement`, and `withoutReduction`.
- Implement nearest, linear, cubic, Mitchell, Lanczos 2, and Lanczos 3 kernels first.
- Add MKS kernels after baseline parity tests exist.
- Implement pre/post extraction order and operation list semantics.

### 5.5 Pixel Operations

- Implement alpha operations: ensure alpha, remove alpha, flatten, unflatten, premultiplication helpers.
- Implement channel extraction/join and band boolean.
- Implement rotate/auto-orient, flip, flop, and affine transform.
- Implement filters: blur, sharpen, median, convolve, dilate, erode.
- Implement color math: grayscale, tint, gamma, negate, normalize, threshold, linear, recomb, modulate, and CLAHE.
- Implement color-space conversions in stages: sRGB/grayscale first, CMYK next, ICC/LAB/XYZ later.

### 5.6 Composite and Animation

- Implement `CompositeLayer` and placement by offset/gravity.
- Implement Porter-Duff blend modes first.
- Implement artistic blend modes with golden tests.
- Implement tile/repeat overlays.
- Represent animated images as ordered frames with delay, loop, page height, and frame metadata.
- Implement multi-frame restrictions for operations that cannot safely handle animation yet.

### 5.7 Output, Metadata Writing, and IO

- Implement `toBytes`, `toBytesWithInfo`, `toPixelImage`, `metadata`, and `stats`.
- Implement format option methods: `jpeg`, `png`, `gif`, `tiff`, `webp`, `raw`, and `toFormat`.
- Add `dsharp_io.dart` file read/write extensions.
- Implement metadata preservation/writing only for formats with verified pure Dart support.
- Add deep zoom tile output only after an in-house archive/container writer and
  codec support exist.

### 5.8 Tests and Fixtures

- Build independent generated fixtures first: single pixels, 2x2 RGBA, gradients, alpha checkerboards, tiny animated frames, raw buffers, and malformed byte sequences.
- Add unit tests per public type and algorithmic primitive.
- Add integration tests for full pipelines such as decode -> resize -> encode, create -> composite -> encode, raw -> operation -> raw.
- Add property tests for geometry invariants, crop bounds, alpha ranges, kernel normalization, operation idempotency where applicable, and malformed input robustness.
- Add optional compatibility tests that read `sharp_clone/test/fixtures/**` when present and compare dimensions, metadata, pixels, or perceptual deltas without copying fixture files.
- Add coverage thresholds and CI reporting.

### 5.9 Benchmarks

- Add benchmark scenarios matching the upstream benchmark intent:
  - JPEG decode -> resize 2725x2225 to 720x588 -> JPEG encode quality 80.
  - PNG RGBA decode -> premultiply -> resize 2048x1536 to 720x540 -> PNG encode.
  - Random dimension resize 320 to 960.
  - Parallel or batched execution if isolate support is added.
- Track throughput, memory allocations, peak memory, and output dimensions.
- Do not require matching native `libvips` throughput. The target is pure Dart correctness first, then predictable performance.

### 5.10 Documentation and Release Polish

- README must explain:
  - Pure Dart and web-safe core.
  - Optional native IO entrypoint.
  - Supported and unsupported format matrix.
  - Common pipeline examples.
  - Security limits for untrusted input.
- Add examples for bytes, stream, raw pixels, generated image, optional file IO, resize, composite, metadata, and stats.
- Add pub.dev topics and screenshots/assets only if useful.
- Expand CONTRIBUTING with clean-room policy, fixture policy, dependency review, and format support criteria.
- Expand CI with coverage, fixture-skipping behavior, doc generation, publish dry-run, and benchmark smoke checks.
- Replace placeholder target repository URL before publishing.

## 6. Testing and Verification Strategy

### 6.1 Required Checks

- `dart run melos bootstrap`
- `dart run melos run format`
- `dart run melos run analyze`
- `dart run melos run test`
- Package-specific:
  - `dart analyze lib/`
  - `dart analyze test/`
  - `dart format lib/ test/`
  - `dart test`

### 6.2 Core Test Categories

- API shape tests for entrypoints, exports, and no `dart:io` leakage.
- Unit tests for every public options class and enum.
- Unit tests for format sniffing and codec support matrix.
- Unit tests for raw pixels and generated images.
- Unit tests for metadata and stats.
- Geometry tests for resize/extract/extend/trim.
- Pixel operation tests for every operation family.
- Encoder/decoder integration tests for every supported format.
- IO adapter tests behind VM-only tags.
- Web compatibility tests using `dart test -p chrome` once the in-house codecs
  are exercised in browser CI.
- Fuzz/property tests for parsers and pixel operations.
- Performance benchmarks under `packages/dsharp/benchmark/`.

### 6.3 Compatibility Fixtures

- Local optional tests may reference `sharp_clone/test/fixtures/**`.
- Any tracked fixture copied from upstream must be approved by an explicit licensing task first.
- Golden tests should use generated fixtures and independently computed expected pixels wherever possible.
- For lossy codecs, compare decoded pixels with tolerances and metadata/dimension assertions rather than encoded byte equality.

## 7. Security, Robustness, and Limits

- All decoders must enforce byte length, pixel count, frame count, dimensions, and recursion/chunk limits.
- Defaults should mirror the source package's intent: protect against memory exhaustion, with explicit opt-in for larger inputs.
- Malformed metadata should fail even when pixel `failOn` is permissive, unless a task explicitly documents safe best-effort behavior.
- Parser code must avoid unbounded allocation based on untrusted metadata.
- Expose clear exception types and messages that identify invalid parameters versus invalid image data versus unsupported features.
- Add regression tests for truncated/corrupt input, oversized dimensions, invalid raw layout, invalid frame/page settings, invalid colors, invalid matrices, and invalid format options.

## 8. Migration and Implementation Order

1. Foundation and package correctness.
2. Core source, byte, raw pixel, format, and capability models.
3. First-party raw/PNG/baseline JPEG/GIF/TIFF codec paths plus explicit WebP
   unsupported semantics.
4. Pixel image model, metadata, and stats.
5. Resize geometry and resampling.
6. Transform, color, channel, alpha, and filter operations.
7. Composite and animation.
8. Output APIs, encoder options, metadata writing, and optional IO adapter.
9. Compatibility fixtures, fuzzing, and performance benchmarks.
10. Documentation, CI polish, and publish readiness.

This order makes the web-safe boundary and type model hard to regress before large operation work starts.

## 9. Risks and Open Decisions

- Placeholder repository URL: replace `https://github.com/mike-diarmid/dsharp` with the real repository URL before publishing.
- Dependency choice: runtime dependencies are disallowed; codec and metadata
  support must be implemented in-house or remain explicitly unsupported.
- Exact parity tolerance: native `libvips` kernels and codecs will not always match pure Dart output byte-for-byte. The plan uses pixel/dimension tolerances where exact equality is unrealistic.
- Advanced codecs: AVIF, HEIF, JP2, JXL, PDF, OpenSlide, Magick, DCRAW, FITS, RAD, and SVG rasterization may remain unsupported for a long time without pure Dart implementations.
- Text rendering: native Pango behavior is out of scope for phase 1. A pure Dart text renderer needs separate design.
- Color management: ICC/LAB/XYZ parity is high risk and should not block raw/PNG/JPEG/resize usefulness.
- Performance: pure Dart correctness may be significantly slower than native `libvips`; benchmarks must track this without making native parity a release blocker.

## 10. Acceptance Criteria

- `packages/dsharp/lib/dsharp.dart` exports a useful pure Dart, web-safe image pipeline API with no `dart:io` dependency.
- `packages/dsharp/lib/dsharp_io.dart` provides optional native IO convenience without contaminating the core library.
- Public APIs are strongly typed and documented with Dartdoc.
- Supported codecs and operations are accurately reported through capabilities.
- Unsupported native-only features fail with explicit typed exceptions.
- Unit, integration, property/fuzz, optional compatibility, and benchmark scaffolds exist.
- CI runs format, analyze, tests, coverage, and publish dry-run checks.
- README and examples document byte/stream/raw inputs, optional IO usage, supported formats, unsupported formats, and security limits.
- `dart run melos run format`, `dart run melos run analyze`, and `dart run melos run test` pass.
