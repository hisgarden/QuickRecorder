#!/bin/bash
# Staple notarization ticket to QuickRecorder app
# This can be run independently after notarization succeeds

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

main() {
    echo -e "${BLUE}🔏 Stapling Notarization Ticket${NC}"
    echo ""
    
    # Find the most recent app in archive
    echo "📍 Searching for notarized app..."
    
    if [ -z "$1" ]; then
        # Find the most recent .app file in archive directory
        APP_PATH=$(find archive -name "QuickRecorder-*.app" -type d 2>/dev/null | sort -r | head -1)
    else
        # Use provided path
        APP_PATH="$1"
    fi
    
    if [ -z "$APP_PATH" ] || [ ! -d "$APP_PATH" ]; then
        echo -e "${RED}❌ No notarized app found${NC}"
        echo ""
        echo "Usage: $0 [path/to/app]"
        echo ""
        echo "Examples:"
        echo "  $0                           # Uses latest from archive/"
        echo "  $0 archive/QuickRecorder-20251229-1407.app"
        exit 1
    fi
    
    echo "✅ Found app: $APP_PATH"
    echo ""
    
    # Check if app exists
    if [ ! -d "$APP_PATH" ]; then
        echo -e "${RED}❌ App not found at: $APP_PATH${NC}"
        exit 1
    fi
    
    # Staple the ticket
    echo "📌 Stapling notarization ticket..."
    echo "(This attaches the Apple notarization approval to the app)"
    echo ""
    
    if xcrun stapler staple "$APP_PATH"; then
        echo ""
        echo -e "${GREEN}✅ Stapling successful!${NC}"
        echo ""
        echo "Your app is now ready for distribution:"
        echo "  Location: $APP_PATH"
        echo ""
        echo "Next steps:"
        echo "  1. Test the app works correctly"
        echo "  2. Create a .dmg or .zip for distribution"
        echo "  3. Share with users (no Gatekeeper warnings!)"
        echo ""
    else
        echo ""
        echo -e "${RED}❌ Stapling failed${NC}"
        echo ""
        echo "Common causes:"
        echo "  1. Apple notarization not yet approved"
        echo "  2. Connection issue when contacting Apple"
        echo "  3. Invalid or expired submission"
        echo ""
        echo "Solutions:"
        echo "  1. Wait a moment and try again: just staple"
        echo "  2. Check notarization status:"
        echo "     xcrun notarytool history --apple-id <email> --password <password>"
        echo "  3. Create a new submission: just notarize"
        exit 1
    fi
}

# Run main function
main "$@"





