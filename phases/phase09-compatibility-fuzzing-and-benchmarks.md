═══════════════════════════════════════════════════════════════════════════════
⚠️  ONE TASK ONLY - THEN STOP
═══════════════════════════════════════════════════════════════════════════════
This file: phases/phase09-compatibility-fuzzing-and-benchmarks.md

1. Find first unchecked task in this phase file
2. Read the referenced section in PLAN.md and any external links provided
3. Complete task (Implementation + Tests + Analyzer)
4. Visual Verification: Run Golden tests and MANUALLY INSPECT outputs (if applicable)
5. Mark the task complete
6. STOP

Phase complete → mark the corresponding phase item in root TODO.md.
All phases complete → output: <promise>ALL_DONE</promise>
═══════════════════════════════════════════════════════════════════════════════

# Phase 9: Compatibility, Fuzzing, and Benchmarks

Purpose: broaden verification beyond unit tests with optional upstream-observed fixtures, property tests, fuzz tests, and performance baselines.

Relevant plan links:

- Plan: [Tests, Fixtures, and Benchmarks](../PLAN.md#310-tests-fixtures-and-benchmarks)
- Plan: [Tests and Fixtures](../PLAN.md#58-tests-and-fixtures)
- Plan: [Benchmarks](../PLAN.md#59-benchmarks)

External references:

- Ref: `sharp_clone/test/fixtures/**`
- Ref: `sharp_clone/test/bench/perf.js`
- Ref: `sharp_clone/test/bench/random.js`
- Ref: [benchmark_harness package](https://pub.dev/packages/benchmark_harness)

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

- [x] **9.1 Add generated fixture factory**
  - Plan: [Tests and Fixtures](../PLAN.md#58-tests-and-fixtures)
  - Ref: `sharp_clone/test/fixtures/index.js`
  - Add test helpers that generate tiny images, gradients, alpha grids, animation frames, raw buffers, and malformed byte arrays.
  - Store generated fixtures under `packages/dsharp/test/fixtures/generated/` only when stable bytes are needed.
  - Test fixture helpers themselves.
- [x] **9.2 Add optional compatibility fixture harness**
  - Plan: [Compatibility Fixtures](../PLAN.md#63-compatibility-fixtures)
  - Ref: `sharp_clone/test/fixtures/**`
  - Add tests that skip when `sharp_clone/` is absent.
  - Read ignored fixtures locally without copying them into tracked files.
  - Compare dimensions, metadata, and pixels with explicit lossy tolerances.
- [x] **9.3 Add golden visual tests**
  - Plan: [Testing and Verification Strategy](../PLAN.md#6-testing-and-verification-strategy)
  - Ref: `packages/dsharp/test/fixtures/generated/`
  - Add golden PNG outputs for deterministic generated fixtures.
  - Store goldens in `packages/dsharp/test/goldens/`.
  - Run golden generation and manually inspect PNG outputs before marking done.
- [x] **9.4 Add property tests for geometry and operations**
  - Plan: [Tests and Fixtures](../PLAN.md#58-tests-and-fixtures)
  - Ref: [Dart test package](https://pub.dev/packages/test)
  - Add randomized tests for resize bounds, crop bounds, channel ranges, alpha ranges, kernel normalization, and idempotent operations.
  - Use deterministic seeds.
  - Record failing seeds in regression tests.
- [x] **9.5 Add parser fuzz tests**
  - Plan: [Security, Robustness, and Limits](../PLAN.md#7-security-robustness-and-limits)
  - Ref: `sharp_clone/test/fixtures/truncated.png`
  - Generate malformed headers, truncated chunks, random bytes, oversized dimensions, and invalid metadata.
  - Assert typed exceptions, bounded memory behavior, and no hangs.
  - Keep fuzz tests deterministic and CI-friendly.
- [x] **9.6 Add benchmark suite**
  - Plan: [Benchmarks](../PLAN.md#59-benchmarks)
  - Ref: [benchmark_harness package](https://pub.dev/packages/benchmark_harness)
  - Implement JPEG resize, PNG RGBA resize, random dimension resize, raw operation, and composite benchmarks.
  - Report throughput and elapsed time without requiring native parity.
  - Add benchmark README instructions.
- [x] **9.7 Add coverage reporting**
  - Plan: [Required Checks](../PLAN.md#61-required-checks)
  - Ref: [Dart test coverage](https://pub.dev/packages/coverage)
  - Add coverage tooling and CI artifact upload.
  - Define initial thresholds by package area.
  - Ensure generated or skipped compatibility tests do not distort coverage.

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
