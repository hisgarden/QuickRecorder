# Taskfile Usage Examples

## Real-World Scenarios

### Scenario 1: First Time Setup

```bash
# Install Task
brew install go-task/tap/go-task

# Navigate to project
cd /path/to/QuickRecorder

# Setup everything
task setup
# Automatically:
# - Checks for XcodeGen
# - Generates Xcode project
# - Resolves Swift packages
```

### Scenario 2: Development Build & Test

```bash
# Build and test in sequence
task build
task test

# Or run both (Task can parallelize)
task build test
```

### Scenario 3: Smart Caching in Action

```bash
# First build: compiles everything
$ task build
🔨 Debug Build...
[xcodebuild output...]

# Second build: skipped (unchanged)
$ task build
task: Task "build" is up to date

# After editing a source file
$ echo "// comment" >> QuickRecorder/ViewModel/SettingsView.swift
$ task build
🔨 Debug Build...
[xcodebuild output...]
```

### Scenario 4: Release Build (Single Command)

```bash
# Old way (Justfile - manual sequence)
just release
just archive
just notarize

# New way (Taskfile - automatic)
task notarize
# Automatically runs: release → archive → notarize
```

### Scenario 5: Verify Release Will Build Correctly

```bash
# See what will run without executing
$ task --dry notarize

task: Task "check-project" is up to date
task: [release] echo "🚀 Release Build..."
task: [release] xcodebuild build -project QuickRecorder.xcodeproj...
task: [archive] echo "📦 Creating Archive..."
task: [archive] ARCHIVE_NAME="QuickRecorder-$(date +%Y%m%d-%H%M)"
task: [archive] xcodebuild archive...
task: [notarize] echo "🔐 Notarizing app..."
task: [notarize] chmod +x scripts/notarize.sh && ./scripts/notarize.sh
```

### Scenario 6: CI/CD Pipeline

```bash
# Run full CI check (build + test)
task ci-check
# Automatically runs: check-project → ci-build → ci-test

# See what will run
task --dry ci-check
```

### Scenario 7: List Available Tasks

```bash
$ task --list
task: Available tasks for this project:
* appcast:             Generate Sparkle appcast.xml
* archive:             Create .xcarchive
* build:               Debug build
* build-plus:          Debug build with full logging and analysis
* check-project:       Verify Xcode project exists
* ci-build:            CI build (no code signing)
* ci-check:            CI full check (build + test)
* ci-test:             CI test with coverage
* clean:               Clean build artifacts
* clean-all:           Deep clean (remove project, regenerate needed)
* default:             Show all available tasks
* diagnose:            Full system diagnostic
...
```

### Scenario 8: Clean & Regenerate

```bash
# Clean everything
task clean

# Deep clean (remove Xcode project)
task clean-all

# Regenerate from scratch
task regenerate
```

### Scenario 9: Diagnostic Check

```bash
$ task diagnose
QuickRecorder System Diagnostic
Date: Fri Jan 17 12:30:45 PST 2026
Xcode: configured
XcodeGen: installed
Project: exists
project.yml: exists
```

### Scenario 10: View Build Logs

```bash
# Show all logs
task logs

# Show latest errors
task errors
```

## Comparison: Before vs After

### Build Release Build

**Before (Justfile):**
```bash
just release        # Build
just archive        # Archive
# Then manually run notarize script
```

**After (Taskfile):**
```bash
task notarize       # All three run automatically
```

### Check If Build Is Current

**Before (Justfile):**
```bash
just build          # Always rebuilds
just build          # Always rebuilds again
```

**After (Taskfile):**
```bash
task build          # Builds first time
task build          # Skipped (no changes)
task --force build  # Force rebuild if needed
```

### Verify Release Workflow

**Before (Justfile):**
```bash
# No way to preview the sequence without running
just release    # Could fail after spending time on this
just archive    # Could fail after spending time on previous
```

**After (Taskfile):**
```bash
task --dry notarize  # Preview the entire sequence first
# All steps shown without execution
task notarize        # Run with confidence
```

## Advanced Usage

### Force Rebuild

```bash
task --force release
# Rebuilds even if sources haven't changed
```

### Skip Dependencies

```bash
task archive --no-deps
# Runs archive without running release
```

### Verbose Output

```bash
task --verbose build
# Shows detailed execution information
```

### Watch Task

```bash
task --watch build
# Runs task and watches for changes
```

### Multiple Tasks in Sequence

```bash
task clean build test
# Runs: clean, then build, then test (in order)
```

### Parallel Execution

```bash
task --parallel build test
# Runs build and test in parallel (if safe)
```

## Tips & Tricks

### 1. Use Dry Run to Understand Flow
```bash
task --dry publish    # See the complete release workflow
```

### 2. Check Task Status
```bash
task --list           # See all tasks
task --list-all       # See even disabled tasks
```

### 3. Force Re-run When Needed
```bash
task --force build    # Skip cache, rebuild
```

### 4. Watch Mode for Development
```bash
task --watch test     # Re-run tests on file changes
```

### 5. Understand Dependencies
```bash
# archive depends on release:
task archive          # Auto-runs release first

# notarize depends on archive:
task notarize         # Auto-runs release → archive
```

## Common Workflows

### Daily Development
```bash
task build
task test
```

### Preparing Release
```bash
task notarize         # Build → Archive → Notarize
task --dry publish    # Preview publication
task publish          # Publish to GitHub
```

### CI/CD Pipeline
```bash
task ci-check         # Build + Test + Report
```

### System Maintenance
```bash
task diagnose         # System health check
task clean-all        # Deep clean
task setup            # Regenerate
```

## Troubleshooting Examples

### Build Not Rebuilding?
```bash
# Check if file changed
task --dry build

# Force rebuild
task --force build
```

### Unsure What Will Run?
```bash
# Always preview first
task --dry <task>

# Then run with confidence
task <task>
```

### Need to Clean Everything?
```bash
task clean-all        # Remove project
task setup            # Regenerate from scratch
```

---

For complete documentation, see:
- `TASK_QUICK_REFERENCE.md` - Command cheat sheet
- `TASKFILE_README.md` - Getting started
- `TASKFILE_FEATURES.md` - Feature deep dive
- `TASKFILE_MIGRATION.md` - Migration from Justfile
