---
title: "Migrate notarization to notarytool keychain-profile; remove APP_SPECIFIC_PASSWORD env var"
type: fix
status: completed
date: 2026-05-01
origin: docs/audits/2026-05-01-owasp.md
verified: 2026-05-01 (submission b36d9ce9-e487-4893-8a2e-92e4b5c142a8 Accepted)
---

# Migrate notarization to notarytool keychain-profile; remove `APP_SPECIFIC_PASSWORD` env var

## Overview

Eliminate `APP_SPECIFIC_PASSWORD` as an environment variable, `.env` field, or shell-script parameter anywhere in the repo. Notarization moves to `xcrun notarytool`'s native `--keychain-profile` mechanism: credentials are stored once via `xcrun notarytool store-credentials`, gated by Touch ID / Apple Watch on every access, and never enter shell variable scope. After this plan ships, the only place an app-specific password lives is the macOS Keychain — and the only way to access it is biometric/passcode approval at notarization time.

This plan is the **forward-fix** that makes the F-owasp-1 leak structurally non-recurrable. It does **not** rotate the already-exposed credential (user's manual step at appleid.apple.com) and does **not** rewrite git history (separate plan, post-rotation).

---

## Problem Frame

The OWASP audit (`docs/audits/2026-05-01-owasp.md`, F-owasp-1) confirmed an Apple App-Specific Password committed to `scripts/STAPLING_GUIDE.md` and pushed to `origin/main`. The audit treated the credential as publicly exposed. The leak landed because the example in that doc used a real password value instead of a placeholder — and the project's notarization flow normalized having that password value live in plaintext: `.env` carries it (currently mode `0644`), `setup-credentials-interactive.sh` writes it there, `notarize.sh` and `check-notarization.sh` read it back into shell variables, and `xcrun notarytool` is invoked with `--apple-id "$APPLE_ID" --password "$APP_SPECIFIC_PASSWORD"`. The password is therefore visible to:

- Anyone with read access to `.env` (currently world-readable on disk),
- The shell process environment of any script that sources it,
- `ps`-style observation during the brief `notarytool` invocation window,
- Anyone who copy-pastes a `notarytool` example without sanitizing — exactly how F-owasp-1 happened.

`xcrun notarytool` has supported `--keychain-profile <name>` since Xcode 13. Apple's `xcrun notarytool store-credentials` writes a structured entry to Keychain (Apple ID + Team ID + ASP bundled together under one profile name) and the binary itself is the only consumer. The password never enters shell scope. Touch ID prompts on every read by default. This plan adopts that path as the only path.

The repo already has *partial* keychain support — `buildRelease.sh --setup-keychain` exists today and writes via custom `security add-internet-password` calls — but the downstream consumers (`notarize.sh`, `check-notarization.sh`) extract the password back into a shell variable before invoking `notarytool`, which defeats the purpose. This plan replaces both the storage and the consumption with notarytool's native flow.

---

## Requirements Trace

- R1. After this plan ships, no file under the repo emits, samples, or documents `APP_SPECIFIC_PASSWORD=...` as an env-var or `.env` field.
- R2. `xcrun notarytool` is never invoked with `--apple-id` + `--password` flags from any tracked script. All invocations use `--keychain-profile <name>`.
- R3. A single canonical setup command exists (`./scripts/buildRelease.sh --setup-keychain` or equivalent) that calls `xcrun notarytool store-credentials` once and produces a working keychain profile.
- R4. Touch ID / Apple Watch prompt is the access gate; the password value is not extractable by any tracked script's shell logic.
- R5. The exposing example in `scripts/STAPLING_GUIDE.md` is replaced with a `--keychain-profile`-based example using a placeholder profile name.
- R6. Existing tracked notarization docs (`scripts/NOTARIZATION_SETUP.md`, `scripts/APPLE_ID_GUIDE.md`, `scripts/STAPLING_GUIDE.md`, `Justfile` help text) reflect the new flow only — no env-var fallback documented as supported.
- R7. The migration is verifiable end-to-end: a real notarization run completes successfully under the new flow before the plan is marked complete.

**Non-requirement (explicit):** This plan does not rotate the leaked credential. That is a manual user action at appleid.apple.com and must happen *before* U6's verification step (otherwise verification would re-use the compromised credential).

---

## Scope Boundaries

- This plan does **not** rotate the exposed Apple App-Specific Password. That is a manual user action at appleid.apple.com, treated as a prerequisite to U6.
- This plan does **not** rewrite git history to scrub the leaked credential from past commits. That is a separate `fix:` plan (`fix: filter-repo scrub scripts/STAPLING_GUIDE.md secret from public history`) that should run after rotation is confirmed.
- This plan does **not** change the GitHub PAT also present in `.env`. The PAT is local-only (not in git history) and out of this plan's scope; it should be rotated separately as part of the credential-hygiene cleanup.
- This plan does **not** restructure the broader build pipeline (Justfile, Xcode project config, signing identity selection). Only credential-handling code paths change.
- This plan does **not** introduce CI-side notarization. Keychain-profile flows are inherently local-developer-machine flows. CI notarization (App Store Connect API key) is a separate concern and explicitly deferred.

### Deferred to Follow-Up Work

- **Credential rotation** — manual web-UI action at appleid.apple.com. Prerequisite to U6.
- **Git history scrub** — separate `fix:` plan. Sequence: rotate first, then this plan, then history scrub.
- **GitHub PAT rotation + `.env` permission tightening** — separate small `fix:` plan; can fold into the `.gitignore` hardening PR from the audit's F-lnt-1 backlog.
- **CI notarization via App Store Connect API key** — separate `feat:` plan if/when CI builds need to notarize. Out of scope here.

---

## Context & Research

### Relevant Code and Patterns

- `scripts/buildRelease.sh:44-105` — current `setup_keychain()` uses `security add-internet-password` under service `"hisgarden"` with accounts `"appleid"` and `"notarize"`. To be replaced.
- `scripts/buildRelease.sh:138-141` — `--setup-keychain` flag dispatch. Implementation body changes; flag name preserved.
- `scripts/buildRelease.sh:48-66` — `get_apple_id()` and `get_app_password()` helpers extract creds from keychain into shell variables. To be deleted (notarytool no longer needs them).
- `scripts/notarize.sh:43-49,106,131-141,287-296,339,356,372` — every `xcrun notarytool` invocation and every error message that references the env-var flow.
- `scripts/check-notarization.sh:29-52` — second consumer of `notarytool` with `--apple-id`/`--password`.
- `scripts/credentials.sh` — entire file becomes vestigial under the new flow. The `get_credentials` orchestrator (Keychain → env → `.env` → prompt) collapses to "let notarytool resolve via keychain-profile, prompt only for the profile name on first use." Plan to delete the file in U4.
- `scripts/setup-credentials-interactive.sh:107,160` — currently writes `APP_SPECIFIC_PASSWORD=$APP_PASSWORD` to `.env`. Either delete the script (its purpose dissolves) or repurpose it to call the new setup command.
- `Justfile:271` — help-text reference to `export APP_SPECIFIC_PASSWORD='xxxx-...'`. Update.
- `.env.sample` lines 1-22 — currently teaches the bad pattern in its preamble even while warning against it. Trim to just `APPLE_ID` and `APPLE_TEAM_ID`.

### Institutional Learnings

- The repo's `~/.claude/CLAUDE.md` "Sensitive File Protection" rule lists `*.password` and `*.env` patterns as commit-block surfaces — this plan reinforces that boundary in code, not just in policy.
- `docs/audits/2026-05-01-owasp.md` F-owasp-1 evidence shows the leak path: doc example → copy-paste pattern → real password in tracked file. The forward-fix is to make sure no doc *needs* a real password value to be useful.

### External References

- Apple Developer documentation on `xcrun notarytool store-credentials` and `--keychain-profile`. The relevant primitives:
  - `xcrun notarytool store-credentials <profile-name> --apple-id <email> --team-id <id> --password <ASP>` — interactive, run once.
  - `xcrun notarytool submit <path> --keychain-profile <profile-name>` — no `--apple-id` / `--password` ever again.
  - `xcrun notarytool history --keychain-profile <profile-name>` — same for history queries.
  - `xcrun notarytool log <submission-id> --keychain-profile <profile-name>` — same for log fetches.
- Touch ID / Apple Watch prompt is the macOS Keychain default for items written by tools-with-entitlements like notarytool. Verified by Apple's tooling for Xcode 13+.

---

## Key Technical Decisions

- **Profile name: `QuickRecorder-notarize`.** Stable, repo-namespaced. Avoid `notarize` alone (could collide across projects on the same machine) and avoid the current `"hisgarden"` service name (user-name-coupled). The profile name appears in scripts and docs as a literal — keep it predictable.
- **Single canonical setup command: `./scripts/buildRelease.sh --setup-keychain`.** Preserve the existing flag name (already documented in `--help`) but swap the body to call `xcrun notarytool store-credentials`. No new entry-point script.
- **Delete `credentials.sh` and `setup-credentials-interactive.sh` rather than refactor.** Their reason for existing — bridging env-var / `.env` / Keychain into a single shell variable — disappears entirely under the keychain-profile flow. Keeping them refactored to "just call notarytool" would be dead weight.
- **Drop the `--secure` flag from `buildRelease.sh`.** Today it gates the keychain-vs-env branch. Under the new flow there is no env branch — keychain-profile is the only path. The flag becomes a no-op. Remove it from arg parsing and from `--help` output. (Minor breaking change to anyone scripting against `buildRelease.sh`; mitigated by the new path being strictly safer.)
- **`.env` keeps `APPLE_ID` and `APPLE_TEAM_ID`.** Both are non-secret — Team IDs are public identifiers, Apple ID emails are user-readable. They stay as convenience for the user, but neither is *required* (notarytool's keychain profile already stores them). The script falls back to the keychain profile values if `.env` is absent.
- **No backward-compatibility shim.** If a user has the old keychain entries from `security add-internet-password`, they re-run `--setup-keychain` once. Documented in U5 release notes; trivial to redo.
- **Verification gates the plan, not just U6.** U6 actually runs a notarization end-to-end with the new flow. The plan is not complete on a successful build — it's complete on a successful notarization submission ID returning `Accepted`.

---

## Open Questions

### Resolved During Planning

- *Should `--secure` survive as a deprecated alias?* No — see Key Technical Decisions. The path it gates no longer has a meaningful "off" position.
- *Where should the canonical setup live?* `buildRelease.sh --setup-keychain` (existing flag, swap body). Avoids new surface area.
- *What profile name?* `QuickRecorder-notarize`. Repo-namespaced, stable, appears literally in scripts and docs.
- *Is rotation in scope?* No — explicit non-goal. Rotation is a manual prerequisite to U6 verification.

### Deferred to Implementation

- *Whether to delete `credentials.sh` outright or leave it as an empty stub.* Plan says delete; if implementation discovers another script sourcing it, decide between fix-the-caller or stub-with-deprecation-notice at that moment.
- *Exact Touch ID prompt UX.* macOS Keychain controls the prompt; not a script-level decision. If the prompt does not appear (e.g., on a non-biometric Mac), document the password fallback path in U5.
- *Whether `Justfile`'s `notarize` recipe needs new env-var inputs.* Likely no — the recipe just shells to `scripts/notarize.sh`, which post-migration takes no credential inputs. Confirm during U2.

---

## High-Level Technical Design

> *This illustrates the intended approach and is directional guidance for review, not implementation specification.*

### Before / after, by callsite

| File | Before | After |
|---|---|---|
| `scripts/buildRelease.sh` `setup_keychain()` | `security add-internet-password -s hisgarden -a appleid …` × 2 | `xcrun notarytool store-credentials "QuickRecorder-notarize" --apple-id "$APPLE_ID" --team-id "$APPLE_TEAM_ID"` (prompts for password) |
| `scripts/notarize.sh` submit (×2) | `xcrun notarytool submit "$ZIP" --apple-id "$APPLE_ID" --password "$APP_SPECIFIC_PASSWORD" --team-id "$TEAM_ID" --wait` | `xcrun notarytool submit "$ZIP" --keychain-profile "QuickRecorder-notarize" --wait` |
| `scripts/notarize.sh` history (×2) | `xcrun notarytool history --apple-id "$APPLE_ID" --password "$APP_SPECIFIC_PASSWORD" --team-id "$TEAM_ID"` | `xcrun notarytool history --keychain-profile "QuickRecorder-notarize"` |
| `scripts/check-notarization.sh` log (×2) | `xcrun notarytool log "$SUB_ID" --apple-id "$APPLE_ID" --password "$APP_SPECIFIC_PASSWORD"` | `xcrun notarytool log "$SUB_ID" --keychain-profile "QuickRecorder-notarize"` |
| `.env.sample` | preamble + `APP_SPECIFIC_PASSWORD=...` line | `APPLE_ID`, optional `APPLE_TEAM_ID`, no password field |
| `Justfile:271` | `export APP_SPECIFIC_PASSWORD='xxxx-...'` (in help text) | `./scripts/buildRelease.sh --setup-keychain` (one-time) |
| `scripts/STAPLING_GUIDE.md` (the leaking file) | inline `--password glwq-...` example | `--keychain-profile QuickRecorder-notarize` example |

### New developer flow

```
# One-time setup (run once per machine)
./scripts/buildRelease.sh --setup-keychain
  → prompts: Apple ID email
  → prompts: Apple Team ID (or reads from .env)
  → prompts: App-Specific Password (input hidden)
  → calls: xcrun notarytool store-credentials "QuickRecorder-notarize" \
             --apple-id <email> --team-id <id>
           (notarytool prompts for password, stores in Keychain)
  → confirms: profile created

# Every subsequent notarization (from any context)
just notarize
# or
./scripts/notarize.sh <path-to-app>
  → notarytool submit ... --keychain-profile "QuickRecorder-notarize"
  → macOS Keychain prompts: Touch ID / passcode
  → submission proceeds; password never enters shell scope
```

---

## Implementation Units

- [x] U1. **Replace `setup_keychain()` body in `buildRelease.sh` with `notarytool store-credentials` invocation**

**Goal:** `./scripts/buildRelease.sh --setup-keychain` produces a working `QuickRecorder-notarize` profile via `xcrun notarytool store-credentials`. The custom `security add-internet-password` plumbing is removed.

**Requirements:** R3, R4

**Dependencies:** None

**Files:**
- Modify: `scripts/buildRelease.sh` (replace lines 44-105 helpers and 68-103 setup body; preserve `--setup-keychain` flag at 138-141)
- Test: manual run of `./scripts/buildRelease.sh --setup-keychain` followed by `xcrun notarytool history --keychain-profile QuickRecorder-notarize` to confirm profile resolves

**Approach:**
- Delete `get_apple_id()`, `get_app_password()`, `check_keychain_credentials()` — no longer needed downstream.
- Rewrite `setup_keychain()` to:
  1. Read `APPLE_ID` and `APPLE_TEAM_ID` from `.env` if present; prompt otherwise.
  2. Invoke `xcrun notarytool store-credentials "QuickRecorder-notarize" --apple-id "$APPLE_ID" --team-id "$APPLE_TEAM_ID"` — notarytool prompts for the password directly.
  3. On success, print confirmation: profile name, how to verify (`xcrun notarytool history --keychain-profile QuickRecorder-notarize`).
- Drop the `SECURE` / `--secure` arg-parse branches (they no longer mean anything).
- Update `--help` to reflect: `--setup-keychain` is one-time setup; `--notarize` does the build+notarize using the profile; no other credential-related flags.

**Patterns to follow:**
- The existing `--help` block's tone and indentation in `buildRelease.sh` (replace, don't restructure).
- Defensive shell: `set -euo pipefail` already present at top of file.

**Test scenarios:**
- Happy path: fresh machine, no profile exists; user runs `--setup-keychain`; profile is created; `xcrun notarytool history --keychain-profile QuickRecorder-notarize` returns successfully.
- Idempotency: user runs `--setup-keychain` twice; second run overwrites without error (notarytool's `store-credentials` is upsert-style).
- Missing `.env`: user runs without `.env` present; script prompts for Apple ID and Team ID interactively rather than failing.

**Verification:**
- After running `--setup-keychain`, `security find-generic-password -s "com.apple.gk.notary.tool.profile" -a "QuickRecorder-notarize"` returns 0 (notarytool stores under this service).
- `xcrun notarytool history --keychain-profile QuickRecorder-notarize` returns history (or empty success) without error.
- No password value appears in any shell variable, `set` output, or `ps` listing during or after the run.

---

- [x] U2. **Migrate `scripts/notarize.sh` to `--keychain-profile`**

**Goal:** All `xcrun notarytool` invocations in `notarize.sh` use `--keychain-profile "QuickRecorder-notarize"`. The script no longer reads `APP_SPECIFIC_PASSWORD` or sources `credentials.sh`.

**Requirements:** R1, R2, R4

**Dependencies:** U1 (profile must exist before this script's flow can succeed end-to-end; the script edit itself does not depend on U1)

**Files:**
- Modify: `scripts/notarize.sh` — replace lines 43-49 credential-extraction block, line 106 `cut -d'|'` extraction, lines 131-141 history calls, lines 287-296 submit calls, lines 339/356/372 error-message templates that show the old flag set.

**Approach:**
- Delete the `get_credentials_for_script` shim (or whatever the local `notarize.sh` extraction helper is called) at lines 43-49 and 106.
- Replace each `--apple-id ... --password ...` (with optional `--team-id`) tuple with the single flag `--keychain-profile "QuickRecorder-notarize"`.
- Update error messages at 339/356/372 (currently show `xcrun notarytool log "$SUB_ID" --apple-id ... --password ...` as a hint) to show the keychain-profile form.
- Add an early-fail guard: if `xcrun notarytool history --keychain-profile "QuickRecorder-notarize" >/dev/null 2>&1` fails, print: `Run ./scripts/buildRelease.sh --setup-keychain first.` and exit 1.
- Constant `KEYCHAIN_PROFILE="QuickRecorder-notarize"` defined at top-of-file so the literal isn't repeated.

**Patterns to follow:**
- Existing top-of-file `set -euo pipefail` and color-output helpers — no change.
- Existing argument-parsing style for the `<path-to-app>` positional.

**Test scenarios:**
- Happy path: existing `.app` zipped, profile present, `notarize.sh` submits successfully and prints submission ID; Touch ID prompt fires once.
- Missing profile: profile not yet created; script prints the setup-instruction and exits non-zero before attempting any notarytool call.
- Re-run: a second `notarize.sh` invocation in the same shell session prompts Touch ID again (Keychain default is per-call, not session).
- History query: `--history` flag (if present) returns submission history under the new flag set.

**Verification:**
- `grep -c 'APP_SPECIFIC_PASSWORD\|--password ' scripts/notarize.sh` returns 0.
- `grep -c -- '--keychain-profile' scripts/notarize.sh` returns ≥ 5 (one per notarytool invocation including error-message templates).
- An end-to-end submit completes (deferred to U6, but a `--dry-run` or `--help` smoke must succeed here).

---

- [x] U3. **Migrate `scripts/check-notarization.sh` and `scripts/staple.sh` examples**

**Goal:** `check-notarization.sh` consumes only the keychain profile; `staple.sh` documentation lines reference the new flag set.

**Requirements:** R1, R2, R6

**Dependencies:** None (independent of U1/U2 at the edit level; U6 verifies all together)

**Files:**
- Modify: `scripts/check-notarization.sh` lines 29-52
- Modify: `scripts/staple.sh` line 78 (currently shows `xcrun notarytool history --apple-id <email> --password <password>` in user-facing help text)

**Approach:**
- `check-notarization.sh`: drop the `APP_SPECIFIC_PASSWORD` env-var guard at lines 29-31; replace both `xcrun notarytool log` invocations at 45-52 with the keychain-profile form. Same early-fail guard pattern as U2.
- `staple.sh`: swap the help-text command example to `--keychain-profile QuickRecorder-notarize`.

**Patterns to follow:**
- Same `KEYCHAIN_PROFILE` constant pattern as U2 for `check-notarization.sh`.

**Test scenarios:**
- `check-notarization.sh <submission-id>` succeeds against a real submission ID using the profile.
- `staple.sh` with no args still prints the help text, and the help text shows the keychain-profile form.

**Verification:**
- `grep -c 'APP_SPECIFIC_PASSWORD\|--password ' scripts/check-notarization.sh scripts/staple.sh` returns 0.
- `grep -c -- '--keychain-profile' scripts/check-notarization.sh` returns 2 (both `notarytool log` calls).
- `staple.sh` help-text example references `--keychain-profile`.

---

- [x] U4. **Remove `APP_SPECIFIC_PASSWORD` emissions from `.env.sample`, `Justfile`, and delete dead credential-shim scripts**

**Goal:** No tracked file emits, samples, or documents `APP_SPECIFIC_PASSWORD` as an environment variable.

**Requirements:** R1, R6

**Dependencies:** U2, U3 (the consumers must already have moved off `APP_SPECIFIC_PASSWORD` before deleting the shims that fed it to them)

**Files:**
- Modify: `.env.sample` — remove the `APP_SPECIFIC_PASSWORD=...` line (line 21) and the entire preamble that warns about it (lines 1-21). Replace with a 4-line preamble pointing at `./scripts/buildRelease.sh --setup-keychain`.
- Modify: `Justfile` line 271 — replace the `export APP_SPECIFIC_PASSWORD='xxxx-...'` help text with the keychain-setup pointer.
- Delete: `scripts/credentials.sh` — entire file becomes vestigial.
- Delete: `scripts/setup-credentials-interactive.sh` — purpose dissolves; the new flow is `--setup-keychain`.
- Audit-remove: any other reference. Search command: `git grep -n 'APP_SPECIFIC_PASSWORD\|APPLE_ID_PASSWORD' -- ':!docs/audits/' ':!docs/plans/'`. Each hit becomes either a deletion or a docs-update (handled in U5).

**Approach:**
- Before deleting `credentials.sh` and `setup-credentials-interactive.sh`, confirm no remaining script sources them: `grep -rn 'credentials.sh\|setup-credentials-interactive' scripts/ Justfile`. If any consumer remains after U2/U3, fix it here.
- The user has unrelated uncommitted work in some of these files (per branch `chore/bau-assessment-2026-05-01` git status). Do not touch those changes; only this plan's edits.

**Patterns to follow:**
- `.env.sample` should mirror the conventional shape: comment-prefixed instructions, then KEY=value lines for non-secret keys only.

**Test scenarios:**
- After this unit, `git grep -n 'APP_SPECIFIC_PASSWORD' -- ':!docs/audits/' ':!docs/plans/' ':!.env'` returns zero matches. (`.env` itself is gitignored; the user removes their local line manually as part of U6's prerequisites.)
- `git ls-files scripts/credentials.sh scripts/setup-credentials-interactive.sh` returns empty (files gone from index).

**Verification:**
- The `git grep` count above is 0.
- `Justfile`'s help text for the relevant recipe (likely `notarize`-help or similar) renders the keychain-profile guidance, not the env-var guidance.

---

- [x] U5. **Update tracked docs to reflect keychain-profile-only flow; placeholder-swap `STAPLING_GUIDE.md`**

**Goal:** All tracked notarization docs describe only the keychain-profile flow. The leaking inline credential in `scripts/STAPLING_GUIDE.md` is replaced with a `--keychain-profile QuickRecorder-notarize` placeholder example.

**Requirements:** R5, R6

**Dependencies:** U1 (the canonical setup command described in docs must exist)

**Files:**
- Modify: `scripts/STAPLING_GUIDE.md` — replace the inline-credential troubleshooting example with a `--keychain-profile` form. (This is *not* a fix for the historical leak — the credential is still in commits `e83c933`, `faa9e32`, `e511f04`. This unit fixes the working tree only; history scrub is a separate plan.)
- Modify: `scripts/NOTARIZATION_SETUP.md` — full rewrite of the credential-setup section. Replace `APP_SPECIFIC_PASSWORD` env-var instructions with `./scripts/buildRelease.sh --setup-keychain` instructions.
- Modify: `scripts/APPLE_ID_GUIDE.md` — drop env-var setup; reference the keychain flow.
- Modify (if it exists): `scripts/CODE_SIGNING_GUIDE.md`, `scripts/DEVELOPER_ID_CERTIFICATE.md` — only if they reference notarization credentials. Touch lightly; not the focus.
- Audit pass: `git grep -nE 'APP_SPECIFIC_PASSWORD|--password .* (notarytool|notarize)' -- '*.md'` — every hit is either updated or removed.
- Optional (already in `docs/audits/`): the audit's redacted references to the old flow are intentional historical record; do not edit.

**Approach:**
- The docs are user-facing and tone-sensitive — keep the same voice, just swap the flow.
- For `STAPLING_GUIDE.md`, the troubleshooting block becomes:

  ```
  # Check past submissions:
  xcrun notarytool history --keychain-profile QuickRecorder-notarize

  # Fetch a submission's log:
  xcrun notarytool log <submission-id> --keychain-profile QuickRecorder-notarize
  ```

  No real Apple ID, no real password, no real Team ID — just the literal profile name.

**Patterns to follow:**
- Existing doc tone in `scripts/NOTARIZATION_SETUP.md`.

**Test scenarios:**
- `git grep -n 'glwq\|--password .* notar\|APP_SPECIFIC_PASSWORD' -- '*.md' ':!docs/audits/' ':!docs/plans/'` returns 0 matches.
- A reader following `NOTARIZATION_SETUP.md` from a fresh checkout can complete setup without ever needing to set an env var.

**Verification:**
- The grep above returns 0.
- `STAPLING_GUIDE.md` no longer contains any literal credential value (only `<placeholder>` or profile-name forms).

---

- [x] U6. **End-to-end verification: rotate, set up, notarize**

**Goal:** A real notarization run completes successfully under the new flow, proving every other unit's correctness on a real Apple submission. This unit also serves as the gate that rotation has happened.

**Requirements:** R7

**Dependencies:** U1, U2, U3, U4, U5; **and credential rotation completed by user (manual prerequisite)**

**Files:**
- No file changes. This is a verification unit. Output is a single line in the final commit message confirming submission ID `Accepted`.

**Approach:**
1. **Confirm rotation prerequisite.** Verify with the user that the Apple App-Specific Password has been rotated at appleid.apple.com. The new ASP value is the only one stored via U1.
2. Remove the `APP_SPECIFIC_PASSWORD` line from local `.env`. The user does this manually (out of git scope).
3. `./scripts/buildRelease.sh --setup-keychain` — store the new ASP under profile `QuickRecorder-notarize`. Touch ID prompt should fire when notarytool writes the profile.
4. Build a release: `just build-release` (or the equivalent recipe).
5. Notarize: `./scripts/notarize.sh <path-to-app>`. Touch ID prompt fires; submission proceeds; submission ID returned; status reaches `Accepted`.
6. Staple: `./scripts/staple.sh <path-to-app>`.
7. Verify: `xcrun stapler validate <path-to-app>` succeeds.

**Test scenarios:**
- End-to-end happy path runs cleanly.
- Without rotation prerequisite (i.e., still using the leaked ASP): U1 setup may succeed, but U6 verification is incomplete because the profile holds a known-compromised credential. **Do not mark complete in this state.**

**Verification:**
- A submission ID exists and is `Accepted` per `xcrun notarytool info <submission-id> --keychain-profile QuickRecorder-notarize`.
- `xcrun stapler validate` succeeds on the notarized `.app`.
- `grep -c APP_SPECIFIC_PASSWORD .env` returns 0 (user-confirmed local cleanup).
- `git grep -c APP_SPECIFIC_PASSWORD -- ':!docs/audits/' ':!docs/plans/'` returns 0.

---

## System-Wide Impact

- **Interaction graph:** `buildRelease.sh` ↔ `notarize.sh` ↔ `check-notarization.sh` ↔ `staple.sh` are the affected scripts; `Justfile` recipes that invoke them are downstream. No Swift source code touched.
- **Error propagation:** New error path — "keychain profile not found" must produce a clear message pointing the user at `--setup-keychain`. The early-fail guard in U2 and U3 covers this.
- **State lifecycle risks:** macOS Keychain is the new state holder. If the keychain entry is deleted out-of-band, `--setup-keychain` re-creates it; no other script holds a copy.
- **API surface parity:** `--secure` flag in `buildRelease.sh` is removed. Minor breaking change for anyone scripting against it; documented in U1.
- **Integration coverage:** U6 is the integration test. There is no CI gate today (per audit F-tdd-6) and adding one is out of scope here.
- **Unchanged invariants:** Build pipeline (`xcodebuild` invocation, archive shape, signing identity selection) is untouched. Only the credential-handoff layer between scripts and `xcrun notarytool` changes.

---

## Risks & Dependencies

| Risk | Mitigation |
|------|------------|
| User runs `--setup-keychain` with the *old* (leaked) ASP and proceeds before rotation. The keychain profile is then a clean cage around a compromised key. | U6 explicitly gates on rotation. Plan does not mark complete until rotation is confirmed. |
| Touch ID prompt does not fire (e.g., on a non-biometric Mac). | macOS falls back to admin passcode prompt automatically; document the fallback briefly in `NOTARIZATION_SETUP.md` (U5) and confirm during U6. |
| `xcrun notarytool` version too old for `store-credentials`/`--keychain-profile`. | The repo already requires Xcode 13+ per `notarize.sh:64-67`. No new constraint introduced. |
| Existing keychain entries from `security add-internet-password` (service `"hisgarden"`) linger after migration. | Harmless but stale. Document the optional cleanup command in U5: `security delete-internet-password -s "hisgarden" -a "appleid"` and `-a "notarize"`. |
| User has uncommitted edits to `scripts/notarize.sh` on `main` (per branch state observed during BAU audit). | U2 explicitly notes "do not touch unrelated uncommitted changes". The fix is scoped to credential-handling lines only. Surface a clean diff before commit. |
| `Justfile` recipes implicitly rely on `APP_SPECIFIC_PASSWORD` being in environment via `dotenv` loading. | U2/U4 verify by grepping `Justfile` for the var name. If any recipe does, it gets updated to the new flow in the same unit. |
| The leaked ASP was used for non-notarization purposes (e.g., signed into iCloud, Mac App Store Connect uploads). | Out of scope of this plan — but rotation at appleid.apple.com revokes the credential everywhere it was authorized. The audit's recommendation to review submission history covers this. |

---

## Documentation / Operational Notes

- After this plan ships, the canonical "how to notarize" reference is `scripts/NOTARIZATION_SETUP.md` (rewritten in U5). Keep it short — the new flow is two commands.
- Mention the deletion of `credentials.sh` and `setup-credentials-interactive.sh` in the PR description so reviewers know it's intentional, not accidental.
- The leaked-credential history scrub is **NOT** part of this plan. After this PR merges and rotation is verified, open the follow-up `fix:` plan for `git filter-repo` + force-push.

---

## Sources & References

- **Origin audit:** [docs/audits/2026-05-01-owasp.md](../audits/2026-05-01-owasp.md), F-owasp-1.
- **BAU assessment summary:** [docs/audits/2026-05-01-bau-assessment.md](../audits/2026-05-01-bau-assessment.md).
- **Apple notarytool reference:** Apple Developer documentation for `xcrun notarytool` (`store-credentials`, `--keychain-profile`).
- **Current scripts:** `scripts/buildRelease.sh`, `scripts/notarize.sh`, `scripts/check-notarization.sh`, `scripts/staple.sh`, `scripts/credentials.sh`, `scripts/setup-credentials-interactive.sh`, `Justfile`, `.env.sample`.
- **CLAUDE.md sensitive-file rule:** `~/.claude/CLAUDE.md`.
