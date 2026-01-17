# Justfile → Taskfile Migration Guide

## Overview

This project has been migrated from **Justfile** to **Taskfile** with improved build dependency management. Task Runner (Task) provides better dependency tracking, allowing tasks to automatically execute their dependencies before running.

## Installation

### Remove Justfile Dependency
```bash
# If you had installed just via Homebrew:
brew uninstall just
```

### Install Task
```bash
# macOS (Homebrew)
brew install go-task/tap/go-task

# Or visit: https://taskfile.dev/installation/
```

## Quick Start

### Before (Justfile)
```bash
just build
just test
just publish
```

### After (Taskfile)
```bash
task build
task test
task publish
```

## Key Improvements

### 1. Build Dependency Management

**Taskfile** automatically manages dependencies. Tasks that depend on others will run them first:

```yaml
notarize:
  desc: Build, archive, and notarize
  deps:
    - release      # Runs first
    - archive      # Runs second (depends on release)
  cmds:
    - ./scripts/notarize.sh  # Runs last
```

**Benefits:**
- `task notarize` automatically runs `task release` and `task archive` before notarizing
- No manual sequencing needed
- Dependency graph is explicit and visible
- Failed dependencies prevent downstream tasks from running

### 2. Source-Based Caching

Tasks can skip if source files haven't changed:

```yaml
build:
  sources:
    - QuickRecorder/**/*.swift
    - QuickRecorder/Info.plist
    - QuickRecorder.xcodeproj/project.pbxproj
```

Run `task build` multiple times without changes = skipped build (saves time).

### 3. Status Checks

Skip tasks if prerequisites are met:

```yaml
check-project:
  status:
    - test -d QuickRecorder.xcodeproj
  cmds:
    - echo "✅ Project verified"
```

If the directory exists, the check passes and cmds are skipped.

## Command Reference

### Setup & Configuration
```bash
task setup              # Full setup (install XcodeGen, generate project)
task generate           # Generate Xcode project from project.yml
task diagnose           # System diagnostic
task deps               # Check dependencies
```

### Building
```bash
task build              # Debug build
task release            # Release build
task build-plus         # Build with logging & analysis
```

### Testing
```bash
task test               # Run unit tests
task test-coverage      # Run tests with code coverage
task watch              # Watch mode (re-test on file changes)
```

### Distribution
```bash
task archive            # Create .xcarchive (depends on release build)
task export-app         # Export .app to Desktop
task notarize           # Build → Archive → Notarize (auto runs deps)
task staple             # Staple notarization ticket
task appcast            # Generate Sparkle appcast.xml
task publish            # Complete release workflow
```

### Maintenance
```bash
task clean              # Clean build artifacts
task clean-all          # Deep clean + remove project
task regenerate         # Clean all + setup (fresh start)
task open               # Open in Xcode
task size               # Show last build size
task logs               # View build logs
task errors             # Show last build errors
```

### CI/CD
```bash
task ci-build           # CI build (no signing)
task ci-test            # CI test with coverage
task ci-check           # CI full check (build + test)
```

## Build Dependency Examples

### Example 1: Simple Release Workflow
```bash
task notarize
```

This automatically runs:
1. `task release` (compiles app)
2. `task archive` (creates .xcarchive, depends on release)
3. `./scripts/notarize.sh` (notarizes the archive)

### Example 2: Complete Publication
```bash
task publish
```

This automatically runs:
1. `task release` (compiles in Release mode)
2. `task archive` (creates archive)
3. Then your release workflow (DMG, appcast, git push)

### Example 3: Skip Unchanged Builds
```bash
task build
# Output: "✅ Task build is up to date"  (if no source changes)
```

## Differences from Justfile

| Feature | Justfile | Taskfile |
|---------|----------|----------|
| Dependency management | Manual sequencing | Automatic (deps) |
| Source file tracking | None | Supported (sources) |
| Status checks | None | Supported (status) |
| Caching | None | Skip if unchanged |
| Parallel execution | No | Yes (with proper setup) |
| YAML format | No (custom) | Yes |
| Task visualization | `just --list` | `task --list` |

## Troubleshooting

### Task not found
```bash
task --list  # See all available tasks
task <name>  # Run task
```

### Task runs every time (no caching)
Ensure `sources:` is defined correctly:
```yaml
build:
  sources:
    - QuickRecorder/**/*.swift
```

### Dependency not running
Check the `deps:` section:
```yaml
archive:
  deps:
    - check-project  # This runs first
```

### Want to force run without cache
```bash
task --force build  # Ignore cache, run anyway
```

## Migration Checklist

- [x] Created `Taskfile.yml` with all recipes
- [x] Added build dependencies (release → archive → notarize)
- [x] Added source file tracking for caching
- [x] Added status checks for project validation
- [ ] Test `task build`
- [ ] Test `task test`
- [ ] Test `task archive` (depends on release)
- [ ] Test `task publish` (multi-step workflow)
- [ ] Update CI/CD pipeline (if needed)
- [ ] Remove `Justfile` from repo (optional)

## Next Steps

1. **Install Task:**
   ```bash
   brew install go-task/tap/go-task
   ```

2. **Test basic tasks:**
   ```bash
   task diagnose      # System check
   task build         # Build debug
   task test          # Run tests
   ```

3. **Test dependency workflow:**
   ```bash
   task notarize      # Should auto-run release + archive
   ```

4. **Update documentation** (if distributed)

5. **Update CI/CD** if using GitHub Actions

## Resources

- **Task Documentation:** https://taskfile.dev
- **Task CLI Guide:** https://taskfile.dev/usage/
- **Task Variables:** https://taskfile.dev/api/#vars
- **Task Dependencies:** https://taskfile.dev/usage/#dependencies

## Questions?

Refer to Taskfile docs at https://taskfile.dev/api/ for advanced features like:
- Parallel task execution
- Environment variables
- Conditional task execution
- Output formatting
