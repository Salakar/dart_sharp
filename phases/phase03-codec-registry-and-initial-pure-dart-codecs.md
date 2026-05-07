═══════════════════════════════════════════════════════════════════════════════
⚠️  ONE TASK ONLY - THEN STOP
═══════════════════════════════════════════════════════════════════════════════
This file: phases/phase03-codec-registry-and-initial-pure-dart-codecs.md

1. Find first unchecked task in this phase file
2. Read the referenced section in PLAN.md and any external links provided
3. Complete task (Implementation + Tests + Analyzer)
4. Visual Verification: Run Golden tests and MANUALLY INSPECT outputs (if applicable)
5. Mark the task complete
6. STOP

Phase complete → mark the corresponding phase item in root TODO.md.
All phases complete → output: <promise>ALL_DONE</promise>
═══════════════════════════════════════════════════════════════════════════════

# Phase 3: Codec Registry and Initial Pure Dart Codecs

Purpose: build the codec abstraction, support matrix, format sniffing, and first useful pure Dart decode/encode paths.

Relevant plan links:

- Plan: [Format and Codec Surface](../PLAN.md#32-format-and-codec-surface)
- Plan: [Codec Foundation](../PLAN.md#52-codec-foundation)
- Plan: [Dependency Strategy](../PLAN.md#45-dependency-strategy)

External references:

- Ref: `sharp_clone/lib/output.js`
- Ref: rejected runtime candidates recorded in `../docs/DEPENDENCY_REVIEW.md`

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

- [x] **3.1 Complete no-runtime-dependency review**
  - Plan: [Dependency Strategy](../PLAN.md#45-dependency-strategy)
  - Ref: `../docs/DEPENDENCY_REVIEW.md`
  - Record rejected runtime candidates and the no-runtime-dependency rule.
  - Add no runtime dependencies; keep only dev dependencies.
- [x] **3.2 Implement codec interfaces**
  - Plan: [Codec Foundation](../PLAN.md#52-codec-foundation)
  - Ref: `sharp_clone/lib/index.d.ts`
  - Add `ImageCodec`, `ImageDecoder`, `ImageEncoder`, `CodecRegistry`, and `UnsupportedCodec`.
  - Ensure public API exposes capabilities without leaking backend classes.
  - Test registration, duplicate IDs, and unsupported failures.
- [x] **3.3 Implement format sniffing**
  - Plan: [Codec Foundation](../PLAN.md#52-codec-foundation)
  - Ref: `sharp_clone/src/common.h`
  - Detect PNG, JPEG, GIF, TIFF, WebP, raw-explicit, and known unsupported signatures.
  - Return unknown format instead of throwing when sniffing cannot decide.
  - Test magic bytes, truncated bytes, and conflicting hints.
- [x] **3.4 Implement raw codec**
  - Plan: [Codec Foundation](../PLAN.md#52-codec-foundation)
  - Ref: `sharp_clone/test/unit/raw.js`
  - Decode `RawPixels` into `PixelImage` without copying where safe.
  - Encode `PixelImage` back to raw bytes and `RawPixels`.
  - Test 1, 2, 3, and 4 channel inputs plus invalid byte lengths.
- [x] **3.5 Implement initial compressed image codecs in-house**
  - Plan: [Dependency Strategy](../PLAN.md#45-dependency-strategy)
  - Ref: `sharp_clone/test/unit/{jpeg,png,gif,tiff,webp}.js`
  - Add first-party codec paths for PNG, JPEG, GIF, TIFF, and WebP read support.
  - Keep conversion code in package-local private files.
  - Test tiny generated encoded fixtures for each enabled format.
- [x] **3.6 Add unsupported advanced codec entries**
  - Plan: [Format and Codec Surface](../PLAN.md#32-format-and-codec-surface)
  - Ref: `sharp_clone/docs/src/content/docs/install.md`
  - Register AVIF, HEIF, JP2, JXL, PDF, OpenSlide, Magick, DCRAW, FITS, RAD, SVG rasterization, deep zoom, and native V as unsupported.
  - Include specific user-facing exception messages.
  - Test all unsupported formats fail predictably.
- [x] **3.7 Add codec round-trip smoke tests**
  - Plan: [Testing and Verification Strategy](../PLAN.md#6-testing-and-verification-strategy)
  - Ref: `sharp_clone/test/unit/{jpeg,png,gif,tiff,webp}.js`
  - Create independent generated fixtures under `test/fixtures/generated/`.
  - Decode -> encode -> decode and assert dimensions, channels, and basic pixel expectations.
  - Use tolerances for lossy JPEG tests.

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
