═══════════════════════════════════════════════════════════════════════════════
⚠️  ONE TASK ONLY - THEN STOP
═══════════════════════════════════════════════════════════════════════════════
This file: phases/phase04-metadata-stats-and-safety-limits.md

1. Find first unchecked task in this phase file
2. Read the referenced section in PLAN.md and any external links provided
3. Complete task (Implementation + Tests + Analyzer)
4. Visual Verification: Run Golden tests and MANUALLY INSPECT outputs (if applicable)
5. Mark the task complete
6. STOP

Phase complete → mark the corresponding phase item in root TODO.md.
All phases complete → output: <promise>ALL_DONE</promise>
═══════════════════════════════════════════════════════════════════════════════

# Phase 4: Metadata, Stats, and Safety Limits

Purpose: implement image metadata, statistics, and robust limits for untrusted byte inputs.

Relevant plan links:

- Plan: [Metadata and Statistics](../PLAN.md#33-metadata-and-statistics)
- Plan: [Pixel and Metadata Model](../PLAN.md#53-pixel-and-metadata-model)
- Plan: [Security, Robustness, and Limits](../PLAN.md#7-security-robustness-and-limits)

External references:

- Ref: [xml package](https://pub.dev/packages/xml)
- Ref: `sharp_clone/src/metadata.cc`
- Ref: `sharp_clone/src/stats.cc`

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

- [x] **4.1 Implement metadata value classes**
  - Plan: [Metadata and Statistics](../PLAN.md#33-metadata-and-statistics)
  - Ref: `sharp_clone/lib/index.d.ts`
  - Add `ImageMetadata`, `FrameMetadata`, `ProfileMetadata`, `ImageComment`, and related enums.
  - Cover dimensions, format, channels, depth, density, animation, profiles, and comments.
  - Test default values and immutable copies.
- [x] **4.2 Implement metadata extraction from decoded images**
  - Plan: [Pixel and Metadata Model](../PLAN.md#53-pixel-and-metadata-model)
  - Ref: `sharp_clone/test/unit/metadata.js`
  - Map backend metadata into public `ImageMetadata`.
  - Preserve unsupported metadata as absent rather than loosely typed maps.
  - Test PNG, JPEG, GIF, raw, and unsupported format cases.
- [x] **4.3 Implement stats computation**
  - Plan: [Metadata and Statistics](../PLAN.md#33-metadata-and-statistics)
  - Ref: `sharp_clone/test/unit/stats.js`
  - Compute per-channel min, max, sum, squares sum, mean, standard deviation, min/max coordinates, opacity, entropy, sharpness, and dominant color.
  - Document rounding and complexity.
  - Test against tiny generated images with hand-computed expected values.
- [x] **4.4 Implement safety limits**
  - Plan: [Security, Robustness, and Limits](../PLAN.md#7-security-robustness-and-limits)
  - Ref: `sharp_clone/lib/input.js`
  - Add `InputSafetyLimits` for bytes, pixels, dimensions, frames, metadata length, and stream length.
  - Enforce limits before allocation where possible.
  - Test oversized dimensions, byte streams, and raw buffers.
- [x] **4.5 Implement fail-on policy**
  - Plan: [Constructor and Input](../PLAN.md#31-constructor-and-input)
  - Ref: `sharp_clone/test/unit/failOn.js`
  - Add typed `DecodeFailurePolicy` with none, truncated, error, and warning semantics.
  - Define which failures are always fatal.
  - Test malformed metadata, truncated bytes, and permissive pixel decode behavior.
- [x] **4.6 Add metadata XML scaffolding**
  - Plan: [Output and Encoders](../PLAN.md#38-output-and-encoders)
  - Ref: [xml package](https://pub.dev/packages/xml)
  - Add XMP/XML parse and validation scaffolding after dependency review.
  - Do not expose raw XML maps in public APIs.
  - Test invalid XML and unsupported metadata write paths.

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
