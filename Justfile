#
#  QuickRecorder Justfile
#  A command runner for all development tasks with build logging & analysis
#
#  Installation:
#    1. Install just: brew install just
#    2. From project root: just --unstable --justfile Justfile <recipe>
#
#  Recipes:
#    just                    # Show all available recipes
#    just setup              # Full setup (install deps, generate project)
#    just generate           # Generate Xcode project only
#    just build              # Debug build with logging
#    just release            # Release build with logging
#    just build+             # Build with full analysis & debug info
#    just test               # Run all tests
#    just test-coverage      # Run tests with coverage
#    just watch              # Watch and test on changes
#    just archive            # Create .xcarchive
#    just export             # Export .app to Desktop
#    just clean              # Clean build artifacts
#
#  Debug Recipes:
#    just diagnose           # Full system diagnostic
#    just logs               # View build logs
#    just errors             # Show last build errors
#
#  For more info: https://github.com/casey/just
#

# =============================================================================
# Configuration
# =============================================================================

PROJECT_NAME := "QuickRecorder"
LOG_DIR := "logs"
TIMESTAMP := `date +%Y%m%d-%H%M%S`
LOG_FILE := LOG_DIR + "/build-" + TIMESTAMP + ".log"

# =============================================================================
# Default Recipe (Help)
# =============================================================================

default:
    @echo "QuickRecorder Development Commands"
    @echo ""
    @echo "Setup & Configuration:"
    @echo "  just setup           Install deps & generate project"
    @echo "  just generate       Generate Xcode project"
    @echo "  just diagnose       Full system diagnostic"
    @echo ""
    @echo "Building:"
    @echo "  just build          Debug build"
    @echo "  just release        Release build"
    @echo "  just build-plus     Build + full analysis & debug"
    @echo "  just release-export Release build + export to Desktop"
    @echo ""
    @echo "Testing:"
    @echo "  just test           Run all tests"
    @echo "  just test-coverage  Run tests with code coverage"
    @echo "  just watch          Watch mode (auto-re-test)"
    @echo ""
    @echo "Distribution:"
    @echo "  just archive        Create .xcarchive"
    @echo "  just export         Export .app to Desktop"
    @echo "  just notarize       Build + archive + notarize"
    @echo "  just publish        Complete release: DMG + appcast + git push"
    @echo "  just appcast        Generate/update appcast.xml"
    @echo ""
    @echo "Logs & Debug:"
    @echo "  just logs           View build logs"
    @echo "  just errors         Show last build errors"
    @echo "  just clean          Clean build artifacts"
    @echo ""
    @echo "Options:"
    @echo "  just -n <recipe>   Dry run (show commands only)"
    @echo "  just -v <recipe>   Verbose output"

# =============================================================================
# Setup & Configuration
# =============================================================================

# Full setup - install XcodeGen and generate project
setup:
    @echo "🔧 Setting up QuickRecorder..."
    @echo ""
    @echo "Checking for Homebrew..."
    @which brew > /dev/null && echo "✅ Homebrew installed" || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    @echo ""
    @echo "Checking for XcodeGen..."
    @which xcodegen > /dev/null && echo "✅ XcodeGen installed ($(xcodegen --version))" || brew install xcodegen
    @echo ""
    @echo "Generating Xcode project..."
    xcodegen generate
    @echo ""
    @echo "Resolving Swift packages..."
    xcodebuild -resolvePackageDependencies -project QuickRecorder.xcodeproj -scheme QuickRecorder > /dev/null 2>&1
    @echo "✅ Setup complete!"
    @echo ""
    @echo "Next: just build"

# Generate Xcode project from project.yml
generate:
    @echo "📦 Generating Xcode project..."
    xcodegen generate
    @echo "✅ Xcode project generated"

# Check dependencies
deps:
    @echo "📋 Dependency Check"
    @echo ""
    @echo "XcodeGen:"
    @which xcodegen > /dev/null && echo "  ✅ Installed ($(xcodegen --version))" || echo "  ❌ Not installed (brew install xcodegen)"
    @echo ""
    @echo "Xcode Command Line Tools:"
    @xcode-select -p > /dev/null && echo "  ✅ Configured" || echo "  ❌ Not configured (sudo xcode-select -s /Applications/Xcode.app/Contents/Developer)"
    @echo ""
    @echo "Swift Packages:"
    @xcodebuild -project QuickRecorder.xcodeproj -scheme QuickRecorder -showPackageGraph 2>/dev/null | head -10 || echo "  ⚠️  Run 'just generate' first"

# Full system diagnostic
diagnose:
    @echo "🔍 QuickRecorder System Diagnostic"
    @echo ""
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    @echo "System Information"
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    @echo "Date:          $(date)"
    @echo "User:          $(whoami)"
    @echo "Working Dir:   $(pwd)"
    @echo ""
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    @echo "Xcode & Tools"
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    @xcode-select -p && echo "  ✅ xcode-select configured" || echo "  ❌ xcode-select not configured"
    @xcodebuild -version 2>/dev/null | head -1 && echo "  ✅ Xcode found" || echo "  ❌ Xcode not found"
    @which xcodegen > /dev/null && echo "  ✅ XcodeGen installed" || echo "  ❌ XcodeGen not installed"
    @echo ""
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    @echo "Project Status"
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    @if [ -d "QuickRecorder.xcodeproj" ]; then echo "  ✅ Project exists"; else echo "  ❌ Project missing"; fi
    @if [ -f "project.yml" ]; then echo "  ✅ project.yml exists"; else echo "  ❌ project.yml missing"; fi
    @if [ -d "QuickRecorder" ]; then echo "  ✅ Source exists"; else echo "  ❌ Source missing"; fi
    @if [ -d "QuickRecorderTests" ]; then echo "  ✅ Tests exist"; else echo "  ❌ Tests missing"; fi
    @echo ""
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    @echo "Disk Space"
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    @df -h . | tail -1 | awk '{print "  Available: " $4}'

# =============================================================================
# Building
# =============================================================================

# Debug build
build:
    @echo "🔨 Debug Build..."
    xcodebuild build \
        -project QuickRecorder.xcodeproj \
        -scheme QuickRecorder \
        -destination 'platform=macOS' \
        -configuration Debug \
        CODE_SIGNING_ALLOWED=NO \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGN_IDENTITY="-"

# Release build
release:
    @echo "🚀 Release Build..."
    xcodebuild build \
        -project QuickRecorder.xcodeproj \
        -scheme QuickRecorder \
        -destination 'platform=macOS' \
        -configuration Release \
        CODE_SIGNING_ALLOWED=NO \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGN_IDENTITY="-"

# Debug build with full logging and analysis
build-plus:
    @chmod +x scripts/build.sh
    @./scripts/build.sh "{{LOG_FILE}}"

# Release build + export to Desktop
release-export:
    @chmod +x scripts/release-export.sh
    @./scripts/release-export.sh

# =============================================================================
# Testing
# =============================================================================

# Run all tests
test:
    @echo "🧪 Running Tests..."
    xcodebuild test \
        -project QuickRecorder.xcodeproj \
        -scheme QuickRecorder \
        -destination 'platform=macOS' \
        -configuration Debug \
        CODE_SIGNING_ALLOWED=NO \
        CODE_SIGNING_REQUIRED=NO

# Run tests with code coverage
test-coverage:
    @echo "🧪 Running Tests with Coverage..."
    xcodebuild test \
        -project QuickRecorder.xcodeproj \
        -scheme QuickRecorder \
        -destination 'platform=macOS' \
        -configuration Debug \
        -enableCodeCoverage YES \
        CODE_SIGNING_ALLOWED=NO \
        CODE_SIGNING_REQUIRED=NO

# Watch mode - requires fswatch
watch:
    @echo "👀 Watch Mode (Ctrl+C to stop)..."
    @which fswatch > /dev/null && \
    fswatch -r . --exclude=".xcodeproj" --exclude="DerivedData" | while read; do \
        echo ""; \
        echo "📁 File changed, re-running tests..."; \
        just test | tail -20; \
    done || \
    echo "⚠️  fswatch not installed (brew install fswatch)"

# =============================================================================
# Distribution
# =============================================================================

# Create .xcarchive
archive:
    @echo "📦 Creating Archive..."
    ARCHIVE_NAME="QuickRecorder-$(date +%Y%m%d-%H%M)"
    xcodebuild archive \
        -project QuickRecorder.xcodeproj \
        -scheme QuickRecorder \
        -destination 'platform=macOS' \
        -configuration Release \
        CODE_SIGNING_ALLOWED=NO \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGN_IDENTITY="-" \
        ARCHIVE_PATH="archive/$ARCHIVE_NAME.xcarchive"
    @echo "✅ Archive created: archive/$ARCHIVE_NAME.xcarchive"

# Export .app to Desktop
export-app:
    @echo "📤 Exporting .app to Desktop..."
    DEST="$HOME/Desktop/release"
    mkdir -p "$DEST"
    # Find latest release build
    @APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "QuickRecorder.app" -type d -path "*/Release/*" 2>/dev/null | head -1) && \
    cp -R "$APP_PATH" "$DEST/" && \
    SIZE=$(du -h "$DEST/QuickRecorder.app" | cut -f1) && \
    echo "✅ Exported: $DEST/QuickRecorder.app ($SIZE)"

# Build + archive + notarize (requires Apple ID credentials)
# Supports: Keychain (secure), .env file, or environment variables
notarize:
    @bash scripts/notarize.sh

# Staple notarization ticket to app (after notarization is approved)
# Usage: just staple [optional: path/to/app]
staple app_path="":
    @bash scripts/staple.sh {{app_path}}

# Generate Sparkle appcast for automatic updates
# Usage: just appcast [version] [path/to/release.zip]
# Examples:
#   just appcast                    # Auto-detect version and file
#   just appcast 1.2.1              # Use version, auto-find file
#   just appcast 1.2.1 path/to.zip  # Provide both explicitly
appcast *args:
    @bash scripts/generate-appcast.sh {{args}}

# Complete release workflow: DMG creation, appcast update, git commit & push
# Usage: just publish [version] [app_path]
# Examples:
#   just publish                    # Auto-detect version and find latest app
#   just publish 1.7.0              # Use version, auto-find app
#   just publish 1.7.0 archive/export-*/QuickRecorder.app  # Provide both
publish version="" app_path="":
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    @echo "  QuickRecorder Release Workflow"
    @echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    @echo ""
    @bash scripts/release.sh {{version}} {{app_path}}

# =============================================================================
# Logs & Debug
# =============================================================================

# View build logs
logs:
    @echo "📄 Build Logs"
    @echo ""
    @ls -la {{LOG_DIR}}/ 2>/dev/null || echo "No logs yet. Run 'just build-plus' first."
    @echo ""
    @echo "Latest log:"
    @ls -t {{LOG_DIR}}/build-*.log 2>/dev/null | head -1 | xargs head -50 || echo "No logs found"

# Show errors from last build
errors:
    @echo "❌ Errors from Last Build"
    @echo ""
    @LATEST_LOG=$$(ls -t {{LOG_DIR}}/build-*.log 2>/dev/null | head -1)
    @if [ -n "$$LATEST_LOG" ]; then \
        echo "Log: $$LATEST_LOG"; \
        echo ""; \
        echo "Error count: $$(grep -c 'error:' $$LATEST_LOG 2>/dev/null || echo '0')"; \
        echo ""; \
        echo "First 10 errors:"; \
        grep 'error:' $$LATEST_LOG 2>/dev/null | head -10 | nl; \
    else \
        echo "No logs found. Run 'just build-plus' first."; \
    fi

# =============================================================================
# Maintenance
# =============================================================================

# Clean build artifacts
clean:
    @echo "🧹 Cleaning..."
    rm -rf build
    rm -rf release
    rm -rf archive
    rm -rf ~/Library/Developer/Xcode/DerivedData/QuickRecorder-*
    xcodebuild clean -project QuickRecorder.xcodeproj -scheme QuickRecorder > /dev/null 2>&1 || true
    @echo "✅ Cleaned"

# Clean everything including XcodeGen cache
clean-all: clean
    @echo "🧹 Deep cleaning..."
    rm -rf ~/.xcodegen
    rm -rf QuickRecorder.xcodeproj
    @echo "✅ Deep cleaned (run 'just setup' to regenerate)"

# Regenerate from scratch
regenerate: clean-all setup
    @echo "✅ Project regenerated from scratch"

# =============================================================================
# Development
# =============================================================================

# Open project in Xcode
open:
    @echo "📱 Opening in Xcode..."
    open QuickRecorder.xcodeproj

# Open derived data folder
derived-data:
    @echo "📂 Opening DerivedData..."
    open ~/Library/Developer/Xcode/DerivedData

# Show last build size
size:
    @echo "📊 Build Size..."
    @du -sh ~/Library/Developer/Xcode/DerivedData/QuickRecorder-*/Build/Products/Release/*.app 2>/dev/null || echo "No release builds found"

# =============================================================================
# CI/CD (for GitHub Actions)
# =============================================================================

# CI build (no code signing)
ci-build:
    xcodebuild build \
        -project QuickRecorder.xcodeproj \
        -scheme QuickRecorder \
        -destination 'platform=macOS' \
        -configuration Release \
        CODE_SIGNING_ALLOWED=NO \
        CODE_SIGNING_REQUIRED=NO

# CI test (with coverage)
ci-test:
    xcodebuild test \
        -project QuickRecorder.xcodeproj \
        -scheme QuickRecorder \
        -destination 'platform=macOS' \
        -configuration Debug \
        -enableCodeCoverage YES \
        CODE_SIGNING_ALLOWED=NO \
        CODE_SIGNING_REQUIRED=NO

# CI full check (build + test)
ci-check: ci-build ci-test
    @echo "✅ CI check passed"
