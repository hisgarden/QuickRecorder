# Taskfile Features & Build Dependency Examples

## Build Dependency Tree

The Taskfile understands the logical sequence of build tasks:

```
publish
  ├── release (build Release configuration)
  │   └── check-project (validate project exists)
  └── archive (create .xcarchive)
      └── release (reused, won't run twice)

notarize
  ├── release (build Release configuration)
  │   └── check-project
  └── archive (create .xcarchive)
      └── release (reused)

ci-check (full CI workflow)
  ├── ci-build (Release build)
  │   └── check-project
  └── ci-test (run tests)
      └── check-project
```

## Key Features Explained

### 1. Automatic Dependency Execution

When you run:
```bash
task archive
```

Taskfile automatically executes:
1. `check-project` (prereq of archive)
2. `archive` (the requested task)

**You don't need to manually run prerequisites.**

### 2. Smart Caching with Source Tracking

```yaml
build:
  sources:
    - QuickRecorder/**/*.swift
    - QuickRecorder/Info.plist
    - QuickRecorder.xcodeproj/project.pbxproj
```

**First run:** Builds the app
```bash
$ task build
🔨 Debug Build...
[building...]
```

**Second run** (no source changes): Skips the build
```bash
$ task build
✅ Task build is up to date
```

**Modified source:** Rebuilds automatically
```bash
$ echo "// change" >> QuickRecorder/ViewModel/SettingsView.swift
$ task build
🔨 Debug Build...
[building...]
```

### 3. Status Checks

```yaml
check-project:
  status:
    - test -d QuickRecorder.xcodeproj
  cmds:
    - echo "✅ Project verified"
```

**If project exists:** Task skips (status check passes)
```bash
$ task check-project
✅ Task check-project is up to date
```

**If project missing:** Task runs (status check fails)
```bash
$ task check-project
✅ Project verified
```

### 4. Dependency Reuse

Dependencies run only once, even if multiple tasks depend on them:

```yaml
notarize:
  deps:
    - release
    - archive  # also depends on release
```

When you run `task notarize`:
- `release` runs once
- `archive` runs (uses the same release build)
- `notarize` runs last

**Result:** No duplicate builds.

### 5. Error Handling

If a dependency fails, dependent tasks don't run:

```bash
$ task notarize
# If 'release' fails, 'archive' and 'notarize' are skipped
```

## Common Workflows

### Workflow 1: Quick Build & Test
```bash
task build
task test
```

Both use `check-project` dependency (runs once, reused).

### Workflow 2: Full Release Cycle
```bash
task publish
```

Automatically runs:
1. `check-project`
2. `release` (builds app in Release mode)
3. `archive` (creates .xcarchive)
4. Release workflow (create DMG, update appcast, push to GitHub)

### Workflow 3: Notarization
```bash
task notarize
```

Automatically runs:
1. `release` (compile app)
2. `archive` (create .xcarchive)
3. Notarization script

### Workflow 4: CI/CD Pipeline
```bash
task ci-check
```

Automatically runs:
1. `check-project`
2. `ci-build` (compile Release)
3. `ci-test` (run tests with coverage)

Both reuse `check-project`.

## Advanced Features

### Force Re-run Ignoring Cache
```bash
task --force build
```

### Run Task Only (Skip Dependencies)
```bash
task notarize --no-deps
```

### List All Tasks with Details
```bash
task --list
```

### View Task Dependency Graph
```bash
task --graph
```

### Dry Run (Show Commands Without Running)
```bash
task --dry notarize
```

### Verbose Output
```bash
task --verbose notarize
```

## Comparison: Before vs After

### Before (Justfile) - Manual Sequencing
```bash
# User must remember the order
just release          # Step 1: build
just archive          # Step 2: archive
just notarize         # Step 3: notarize
```

### After (Taskfile) - Automatic Dependencies
```bash
# One command, all prerequisites run automatically
task notarize
```

### Before (Justfile) - Always Rebuilds
```bash
just build    # Always rebuilds, even if nothing changed
just build    # Always rebuilds again
```

### After (Taskfile) - Smart Caching
```bash
task build    # Builds app
task build    # Skipped (nothing changed)
echo "change" >> QuickRecorder/ViewModel/SettingsView.swift
task build    # Rebuilds (source changed)
```

## Implementation Details

### Variables
```yaml
vars:
  PROJECT_NAME: QuickRecorder
  LOG_DIR: logs
  TIMESTAMP:
    sh: date +%Y%m%d-%H%M%S
  LOG_FILE: '{{.LOG_DIR}}/build-{{.TIMESTAMP}}.log'
```

Available in commands as `{{.VARIABLE_NAME}}`.

### Command Execution
```yaml
cmds:
  - echo "Message"                    # Shell command
  - sh: date                          # Explicit shell
  - cmd: xcodebuild build             # Multi-line
      -project QuickRecorder.xcodeproj
      -scheme QuickRecorder
```

### Conditional Execution
```yaml
watch:
  cmds:
    - sh: |
        if command -v fswatch > /dev/null; then
          fswatch -r . | while read; do
            task test
          done
        else
          echo "Install fswatch: brew install fswatch"
        fi
```

## File Organization

```
QuickRecorder/
├── Taskfile.yml                 ← Main task definitions
├── TASKFILE_MIGRATION.md        ← Migration guide
├── TASKFILE_FEATURES.md         ← This file
├── project.yml                  ← XcodeGen config
├── scripts/
│   ├── build.sh                 ← Build with logging
│   ├── notarize.sh              ← Notarization script
│   ├── staple.sh                ← Stapling script
│   └── release.sh               ← Release workflow
└── Justfile                     ← (Optional: keep for reference)
```

## Migration Checklist

- [x] Created `Taskfile.yml` with all recipes
- [x] Implemented build dependency chain
- [x] Added source file tracking
- [x] Added status checks
- [x] Documented features
- [ ] Test each major task
- [ ] Update team documentation
- [ ] Remove old Justfile (optional)

## Troubleshooting

**Task shows "no sources or status checks defined"**
```bash
task --force build  # Force execution
```

**Dependency not running**
Check the `deps:` section and ensure they're spelled correctly.

**Want to see what will run**
```bash
task --graph notarize  # Show dependency graph
```

**Task too slow**
- Check for unnecessary dependencies
- Use `task --no-deps` to skip dependencies if safe
- Consider parallelization with `run: when_available`

## Next Steps

1. Replace all `just` commands with `task` in your workflow
2. Update CI/CD pipeline (GitHub Actions, etc.)
3. Remove `Justfile` once migration is complete
4. Share updated docs with team

---

For more details, see the [Task Documentation](https://taskfile.dev)
