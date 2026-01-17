# QuickRecorder Taskfile - Getting Started

## What's New

This project has migrated from **Justfile** to **Taskfile** with advanced build dependency management.

**Key Improvements:**
✅ Automatic dependency execution (no manual sequencing)  
✅ Smart source file caching (skip unchanged builds)  
✅ Build dependency graphs (see which tasks depend on what)  
✅ Better error handling (stop if prerequisites fail)  
✅ YAML format (industry standard)  

## Installation

### Step 1: Install Task

```bash
# macOS with Homebrew
brew install go-task/tap/go-task

# Verify installation
task --version
```

Other platforms: https://taskfile.dev/installation/

### Step 2: (Optional) Remove Justfile

```bash
brew uninstall just     # Remove old tool
# Optionally keep Justfile for reference
```

## First Run

```bash
# See all available tasks
task

# Run a task
task build

# See task dependencies
task --list

# Show dependency graph
task --graph notarize
```

## Common Commands

### Development
```bash
task setup              # First-time setup
task build              # Debug build
task test               # Run tests
task diagnose           # System check
```

### Building & Distribution
```bash
task release            # Release build
task archive            # Create .xcarchive
task notarize           # Build → Archive → Notarize (auto)
task publish            # Full release workflow
```

### Cleanup
```bash
task clean              # Clean artifacts
task clean-all          # Deep clean + regenerate
```

## The Power of Dependencies

### Before (Justfile)
You had to remember the sequence:
```bash
just release
just archive
just notarize
```

### Now (Taskfile)
One command handles everything:
```bash
task notarize
# Automatically runs: release → archive → notarize
```

### See What Will Run
```bash
task --dry notarize     # Show commands without running
task --graph notarize   # Show dependency tree
```

## Smart Caching

Build unchanged code is skipped automatically:

```bash
# First run: builds the app
$ task build
🔨 Debug Build...
[building app]

# Second run: skipped (no source changes)
$ task build
✅ Task build is up to date

# After code change: rebuilds
$ echo "// comment" >> QuickRecorder/ViewModel/SettingsView.swift
$ task build
🔨 Debug Build...
[building app]
```

## Build Dependency Tree

```
notarize (one command)
├── release (compile Release build)
│   └── check-project (verify project exists)
└── archive (create .xcarchive)
    └── release (reused from above)

publish (complete release)
├── release
│   └── check-project
└── archive
    └── release
    
ci-check (CI pipeline)
├── ci-build (Release build)
│   └── check-project
└── ci-test (run tests with coverage)
    └── check-project
```

## All Tasks

### Setup & Configuration
```bash
task setup              # Install XcodeGen, generate project
task generate           # Generate Xcode project
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
task test-coverage      # Run tests with coverage
task watch              # Auto-test on file changes
```

### Distribution
```bash
task archive            # Create .xcarchive (auto-deps)
task export-app         # Export .app to Desktop
task notarize           # Build → Archive → Notarize (auto-deps)
task staple             # Staple notarization ticket
task appcast            # Generate Sparkle appcast.xml
task publish            # Full release workflow (auto-deps)
```

### Maintenance
```bash
task clean              # Clean artifacts
task clean-all          # Deep clean + regenerate
task regenerate         # Fresh project setup
task open               # Open in Xcode
task size               # Show build size
task logs               # View build logs
task errors             # Show build errors
```

### CI/CD
```bash
task ci-build           # CI build (no signing)
task ci-test            # CI test with coverage
task ci-check           # CI full check (build + test)
```

## Advanced Usage

### Force Build Ignoring Cache
```bash
task --force build
```

### Run Task Without Dependencies
```bash
task notarize --no-deps
```

### List All Tasks
```bash
task --list
```

### Dry Run (Show Commands)
```bash
task --dry notarize
```

### Verbose Output
```bash
task --verbose build
```

## Troubleshooting

### "command not found: task"
```bash
brew install go-task/tap/go-task
```

### Task runs every time (no caching)
Make sure `sources:` is defined in the task. Check with:
```bash
task --list
```

### Task not running as expected
```bash
task --verbose <task>   # See what's happening
task --dry <task>       # See what would run
```

### Dependency not running
Check the `deps:` section in Taskfile.yml and ensure correct spelling.

## Documentation

- **Setup Guide:** See `TASKFILE_MIGRATION.md`
- **Features & Examples:** See `TASKFILE_FEATURES.md`
- **Task Official Docs:** https://taskfile.dev

## File Organization

```
QuickRecorder/
├── Taskfile.yml                 ← Task definitions (this replaces Justfile)
├── TASKFILE_README.md           ← Quick start (this file)
├── TASKFILE_MIGRATION.md        ← Detailed migration guide
├── TASKFILE_FEATURES.md         ← Features & examples
├── Justfile                     ← (old, can be archived)
├── project.yml                  ← XcodeGen config
└── scripts/
    ├── build.sh
    ├── notarize.sh
    ├── staple.sh
    └── release.sh
```

## Migration from Justfile

| Command | Justfile | Taskfile |
|---------|----------|----------|
| List tasks | `just --list` | `task --list` |
| Run task | `just build` | `task build` |
| Show help | `just` | `task` |
| Dry run | `just --dry build` | `task --dry build` |
| Watch mode | `just watch` | `task watch` |
| Full check | `just ci-check` | `task ci-check` |

## Next Steps

1. **Install Task:**
   ```bash
   brew install go-task/tap/go-task
   ```

2. **Test basic workflow:**
   ```bash
   task diagnose      # Check system
   task build         # Build debug
   task test          # Run tests
   ```

3. **Test dependency workflow:**
   ```bash
   task notarize      # Should auto-run release + archive
   ```

4. **Update CI/CD if needed**

5. **Share with team** (send them this README)

## Questions?

Refer to:
- Task Documentation: https://taskfile.dev
- This project: `TASKFILE_MIGRATION.md` and `TASKFILE_FEATURES.md`

---

**Ready to go?** Run: `task`
