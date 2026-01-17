# Task Quick Reference

## Installation
```bash
brew install go-task/tap/go-task
```

## Basic Commands

```bash
task                    # Show help (default task)
task --list             # List all tasks
task build              # Run build task
task --dry <task>       # Show what will run without executing
task --force <task>     # Force run (ignore cache)
```

## Key Tasks

### Setup
```bash
task setup              # Install XcodeGen, generate project
task generate           # Generate Xcode project
task diagnose           # System diagnostic
```

### Building
```bash
task build              # Debug build (cached)
task release            # Release build (cached)
task build-plus         # Build with logging
```

### Testing
```bash
task test               # Run tests
task test-coverage      # Run tests with coverage
```

### Distribution
```bash
task archive            # Create .xcarchive (auto-runs: release)
task notarize           # Build → Archive → Notarize (auto-runs: release, archive)
task publish            # Full release workflow (auto-runs: release, archive)
```

### Maintenance
```bash
task clean              # Clean artifacts
task clean-all          # Deep clean + regenerate
task open               # Open in Xcode
```

## Build Dependency Chain Examples

### Example 1: task archive
Automatically runs:
1. `release` (compiles Release build)
2. `archive` (creates .xcarchive)

### Example 2: task notarize
Automatically runs:
1. `release` (compiles Release build)
2. `archive` (creates .xcarchive)
3. Notarization script

### Example 3: task ci-check
Automatically runs in parallel:
1. `ci-build` (Release build)
2. `ci-test` (tests with coverage)

Both depend on `check-project` (runs once, reused).

## Smart Caching

Source files tracked:
- `QuickRecorder/**/*.swift`
- `QuickRecorder/Info.plist`
- `QuickRecorder.xcodeproj/project.pbxproj`

```bash
task build        # First run: builds
task build        # Second run: skipped (no changes)
# Edit a source file
task build        # Rebuilds automatically
```

## Dry Run (See What Will Execute)

```bash
task --dry notarize
# Output shows:
# task: [release] echo "🚀 Release Build..."
# task: [release] xcodebuild build...
# task: [archive] echo "📦 Creating Archive..."
# task: [archive] xcodebuild archive...
# task: [notarize] echo "🔐 Notarizing app..."
# task: [notarize] chmod +x scripts/notarize.sh && ./scripts/notarize.sh
```

## Force Build (Skip Cache)

```bash
task --force build    # Builds even if unchanged
```

## All Tasks

Run `task --list` to see all available tasks with descriptions.

## Verbose Output

```bash
task --verbose build  # Show detailed execution info
```

## Troubleshooting

**Task not found:**
```bash
task --list-all       # Show all tasks including disabled ones
```

**Dependency not running:**
Check the task definition. Dependencies are specified with `deps:`.

**Want to run task without dependencies:**
```bash
task notarize --no-deps  # Skip dependency execution
```

## Environment Variables

Pass variables:
```bash
task --var KEY=VALUE build
```

## Parallel Execution

Some tasks can run in parallel (specified by `run: when_available`).

## See Also

- Full documentation: `TASKFILE_README.md`
- Feature examples: `TASKFILE_FEATURES.md`
- Migration guide: `TASKFILE_MIGRATION.md`
- Task docs: https://taskfile.dev
