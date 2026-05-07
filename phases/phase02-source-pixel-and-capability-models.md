═══════════════════════════════════════════════════════════════════════════════
⚠️  ONE TASK ONLY - THEN STOP
═══════════════════════════════════════════════════════════════════════════════
This file: phases/phase02-source-pixel-and-capability-models.md

1. Find first unchecked task in this phase file
2. Read the referenced section in PLAN.md and any external links provided
3. Complete task (Implementation + Tests + Analyzer)
4. Visual Verification: Run Golden tests and MANUALLY INSPECT outputs (if applicable)
5. Mark the task complete
6. STOP

Phase complete → mark the corresponding phase item in root TODO.md.
All phases complete → output: <promise>ALL_DONE</promise>
═══════════════════════════════════════════════════════════════════════════════

# Phase 2: Source, Pixel, and Capability Models

Purpose: define the typed, web-safe data model that every codec, operation, and IO adapter will use.

Relevant plan links:

- Plan: [Target Dart Architecture](../PLAN.md#4-target-dart-architecture)
- Plan: [Public API Shape](../PLAN.md#43-public-api-shape)
- Plan: [Processing Model](../PLAN.md#46-processing-model)

External references:

- Ref: [Dart class modifiers](https://dart.dev/language/class-modifiers)
- Ref: [Dart typed data](https://api.dart.dev/stable/dart-typed_data/dart-typed_data-library.html)
- Ref: `sharp_clone/lib/index.d.ts`

## Checklist (Every Task)

### Pre-Implementation
- [x] Read ONLY referenced PLAN.md sections (scan headers first)
- [x] Review external links/docs provided in task
- [x] Identify edge cases

### Implementation
- [x] Correct file location
- [x] Follows project patterns
- [x] <300 lines/file (split if larger)
- [x] Dartdoc on public APIs

### Analysis
- [x] `dart analyze lib/` - clean
- [x] `dart format lib/ test/`
- [x] `dart analyze test/` - clean

### Tests
- [x] Tests in correct file
- [x] <250 lines per test file (split by feature)
- [x] Test fixtures in `./test/fixtures/` where needed
- [x] Happy path + edge cases + errors
- [x] `flutter test test/<file>.dart` or `dart test test/<file>.dart` - all pass
- [x] Goldens verified (if visual)

### Compliance
- [x] Re-read relevant PLAN.md section
- [x] All requirements implemented
- [x] Edge cases handled

### Git
- [x] `git diff` - only task-related changes
- [x] `git commit -m "feat(<scope>): <task>"`

### Post
- [x] Issues found → add tasks (don't fix)
- [x] Mark the task complete
- [x] STOP

## Tasks

- [x] **2.1 Implement domain exceptions**
  - Plan: [Public API Shape](../PLAN.md#43-public-api-shape)
  - Ref: [Dart error handling](https://dart.dev/language/error-handling)
  - Add `lib/src/api/exceptions.dart`.
  - Define typed exceptions for processing, invalid input, unsupported codecs, limits, validation, and cancellation.
  - Test messages, causes, and equality behavior where applicable.
- [x] **2.2 Implement image source sealed classes**
  - Plan: [Constructor and Input](../PLAN.md#31-constructor-and-input)
  - Ref: [Dart sealed classes](https://dart.dev/language/class-modifiers#sealed)
  - Add `lib/src/source/image_source.dart` and source-specific files.
  - Support bytes, byte buffer, byte data, stream, raw pixels, generated images, and future text descriptors.
  - Test empty input, byte offset handling, and stream size limits.
- [x] **2.3 Implement raw pixel model**
  - Plan: [Pixel and Metadata Model](../PLAN.md#53-pixel-and-metadata-model)
  - Ref: `sharp_clone/lib/input.js`
  - Add `RawPixels`, `PixelDepth`, `ChannelCount`, `PixelLayout`, and premultiplication state.
  - Validate width, height, channels, page height, byte length, and typed data depth.
  - Test valid and invalid raw layouts.
- [x] **2.4 Implement color and pixel value types**
  - Plan: [Channel and Color APIs](../PLAN.md#36-channel-and-color-apis)
  - Ref: [Dart extension types](https://dart.dev/language/extension-types)
  - Add `RgbaColor`, grayscale helpers, and color parsing policy.
  - Avoid raw maps in public APIs.
  - Test clamping, alpha defaults, and invalid color input.
- [x] **2.5 Implement pixel image and frame models**
  - Plan: [Pixel and Metadata Model](../PLAN.md#53-pixel-and-metadata-model)
  - Ref: `sharp_clone/src/common.h`
  - Add `PixelImage` and `ImageFrame` abstractions with dimensions, format, frame delay, and pixel storage.
  - Preserve immutable public views with controlled internal mutation for processing.
  - Test frame count, dimensions, and defensive copies.
- [x] **2.6 Implement format and capability models**
  - Plan: [Format and Codec Surface](../PLAN.md#32-format-and-codec-surface)
  - Ref: `sharp_clone/lib/index.d.ts`
  - Add `ImageFormat`, `CodecSupport`, and package capability types.
  - Include known upstream format identifiers and explicit unsupported states.
  - Test capability lookup and unsupported messaging.
- [x] **2.7 Implement immutable pipeline shell**
  - Plan: [Processing Model](../PLAN.md#46-processing-model)
  - Ref: `sharp_clone/lib/constructor.js`
  - Add `ImagePipeline` with source, options, operation list, and immutable chain methods for no-op placeholders.
  - Add `clone` semantics as a branch over the same source and operation list.
  - Test immutability and operation ordering.

## Checklist (Every Task)

### Pre-Implementation
- [x] Read ONLY referenced PLAN.md sections (scan headers first)
- [x] Review external links/docs provided in task
- [x] Identify edge cases

### Implementation
- [x] Correct file location
- [x] Follows project patterns
- [x] <300 lines/file (split if larger)
- [x] Dartdoc on public APIs

### Analysis
- [x] `dart analyze lib/` - clean
- [x] `dart format lib/ test/`
- [x] `dart analyze test/` - clean

### Tests
- [x] Tests in correct file
- [x] <250 lines per test file (split by feature)
- [x] Test fixtures in `./test/fixtures/` where needed
- [x] Happy path + edge cases + errors
- [x] `flutter test test/<file>.dart` or `dart test test/<file>.dart` - all pass
- [x] Goldens verified (if visual)

### Compliance
- [x] Re-read relevant PLAN.md section
- [x] All requirements implemented
- [x] Edge cases handled

### Git
- [x] `git diff` - only task-related changes
- [x] `git commit -m "feat(<scope>): <task>"`

### Post
- [x] Issues found → add tasks (don't fix)
- [x] Mark the task complete
- [x] STOP

═══════════════════════════════════════════════════════════════════════════════
AGAIN: ONE TASK ONLY - THEN STOP. 
When this phase is complete, mark the corresponding phase item in root TODO.md.
Output <promise>ALL_DONE</promise> only when every root phase and phase-file task is checked.
═══════════════════════════════════════════════════════════════════════════════
