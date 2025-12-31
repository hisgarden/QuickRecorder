#!/bin/bash
#
#  QuickRecorder Test Setup Script
#  Verifies test configuration and runs tests
#
#  Usage:
#    ./setupTests.sh              # Run all tests
#    ./setupTests.sh --watch     # Watch mode (continuous testing)
#    ./setupTests.sh --coverage  # Run with code coverage
#    ./setupTests.sh --verbose   # Verbose output
#
#  Requirements:
#    - XcodeGen must be installed
#    - Xcode project must be generated
#    - Tests must be configured in project.yml
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

PROJECT_NAME="QuickRecorder"
TEST_TARGET="QuickRecorderTests"

# Parse arguments
WATCH_MODE=false
COVERAGE=false
VERBOSE=false
FILTER=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --watch|-w)
            WATCH_MODE=true
            shift
            ;;
        --coverage|-c)
            COVERAGE=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            echo "QuickRecorder Test Setup Script"
            echo ""
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --watch, -w       Watch mode (continuous testing)"
            echo "  --coverage, -c    Run with code coverage"
            echo "  --verbose, -v     Verbose output"
            echo "  --help, -h        Show this help"
            exit 0
            ;;
        *)
            FILTER=$1
            shift
            ;;
    esac
done

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                   ║"
echo "║   🧪 QuickRecorder - Test Runner                   ║"
echo "║                                                   ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check prerequisites
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📋 Prerequisites Check${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Check XcodeGen
if ! command -v xcodegen &> /dev/null; then
    echo -e "${YELLOW}⚠️  XcodeGen not found. Running setup...${NC}"
    if command -v brew &> /dev/null; then
        brew install xcodegen
    else
        echo -e "${RED}❌ Homebrew not found. Please install XcodeGen manually.${NC}"
        exit 1
    fi
fi

# Check project exists
if [ ! -d "$PROJECT_NAME.xcodeproj" ]; then
    echo -e "${YELLOW}⚠️  Xcode project not found. Generating...${NC}"
    xcodegen generate
fi

# Resolve packages
echo -e "${GREEN}✓${NC} Resolving Swift packages..."
xcodebuild -resolvePackageDependencies -project "$PROJECT_NAME.xcodeproj" -scheme "$PROJECT_NAME" > /dev/null 2>&1

# Test configuration
echo -e "${GREEN}✓${NC} Test target: $TEST_TARGET"

# Build test target first
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔨 Building Tests${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

if ! xcodebuild build \
    -project "$PROJECT_NAME.xcodeproj" \
    -scheme "$PROJECT_NAME" \
    -destination 'platform=macOS' \
    -configuration Debug \
    -target "$TEST_TARGET" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    2>&1 | tail -5; then
    echo -e "${RED}❌ Test build failed${NC}"
    exit 1
fi

echo -e "\n${GREEN}✓${NC} Test build successful!"

# Run tests
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🧪 Running Tests${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Build xcodebuild command
XCODEBUILD_CMD="xcodebuild test \
    -project '$PROJECT_NAME.xcodeproj' \
    -scheme '$PROJECT_NAME' \
    -destination 'platform=macOS' \
    -configuration Debug \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO"

# Add coverage if requested
if [ "$COVERAGE" = true ]; then
    XCODEBUILD_CMD="$XCODEBUILD_CMD -enableCodeCoverage YES"
fi

# Add filter if specified
if [ -n "$FILTER" ]; then
    XCODEBUILD_CMD="$XCODEBUILD_CMD -only-testing:$FILTER"
fi

# Execute tests
if eval "$XCODEBUILD_CMD" 2>&1 | tee /tmp/test-output.txt; then
    echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ All Tests Passed!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Show summary
    echo -e "\n${CYAN}Test Summary:${NC}"
    grep -E "Test Case.*passed|Test Case.*failed" /tmp/test-output.txt | tail -10 || true
    
    if [ "$COVERAGE" = true ]; then
        echo -e "\n${CYAN}Code Coverage:${NC}"
        xcrun xccov view --report --json /tmp/coverage.json 2>/dev/null || \
            xcrun xccov view --report /tmp/coverage.json 2>/dev/null || \
            echo "Coverage report available in Xcode"
    fi
else
    echo -e "\n${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}❌ Some Tests Failed${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Show failures
    echo -e "\n${CYAN}Failed Tests:${NC}"
    grep -E "FAILED|error:" /tmp/test-output.txt | head -20 || true
    
    exit 1
fi

# Watch mode
if [ "$WATCH_MODE" = true ]; then
    echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}👀 Watch Mode Enabled${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "Watching for file changes..."
    echo "Press Ctrl+C to stop"
    
    # Simple watch using fswatch if available
    if command -v fswatch &> /dev/null; then
        fswatch -r . --exclude=".xcodeproj" --exclude="DerivedData" | while read; do
            echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${BLUE}📁 File changed, re-running tests...${NC}"
            echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            eval "$XCODEBUILD_CMD" 2>&1 | tail -20 || true
        done
    else
        echo "Install fswatch for automatic re-testing:"
        echo "  brew install fswatch"
        echo ""
        echo "Or press Ctrl+C to exit, then run tests manually."
    fi
fi

# Cleanup
rm -f /tmp/test-output.txt

echo -e "\n${GREEN}Done!${NC}"





