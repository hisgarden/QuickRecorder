#!/bin/bash
#
#  QuickRecorder Build & Debug Script
#  Captures all build output to log file for analysis
#
#  Usage:
#    ./buildDebug.sh              # Debug build with full logging
#    ./buildDebug.sh --release    # Release build with full logging
#    ./buildDebug.sh --test       # Run tests with full logging
#    ./buildDebug.sh --all        # Full build + test
#
#  Output:
#    Logs are saved to: logs/build-[timestamp].log
#

set -e

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Configuration
PROJECT_NAME="QuickRecorder"
LOG_DIR="logs"
LOG_FILE=""

# Parse arguments
BUILD_TYPE="debug"
RUN_TESTS=false
RUN_ALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --release|-r)
            BUILD_TYPE="release"
            shift
            ;;
        --test|-t)
            RUN_TESTS=true
            shift
            ;;
        --all|-a)
            RUN_ALL=true
            shift
            ;;
        --help|-h)
            echo "QuickRecorder Build & Debug Script"
            echo ""
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --release, -r    Build Release configuration"
            echo "  --test, -t       Run tests after build"
            echo "  --all, -a        Full build + test + archive"
            echo "  --help, -h       Show this help"
            echo ""
            echo "Output:"
            echo "  Logs saved to: logs/build-[timestamp].log"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Create log directory
mkdir -p "$LOG_DIR"

# Generate timestamp
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOG_FILE="$LOG_DIR/build-$TIMESTAMP.log"

# Header
echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║                                                                   ║"
echo "║   🔨 QuickRecorder - Build & Debug Script                        ║"
echo "║                                                                   ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📋 Build Configuration${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  Project:      $PROJECT_NAME"
echo "  Configuration: $BUILD_TYPE"
echo "  Log File:     $LOG_FILE"
echo "  Timestamp:    $TIMESTAMP"
echo ""

# Start logging
exec > >(tee "$LOG_FILE") 2>&1

echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Build Session Started: $(date)${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
echo ""

# =============================================================================
# Step 1: Prerequisites Check
# =============================================================================

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Step 1: Prerequisites Check${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "Date: $(date)"
echo "Working Directory: $(pwd)"
echo "User: $(whoami)"
echo ""

# Check XcodeGen
echo "Checking XcodeGen..."
if command -v xcodegen &> /dev/null; then
    XCODEGEN_VERSION=$(xcodegen --version)
    echo "  ✅ XcodeGen installed: $XCODEGEN_VERSION"
else
    echo "  ❌ XcodeGen not found!"
    echo ""
    echo "Install with: brew install xcodegen"
    exit 1
fi

# Check Xcode
echo ""
echo "Checking Xcode..."
XCODE_VERSION=$(xcodebuild -version 2>/dev/null || echo "Not found")
echo "  ✅ $XCODE_VERSION"

# Check xcode-select
echo ""
echo "Checking Xcode Command Line Tools..."
XCODE_DEV_DIR=$(xcode-select -p 2>/dev/null || echo "Not configured")
if [ -d "$XCODE_DEV_DIR" ]; then
    echo "  ✅ Developer directory: $XCODE_DEV_DIR"
else
    echo "  ❌ Xcode Command Line Tools not configured!"
    echo ""
    echo "Set with: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
    exit 1
fi

# Check project exists
echo ""
echo "Checking project..."
if [ -d "$PROJECT_NAME.xcodeproj" ]; then
    echo "  ✅ Xcode project exists"
else
    echo "  ⚠️  Xcode project not found, generating..."
    xcodegen generate
    echo "  ✅ Project generated"
fi

# =============================================================================
# Step 2: Clean (if needed)
# =============================================================================

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Step 2: Clean Previous Builds${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if we should clean
echo "Checking for old builds..."
if [ -d "build" ]; then
    echo "  🗑️  Removing old build directory..."
    rm -rf build
    echo "  ✅ Removed build/"
fi

if [ -d "archive" ]; then
    echo "  🗑️  Removing old archive directory..."
    rm -rf archive
    echo "  ✅ Removed archive/"
fi

echo "  ✅ Clean complete"

# =============================================================================
# Step 3: Resolve Packages
# =============================================================================

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Step 3: Resolve Swift Packages${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "Resolving package dependencies..."
xcodebuild -resolvePackageDependencies \
    -project "$PROJECT_NAME.xcodeproj" \
    -scheme "$PROJECT_NAME" 2>&1 | grep -E "(Resolved|Updating|error:|warning:)" || true

echo ""
echo "  ✅ Packages resolved"

# =============================================================================
# Step 4: Build
# =============================================================================

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Step 4: Build ($BUILD_TYPE configuration)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

CONFIG_UPPER=$(echo "$BUILD_TYPE" | tr '[:lower:]' '[:upper:]')

echo "Building $CONFIG_UPPER configuration..."
echo ""

xcodebuild build \
    -project "$PROJECT_NAME.xcodeproj" \
    -scheme "$PROJECT_NAME" \
    -destination 'platform=macOS' \
    -configuration "$CONFIG_UPPER" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGN_IDENTITY="-" \
    2>&1 | tee /dev/fd/3

BUILD_RESULT=${PIPESTATUS[0]}

if [ $BUILD_RESULT -eq 0 ]; then
    echo ""
    echo "  ✅ Build successful!"
else
    echo ""
    echo "  ❌ Build failed with exit code: $BUILD_RESULT"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "ERROR SUMMARY"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Extract key error info
    echo ""
    echo "Errors:"
    grep -E "^/.*error:" "$LOG_FILE" 2>/dev/null | head -20 || echo "  (see full log for details)"
    
    echo ""
    echo "Warnings:"
    grep -E "^/.*warning:" "$LOG_FILE" 2>/dev/null | wc -l || echo "  0"
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "SUGGESTED NEXT STEPS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "1. Check the full log file: $LOG_FILE"
    echo "2. Look for 'error:' patterns in the log"
    echo "3. Common fixes:"
    echo "   - Clean build: rm -rf ~/Library/Developer/Xcode/DerivedData/*"
    echo "   - Reset packages: rm -rf ~/Library/Caches/org.swift.swiftpm"
    echo "   - Regenerate project: xcodegen generate"
    echo ""
    echo "4. Share the log file for debugging"
    echo ""
fi

# =============================================================================
# Step 5: Tests (if requested)
# =============================================================================

if [ "$RUN_TESTS" = true ] || [ "$RUN_ALL" = true ]; then
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Step 5: Run Tests${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    echo "Running tests..."
    xcodebuild test \
        -project "$PROJECT_NAME.xcodeproj" \
        -scheme "$PROJECT_NAME" \
        -destination 'platform=macOS' \
        -configuration Debug \
        CODE_SIGNING_ALLOWED=NO \
        2>&1 | tee /dev/fd/3
    
    TEST_RESULT=${PIPESTATUS[0]}
    
    if [ $TEST_RESULT -eq 0 ]; then
        echo ""
        echo "  ✅ Tests passed!"
    else
        echo ""
        echo "  ❌ Tests failed with exit code: $TEST_RESULT"
    fi
fi

# =============================================================================
# Step 6: Archive (if --all)
# =============================================================================

if [ "$RUN_ALL" = true ]; then
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Step 6: Create Archive${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    ARCHIVE_NAME="$PROJECT_NAME-$(date +%Y%m%d-%H%M%S)"
    
    echo "Creating archive: $ARCHIVE_NAME.xcarchive"
    
    xcodebuild archive \
        -project "$PROJECT_NAME.xcodeproj" \
        -scheme "$PROJECT_NAME" \
        -destination 'platform=macOS' \
        -configuration Release \
        CODE_SIGNING_ALLOWED=NO \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGN_IDENTITY="-" \
        ARCHIVE_PATH="archive/$ARCHIVE_NAME.xcarchive" 2>&1 | tee /dev/fd/3
    
    ARCHIVE_RESULT=${PIPESTATUS[0]}
    
    if [ $ARCHIVE_RESULT -eq 0 ]; then
        echo ""
        echo "  ✅ Archive created: archive/$ARCHIVE_NAME.xcarchive"
    else
        echo ""
        echo "  ❌ Archive failed with exit code: $ARCHIVE_RESULT"
    fi
fi

# =============================================================================
# Summary
# =============================================================================

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Build Session Ended: $(date)${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Log File:     $LOG_FILE"
echo "  Configuration: $BUILD_TYPE"
echo "  Build Result: $([ $BUILD_RESULT -eq 0 ] && echo '✅ Success' || echo '❌ Failed')"
echo "  Log Size:     $(du -h "$LOG_FILE" | cut -f1)"
echo "  Log Lines:    $(wc -l < "$LOG_FILE")"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "QUICK ANALYSIS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Count errors and warnings
ERROR_COUNT=$(grep -c "error:" "$LOG_FILE" 2>/dev/null || echo "0")
WARN_COUNT=$(grep -c "warning:" "$LOG_FILE" 2>/dev/null || echo "0")

echo "  Errors:   $ERROR_COUNT"
echo "  Warnings: $WARN_COUNT"
echo ""

if [ "$ERROR_COUNT" -gt 0 ]; then
    echo "  First 5 errors:"
    grep "error:" "$LOG_FILE" 2>/dev/null | head -5 | nl
    echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "NEXT STEPS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. View full log:     cat $LOG_FILE"
echo "2. Search for errors: grep 'error:' $LOG_FILE"
echo "3. Share for help:    Upload $LOG_FILE"
echo "4. Open in Xcode:     open $PROJECT_NAME.xcodeproj"
echo ""

# Exit with build result
exit $BUILD_RESULT

