═══════════════════════════════════════════════════════════════════════════════
⚠️  ONE TASK ONLY - THEN STOP
═══════════════════════════════════════════════════════════════════════════════
This file: TODO.md

1. Find first unchecked task
2. Read the referenced section in PLAN.md and any external links provided
3. Complete task (Implementation + Tests + Analyzer)
4. Visual Verification: Run Golden tests and MANUALLY INSPECT outputs (if applicable)
5. Mark the task complete
6. STOP

All complete → output: <promise>ALL_DONE</promise>
═══════════════════════════════════════════════════════════════════════════════

## PLAN.md Table of Contents

- [1. Scope, Identity, and Non-Negotiables](PLAN.md#1-scope-identity-and-non-negotiables)
- [2. Current Workspace State](PLAN.md#2-current-workspace-state)
- [3. Upstream Feature Inventory](PLAN.md#3-upstream-feature-inventory)
- [4. Target Dart Architecture](PLAN.md#4-target-dart-architecture)
- [5. Feature Implementation Plan](PLAN.md#5-feature-implementation-plan)
- [6. Testing and Verification Strategy](PLAN.md#6-testing-and-verification-strategy)
- [7. Security, Robustness, and Limits](PLAN.md#7-security-robustness-and-limits)
- [8. Migration and Implementation Order](PLAN.md#8-migration-and-implementation-order)
- [9. Risks and Open Decisions](PLAN.md#9-risks-and-open-decisions)
- [10. Acceptance Criteria](PLAN.md#10-acceptance-criteria)

## Phase Files

- [Phase 1: Foundation and Repository Correctness](phases/phase01-foundation-and-repository-correctness.md)
- [Phase 2: Source, Pixel, and Capability Models](phases/phase02-source-pixel-and-capability-models.md)
- [Phase 3: Codec Registry and Initial Pure Dart Codecs](phases/phase03-codec-registry-and-initial-pure-dart-codecs.md)
- [Phase 4: Metadata, Stats, and Safety Limits](phases/phase04-metadata-stats-and-safety-limits.md)
- [Phase 5: Resize Geometry and Resampling](phases/phase05-resize-geometry-and-resampling.md)
- [Phase 6: Core Pixel Operations](phases/phase06-core-pixel-operations.md)
- [Phase 7: Compositing and Animation](phases/phase07-compositing-and-animation.md)
- [Phase 8: Output APIs, Encoder Options, and IO Adapter](phases/phase08-output-apis-encoder-options-and-io-adapter.md)
- [Phase 9: Compatibility, Fuzzing, and Benchmarks](phases/phase09-compatibility-fuzzing-and-benchmarks.md)
- [Phase 10: Documentation, CI Polish, and Release Readiness](phases/phase10-documentation-ci-polish-and-release-readiness.md)

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

## Phase Checklist

- [x] **Phase 1: Foundation and repository correctness**
  - Phase TODO: [phases/phase01-foundation-and-repository-correctness.md](phases/phase01-foundation-and-repository-correctness.md)
  - Plan: [Foundation](PLAN.md#51-foundation)
  - Complete every unchecked task in the phase file, then mark this phase complete.
- [x] **Phase 2: Source, pixel, and capability models**
  - Phase TODO: [phases/phase02-source-pixel-and-capability-models.md](phases/phase02-source-pixel-and-capability-models.md)
  - Plan: [Target Dart Architecture](PLAN.md#4-target-dart-architecture)
  - Complete every unchecked task in the phase file, then mark this phase complete.
- [x] **Phase 3: Codec registry and initial pure Dart codecs**
  - Phase TODO: [phases/phase03-codec-registry-and-initial-pure-dart-codecs.md](phases/phase03-codec-registry-and-initial-pure-dart-codecs.md)
  - Plan: [Codec Foundation](PLAN.md#52-codec-foundation)
  - Complete every unchecked task in the phase file, then mark this phase complete.
- [x] **Phase 4: Metadata, stats, and safety limits**
  - Phase TODO: [phases/phase04-metadata-stats-and-safety-limits.md](phases/phase04-metadata-stats-and-safety-limits.md)
  - Plan: [Metadata and Statistics](PLAN.md#33-metadata-and-statistics)
  - Complete every unchecked task in the phase file, then mark this phase complete.
- [x] **Phase 5: Resize geometry and resampling**
  - Phase TODO: [phases/phase05-resize-geometry-and-resampling.md](phases/phase05-resize-geometry-and-resampling.md)
  - Plan: [Resize, Extract, Extend, and Trim](PLAN.md#34-resize-extract-extend-and-trim)
  - Complete every unchecked task in the phase file, then mark this phase complete.
- [x] **Phase 6: Core pixel operations**
  - Phase TODO: [phases/phase06-core-pixel-operations.md](phases/phase06-core-pixel-operations.md)
  - Plan: [Operations](PLAN.md#35-operations)
  - Complete every unchecked task in the phase file, then mark this phase complete.
- [x] **Phase 7: Compositing and animation**
  - Phase TODO: [phases/phase07-compositing-and-animation.md](phases/phase07-compositing-and-animation.md)
  - Plan: [Compositing](PLAN.md#37-compositing)
  - Complete every unchecked task in the phase file, then mark this phase complete.
- [x] **Phase 8: Output APIs, encoder options, and IO adapter**
  - Phase TODO: [phases/phase08-output-apis-encoder-options-and-io-adapter.md](phases/phase08-output-apis-encoder-options-and-io-adapter.md)
  - Plan: [Output, Metadata Writing, and IO](PLAN.md#57-output-metadata-writing-and-io)
  - Complete every unchecked task in the phase file, then mark this phase complete.
- [x] **Phase 9: Compatibility, fuzzing, and benchmarks**
  - Phase TODO: [phases/phase09-compatibility-fuzzing-and-benchmarks.md](phases/phase09-compatibility-fuzzing-and-benchmarks.md)
  - Plan: [Tests and Fixtures](PLAN.md#58-tests-and-fixtures)
  - Complete every unchecked task in the phase file, then mark this phase complete.
- [x] **Phase 10: Documentation, CI polish, and release readiness**
  - Phase TODO: [phases/phase10-documentation-ci-polish-and-release-readiness.md](phases/phase10-documentation-ci-polish-and-release-readiness.md)
  - Plan: [Documentation and Release Polish](PLAN.md#510-documentation-and-release-polish)
  - Complete every unchecked task in the phase file, then mark this phase complete.
- [x] **Strict codec parity follow-up: first-party interoperable JPEG/WebP**
  - Phase TODO: [phases/phase03-codec-registry-and-initial-pure-dart-codecs.md](phases/phase03-codec-registry-and-initial-pure-dart-codecs.md)
  - Plan: [Codec Foundation](PLAN.md#52-codec-foundation)
  - Replace marker-raster JPEG/WebP placeholders with interoperable in-house codec implementations or update the support matrix to explicitly drop that support.

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
Output <promise>ALL_DONE</promise> only when every single item is checked.
═══════════════════════════════════════════════════════════════════════════════
