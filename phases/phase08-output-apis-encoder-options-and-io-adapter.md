═══════════════════════════════════════════════════════════════════════════════
⚠️  ONE TASK ONLY - THEN STOP
═══════════════════════════════════════════════════════════════════════════════
This file: phases/phase08-output-apis-encoder-options-and-io-adapter.md

1. Find first unchecked task in this phase file
2. Read the referenced section in PLAN.md and any external links provided
3. Complete task (Implementation + Tests + Analyzer)
4. Visual Verification: Run Golden tests and MANUALLY INSPECT outputs (if applicable)
5. Mark the task complete
6. STOP

Phase complete → mark the corresponding phase item in root TODO.md.
All phases complete → output: <promise>ALL_DONE</promise>
═══════════════════════════════════════════════════════════════════════════════

# Phase 8: Output APIs, Encoder Options, and IO Adapter

Purpose: expose final output APIs, typed encoder options, metadata-write hooks, cancellation, and optional native file IO.

Relevant plan links:

- Plan: [Output and Encoders](../PLAN.md#38-output-and-encoders)
- Plan: [Output, Metadata Writing, and IO](../PLAN.md#57-output-metadata-writing-and-io)
- Plan: [IO Adapter Shape](../PLAN.md#44-io-adapter-shape)

External references:

- Ref: `sharp_clone/lib/output.js`
- Ref: `sharp_clone/test/unit/toBuffer.js`
- Ref: `sharp_clone/test/unit/io.js`
- Ref: [Dart async](https://dart.dev/libraries/async/async-await)

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

- [x] **8.1 Implement output result types**
  - Plan: [Output and Encoders](../PLAN.md#38-output-and-encoders)
  - Ref: `sharp_clone/lib/index.d.ts`
  - Add `EncodedImage`, `OutputInfo`, and `ImageBytesResult`.
  - Include format, size, width, height, channels, premultiplied, crop/trim offsets, animation fields, and text fields where implemented.
  - Test field mapping and immutability.
- [x] **8.2 Implement toBytes and toBytesWithInfo**
  - Plan: [Output, Metadata Writing, and IO](../PLAN.md#57-output-metadata-writing-and-io)
  - Ref: `sharp_clone/test/unit/toBuffer.js`
  - Add pipeline execution methods for bytes and bytes-with-info.
  - Ensure repeated calls do not reset options unexpectedly.
  - Test default output format and explicit format behavior.
- [x] **8.3 Implement encoder option classes**
  - Plan: [Output and Encoders](../PLAN.md#38-output-and-encoders)
  - Ref: `sharp_clone/lib/index.d.ts`
  - Add typed options for JPEG, PNG, GIF, TIFF, WebP, raw, and unsupported future formats.
  - Validate quality, effort, bit depth, animation, compression, and palette options.
  - Test invalid options separately from encode failures.
- [x] **8.4 Implement toFormat and format-specific chain methods**
  - Plan: [Output, Metadata Writing, and IO](../PLAN.md#57-output-metadata-writing-and-io)
  - Ref: `sharp_clone/test/unit/toFormat.js`
  - Add `toFormat`, `jpeg`, `png`, `gif`, `tiff`, `webp`, and `raw` chain methods.
  - Unsupported formats must fail through codec capabilities.
  - Test method precedence and `force` semantics if supported.
- [x] **8.5 Implement cancellation and timeout**
  - Plan: [Output and Encoders](../PLAN.md#38-output-and-encoders)
  - Ref: `sharp_clone/test/unit/timeout.js`
  - Add `CancellationToken` and timeout options with cooperative checkpoints.
  - Test cancellation before decode, during operation loops, and before encode.
  - Avoid isolate termination in the first implementation.
- [x] **8.6 Implement optional native IO adapter**
  - Plan: [IO Adapter Shape](../PLAN.md#44-io-adapter-shape)
  - Ref: [Dart File class](https://api.dart.dev/stable/dart-io/File-class.html)
  - Add `packages/dsharp/lib/dsharp_io.dart` and private IO helpers.
  - Add `ImagePipeline.fromFile`, `ImageSource.file`, and `writeToFile` extensions.
  - Add VM-only tests and confirm core no-IO guard still passes.
- [x] **8.7 Add metadata write API stubs**
  - Plan: [Output and Encoders](../PLAN.md#38-output-and-encoders)
  - Ref: `sharp_clone/test/unit/metadata.js`
  - Add typed methods for keep/set/merge EXIF, ICC, XMP, and `withMetadata`.
  - Implement only verified formats; unsupported writes must fail clearly.
  - Test unsupported metadata write paths and README support matrix.

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
