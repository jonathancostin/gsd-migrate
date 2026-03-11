# gsd-migrate

**Add `/gsd migrate` to [GSD-2](https://github.com/gsd-build/GSD-2)** — migrate old `.planning` directories to `.gsd` format.

> Pre-release. This may be merged into GSD-2 core — install this if you want it now.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/jonathancostin/gsd-migrate/main/install.sh | bash
```

Then restart `gsd`.

## Usage

```bash
# From within a project that has a .planning directory
/gsd migrate

# Or specify a path
/gsd migrate ~/projects/my-old-project
```

The command shows a preview before writing anything, and optionally runs an agent-driven quality review afterward.

## What it does

Reads an old get-shit-done `.planning` directory and writes a complete `.gsd` directory tree:

- **Phases → Slices** — numbered, ordered, completion state preserved
- **Plans → Tasks** — titles, descriptions, must-haves carried over
- **Milestones** — detected from roadmap structure (flat lists, `## v2.0` headings, `<details>` blocks)
- **Requirements** — classified as active/validated/deferred, IDs preserved
- **Research** — consolidated into milestone research files
- **Summaries** — completed task/slice summaries written from old summary content
- **PROJECT.md** — project description carried over
- **DECISIONS.md** — extracted from summary content when present

The output is a valid `.gsd` tree that `deriveState()` reads correctly — ready for `/gsd auto`.

## Format support

Handles real-world `.planning` variations:

| Format | Example |
|--------|---------|
| Em-dash phases | `- [x] 25 — Auth System` |
| Colon phases | `- [x] Phase 25: Auth System` |
| Bold phases | `- [x] **Phase 25: Auth System**` |
| `<details>` milestones | `<details><summary>v1.0 Core (Phases 1-10)</summary>` |
| Heading milestones | `## v2.0 — Platform` |
| Bullet requirements | `- [x] **AGNT-01**: Agent framework` |
| Heading requirements | `### R001 — Performance` |
| Decimal phase numbers | `2.1, 2.2` → sorted, renumbered `S01, S02` |
| Duplicate phase numbers | Disambiguated by title similarity |
| Completion aliases | `complete`/`done`/`shipped` → `validated` |

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/jonathancostin/gsd-migrate/main/install.sh | bash -s -- --uninstall
```

Or just update `gsd-pi` — the next version will overwrite the patched files.

## How it works

The installer downloads TypeScript source files into `~/.gsd/agent/extensions/gsd/` (the runtime extension directory). GSD loads extensions via `tsx` at runtime, so no compilation needed. It backs up `commands.ts` and `files.ts` before patching, and the uninstaller restores the originals.

## Status

[PR #3](https://github.com/jonathancostin/GSD-2/pull/3) — 478 test assertions, UAT against real projects. Pending review for merge into GSD-2 core.
