═══════════════════════════════════════════════════════════════════════════════
⚠️  ONE TASK ONLY - THEN STOP
═══════════════════════════════════════════════════════════════════════════════
This file: phases/phase05-resize-geometry-and-resampling.md

1. Find first unchecked task in this phase file
2. Read the referenced section in PLAN.md and any external links provided
3. Complete task (Implementation + Tests + Analyzer)
4. Visual Verification: Run Golden tests and MANUALLY INSPECT outputs (if applicable)
5. Mark the task complete
6. STOP

Phase complete → mark the corresponding phase item in root TODO.md.
All phases complete → output: <promise>ALL_DONE</promise>
═══════════════════════════════════════════════════════════════════════════════

# Phase 5: Resize Geometry and Resampling

Purpose: implement deterministic resize, extract, extend, trim, kernels, and crop strategy behavior.

Relevant plan links:

- Plan: [Resize, Extract, Extend, and Trim](../PLAN.md#34-resize-extract-extend-and-trim)
- Plan: [Geometry and Resampling](../PLAN.md#54-geometry-and-resampling)
- Plan: [Tests and Fixtures](../PLAN.md#58-tests-and-fixtures)

External references:

- Ref: `sharp_clone/lib/resize.js`
- Ref: `sharp_clone/test/unit/resize.js`
- Ref: `sharp_clone/test/unit/resize-cover.js`
- Ref: `sharp_clone/test/unit/resize-contain.js`

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

- [x] **5.1 Implement geometry value types**
  - Plan: [Resize, Extract, Extend, and Trim](../PLAN.md#34-resize-extract-extend-and-trim)
  - Ref: `sharp_clone/lib/resize.js`
  - Add `Region`, `Insets`, `Gravity`, `Position`, `ResizeFit`, and `ResizeOptions`.
  - Validate positive dimensions and paired offsets.
  - Test invalid dimensions, null-like omitted dimensions, and alias values.
- [x] **5.2 Implement resize dimension resolution**
  - Plan: [Geometry and Resampling](../PLAN.md#54-geometry-and-resampling)
  - Ref: `sharp_clone/test/unit/resize.js`
  - Compute target dimensions for fixed width, fixed height, cover, contain, fill, inside, outside, enlargement, and reduction rules.
  - Keep this pure and independent of pixel buffers.
  - Test all known rounding and orientation interactions.
- [x] **5.3 Implement extraction order semantics**
  - Plan: [Resize, Extract, Extend, and Trim](../PLAN.md#34-resize-extract-extend-and-trim)
  - Ref: `sharp_clone/test/unit/extract.js`
  - Represent pre-resize and post-resize extraction based on call order.
  - Validate region bounds after the correct stage.
  - Test extract-before-resize, extract-after-resize, and both.
- [x] **5.4 Implement resize kernels**
  - Plan: [Geometry and Resampling](../PLAN.md#54-geometry-and-resampling)
  - Ref: `sharp_clone/docs/src/content/docs/api-resize.md`
  - Add nearest, linear, cubic, Mitchell, Lanczos 2, and Lanczos 3 kernels.
  - Add MKS 2013 and MKS 2021 as a separate module when formulas are reviewed.
  - Test kernel normalization and tiny image outputs.
- [x] **5.5 Implement resampler**
  - Plan: [Geometry and Resampling](../PLAN.md#54-geometry-and-resampling)
  - Ref: `sharp_clone/test/unit/resize.js`
  - Apply kernels to `PixelImage` with channel and alpha awareness.
  - Preserve dimensions exactly as computed by geometry.
  - Test grayscale, RGB, RGBA, and transparent pixels.
- [x] **5.6 Implement extend and trim**
  - Plan: [Resize, Extract, Extend, and Trim](../PLAN.md#34-resize-extract-extend-and-trim)
  - Ref: `sharp_clone/test/unit/extend.js`
  - Ref: `sharp_clone/test/unit/trim.js`
  - Implement background, copy, repeat, and mirror extension modes.
  - Implement trim threshold and line-art mode with offset output.
  - Test tiny synthetic expected pixels.
- [x] **5.7 Implement entropy and attention crop strategy scaffolds**
  - Plan: [Geometry and Resampling](../PLAN.md#54-geometry-and-resampling)
  - Ref: `sharp_clone/lib/resize.js`
  - Add strategy interfaces and entropy implementation.
  - Add attention strategy with documented approximation if full behavior is deferred.
  - Test deterministic crop choices.

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
