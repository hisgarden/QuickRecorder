# BAU Assessment — 2026-05-01

> **🚨 CRITICAL ACTION REQUIRED — read first.**
>
> An Apple App-Specific Password is committed to `scripts/STAPLING_GUIDE.md` in commits `e83c933`, `faa9e32`, `e511f04` and reachable from `origin/main` on the **public** GitHub repo `git@github.com:hisgarden/QuickRecorder.git`. The credential must be considered publicly exposed. Co-located in the same blob: Apple ID email and Apple Team ID. See [F-owasp-1](2026-05-01-owasp.md#f-owasp-1-apple-app-specific-password-committed-and-pushed-in-scriptsstapling_guidemd).
>
> Adjacent local-disk exposure (not in git history): `.env` mode `0644` contains a live GitHub PAT and the same Apple ASP.
>
> **Do this before anything else:**
> 1. Rotate the Apple App-Specific Password at appleid.apple.com (revoke + re-issue) — *before* any history rewrite.
> 2. Rotate the GitHub PAT, then `chmod 600 .env`.
> 3. Audit Apple's notarization submission history for unauthorized use.
> 4. Decide on history remediation (filter-repo + force-push) as a separate plan.
>
> Until rotation is complete, OWASP lenses A01 / A03 / A05 / A08 are **deferred** — `ce-plan` U2 was halted by design after the secret-exposure short-circuit.

---

## Executive read

- **28 findings across 5 lenses.** Severity distribution: **3 Critical, 5 High, 14 Medium, 6 Low.**
- **One finding sits above all others by impact:** the Apple credential leak (F-owasp-1). Rotation is S-effort and time-critical. Everything else is non-emergency.
- **Two structural patterns dominate the rest:** (a) god-object coupling concentrated in `SCContext` and `AppDelegate`, and (b) a ~75% test-coverage gap concentrated in `QuickRecorder/ViewModel/`. Both predate the audit; neither is on a recent regression trajectory (`git log --since='2026-02-01'` shows zero source/test commits).
- **Hygiene gaps are uniformly Medium / Low and mechanically resolvable:** changelog footers missing on 23 of 23 task-runner / shell files, 5 of 8 CLAUDE.md sensitive-file globs missing from `.gitignore`, no live CI gate, `Justfile clean` does not cover `logs/`.
- **One audit lens (OWASP) is incomplete by design** and must be re-run after F-owasp-1 is remediated.

---

## Per-criterion roll-up

| Lens | Critical | High | Medium | Low | Detail |
|---|---:|---:|---:|---:|---|
| OWASP | 1 | 0 | 0 | 0 | [2026-05-01-owasp.md](2026-05-01-owasp.md) — **halted on Critical**; A01/A03/A05/A08 deferred |
| SOLID | 2 | 3 | 6 | 2 | [2026-05-01-solid.md](2026-05-01-solid.md) — 13 findings across 8 source files |
| TDD | 0 | 2 | 5 | 1 | [2026-05-01-tdd.md](2026-05-01-tdd.md) — ~25% LOC-weighted coverage; no live CI gate |
| Formatting / changelog | 0 | 0 | 2 | 1 | [2026-05-01-formatting-and-changelog.md](2026-05-01-formatting-and-changelog.md) — 0 of 23 task-runner / shell files compliant; AsciiDoc N/A |
| LNT / sensitive files | 0 | 0 | 1 | 2 | [2026-05-01-lnt-and-sensitive-files.md](2026-05-01-lnt-and-sensitive-files.md) — tracked-file scan clean; 5 of 8 gitignore globs missing |
| **Total** | **3** | **5** | **14** | **6** | 28 findings |

---

## Prioritized backlog

Heuristic: severity_weight / effort_weight, with Critical = 8, High = 4, Medium = 2, Low = 1; S = 1, M = 2, L = 4. Ties broken by criticality of the system surface (security > correctness > maintainability > hygiene).

### Time-critical (do now, before any other work)

| # | Finding | Sev / Effort | Score | Suggested follow-up plan |
|---:|---|---|---:|---|
| 1 | [F-owasp-1](2026-05-01-owasp.md#f-owasp-1-apple-app-specific-password-committed-and-pushed-in-scriptsstapling_guidemd) — Apple ASP exposed in public repo (rotation slice) | Critical / S | 8.0 | `fix: rotate exposed Apple notarization credential and replace inline secret with placeholder` |

### Top backlog (next 5, post-rotation)

| # | Finding | Sev / Effort | Score | Suggested follow-up plan |
|---:|---|---|---:|---|
| 2 | F-owasp-1 (history-rewrite slice) — scrub credential from git history | Critical / M | 4.0 | `fix: filter-repo scrub scripts/STAPLING_GUIDE.md secret from public history` |
| 3 | Resume OWASP deep audit (A01 / A03 / A05 / A08) | — | — | `audit: resume U2 OWASP deep audit after credential rotation` |
| 4 | [F-solid-1](2026-05-01-solid.md#f-solid-1) — `SCContext` god-object split | Critical / L | 2.0 | `refactor: split SCContext.swift into capture / state / writer / permissions / post-processing / device-directory collaborators` |
| 5 | [F-solid-2](2026-05-01-solid.md#f-solid-2) — `AppDelegate` god-object extraction | Critical / L | 2.0 | `refactor: extract RecordingPipelineCoordinator + MouseAndMagnifierMonitor + WindowDirector from AppDelegate` |
| 6 | [F-tdd-6](2026-05-01-tdd.md#f-tdd-6) — restore CI test gate | Medium / S | 2.0 | `chore: restore GitHub Actions test workflow for QuickRecorder scheme` |

### Cheap early wins (S effort, parallel-safe with the structural work above)

| # | Finding | Sev / Effort | Score | Suggested follow-up plan |
|---:|---|---|---:|---|
| 7 | [F-lnt-1](2026-05-01-lnt-and-sensitive-files.md#f-lnt-1) — `.gitignore` missing 5 of 8 CLAUDE.md sensitive-file globs | Medium / S | 2.0 | `fix: harden .gitignore for CLAUDE.md sensitive-file patterns` |
| 8 | [F-tdd-4](2026-05-01-tdd.md#f-tdd-4) — `RecordEngine` test mocks return nil | Medium / S | 2.0 | `fix: implement SCDisplay/SCWindow/SCRunningApplication test mocks per TEST_IMPROVEMENTS.md` |
| 9 | [F-solid-10](2026-05-01-solid.md#f-solid-10) — stringly-typed stream/format switches | Medium / S | 2.0 | `refactor: replace string-keyed stream/format switches with enum-driven properties` |
| 10 | [F-solid-4](2026-05-01-solid.md#f-solid-4) — `QuickRecorderApp.swift` junk-drawer split | High / M | 2.0 | `refactor: relocate value types and free helpers out of QuickRecorderApp.swift` |
| 11 | [F-solid-12](2026-05-01-solid.md#f-solid-12) — split `QmaPlayer.swift` into per-type files | Low / S | 1.0 | `chore: split QmaPlayer.swift into per-type files` |
| 12 | [F-solid-9](2026-05-01-solid.md#f-solid-9) — collapse duplicate notification path in `AVContext.swift` | Medium / S | 2.0 | `refactor: route AVContext notifications through SCContext.showNotification` |

### Medium / Low backlog (schedule after structural work)

| # | Finding | Sev / Effort | Score | Suggested follow-up plan |
|---:|---|---|---:|---|
| 13 | [F-tdd-1](2026-05-01-tdd.md#f-tdd-1) — entire ViewModel/ directory untested | High / L | 1.0 | `feat: backfill unit tests for ViewModel layer (QmaPlayer → AreaSelector → SettingsView first)`. Sequence alongside the SCContext/AppDelegate refactor — refactor + test backfill compose well |
| 14 | [F-tdd-2](2026-05-01-tdd.md#f-tdd-2) — `AppleScript.swift` untested (OWASP-adjacent surface) | High / M | 2.0 | `feat: add unit tests for AppleScript.swift covering injection-resistance and command construction` |
| 15 | [F-solid-3](2026-05-01-solid.md#f-solid-3) — `RecordEngine.swift` mixed concerns | High / L | 1.0 | `refactor: extract filter / writer / audio-routing / frame-callback collaborators from RecordEngine` |
| 16 | [F-solid-5](2026-05-01-solid.md#f-solid-5) — `AudioPlayerManager` mixes UI + I/O + state | High / M | 2.0 | `refactor: split AudioPlayerManager into PlayerEngine + ExportCoordinator + UI binding` |
| 17 | [F-tdd-5](2026-05-01-tdd.md#f-tdd-5) — `SCContext` lifecycle + permission tests missing | Medium / M | 1.0 | `feat: extend SCContextTests with lifecycle, permission, and static-state-cleanup coverage` |
| 18 | [F-tdd-7](2026-05-01-tdd.md#f-tdd-7) — `QuickRecorderApp.swift` lifecycle untested | Medium / M | 1.0 | `refactor+feat: extract testable helpers from QuickRecorderApp.swift and add coverage`. Sequence after F-solid-4 |
| 19 | [F-tdd-3](2026-05-01-tdd.md#f-tdd-3) — `Supports/WindowHighlighter.swift` + `GroupForm.swift` untested | Medium / M | 1.0 | `feat: cover Supports/ modules with unit tests` |
| 20 | [F-fmt-1 + F-fmt-2](2026-05-01-formatting-and-changelog.md#f-fmt-1) — changelog footers missing on 23 of 23 task-runner / shell files | Medium / M | 1.0 | `chore: backfill changelog footers across scripts/, root-level shell scripts, and Justfile + add CI guard` |
| 21 | [F-solid-6](2026-05-01-solid.md#f-solid-6) — `AreaSelector` mixes SwiftUI + NSView + NSPanel | Medium / M | 1.0 | `refactor: separate AreaSelector view file into SwiftUI / NSView / NSPanel files` |
| 22 | [F-solid-7](2026-05-01-solid.md#f-solid-7) — `ContentView` reaches into globals | Medium / M | 1.0 | `refactor: route ContentView reach-throughs via injected dependencies` |
| 23 | [F-solid-8](2026-05-01-solid.md#f-solid-8) — duplicated `@AppStorage` keys across `AppDelegate` and `SettingsView` | Medium / M | 1.0 | `refactor: centralize @AppStorage key declarations`. Sequence with SettingsView extension cleanup |
| 24 | [F-solid-11](2026-05-01-solid.md#f-solid-11) — free top-level window globals | Medium / M | 1.0 | `refactor: encapsulate floating-window globals behind a WindowRegistry/WindowDirector`. Pairs with F-solid-2 |
| 25 | [F-lnt-3](2026-05-01-lnt-and-sensitive-files.md#f-lnt-3) — `Justfile clean` misses `logs/` and lacks post-teardown verification | Low / S | 1.0 | `chore: extend Justfile clean recipe to cover logs/ and add post-teardown verification` |
| 26 | [F-tdd-8](2026-05-01-tdd.md#f-tdd-8) — UI launch-smoke tests minimal | Low / M | 0.5 | `feat: add primary-flow UI tests (start/stop recording, settings persistence)`. Sequence after F-tdd-1 |
| 27 | [F-fmt-3](2026-05-01-formatting-and-changelog.md#f-fmt-3) — AsciiDoc rule N/A (no `.adoc` files) | Low | — | none — revisit if AsciiDoc adopted |
| 28 | [F-solid-13](2026-05-01-solid.md#f-solid-13) — `SettingsView` clean SRP, minor extension placement | Low / S | 1.0 | none — fix inline next time the file is touched |
| 29 | [F-lnt-2](2026-05-01-lnt-and-sensitive-files.md#f-lnt-2) — tracked-file scan clean (baseline) | Low | — | optional CI/pre-commit guard; can fold into F-lnt-1 PR |

---

## Recommended sequencing

**Phase 0 — Time-critical (this week):**
1. Rotate Apple ASP at appleid.apple.com.
2. Rotate GitHub PAT; `chmod 600 .env`.
3. Audit Apple notarization history for unauthorized submissions.
4. Replace `STAPLING_GUIDE.md` inline secret with placeholder (no force-push yet — this is a working-tree fix).
5. Decide on history-rewrite cadence; schedule as a separate `fix:` plan once collaborators are coordinated.

**Phase 1 — Stabilize for refactor (parallel-safe with Phase 0 once rotation is done):**
- `chore: restore GitHub Actions test workflow` (#6) — turns existing tests into a live gate.
- `fix: implement SCDisplay/SCWindow/SCRunningApplication test mocks` (#8) — unblocks `RecordEngineTests` from compile-only stubs.
- `fix: harden .gitignore for CLAUDE.md sensitive-file patterns` (#7) — preventive; fold the post-rotation `STAPLING_GUIDE.md` placeholder swap into the same PR if convenient.
- `audit: resume U2 OWASP deep audit` (#3) — once rotation is confirmed.

**Phase 2 — Structural refactors (multi-week, sequenced):**
- `refactor: split SCContext.swift` (#4) — unblocks every other refactor.
- `refactor: extract RecordingPipelineCoordinator + WindowDirector from AppDelegate` (#5) — pairs with #4.
- `refactor: replace string-keyed switches with enums` (#9) — small, mechanical, prerequisite-friendly.
- `feat: backfill ViewModel unit tests` (#13) — runs in parallel with the refactors; the boundaries the refactors expose become the testing seams.

**Phase 3 — Hygiene sweep (any time):**
- Changelog backfill, AppDelegate decomposition cleanup, Justfile clean recipe, AppStorage key centralization, AreaSelector / ContentView decomposition.

---

## Sources

- [SOLID detail](2026-05-01-solid.md)
- [OWASP detail](2026-05-01-owasp.md) — incomplete; resume after rotation
- [TDD detail](2026-05-01-tdd.md)
- [Formatting / changelog detail](2026-05-01-formatting-and-changelog.md)
- [LNT / sensitive-files detail](2026-05-01-lnt-and-sensitive-files.md)
- Origin plan: [`docs/plans/2026-05-01-001-refactor-bau-design-criteria-assessment-plan.md`](../plans/2026-05-01-001-refactor-bau-design-criteria-assessment-plan.md)
- BAU criteria: `~/.claude/CLAUDE.md` (SOLID / OWASP / TDD / AsciiDoc / changelog / LNT / sensitive files)
