#!/bin/bash

# Test script for permission flow
# This script helps test the improved permission handling

echo "=== QuickRecorder Permission Testing Script ==="
echo ""
echo "This script will help you test the permission improvements:"
echo ""
echo "1. Reset screen recording permissions"
echo "2. Launch QuickRecorder to test the new permission flow"
echo "3. Verify the dialog auto-closes after granting permissions"
echo ""

# Check if running with proper context
if [ "$EUID" -eq 0 ]; then
    echo "ERROR: Do not run this script as root"
    exit 1
fi

# Function to reset permissions
reset_permissions() {
    echo "Resetting screen recording permissions for QuickRecorder..."
    tccutil reset ScreenCapture dev.hisgarden.QuickRecorder 2>/dev/null

    if [ $? -eq 0 ]; then
        echo "✓ Permissions reset successfully"
    else
        echo "⚠ Could not reset permissions (this is normal if permissions weren't set)"
    fi
    echo ""
}

# Function to check current permission status
check_permissions() {
    echo "Checking current permission status..."

    # Build the app path
    APP_PATH="/Users/hisgarden/Library/Developer/Xcode/DerivedData/QuickRecorder-hkqsdurnaueuugdwzzozbromwbdc/Build/Products/Debug/QuickRecorder.app"

    if [ ! -d "$APP_PATH" ]; then
        echo "⚠ Debug build not found. Building project first..."
        cd /Users/hisgarden/workspace/util/QuickRecorder
        xcodebuild -project QuickRecorder.xcodeproj -scheme QuickRecorder -configuration Debug build > /dev/null 2>&1

        if [ $? -eq 0 ]; then
            echo "✓ Build completed"
        else
            echo "✗ Build failed"
            exit 1
        fi
    fi

    echo "✓ App found at: $APP_PATH"
    echo ""
}

# Function to launch the app
launch_app() {
    echo "Launching QuickRecorder..."
    echo ""
    echo "=========================================="
    echo "TESTING INSTRUCTIONS:"
    echo "=========================================="
    echo ""
    echo "When the permission dialog appears:"
    echo "1. Click 'Open System Settings & Restart'"
    echo "2. Grant screen recording permission in System Settings"
    echo "3. Wait and observe - the app should:"
    echo "   ✓ Detect the permission grant (within 60 seconds)"
    echo "   ✓ Automatically restart"
    echo "   ✓ Launch successfully with permissions"
    echo ""
    echo "If the dialog doesn't auto-close within 60 seconds,"
    echo "you'll see a timeout message instructing manual restart."
    echo ""
    echo "=========================================="
    echo ""

    APP_PATH="/Users/hisgarden/Library/Developer/Xcode/DerivedData/QuickRecorder-hkqsdurnaueuugdwzzozbromwbdc/Build/Products/Debug/QuickRecorder.app"
    open "$APP_PATH"

    echo "App launched. Monitor the console for permission check logs."
    echo ""
}

# Main menu
show_menu() {
    echo "What would you like to do?"
    echo ""
    echo "1) Reset permissions and test (recommended)"
    echo "2) Just launch the app"
    echo "3) Only reset permissions"
    echo "4) Check current status"
    echo "5) Exit"
    echo ""
    read -p "Enter your choice [1-5]: " choice

    case $choice in
        1)
            reset_permissions
            check_permissions
            launch_app
            ;;
        2)
            check_permissions
            launch_app
            ;;
        3)
            reset_permissions
            ;;
        4)
            check_permissions
            ;;
        5)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please try again."
            echo ""
            show_menu
            ;;
    esac
}

# Run the menu
show_menu

echo ""
echo "=== Test Complete ==="
echo ""
echo "Changes implemented:"
echo "✓ Asynchronous permission checking (no blocking at launch)"
echo "✓ Continuous permission monitoring (checks every 1 second for 30 seconds)"
echo "✓ Auto-restart when permission granted (within 60 seconds)"
echo "✓ CGPreflightScreenCaptureAccess for better permission detection"
echo "✓ Improved user messaging with clear instructions"
echo ""
