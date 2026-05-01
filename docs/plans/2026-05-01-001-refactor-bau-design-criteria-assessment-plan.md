---
title: "Assess QuickRecorder Repo Against BAU Design Criteria"
type: refactor
status: active
date: 2026-05-01
---

# Assess QuickRecorder Repo Against BAU Design Criteria

## Overview

Produce a structured assessment of the QuickRecorder repository against the user's standing BAU design criteria — SOLID, OWASP, TDD, AsciiDoc formatting, file changelog convention, Leave No Trace (LNT), and sensitive-file protection — and capture findings + remediation guidance in a single audit deliverable that can drive follow-up work.

This is an **assessment** plan: the work units produce findings documents and a prioritized remediation backlog, not direct code rewrites. Concrete refactors are deferred to follow-up plans informed by the assessment output.

---

## Problem Frame

The QuickRecorder codebase has grown organically — a Swift/macOS screen recorder with ~8k lines across `QuickRecorder/`, ~1.5k lines of tests, and ~30 build/release/notarization scripts under `scripts/`. The user wants a baseline read on how the repo conforms to the personal standards in `~/.claude/CLAUDE.md` so technical debt and security exposure can be prioritized rather than guessed at.

Surface signals from a 5-minute scan:

- Several files exceed comfortable SRP thresholds: `QuickRecorder/SCContext.swift` (839 lines), `QuickRecorder/RecordEngine.swift` (774 lines), `QuickRecorder/QuickRecorderApp.swift` (687 lines), `QuickRecorder/ViewModel/QmaPlayer.swift` (678 lines), `QuickRecorder/ViewModel/AreaSelector.swift` (549 lines).
- Test-to-source ratio is ~19% (1544 / 7951 lines). Core engine files have unit tests; ViewModel/UI surfaces appear largely untested.
- Shell scripts under `scripts/` (e.g., `scripts/build.sh`, `scripts/release.sh`, `scripts/notarize.sh`, `scripts/setup.sh`) lack the mandated changelog footer block.
- `.gitignore` covers `.env` but does not list other sensitive patterns called out in CLAUDE.md (`*.key`, `*.password`, `*.pkcs12`, `*secrets.yaml`, `*secret.yaml`).
- The repo contains both `.env` and a `scripts/credentials.sh` workflow handling Apple ID / app-specific passwords for notarization — credential handling deserves an explicit OWASP read.

These are unverified observations from a quick scan, not findings — confirming, scoping, and ranking them is the job of this plan.

---

## Requirements Trace

- R1. Produce a per-criterion assessment document for each BAU lens (SOLID, OWASP, TDD, formatting, changelog, LNT, sensitive-file protection).
- R2. Each finding cites a repo-relative path and a specific code/config line range or symbol so a follow-up agent can act without re-discovering context.
- R3. Findings are scored by severity (Critical / High / Medium / Low) and effort (S / M / L) so a remediation backlog can be prioritized.
- R4. The deliverable distinguishes **confirmed** issues (verified by reading the file) from **suspected** issues (signal only, needs investigation).
- R5. The audit produces one consolidated `docs/audits/2026-05-01-bau-assessment.md` summary with links into per-criterion detail files, suitable for kickoff of follow-up plans.
- R6. The plan does not modify production source code. Remediation is intentionally deferred to follow-up plans driven by the audit output.

---

## Scope Boundaries

- This plan does **not** refactor `SCContext.swift`, `RecordEngine.swift`, or any other source file — those are downstream plans.
- This plan does **not** add missing unit tests; it inventories the gap.
- This plan does **not** rewrite scripts to add changelog blocks; it produces the list of files needing them.
- This plan does **not** rotate, revoke, or move credentials. If exposed secrets are found, the assessment flags them with severity Critical and stops to prompt the user before any cleanup action.
- LNT is assessed only insofar as it applies to a macOS desktop app build pipeline (build artifacts, notarization staging, DerivedData). The full k8s/Helm/Docker LNT rubric in CLAUDE.md does not apply to this repo and will be marked N/A with rationale rather than padded.

### Deferred to Follow-Up Work

- SRP-driven refactor of god-object files (separate `refactor` plan after SOLID audit).
- Test coverage backfill for ViewModel/UI surfaces (separate `feat` plan after TDD audit).
- Changelog footer backfill across `scripts/*.sh` and `Justfile` (separate `chore` plan, likely scriptable).
- `.gitignore` hardening + secret rotation (separate `fix` plan, only if the OWASP audit surfaces exposure).

---

## Context & Research

### Relevant Code and Patterns

- `QuickRecorder/SCContext.swift` — likely shared screen-capture context / god object; first SOLID candidate.
- `QuickRecorder/RecordEngine.swift` — recording orchestration; second SOLID candidate.
- `QuickRecorder/QuickRecorderApp.swift` — `@main` SwiftUI app entry; mixes lifecycle, settings, and AppDelegate concerns.
- `QuickRecorder/ViewModel/QmaPlayer.swift`, `QuickRecorder/ViewModel/AreaSelector.swift` — large ViewModels worth checking against MVVM/SRP.
- `QuickRecorder/Supports/AppleScript.swift` — AppleScript execution surface; OWASP injection / privilege concern.
- `scripts/credentials.sh`, `scripts/notarize.sh`, `scripts/setup-credentials-interactive.sh`, `.env`, `.env.sample` — credential plumbing.
- `QuickRecorderTests/*.swift` — existing test footprint, especially `AVContextTests`, `SCContextTests`, `RecordEngineTests`.
- `Justfile`, `scripts/*.sh` — changelog convention compliance surface.
- `.gitignore` — sensitive-file pattern coverage surface.

### Institutional Learnings

- `SKILLS.md` documents IDE-diagnostic resolution patterns and the file changelog convention itself — treat as a local source of truth alongside `~/.claude/CLAUDE.md`.
- `QuickRecorderTests/TEST_IMPROVEMENTS.md` and `scripts/TEST_EVALUATION_REPORT.md` already capture some test-quality observations and should feed into the TDD lens rather than be re-derived.

### External References

- OWASP ASVS v4.0.3 §6 (Stored Cryptography) and §10 (Malicious Code) — relevant for credential handling and AppleScript surface.
- Apple Notarization documentation — used as the reference for "what credentials must exist vs must not be committed."
- SOLID: Robert C. Martin's canonical definitions — used as the rubric, not re-derived.

---

## Key Technical Decisions

- **Audit deliverables live in `docs/audits/`, not `docs/plans/`.** Plans drive change; audits record state. Mixing them in `docs/plans/` would make the directory unreadable over time.
- **One findings file per criterion**, plus one consolidated summary. Keeps each lens reviewable in isolation while giving a single "what now?" entry point.
- **Findings use a fixed schema** (id, location, severity, effort, confirmed/suspected, evidence, recommendation). A consistent shape makes the output mechanically usable as input to follow-up `ce-plan` runs.
- **No code changes in this plan.** Tempting to fix small things inline (e.g., add a missing `.gitignore` line). Resist — surfaces the pattern of how findings flow into follow-ups, and keeps the audit reproducible.
- **Critical findings short-circuit.** If U2 (OWASP) finds an actually-exposed secret in git history, the plan stops and prompts the user before continuing other units. Discovery of exposure outranks completing the audit.

---

## Open Questions

### Resolved During Planning

- *Is this an assessment plan or a remediation plan?* — Assessment only. Remediation is downstream (see Scope Boundaries).
- *Where do audit outputs live?* — `docs/audits/YYYY-MM-DD-<criterion>.md` plus one consolidated summary.
- *Should LNT be force-applied?* — No; partial N/A with rationale, since the macOS app build pipeline lacks Helm/CRDs/PVs.

### Deferred to Implementation

- *Final severity thresholds.* The rubric is fixed (Critical/High/Medium/Low) but the line between High and Medium for, say, an SRP violation in a 500-line file is judgment-call territory and will be decided per finding with rationale.
- *Whether the SOLID audit needs static analysis tooling* (e.g., SwiftLint with custom rules). Decide once U1 starts — if manual reading covers the surface adequately, skip.

---

## Output Structure

    docs/
      audits/
        2026-05-01-bau-assessment.md           # consolidated summary (R5)
        2026-05-01-solid.md                    # U1 output
        2026-05-01-owasp.md                    # U2 output
        2026-05-01-tdd.md                      # U3 output
        2026-05-01-formatting-and-changelog.md # U4 output (formatting + changelog combined)
        2026-05-01-lnt-and-sensitive-files.md  # U5 output (LNT + sensitive-file combined)

---

## High-Level Technical Design

> *This illustrates the intended approach and is directional guidance for review, not implementation specification. The implementing agent should treat it as context, not code to reproduce.*

Per-finding schema used across all audit files:

```
### F-<criterion>-<n>. <short title>

- Location: <repo-relative-path>[:line-range or :symbol]
- Severity: Critical | High | Medium | Low
- Effort:   S | M | L
- Status:   confirmed | suspected
- Evidence: <what was read / observed; quote a few lines or describe the structural issue>
- Why it matters: <link to BAU criterion>
- Recommendation: <concrete next step, sized to land as one PR>
- Follow-up plan: <suggested ce-plan title, or "none — fix inline">
```

Consolidated summary structure:

```
# BAU Assessment 2026-05-01

## Executive read
- N findings: C critical, H high, M medium, L low
- Top 3 recommended follow-up plans

## Per-criterion roll-up
- SOLID: <count by severity, link to detail file>
- OWASP: <count by severity, link to detail file>
- TDD: <count by severity, link to detail file>
- Formatting/changelog: <count by severity, link to detail file>
- LNT/sensitive files: <count by severity, link to detail file>

## Prioritized backlog (severity * effort)
- 1. <finding id> — <one-liner>
- 2. ...
```

---

## Implementation Units

- [x] U1. **SOLID assessment**

**Goal:** Produce `docs/audits/2026-05-01-solid.md` enumerating SRP/OCP/LSP/ISP/DIP findings, with focus on the largest/most-coupled files first.

**Requirements:** R1, R2, R3, R4

**Dependencies:** None

**Files:**
- Create: `docs/audits/2026-05-01-solid.md`
- Read: `QuickRecorder/SCContext.swift`, `QuickRecorder/RecordEngine.swift`, `QuickRecorder/QuickRecorderApp.swift`, `QuickRecorder/AVContext.swift`, `QuickRecorder/ViewModel/QmaPlayer.swift`, `QuickRecorder/ViewModel/AreaSelector.swift`, `QuickRecorder/ViewModel/ContentView.swift`, `QuickRecorder/ViewModel/SettingsView.swift`

**Approach:**
- Triage by size first — open the 5 largest files, read them end-to-end, identify distinct responsibilities clustered in each.
- For each suspected SRP violation, list the 2-4 cohesive responsibility groups and propose a split shape (just the boundaries — the actual extraction is a follow-up plan).
- Spot-check OCP/DIP by looking for `switch` ladders over types and direct singleton/`SCContext.shared` reach-throughs from ViewModels.
- LSP and ISP are unlikely to be primary issues in a SwiftUI app; cover briefly and move on if no signal.

**Patterns to follow:**
- Per-finding schema in High-Level Technical Design.

**Test scenarios:** Test expectation: none — this unit produces a markdown audit document, not code.

**Verification:**
- `docs/audits/2026-05-01-solid.md` exists, contains at least one finding for each of the 5 largest source files (or an explicit "no SRP issue found" note with rationale).
- Every finding cites a repo-relative path and either a line range or a symbol name.

---

- [x] U2. **OWASP assessment**

**Goal:** Produce `docs/audits/2026-05-01-owasp.md` covering input handling, AppleScript execution, credential storage, file I/O, IPC, and update channel (Sparkle).

**Requirements:** R1, R2, R3, R4

**Dependencies:** None

**Files:**
- Create: `docs/audits/2026-05-01-owasp.md`
- Read: `QuickRecorder/Supports/AppleScript.swift`, `QuickRecorder/Supports/Sparkle.swift`, `QuickRecorder/RecordEngine.swift` (file output paths), `QuickRecorder/QuickRecorder.entitlements`, `QuickRecorder/Info.plist`, `scripts/credentials.sh`, `scripts/notarize.sh`, `scripts/setup-credentials-interactive.sh`, `.env`, `.env.sample`, `.gitignore`

**Approach:**
- Map the OWASP Top 10 (Mobile/Desktop variant) to this app: A01 Broken Access Control → entitlements scope; A02 Cryptographic Failures → how credentials are stored on disk and in env; A03 Injection → AppleScript command construction, shell argument handling in `scripts/`; A05 Security Misconfiguration → entitlements granted, hardened runtime flags; A08 Software/Data Integrity → Sparkle update channel signature verification.
- Run `git log --all -- .env` and `git log --all --oneline -S 'app-specific-password' -S 'APP_SPECIFIC_PASSWORD'` (read-only) to detect whether secrets were ever committed. If yes → Critical, halt and prompt user.
- Check entitlements file for over-broad capabilities (e.g., full disk access requested but unused).
- Confirm AppleScript execution does not concatenate untrusted strings into AppleScript source.

**Execution note:** Before doing any deep audit, run the git-history secret-exposure check first. A Critical exposure short-circuits the rest of this unit and the plan.

**Patterns to follow:**
- Per-finding schema in High-Level Technical Design.
- CLAUDE.md sensitive-file list.

**Test scenarios:** Test expectation: none — audit document only.

**Verification:**
- `docs/audits/2026-05-01-owasp.md` exists with at least one finding (or explicit "clean") for each of: AppleScript surface, Sparkle update channel, credential storage, entitlements scope, shell-script argument handling.
- Git-history secret check is documented with the exact commands run and their outcomes.

---

- [x] U3. **TDD assessment**

**Goal:** Produce `docs/audits/2026-05-01-tdd.md` quantifying coverage by surface and listing the highest-value test gaps.

**Requirements:** R1, R2, R3, R4

**Dependencies:** None

**Files:**
- Create: `docs/audits/2026-05-01-tdd.md`
- Read: `QuickRecorderTests/*.swift`, `QuickRecorderTests/TEST_IMPROVEMENTS.md`, `scripts/TEST_EVALUATION_REPORT.md`, `QuickRecorderTests/RUN_TESTS.md`
- Cross-reference: `QuickRecorder/**/*.swift` (which files have a corresponding `*Tests.swift`?)

**Approach:**
- Build a coverage map: for each non-trivial source file (>100 lines), is there a matching test file? If partially covered, what's tested vs not?
- Re-use existing `TEST_IMPROVEMENTS.md` content as input — don't re-derive, layer onto it.
- Identify ViewModel files with zero test files as the largest cohesive gap.
- Note that TDD is also a *workflow* criterion, not just a coverage one. Comment on whether new code in recent commits ships with tests, using `git log --since='2026-02-01' --stat` as signal.

**Patterns to follow:**
- Per-finding schema in High-Level Technical Design.

**Test scenarios:** Test expectation: none — audit document only.

**Verification:**
- `docs/audits/2026-05-01-tdd.md` exists with a coverage table (source file → test file → coverage note) and a ranked gap list.
- The audit cites specific source files for each gap, not generic "tests are sparse" prose.

---

- [x] U4. **Formatting + changelog convention assessment**

**Goal:** Produce `docs/audits/2026-05-01-formatting-and-changelog.md` enumerating: (a) AsciiDoc files violating the heading/bullet blank-line rule (likely none — quick check), (b) `*.sh` files and `Taskfile.yml`/`Justfile` missing the changelog block.

**Requirements:** R1, R2, R3, R4

**Dependencies:** None

**Files:**
- Create: `docs/audits/2026-05-01-formatting-and-changelog.md`
- Read (existence + tail): all `**/*.sh`, `Justfile`, any `Taskfile.yml`
- Search: any `**/*.adoc` files (likely zero in this repo)

**Approach:**
- Run a single shell pass listing every `*.sh` file (tracked + untracked) and check the last ~10 lines for the `# Changelog:` marker. Output a table: file, has-changelog, last-modified-date.
- Likewise for `Justfile`. Confirmed that `scripts/build.sh`, `scripts/release.sh`, `scripts/notarize.sh`, `scripts/setup.sh` lack the block from the planning scan; full inventory comes from this unit.
- AsciiDoc check: quick `find . -name '*.adoc'`. If zero, document N/A with command output.

**Patterns to follow:**
- Per-finding schema in High-Level Technical Design.
- CLAUDE.md changelog block format (shell vs YAML variant).

**Test scenarios:** Test expectation: none — audit document only.

**Verification:**
- The audit contains a complete table of `*.sh` files with present/absent changelog flag.
- The non-compliant set is sized (e.g., "12 of 30 scripts missing changelog block") so the follow-up plan is scoped.

---

- [x] U5. **LNT + sensitive-file protection assessment**

**Goal:** Produce `docs/audits/2026-05-01-lnt-and-sensitive-files.md` covering: (a) which LNT categories actually apply to this macOS desktop app and how they fare, (b) `.gitignore` coverage of CLAUDE.md sensitive-file patterns, (c) whether any tracked file currently matches a sensitive pattern.

**Requirements:** R1, R2, R3, R4

**Dependencies:** None

**Files:**
- Create: `docs/audits/2026-05-01-lnt-and-sensitive-files.md`
- Read: `.gitignore`, `Justfile` (cleanup recipes), `scripts/build.sh`, `scripts/release.sh`, `scripts/notarize.sh` (artifact paths)
- Inventory: tracked-file scan via `git ls-files | grep -iE '<sensitive patterns>'`

**Approach:**
- LNT scoping: list the CLAUDE.md teardown categories and mark each Applicable / N/A with one-line rationale. Likely Applicable: build artifacts (`build/`, `DerivedData/`, `*.dSYM.zip`), notarization staging dirs, exported `.app`/`.dmg`. Likely N/A: Helm releases, CRDs, namespaces, PVs, Docker images.
- Confirm a `just clean`-equivalent (or script) exists and covers each Applicable category. From scan: `Justfile` exists; verify its clean target.
- `.gitignore` audit: confirm presence of `*.key`, `*.password`, `*.pkcs12`, `*secrets.yaml`, `*secret.yaml`, `.env.*`, plus catch-alls. The current scan shows `.env` covered but the others not.
- Tracked-file scan: run `git ls-files | grep -iE '(\.key$|\.password$|\.pkcs12$|secrets?\.ya?ml$|\.env(\..+)?$)'` and capture results. `.env.sample` is acceptable; flag anything else.

**Execution note:** If the tracked-file scan returns a real secret (not just a sample), this is Critical — halt, surface to user, defer remediation to a focused fix plan.

**Patterns to follow:**
- Per-finding schema in High-Level Technical Design.
- CLAUDE.md "Sensitive File Protection" and "Leave No Trace" sections.

**Test scenarios:** Test expectation: none — audit document only.

**Verification:**
- LNT applicability table is present with rationale per category.
- `.gitignore` gap list is explicit (which patterns from CLAUDE.md are missing).
- Tracked-file scan command and output are recorded verbatim in the audit.

---

- [x] U6. **Consolidated summary + prioritized backlog**

**Goal:** Produce `docs/audits/2026-05-01-bau-assessment.md` rolling up U1-U5 with an executive read and a prioritized remediation backlog.

**Requirements:** R5

**Dependencies:** U1, U2, U3, U4, U5

**Files:**
- Create: `docs/audits/2026-05-01-bau-assessment.md`
- Read: all five per-criterion files from U1-U5

**Approach:**
- Open each per-criterion file; pull the count by severity and the top finding.
- Build the prioritized backlog by sorting findings on `severity_weight / effort_weight` (Critical=8, High=4, Medium=2, Low=1; S=1, M=2, L=4 — so a Critical-S sits at the top).
- For the top 3-5 backlog items, name the suggested follow-up `ce-plan` (e.g., "refactor: split SCContext.swift along screen-capture / permissions / state boundaries").
- No new findings introduced here; this unit is pure synthesis.

**Patterns to follow:**
- Consolidated summary template in High-Level Technical Design.

**Test scenarios:** Test expectation: none — audit document only.

**Verification:**
- Summary file links to each per-criterion file with relative paths.
- Backlog is ordered (not alphabetical, not random) by the severity/effort heuristic.
- Top 3 entries name a concrete follow-up plan title, not a vague suggestion.

---

## System-Wide Impact

- **Interaction graph:** None — this plan only writes new files under `docs/audits/` and reads existing source.
- **Error propagation:** N/A — no code paths affected.
- **State lifecycle risks:** N/A — read-only audit.
- **API surface parity:** N/A.
- **Integration coverage:** N/A.
- **Unchanged invariants:** All production source files in `QuickRecorder/`, all `scripts/*.sh`, `Justfile`, `.gitignore`, `.env` — explicitly untouched. Findings are recorded; remediation is deferred to follow-up plans.

---

## Risks & Dependencies

| Risk | Mitigation |
|------|------------|
| Audit drifts toward "fix as you go" and ends up half-refactor, half-audit | Execution note on U2/U5 explicitly halts on Critical findings; otherwise no code changes are permitted in this plan (see Key Technical Decisions). |
| Finding sprawl — 100+ low-severity items make the output unusable | Each unit's verification requires severity sizing and only the top backlog gets named follow-up plans. Low-severity items roll up as counts, not enumerated. |
| Discovery of an actually-leaked credential mid-audit | U2 runs the git-history check first, halts the plan on Critical, and prompts the user before any cleanup action. |
| LNT criterion is mis-applied to a desktop app and pads the output | Scope Boundaries marks LNT partial-N/A explicitly; U5 documents which categories don't apply with rationale. |
| TDD assessment overlaps existing `TEST_IMPROVEMENTS.md` and re-derives instead of layering | U3 approach explicitly says "re-use existing content as input, don't re-derive." |

---

## Documentation / Operational Notes

- New directory `docs/audits/` is introduced. Add a one-line note to `README.md` or `SKILLS.md` describing what lives there once U6 lands — but do that *after* the audit is complete, not as part of this plan.
- The consolidated summary is the durable handoff artifact; per-criterion files are detail support.

---

## Sources & References

- User's BAU criteria: `~/.claude/CLAUDE.md` (SOLID / OWASP / TDD / AsciiDoc / changelog / LNT / sensitive files).
- Local context: `SKILLS.md`, `QuickRecorderTests/TEST_IMPROVEMENTS.md`, `scripts/TEST_EVALUATION_REPORT.md`.
- Repo signals captured during planning: file sizes from `wc -l` on `QuickRecorder/**/*.swift`; gitignore scan; sensitive-file tracked-file scan; script-tail checks on `scripts/build.sh`, `scripts/release.sh`, `scripts/notarize.sh`, `scripts/setup.sh`.
