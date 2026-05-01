# Formatting + Changelog Convention Audit (2026-05-01)

Implementation Unit U4 of `docs/plans/2026-05-01-001-refactor-bau-design-criteria-assessment-plan.md`.

This audit covers two BAU rules from `~/.claude/CLAUDE.md`:

1. **AsciiDoc heading/bullet rule** — every heading must be followed by a blank line before any bullet list. Applies to `.adoc` files only.
2. **File changelog convention** — every `*.sh` script and `Taskfile.yml` (or local equivalent — this repo uses `Justfile`) must end with a `# Changelog:` block in the prescribed shape.

---

## Methodology

Commands run from the repo root (read-only, no mutating actions):

- AsciiDoc inventory:

  ```
  find . -name '*.adoc' -not -path './.git/*'
  ```

- Shell-script inventory (tracked + untracked, excluding build artifacts):

  ```
  find . -name '*.sh' -not -path './.git/*' -not -path './build/*' -not -path './DerivedData/*'
  ```

- Per-file changelog presence check (last ~15 lines must contain the `# Changelog:` marker):

  ```
  tail -15 <file> | grep -q '# Changelog:'
  ```

- Last-modified date via `stat -f '%Sm' -t '%Y-%m-%d' <file>`.

- `Justfile` checked the same way as shell scripts since the user's CLAUDE.md treats `Taskfile.yml` and task-runner equivalents interchangeably; this repo has no `Taskfile.yml`.

---

## AsciiDoc check

`find . -name '*.adoc' -not -path './.git/*'` returned **no results** (empty output, exit 0). The repo has zero `.adoc` files, so the heading/bullet blank-line rule has no surface to apply against.

**Status: N/A** — rule does not apply to this repo. Re-evaluate if AsciiDoc documentation is later introduced (e.g., under `docs/`).

---

## Changelog footer inventory

22 shell scripts plus `Justfile` were inventoried. **All 23 files lack the required `# Changelog:` footer block.** Sorted non-compliant first; there are no compliant files in this repo.

| File | Has changelog block | Last modified | Compliance |
|------|---------------------|---------------|------------|
| `Justfile` | No | 2026-02-15 | Non-compliant |
| `scripts/build.sh` | No | 2025-12-31 | Non-compliant |
| `scripts/buildDebug.sh` | No | 2025-12-31 | Non-compliant |
| `scripts/buildRelease.sh` | No | 2025-12-31 | Non-compliant |
| `scripts/check-notarization.sh` | No | 2025-12-31 | Non-compliant |
| `scripts/create-gh-release.sh` | No | 2025-12-31 | Non-compliant |
| `scripts/create-release.sh` | No | 2025-12-31 | Non-compliant |
| `scripts/credentials.sh` | No | 2026-02-15 | Non-compliant |
| `scripts/export-app.sh` | No | 2026-02-15 | Non-compliant |
| `scripts/extract-project-info.sh` | No | 2026-02-15 | Non-compliant |
| `scripts/fix_sparkle_package.sh` | No | 2026-02-15 | Non-compliant |
| `scripts/generate-appcast.sh` | No | 2025-12-31 | Non-compliant |
| `scripts/notarize.sh` | No | 2026-02-15 | Non-compliant |
| `scripts/release-export.sh` | No | 2025-12-31 | Non-compliant |
| `scripts/release.sh` | No | 2025-12-31 | Non-compliant |
| `scripts/setup-credentials-interactive.sh` | No | 2026-02-15 | Non-compliant |
| `scripts/setup-xcode-select.sh` | No | 2026-02-15 | Non-compliant |
| `scripts/setup.sh` | No | 2025-12-31 | Non-compliant |
| `scripts/setup_tests.sh` | No | 2025-12-31 | Non-compliant |
| `scripts/show-errors.sh` | No | 2026-02-15 | Non-compliant |
| `scripts/staple.sh` | No | 2025-12-31 | Non-compliant |
| `setupTests.sh` | No | 2025-12-31 | Non-compliant |
| `verify_xcode_git.sh` | No | 2026-02-15 | Non-compliant |

Total: **23 of 23 files non-compliant (0 of 23 compliant)**.

---

## Findings

### F-fmt-1. Missing changelog footer in all shell scripts

- Location: `scripts/*.sh` (20 files), plus `setupTests.sh` and `verify_xcode_git.sh` at the repo root
- Severity: Medium
- Effort:   M
- Status:   confirmed
- Evidence: `tail -15 <file> | grep -q '# Changelog:'` returned non-zero (marker absent) for all 22 `*.sh` files. Inventory is captured in the table above. None of the files contain the required `#####…` block at end-of-file.
- Why it matters: `~/.claude/CLAUDE.md` "File Changelog Convention" mandates every `*.sh` script carry a most-recent-first changelog block so future readers and agents have an in-file traceability record without needing to walk `git log`. Several of these scripts (`notarize.sh`, `release.sh`, `setup-credentials-interactive.sh`) handle credentials and build automation where a per-file change record materially helps reviewers.
- Recommendation: Backfill a minimal initial changelog block on every script. Seed entries from `git log --follow --pretty='%ad  %s' --date=short -- <file>` (one line per commit that modified the file, descriptions truncated to <80 chars), then write the `#####…\n# Changelog:\n# YYYY-MM-DD  <desc>\n#####…` block at end-of-file. Going forward, every commit that touches a script must add an entry.
- Follow-up plan: `chore: backfill changelog footers across scripts/ and root-level shell scripts`

### F-fmt-2. Missing changelog footer in Justfile

- Location: `Justfile` (repo root)
- Severity: Medium
- Effort:   S
- Status:   confirmed
- Evidence: `tail -20 Justfile` shows the file ends with the `ci-check` recipe and no changelog block. CLAUDE.md's "File Changelog Convention" calls out `Taskfile.yml`; the repo's task-runner equivalent is `Justfile`, and the unit instructions for U4 explicitly extend the convention to it.
- Why it matters: `Justfile` is the canonical task-runner surface for this repo (`build`, `test`, `ci-build`, `ci-test`, `ci-check` recipes). Treating it on par with `Taskfile.yml` keeps task-runner change history in-band with the rest of the convention.
- Recommendation: Append the YAML-style block (using `# ##############...` form, since `Justfile` uses `#` line comments compatibly with the YAML variant) after the final recipe. Seed initial entries from `git log --follow` on `Justfile`.
- Follow-up plan: Roll into the same `chore:` plan as F-fmt-1 — single PR can backfill all 23 files.

### F-fmt-3. AsciiDoc heading/bullet rule — N/A

- Location: n/a (repo contains zero `.adoc` files)
- Severity: Low
- Effort:   S
- Status:   confirmed
- Evidence: `find . -name '*.adoc' -not -path './.git/*'` returned an empty result set.
- Why it matters: Rule cannot be violated when no surface exists. Recording the N/A status documents the negative result so a later auditor doesn't re-derive it, and flags the audit edge to revisit if AsciiDoc is later adopted.
- Recommendation: No action. If `.adoc` documentation is introduced later (e.g., in a future `docs/` overhaul), revisit the rule then.
- Follow-up plan: none

---

## Roll-up

- **Compliant files:** 0 of 23
- **Non-compliant files:** 23 of 23 (22 shell scripts + 1 `Justfile`)
- **AsciiDoc violations:** 0 (rule N/A — no `.adoc` files)
- **Severity distribution:** 0 Critical, 0 High, 2 Medium (F-fmt-1, F-fmt-2), 1 Low/N/A (F-fmt-3)

**Suggested follow-up plan:** `chore: backfill changelog footers across scripts/ and Justfile` — one PR that:

1. Generates seed entries per file from `git log --follow --pretty='%ad  %s' --date=short` (truncating descriptions to <80 chars, most-recent-first).
2. Appends the prescribed `#####…` block to every `*.sh` file under `scripts/` plus `setupTests.sh` and `verify_xcode_git.sh` at the repo root.
3. Appends the `# ##############…` variant to `Justfile`.
4. Adds (or updates) a pre-commit / CI check that fails if a touched `*.sh` or `Justfile` lacks a same-day-or-newer entry, so the convention does not silently drift again.

The work is mechanically scriptable; estimated effort is M only because of seed-entry curation, not because of complexity. No production code or behavior is affected.
