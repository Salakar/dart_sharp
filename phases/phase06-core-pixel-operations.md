═══════════════════════════════════════════════════════════════════════════════
⚠️  ONE TASK ONLY - THEN STOP
═══════════════════════════════════════════════════════════════════════════════
This file: phases/phase06-core-pixel-operations.md

1. Find first unchecked task in this phase file
2. Read the referenced section in PLAN.md and any external links provided
3. Complete task (Implementation + Tests + Analyzer)
4. Visual Verification: Run Golden tests and MANUALLY INSPECT outputs (if applicable)
5. Mark the task complete
6. STOP

Phase complete → mark the corresponding phase item in root TODO.md.
All phases complete → output: <promise>ALL_DONE</promise>
═══════════════════════════════════════════════════════════════════════════════

# Phase 6: Core Pixel Operations

Purpose: implement transform, alpha, channel, color, filter, convolution, and boolean operations over the shared pixel model.

Relevant plan links:

- Plan: [Operations](../PLAN.md#35-operations)
- Plan: [Channel and Color APIs](../PLAN.md#36-channel-and-color-apis)
- Plan: [Pixel Operations](../PLAN.md#55-pixel-operations)

External references:

- Ref: `sharp_clone/lib/operation.js`
- Ref: `sharp_clone/lib/channel.js`
- Ref: `sharp_clone/lib/colour.js`
- Ref: `sharp_clone/src/operations.h`

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

- [x] **6.1 Implement alpha operations**
  - Plan: [Pixel Operations](../PLAN.md#55-pixel-operations)
  - Ref: `sharp_clone/test/unit/alpha.js`
  - Implement ensure alpha, remove alpha, flatten, unflatten, and premultiplication helpers.
  - Test opaque, transparent, grayscale, RGB, and RGBA cases.
- [x] **6.2 Implement channel operations**
  - Plan: [Channel and Color APIs](../PLAN.md#36-channel-and-color-apis)
  - Ref: `sharp_clone/test/unit/extractChannel.js`
  - Ref: `sharp_clone/test/unit/joinChannel.js`
  - Implement channel extraction, channel join, and channel count validation.
  - Test index and named channel addressing.
- [x] **6.3 Implement transform operations**
  - Plan: [Operations](../PLAN.md#35-operations)
  - Ref: `sharp_clone/test/unit/rotate.js`
  - Ref: `sharp_clone/test/unit/affine.js`
  - Implement rotate, auto-orient hook, flip, flop, and affine transform.
  - Test operation ordering with resize and extract.
- [x] **6.4 Implement core filters**
  - Plan: [Operations](../PLAN.md#35-operations)
  - Ref: `sharp_clone/test/unit/{blur,sharpen,median,dilate,erode}.js`
  - Implement blur, sharpen, median, dilate, and erode.
  - Keep each filter in a focused file under 300 lines.
  - Test edge pixels, alpha, and invalid parameters.
- [x] **6.5 Implement convolution and threshold operations**
  - Plan: [Operations](../PLAN.md#35-operations)
  - Ref: `sharp_clone/test/unit/convolve.js`
  - Ref: `sharp_clone/test/unit/threshold.js`
  - Implement convolution kernels with scale and offset.
  - Implement grayscale/color threshold options.
  - Test invalid kernel shape and known tiny outputs.
- [x] **6.6 Implement color math operations**
  - Plan: [Channel and Color APIs](../PLAN.md#36-channel-and-color-apis)
  - Ref: `sharp_clone/test/unit/{tint,gamma,negate,normalize,linear,recomb,modulate,clahe}.js`
  - Implement grayscale aliases, tint, gamma, negate, normalize, linear, recomb, modulate, and CLAHE.
  - Split high-risk algorithms into separate files and tests.
  - Test ranges, aliases, and alpha behavior.
- [x] **6.7 Implement boolean operations**
  - Plan: [Operations](../PLAN.md#35-operations)
  - Ref: `sharp_clone/test/unit/boolean.js`
  - Ref: `sharp_clone/test/unit/bandbool.js`
  - Implement image boolean and band boolean operations for and, or, and eor.
  - Validate operand dimensions and channel compatibility.
  - Test all operators on generated fixtures.

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
