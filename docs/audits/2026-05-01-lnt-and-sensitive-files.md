# LNT + Sensitive-File Protection Audit — 2026-05-01

Scope: assess the QuickRecorder repository against the two BAU rules in `~/.claude/CLAUDE.md`:

1. Leave No Trace (LNT) — teardown returns the environment to a clean state.
2. Sensitive File Protection — `.gitignore` covers credentials/secrets and no real secret is tracked or in git history.

This is U5 of `docs/plans/2026-05-01-001-refactor-bau-design-criteria-assessment-plan.md`. Read-only audit; no source files modified.

---

## Sensitive-file scan (RUN FIRST)

Per the plan's execution note, the tracked-file scan ran before any deeper audit. The repository is **NOT halted** — no real tracked secret was found.

### Command 1 — tracked-file pattern scan

```bash
git ls-files | grep -iE '(\.key$|\.password$|\.pkcs12$|secrets?\.ya?ml$|\.env$|\.env\..+)' | grep -v -iE '(sample|example|template)' || echo "CLEAN: no tracked sensitive files"
```

Outcome (verbatim):

```
CLEAN: no tracked sensitive files
```

### Command 2 — `.gitignore` coverage of CLAUDE.md required patterns

```bash
for pat in '*.key' '*.password' '*.pkcs12' '.env' '.env.*' '*secrets.yaml' '*secret.yaml' 'credentials.sh'; do
  printf '%s : ' "$pat"
  grep -F -x "$pat" .gitignore >/dev/null 2>&1 && echo COVERED || echo MISSING
done
```

Outcome (verbatim):

```
*.key : MISSING
*.password : MISSING
*.pkcs12 : MISSING
.env : COVERED
.env.* : MISSING
*secrets.yaml : MISSING
*secret.yaml : MISSING
credentials.sh : MISSING
```

Note: `credentials.sh` reports MISSING because the strict `grep -F -x` check looks for an exact line match. The `.gitignore` actually contains the path-qualified entry `scripts/credentials.sh` at line 93, which does cover the project's only `credentials.sh` location. Treat as a path-scoped (rather than universally globbed) cover — see F-lnt-1.

### Command 3 — git history scan for ever-committed `.env`

```bash
git log --all --oneline -- '.env' 2>&1 | head -5
git log --all --oneline -- '.env.sample' 2>&1 | head -5
```

Outcome:

```
(no commits returned for .env)
---
3ea8900 Release v1.7.0: Complete distribution setup
```

`.env` has never been committed. `.env.sample` was added in `3ea8900`, which is acceptable per CLAUDE.md (samples are explicitly carved out).

### Command 4 — git history scan for the `APP_SPECIFIC_PASSWORD` token

```bash
git log --all --oneline -S 'APP_SPECIFIC_PASSWORD'
git log -p --all -S 'APP_SPECIFIC_PASSWORD' | grep -E '^(\+|\-).*APP_SPECIFIC_PASSWORD'
```

Outcome:

```
380d07e Fix permission dialog issues
e83c933 Add all necessary scripts for reproducible builds
3ea8900 Release v1.7.0: Complete distribution setup
```

All hits are **variable-name references** in scripts and docs (e.g., `if [ -z "$APP_SPECIFIC_PASSWORD" ]`, `echo "Please set APP_SPECIFIC_PASSWORD in .env or environment"`). No literal password value (`xxxx-xxxx-xxxx-xxxx` placeholder excepted in `.env.sample`) was found. Confirmed clean.

### Command 5 — working-tree presence

```bash
ls -la .env .env.sample
```

Outcome:

```
-rw-r--r--@ 1 jwen  staff  645 Dec 31 14:25 .env
-rw-r--r--@ 1 jwen  staff  969 Dec 30 10:51 .env.sample
```

`.env` exists in the working tree, is gitignored (line 94 of `.gitignore`), and does not appear in `git status`. `.env.sample` is tracked and contains only placeholder values (`xxxx-xxxx-xxxx-xxxx`) — verified against `.env.sample` lines 1-22.

**Verdict: not halted. Audit proceeds.**

---

## LNT applicability table

CLAUDE.md's "Leave No Trace — Teardown Tasks" section enumerates seven categories. QuickRecorder is a macOS desktop app built with Xcode, signed and notarized via Apple developer credentials, distributed via `.dmg` and Sparkle appcast. Most categories were authored for k8s/Helm/Docker workloads and do not apply.

| Category | Applicable to this repo? | Rationale |
|---|---|---|
| Helm releases (all namespaces) | N/A | No Helm charts; no Kubernetes deployment surface. |
| CRDs left after `helm uninstall` | N/A | No CRDs; no Kubernetes deployment surface. |
| Namespaces created by the project | N/A | No Kubernetes namespaces. |
| Stale PersistentVolumes (Released/Failed) | N/A | No Kubernetes/PV layer. |
| Local staging/config data | **Applicable** | Notarization staging under `archive/` (xcarchive bundles, export dirs, notary logs, `notarization.json`), `logs/` build logs, `~/Library/Developer/Xcode/DerivedData/QuickRecorder-*`. See `scripts/notarize.sh:176-310` for staging paths. |
| ALL Docker images (built, base, infra, operator, utility, registry-tagged) | N/A | No Docker images; build pipeline is `xcodebuild` + `notarytool`. |
| Post-teardown verification confirming each category is clean | **Applicable (partial)** | A `just clean` exists but does not perform post-clean verification. |

**Repo-specific LNT categories (not in CLAUDE.md but implied by macOS build pipeline):**

| Category | Applicable? | Rationale |
|---|---|---|
| Build artifacts (`build/`, `release/`, `archive/`) | **Applicable** | Created by `xcodebuild` and `scripts/notarize.sh`. |
| `DerivedData/` | **Applicable** | Xcode places intermediate build products in `~/Library/Developer/Xcode/DerivedData/QuickRecorder-*`. |
| `*.dSYM` / `*.dSYM.zip` | **Applicable** | Generated during Release builds; gitignored at `.gitignore:30-31`. |
| Exported `.app` / `.dmg` / `.zip` | **Applicable** | Produced by `scripts/notarize.sh` and `scripts/release.sh` under `archive/`. |
| Notarization staging (`archive/export-*`, `archive/notary-*.log`, `archive/notarization.json`) | **Applicable** | Created by `scripts/notarize.sh:211,282,292`. May contain submission IDs / Apple ID metadata. |
| Build logs (`logs/build-*.log`, `archive/build-*.log`) | **Applicable** | Generated by `scripts/build.sh` and the `just build-plus` recipe. |

---

## Cleanup-coverage table

The `clean` recipe lives in `Justfile:336-343`:

```
clean:
    rm -rf build
    rm -rf release
    rm -rf archive
    rm -rf ~/Library/Developer/Xcode/DerivedData/QuickRecorder-*
    xcodebuild clean -project QuickRecorder.xcodeproj -scheme QuickRecorder
```

A deeper `clean-all` extends it (`Justfile:346-350`) to remove `~/.xcodegen` and the generated `QuickRecorder.xcodeproj`.

| LNT category (Applicable) | Cleanup recipe | Verified covers |
|---|---|---|
| Build artifacts (`build/`) | `just clean` (`Justfile:338`) | Yes — `rm -rf build`. |
| `release/` directory | `just clean` (`Justfile:339`) | Yes — `rm -rf release`. |
| `archive/` (xcarchive, export, notary logs, notarization.json) | `just clean` (`Justfile:340`) | Yes — `rm -rf archive` removes the whole tree. |
| `DerivedData/QuickRecorder-*` | `just clean` (`Justfile:341`) | Yes. |
| Xcode internal build state | `just clean` (`Justfile:342`) | Yes — `xcodebuild clean`. |
| `logs/` build logs | **No recipe** | **Gap.** `Justfile` defines `LOG_DIR := "logs"` (line 36) and `build-plus` writes there, but no recipe removes it. |
| `*.dSYM` / `*.dSYM.zip` | Indirect | Removed transitively when `build/`, `archive/`, and `DerivedData` are wiped, since dSYMs are produced inside those trees. Confirmed only by location, not by explicit pattern. |
| Generated `.dmg` / `.zip` outside `archive/` | `.gitignore` only | `.gitignore` lines 103-104 ignore `*.dmg`/`*.zip` repo-wide, so they are not committed; if a release script writes them outside `archive/`, no cleanup recipe exists. |
| `.xcodegen` cache | `just clean-all` only | Yes (in `clean-all`), not in baseline `clean`. |
| Generated `QuickRecorder.xcodeproj` | `just clean-all` only | Yes (in `clean-all`), not in baseline `clean`. |
| Post-teardown verification | **No recipe** | **Gap.** No verification step that asserts each category is clean. CLAUDE.md explicitly calls this out. |

---

## Methodology

The audit ran the four sensitive-file scan commands prescribed in U5 verbatim, captured outputs, then walked `.gitignore` line-by-line against the eight CLAUDE.md sensitive patterns. For LNT, each CLAUDE.md teardown category was tagged Applicable or N/A with a one-line rationale grounded in the actual build pipeline. The Justfile `clean` and `clean-all` recipes were read in full (lines 336-354) and cross-referenced against the artifact paths produced by `scripts/notarize.sh:176-310`, `scripts/build.sh`, and `scripts/release.sh`. Only `Justfile`, `.gitignore`, `.env.sample`, and the cited script regions were inspected; no source code was modified.

---

## Findings

### F-lnt-2. Tracked-file sensitive-pattern scan is clean

- Location: repository root (tracked-file index)
- Severity: Low
- Effort: S
- Status: confirmed
- Evidence: `git ls-files | grep -iE '(\.key$|\.password$|\.pkcs12$|secrets?\.ya?ml$|\.env$|\.env\..+)' | grep -v -iE '(sample|example|template)'` returned `CLEAN: no tracked sensitive files`. Git history scans for `.env` and `APP_SPECIFIC_PASSWORD` returned only references to the variable name (no literal secret values). `.env.sample` (lines 1-22) contains only the placeholder `xxxx-xxxx-xxxx-xxxx (16 characters)`.
- Why it matters: Negative finding worth documenting — establishes baseline that no remediation/rotation is needed, and provides a re-runnable check for future audits.
- Recommendation: Keep as a regression check; consider adding the scan to a pre-commit hook (deferred to F-lnt-1 follow-up).
- Follow-up plan: none — fix inline (no fix needed).

### F-lnt-1. `.gitignore` is missing five of the eight CLAUDE.md sensitive patterns

- Location: `.gitignore:92-94` (the "Credentials and secrets" block)
- Severity: Medium
- Effort: S
- Status: confirmed
- Evidence: The CLAUDE.md "Sensitive File Protection" rubric requires `*.key`, `*.password`, `*.pkcs12`, `*.env`/`*.env.*`, `*secrets.yaml`, `*secret.yaml`. Current `.gitignore` covers only `.env` (exact match, line 94) and `scripts/credentials.sh` (path-scoped, line 93). The strict-match scan in Command 2 above returned MISSING for `*.key`, `*.password`, `*.pkcs12`, `.env.*`, `*secrets.yaml`, `*secret.yaml`, and a non-path-scoped `credentials.sh` glob. None of these patterns currently match an existing untracked file in the working tree (verified by `ls *.key *.password *.pkcs12 *secrets.yaml *secret.yaml` → no matches), so this is preventive hardening, not active leakage.
- Why it matters: A future contributor adding `notarization.key`, `signing.pkcs12`, `prod.env`, or a Helm-style `secrets.yaml` (e.g., during a CI/CD migration) would not be protected by the current `.gitignore`. CLAUDE.md mandates these patterns specifically because the cost of remediating a leaked credential post-commit is large.
- Recommendation: Append the missing globs to the "Credentials and secrets" block of `.gitignore`:

  ```
  *.key
  *.password
  *.pkcs12
  *.env
  .env.*
  !.env.sample
  *secrets.yaml
  *secret.yaml
  credentials.sh
  ```

  The `!.env.sample` negation preserves the existing tracked sample file. Replacing the bare `.env` line with `*.env` widens coverage to all `.env`-suffixed files; `.env.*` covers `.env.local`, `.env.production`, etc.
- Follow-up plan: `fix: harden .gitignore for CLAUDE.md sensitive-file patterns`.

### F-lnt-3. `Justfile` `clean` recipe does not remove `logs/` and has no post-clean verification

- Location: `Justfile:336-343` (`clean` recipe)
- Severity: Low
- Effort: S
- Status: confirmed
- Evidence: `clean` removes `build/`, `release/`, `archive/`, and `~/Library/Developer/Xcode/DerivedData/QuickRecorder-*`, then runs `xcodebuild clean`. It does not touch `logs/`, even though `Justfile:36-38` defines `LOG_DIR := "logs"` and `LOG_FILE := LOG_DIR + "/build-" + TIMESTAMP + ".log"` and `build-plus` writes there (`Justfile:182-185`). `ls logs/` confirms the directory exists in the working tree. The recipe also lacks a verification step asserting each category is empty after teardown — CLAUDE.md's LNT section explicitly requires "post-teardown verification confirming each category is clean."
- Why it matters: Build logs accumulate indefinitely (logs/ contained 5 entries during scan), inflating the working tree. More importantly, logs may capture transient paths that include user identifiers from `xcodebuild` output. Absence of verification means a partial-failure `clean` (e.g., a permissions error on one `rm`) can pass silently.
- Recommendation: Add `rm -rf logs/*` (preserving the directory) to the `clean` recipe. Append a verification block that fails the recipe if any of `build/`, `release/`, `archive/`, or `~/Library/Developer/Xcode/DerivedData/QuickRecorder-*` still exist after the cleanup commands run. Optionally add an explicit `*.dSYM`/`*.dSYM.zip` find-and-remove pass for files outside the wiped trees.
- Follow-up plan: `chore: extend Justfile clean recipe to cover logs/ and add post-teardown verification`.

---

## Roll-up

Severity counts:

- Critical: 0
- High: 0
- Medium: 1 (F-lnt-1)
- Low: 2 (F-lnt-2, F-lnt-3)

Top three follow-up recommendations (by severity * effort):

1. **F-lnt-1** — `fix: harden .gitignore for CLAUDE.md sensitive-file patterns`. Single-file edit; protects against future credential additions; one PR. Highest leverage of the three.
2. **F-lnt-3** — `chore: extend Justfile clean recipe to cover logs/ and add post-teardown verification`. Closes the LNT gap most relevant to a desktop-app pipeline.
3. **F-lnt-2 (preventive)** — Add the tracked-file sensitive-pattern scan as a pre-commit or CI check. Optional; institutionalizes the baseline this audit established. Could fold into the F-lnt-1 PR.

LNT applicability summary: 7 of CLAUDE.md's 7 enumerated teardown categories assessed — 5 N/A (Helm/CRDs/namespaces/PVs/Docker), 2 Applicable (local staging, post-teardown verification). 6 repo-specific LNT categories identified, all covered by `just clean` except `logs/` (gap noted in F-lnt-3).

Sensitive-file protection summary: 0 tracked secrets, 0 secrets in history, 0 `.env`-tracked. `.gitignore` covers `.env` and `scripts/credentials.sh` but is missing 5 of 8 CLAUDE.md-required globs; remediation is preventive (no current file leaks would result from the gap).
