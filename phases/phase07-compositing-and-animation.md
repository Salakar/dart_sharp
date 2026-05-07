═══════════════════════════════════════════════════════════════════════════════
⚠️  ONE TASK ONLY - THEN STOP
═══════════════════════════════════════════════════════════════════════════════
This file: phases/phase07-compositing-and-animation.md

1. Find first unchecked task in this phase file
2. Read the referenced section in PLAN.md and any external links provided
3. Complete task (Implementation + Tests + Analyzer)
4. Visual Verification: Run Golden tests and MANUALLY INSPECT outputs (if applicable)
5. Mark the task complete
6. STOP

Phase complete → mark the corresponding phase item in root TODO.md.
All phases complete → output: <promise>ALL_DONE</promise>
═══════════════════════════════════════════════════════════════════════════════

# Phase 7: Compositing and Animation

Purpose: implement ordered overlays, blend modes, tiled overlays, and multi-frame image behavior.

Relevant plan links:

- Plan: [Compositing](../PLAN.md#37-compositing)
- Plan: [Composite and Animation](../PLAN.md#56-composite-and-animation)
- Plan: [Output and Encoders](../PLAN.md#38-output-and-encoders)

External references:

- Ref: `sharp_clone/lib/composite.js`
- Ref: `sharp_clone/test/unit/composite.js`
- Ref: `sharp_clone/test/unit/gif.js`
- Ref: `sharp_clone/test/unit/webp.js`

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

- [x] **7.1 Implement composite layer model**
  - Plan: [Compositing](../PLAN.md#37-compositing)
  - Ref: `sharp_clone/lib/composite.js`
  - Add `CompositeLayer`, `BlendMode`, placement, tile, and premultiplied options.
  - Validate that top and left are supplied together.
  - Test invalid overlays and typed source handling.
- [x] **7.2 Implement Porter-Duff blend modes**
  - Plan: [Composite and Animation](../PLAN.md#56-composite-and-animation)
  - Ref: `sharp_clone/docs/src/content/docs/api-composite.md`
  - Implement clear, source, over, in, out, atop, dest, dest-over, dest-in, dest-out, dest-atop, and xor.
  - Test 2x2 RGBA fixtures with hand-computed expected pixels.
  - Manually inspect generated golden PNGs if visual goldens are added.
- [x] **7.3 Implement artistic blend modes**
  - Plan: [Composite and Animation](../PLAN.md#56-composite-and-animation)
  - Ref: `sharp_clone/lib/composite.js`
  - Implement add, saturate, multiply, screen, overlay, darken, lighten, color-dodge, color-burn, hard-light, soft-light, difference, and exclusion.
  - Include British spelling aliases only in compatibility-facing APIs if used.
  - Test alpha and channel clamping.
- [x] **7.4 Implement overlay placement and tiling**
  - Plan: [Compositing](../PLAN.md#37-compositing)
  - Ref: `sharp_clone/test/unit/composite.js`
  - Place overlays by gravity or exact offset.
  - Repeat overlays when tile is true.
  - Test negative offsets, large offsets, and overlay larger than base image.
- [x] **7.5 Implement animation frame model behavior**
  - Plan: [Composite and Animation](../PLAN.md#56-composite-and-animation)
  - Ref: `sharp_clone/test/unit/gif.js`
  - Preserve frame order, delay, loop, page height, and dimensions.
  - Define restrictions for operations not yet animation-safe.
  - Test generated two-frame GIF-like frame data before codec integration.
- [x] **7.6 Implement join images behavior**
  - Plan: [Constructor and Input](../PLAN.md#31-constructor-and-input)
  - Ref: `sharp_clone/test/unit/join.js`
  - Add image array joining with across, shim, background, horizontal alignment, vertical alignment, and animated flag.
  - Test grid dimensions and transparent backgrounds.

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
