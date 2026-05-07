═══════════════════════════════════════════════════════════════════════════════
⚠️  ONE TASK ONLY - THEN STOP
═══════════════════════════════════════════════════════════════════════════════
This file: phases/phase10-documentation-ci-polish-and-release-readiness.md

1. Find first unchecked task in this phase file
2. Read the referenced section in PLAN.md and any external links provided
3. Complete task (Implementation + Tests + Analyzer)
4. Visual Verification: Run Golden tests and MANUALLY INSPECT outputs (if applicable)
5. Mark the task complete
6. STOP

Phase complete → mark the corresponding phase item in root TODO.md.
All phases complete → output: <promise>ALL_DONE</promise>
═══════════════════════════════════════════════════════════════════════════════

# Phase 10: Documentation, CI Polish, and Release Readiness

Purpose: prepare the repository for maintainable open source development and eventual pub.dev publication.

Relevant plan links:

- Plan: [Documentation and Release Polish](../PLAN.md#510-documentation-and-release-polish)
- Plan: [Acceptance Criteria](../PLAN.md#10-acceptance-criteria)
- Plan: [Risks and Open Decisions](../PLAN.md#9-risks-and-open-decisions)

External references:

- Ref: [Publishing Dart packages](https://dart.dev/tools/pub/publishing)
- Ref: [Dart documentation comments](https://dart.dev/effective-dart/documentation)
- Ref: [GitHub Actions for Dart](https://github.com/dart-lang/setup-dart)

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

- [x] **10.1 Replace README placeholder with user documentation**
  - Plan: [Documentation and Release Polish](../PLAN.md#510-documentation-and-release-polish)
  - Ref: `packages/dsharp/README.md`
  - Document pure Dart scope, web-safe core, optional IO adapter, supported formats, unsupported formats, and security limits.
  - Keep the only public source-package mention as a short inspiration/compatibility blurb.
  - Add examples for bytes, stream, raw pixels, file IO, resize, composite, metadata, and stats.
- [x] **10.2 Add API examples**
  - Plan: [Documentation and Release Polish](../PLAN.md#510-documentation-and-release-polish)
  - Ref: [Dart package examples](https://dart.dev/tools/pub/package-layout#examples)
  - Add runnable examples under `packages/dsharp/example/`.
  - Ensure examples import `dsharp.dart` for web-safe flows and `dsharp_io.dart` only for native IO flows.
  - Add tests or CI smoke checks for examples.
- [x] **10.3 Expand CI**
  - Plan: [Required Checks](../PLAN.md#61-required-checks)
  - Ref: `.github/workflows/ci.yml`
  - Add package-scoped analyze/test commands, coverage, doc generation, publish dry-run, fixture-skip behavior, and benchmark smoke checks.
  - Keep web tests separate if browser setup is required.
  - Ensure CI fails on format or public Dartdoc violations.
- [x] **10.4 Add pub.dev readiness checks**
  - Plan: [Documentation and Release Polish](../PLAN.md#510-documentation-and-release-polish)
  - Ref: [Publishing Dart packages](https://dart.dev/tools/pub/publishing)
  - Verify description length, topics, repository, issue tracker, homepage, license, screenshots/assets if any, and changelog.
  - Replace placeholder repository URL before publishing.
  - Run `dart pub publish --dry-run` from `packages/dsharp/`.
- [x] **10.5 Expand issue and PR templates**
  - Plan: [Documentation and Release Polish](../PLAN.md#510-documentation-and-release-polish)
  - Ref: `.github/ISSUE_TEMPLATE/`
  - Add fields for input format, output format, platform, web/native, codec support, byte input versus IO adapter, and minimal reproduction.
  - Add PR checklist entries for clean-room compliance, no core `dart:io`, fixtures, and benchmark impact.
- [x] **10.6 Final acceptance verification**
  - Plan: [Acceptance Criteria](../PLAN.md#10-acceptance-criteria)
  - Ref: `TODO.md`
  - Run melos bootstrap, format, analyze, tests, coverage, docs, and publish dry-run.
  - Confirm every public API has Dartdoc.
  - Confirm all root and phase TODO items are checked before emitting `<promise>ALL_DONE</promise>`.

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
