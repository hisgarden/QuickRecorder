#!/bin/bash

# QuickRecorder Test Suite Setup Script
# This script helps set up the test target in Xcode

set -e

echo "QuickRecorder Test Suite Setup"
echo "================================"
echo ""

# Check if we're in the right directory
if [ ! -f "QuickRecorder.xcodeproj/project.pbxproj" ]; then
    echo "Error: Please run this script from the QuickRecorder project root directory"
    exit 1
fi

echo "✓ Found QuickRecorder.xcodeproj"
echo ""

# Check if test directory exists
if [ ! -d "QuickRecorderTests" ]; then
    echo "Error: QuickRecorderTests directory not found"
    echo "Please ensure all test files are in place"
    exit 1
fi

echo "✓ Found QuickRecorderTests directory"
echo ""

echo "Next Steps:"
echo "----------"
echo ""
echo "1. Open QuickRecorder.xcodeproj in Xcode"
echo ""
echo "2. Add Test Target:"
echo "   - Go to File → New → Target"
echo "   - Select 'Unit Testing Bundle' under macOS"
echo "   - Name it 'QuickRecorderTests'"
echo "   - Ensure it tests the 'QuickRecorder' target"
echo ""
echo "3. Configure Test Target:"
echo "   - Select QuickRecorderTests target"
echo "   - In Build Settings, set:"
echo "     * Product Name: QuickRecorderTests"
echo "     * Bundle Identifier: dev.hisgarden.QuickRecorderTests"
echo "   - In Build Phases → Dependencies, add QuickRecorder"
echo ""
echo "4. Enable Testability:"
echo "   - Select QuickRecorder target (not test target)"
echo "   - In Build Settings, search for 'Enable Testability'"
echo "   - Set to 'Yes' for Debug and Release"
echo ""
echo "5. Add Test Files:"
echo "   - Select all files in QuickRecorderTests/"
echo "   - In File Inspector, check QuickRecorderTests target"
echo ""
echo "6. Run Tests:"
echo "   - Press ⌘+U to run all tests"
echo "   - Or use Test Navigator (⌘+6)"
echo ""
echo "For detailed instructions, see QuickRecorderTests/README.md"
echo ""

