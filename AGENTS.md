# AGENTS.md

Guidelines for AI agents working on this repository.

## Project Overview

`remend` is a **Dart port** of the [`remend`](https://www.npmjs.com/package/remend) npm package (v1.2.2) by the [Streamdown](https://github.com/vercel/streamdown) team at Vercel.

It is a lightweight, zero-dependency library that completes incomplete Markdown syntax during streaming AI output — e.g. `**bold text` → `**bold text**`. The source of truth for all behavior is the original TypeScript implementation, which lives in the `streamdown/` git submodule at `streamdown/packages/remend/src/`.

---

## ⚠️ 1:1 Parity Rule — Read This First

This is the single most important constraint in the repo.

Every file in `lib/src/` is a direct 1:1 translation of a file in `streamdown/packages/remend/src/` — same count, same names (with `_` instead of `-`). Every test file in `test/` mirrors a file in `streamdown/packages/remend/__tests__/` in the same way.

### What must match exactly

- All logic and algorithms
- All comments (translated to `///` Dart style)
- Handler names, option names, and priorities
- Test structure and test cases

### Dart-only differences allowed

- `snake_case` filenames instead of `kebab-case`
- `///` doc comments instead of JSDoc `/** */`
- `enum LinkMode` instead of a TypeScript string union type
- Named constructor parameters instead of object literals
- `RegExp` with Dart flags instead of JS regex literals

### What you must NOT do

- Add new handlers, change handler priorities, or rename options without a corresponding change in the upstream TypeScript first
- Add abstraction layers, helpers, or utilities that have no counterpart in the TypeScript source
- Change the behavior of any handler unless the upstream TypeScript changed first

---

## Upstream Sync Strategy

When the `streamdown` submodule receives a new version of the npm package:

1. Note the current submodule commit (the old version reference)
2. Update the submodule: `git submodule update --remote streamdown`
3. Diff each changed TypeScript file against its previous version: `git diff <old-commit> HEAD -- streamdown/packages/remend/src/`
4. For each changed `.ts` file, apply the equivalent change to the corresponding `.dart` file — preserving full 1:1 parity including comments, tests, and any README changes
5. If the npm `package.json` version changed → update `version` in `pubspec.yaml` to match exactly
6. Add a new entry to `CHANGELOG.md` describing what changed
7. If the upstream `README.md` changed meaningfully → apply equivalent changes to the Dart `README.md`, keeping the port notice and Dart-specific adaptations

---

## Repository Structure

```
lib/
  remend.dart       # Barrel file — public exports
  src/              # 1:1 with streamdown/packages/remend/src/ (snake_case filenames)
test/               # 1:1 with streamdown/packages/remend/__tests__/ (snake_case filenames)
streamdown/         # Git submodule — original TypeScript implementation (source of truth)
.github/workflows/
  ci.yaml           # CI: format + analyze + test on every push/PR to main
```

## Public API

Exported from `lib/remend.dart`:

- `remend(String text, [RemendOptions options])` — main function
- `RemendHandler` — class for custom handlers (`name`, `handle`, `priority`)
- `RemendOptions` — configuration class (all options default `true` except `inlineKatex`)
- `LinkMode` — enum: `protocol` (default) or `textOnly`
- `isWithinCodeBlock`, `isWithinMathBlock`, `isWithinLinkOrImageUrl`, `isWordChar` — context utilities for custom handlers
- `countTripleAsterisks` (and other `count*` / `handleIncomplete*` functions from `emphasis_handlers.dart`) — exported for testing

---

## Development Commands

Before every commit, run the full check:

```bash
dart format . && dart analyze --fatal-infos && dart test
```

All three steps must pass. The GitHub Actions CI enforces the same checks on every push and PR to `main`.

---

## Commit Style

Use lowercase conventional commits. No AI coauthor lines.

```
feat:     new feature
fix:      bug fix
docs:     documentation only
chore:    maintenance (deps, config)
refactor: code change without behavior change
ci:       CI/CD changes
```
