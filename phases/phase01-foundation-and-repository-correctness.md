═══════════════════════════════════════════════════════════════════════════════
⚠️  ONE TASK ONLY - THEN STOP
═══════════════════════════════════════════════════════════════════════════════
This file: phases/phase01-foundation-and-repository-correctness.md

1. Find first unchecked task in this phase file
2. Read the referenced section in PLAN.md and any external links provided
3. Complete task (Implementation + Tests + Analyzer)
4. Visual Verification: Run Golden tests and MANUALLY INSPECT outputs (if applicable)
5. Mark the task complete
6. STOP

Phase complete → mark the corresponding phase item in root TODO.md.
All phases complete → output: <promise>ALL_DONE</promise>
═══════════════════════════════════════════════════════════════════════════════

# Phase 1: Foundation and Repository Correctness

Purpose: establish package identity, public entrypoint rules, strict checks, and repo hygiene before implementing image behavior.

Relevant plan links:

- Plan: [Scope, Identity, and Non-Negotiables](../PLAN.md#1-scope-identity-and-non-negotiables)
- Plan: [Current Workspace State](../PLAN.md#2-current-workspace-state)
- Plan: [Foundation](../PLAN.md#51-foundation)

External references:

- Ref: [Dart package layout](https://dart.dev/tools/pub/package-layout)
- Ref: [Dart lints](https://dart.dev/tools/linter-rules)
- Ref: `DART_GUIDELINES.md`

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

- [x] **1.1 Replace scaffold smoke test with package identity tests**
  - Plan: [Current Workspace State](../PLAN.md#2-current-workspace-state)
  - Ref: `packages/dsharp/test/dsharp_test.dart`
  - Assert package imports from `package:dsharp/dsharp.dart`.
  - Assert initial capabilities can be queried without native dependencies.
  - Run `dart test test/dsharp_test.dart`.
- [x] **1.2 Add public entrypoint exports and package docs**
  - Plan: [Library Entrypoints](../PLAN.md#41-library-entrypoints)
  - Ref: [Effective Dart documentation](https://dart.dev/effective-dart/documentation)
  - Implement `packages/dsharp/lib/dsharp.dart` exports for placeholder API files.
  - Add Dartdoc to the library directive explaining pure Dart and web-safe scope.
  - Keep each new file under 300 lines.
- [x] **1.3 Add no-dart-io core import guard**
  - Plan: [IO Adapter Shape](../PLAN.md#44-io-adapter-shape)
  - Ref: [Dart libraries and imports](https://dart.dev/language/libraries)
  - Add a test helper that scans `lib/dsharp.dart` and transitively exported core files for `dart:io`.
  - Exclude `lib/dsharp_io.dart` from the core guard.
  - Add positive and negative fixture cases for the scanner.
- [x] **1.4 Add file-size guard tooling**
  - Plan: [Foundation](../PLAN.md#51-foundation)
  - Ref: `TODO.md`
  - Add a Dart test or small checked script that fails when implementation files exceed 300 lines or test files exceed 250 lines.
  - Document intentional exceptions through comments in the test allowlist.
  - Run the guard in package tests.
- [x] **1.5 Correct package metadata for image processing**
  - Plan: [Package Identity](../PLAN.md#11-package-identity)
  - Ref: [Pubspec fields](https://dart.dev/tools/pub/pubspec)
  - Verify `packages/dsharp/pubspec.yaml` description, topics, repository, issue tracker, and homepage are image-processing specific.
  - Add a TODO note for replacing the placeholder repository URL.
  - Run `dart pub publish --dry-run` only when the package has real implementation files.
- [x] **1.6 Expand clean-room contribution guidance**
  - Plan: [Clean-Room and Naming Rules](../PLAN.md#13-clean-room-and-naming-rules)
  - Ref: `CONTRIBUTING.md`
  - Document that `sharp_clone/` is behavioral reference only.
  - Document fixture copying rules and dependency license review.
  - Keep README as the only public source-package mention.
- [x] **1.7 Bootstrap workspace dependencies**
  - Plan: [Required Checks](../PLAN.md#61-required-checks)
  - Ref: [Melos documentation](https://melos.invertase.dev/)
  - Run `dart pub get` at the root.
  - Run `dart run melos bootstrap`.
  - Commit lockfiles only if this repository policy chooses tracked lockfiles.

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
