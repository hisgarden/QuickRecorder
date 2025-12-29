#!/bin/bash
#
# Pre-commit check script for QuickRecorder
# Can be run manually or as part of git hooks
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_DIR"

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}QuickRecorder Pre-Commit Checks${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Check prerequisites
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}❌ ERROR: xcodebuild not found${NC}"
    echo "Please install Xcode Command Line Tools:"
    echo "  xcode-select --install"
    exit 1
fi

# Check for non-interactive mode (for CI)
NON_INTERACTIVE=${NON_INTERACTIVE:-false}

# Step 1: Full test suite
echo -e "${YELLOW}📋 Step 1/4: Running full test suite...${NC}"
echo ""

if xcodebuild test \
    -project QuickRecorder.xcodeproj \
    -scheme QuickRecorder \
    -destination 'platform=macOS' \
    -enableCodeCoverage YES \
    > /tmp/quickrecorder_test_output.log 2>&1; then
    
    TEST_COUNT=$(grep -E "Executed [0-9]+ tests" /tmp/quickrecorder_test_output.log | tail -1 | grep -oE "[0-9]+ tests" | grep -oE "[0-9]+" || echo "0")
    echo -e "${GREEN}✅ Test suite passed: $TEST_COUNT tests executed${NC}"
else
    echo -e "${RED}❌ TEST SUITE FAILED${NC}"
    echo ""
    echo "Last 50 lines of test output:"
    tail -50 /tmp/quickrecorder_test_output.log
    echo ""
    echo "Full log: /tmp/quickrecorder_test_output.log"
    exit 1
fi

echo ""

# Step 2: Security tests
echo -e "${YELLOW}🔒 Step 2/4: Running security and permission tests...${NC}"
echo ""

if xcodebuild test \
    -project QuickRecorder.xcodeproj \
    -scheme QuickRecorder \
    -destination 'platform=macOS' \
    -only-testing:QuickRecorderTests/PermissionBehaviorTests \
    -only-testing:QuickRecorderTests/ErrorHandlerTests \
    > /tmp/quickrecorder_security_test_output.log 2>&1; then
    
    echo -e "${GREEN}✅ Security tests passed${NC}"
else
    echo -e "${RED}❌ SECURITY TESTS FAILED${NC}"
    echo ""
    echo "Last 50 lines of security test output:"
    tail -50 /tmp/quickrecorder_security_test_output.log
    echo ""
    echo "Full log: /tmp/quickrecorder_security_test_output.log"
    exit 1
fi

echo ""

# Step 3: Build and visual check
echo -e "${YELLOW}🏗️  Step 3/4: Building app for visual inspection...${NC}"
echo ""

# Clean previous build
xcodebuild clean -project QuickRecorder.xcodeproj -scheme QuickRecorder -configuration Debug > /dev/null 2>&1 || true

# Build the app
if xcodebuild build \
    -project QuickRecorder.xcodeproj \
    -scheme QuickRecorder \
    -configuration Debug \
    -derivedDataPath ./build \
    > /tmp/quickrecorder_build_output.log 2>&1; then
    
    echo -e "${GREEN}✅ Build successful${NC}"
    
    # Copy app to project root for easy access
    if [ -d "build/Build/Products/Debug/QuickRecorder.app" ]; then
        rm -rf QuickRecorder_VisualCheck.app 2>/dev/null || true
        cp -R build/Build/Products/Debug/QuickRecorder.app QuickRecorder_VisualCheck.app
        echo -e "${GREEN}✅ App bundle created: QuickRecorder_VisualCheck.app${NC}"
        
        # Open the app for visual inspection
        echo ""
        echo -e "${YELLOW}👁️  Opening app for visual inspection...${NC}"
        echo "   Please verify:"
        echo "   - App launches without crashes"
        echo "   - UI displays correctly"
        echo "   - No obvious visual issues"
        echo ""
        
        # Open app in background
        open -a QuickRecorder_VisualCheck.app 2>/dev/null || open QuickRecorder_VisualCheck.app 2>/dev/null || true
        
        # Wait a moment for app to launch
        sleep 2
        
        # Check if app launched successfully
        if pgrep -f "QuickRecorder_VisualCheck" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ App launched successfully${NC}"
            
            if [ "$NON_INTERACTIVE" = "true" ]; then
                echo -e "${YELLOW}⏭️  Non-interactive mode: Skipping manual visual check${NC}"
                # Wait a bit for app to fully load, then close
                sleep 3
            else
                echo -e "${BLUE}Press Enter after visual inspection (or Ctrl+C to cancel commit)...${NC}"
                # Wait for user confirmation
                read -r
            fi
            
            # Check if app is still running
            if pgrep -f "QuickRecorder_VisualCheck" > /dev/null 2>&1; then
                echo -e "${GREEN}✅ App is running${NC}"
            else
                echo -e "${YELLOW}⚠️  App may have closed (this is OK if you closed it manually)${NC}"
            fi
        else
            echo -e "${RED}❌ App failed to launch${NC}"
            echo "   This may indicate a build or runtime issue"
            rm -rf QuickRecorder_VisualCheck.app 2>/dev/null || true
            exit 1
        fi
        
        # Clean up
        echo ""
        echo -e "${YELLOW}Cleaning up visual check app...${NC}"
        killall QuickRecorder_VisualCheck 2>/dev/null || true
        sleep 1
        rm -rf QuickRecorder_VisualCheck.app 2>/dev/null || true
        echo -e "${GREEN}✅ Visual check completed${NC}"
    else
        echo -e "${RED}❌ App bundle not found after build${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ BUILD FAILED${NC}"
    echo ""
    echo "Last 50 lines of build output:"
    tail -50 /tmp/quickrecorder_build_output.log
    echo ""
    echo "Full log: /tmp/quickrecorder_build_output.log"
    exit 1
fi

echo ""

# Step 4: Security code analysis
echo -e "${YELLOW}🔍 Step 4/4: Running security code analysis...${NC}"
echo ""

FORCE_UNWRAPS=$(grep -r "!" --include="*.swift" QuickRecorder/ | grep -v "//" | grep -v "Test" | grep -v ".git" | wc -l | tr -d ' ')
ASSERTION_FAILURES=$(grep -r "assertionFailure" --include="*.swift" QuickRecorder/ | grep -v "Test" | grep -v ".git" | wc -l | tr -d ' ')

if [ "$FORCE_UNWRAPS" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  WARNING: Found $FORCE_UNWRAPS potential force unwraps${NC}"
    echo "   Review these carefully for security implications"
fi

if [ "$ASSERTION_FAILURES" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  WARNING: Found $ASSERTION_FAILURES assertionFailure calls${NC}"
    echo "   Consider using ErrorHandler for better error reporting"
fi

echo -e "${GREEN}✅ Security analysis completed${NC}"
echo ""

# Summary
echo -e "${BLUE}=========================================${NC}"
echo -e "${GREEN}✅ All pre-commit checks passed!${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""
echo "Summary:"
echo "  ✅ Full test suite: Passed"
echo "  ✅ Security tests: Passed"
echo "  ✅ Visual build check: Passed"
echo "  ✅ Security analysis: Completed"
echo ""
echo -e "${GREEN}Ready to commit!${NC}"
echo ""

exit 0

