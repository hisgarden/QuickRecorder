#!/bin/bash
#
# Reset Spotlight Indexing and Icon Cache
# This fixes issues with app icons not showing up in Finder/Spotlight
#
# Usage:
#   bash scripts/reset-spotlight.sh
#   OR
#   chmod +x scripts/reset-spotlight.sh && ./scripts/reset-spotlight.sh
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔍 Resetting Spotlight Indexing${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Running as root - this is fine${NC}"
    echo ""
fi

# Step 1: Stop Spotlight indexing
echo -e "${BLUE}Step 1: Stopping Spotlight indexing...${NC}"
if sudo launchctl stop com.apple.metadata.mds; then
    echo -e "${GREEN}✅ Spotlight indexing stopped${NC}"
else
    echo -e "${YELLOW}⚠️  Could not stop Spotlight (may already be stopped)${NC}"
fi
echo ""

# Step 2: Delete Spotlight index database
echo -e "${BLUE}Step 2: Deleting Spotlight index database...${NC}"
echo "This requires administrator privileges."
if sudo rm -rf /.Spotlight-V100; then
    echo -e "${GREEN}✅ Spotlight index database deleted${NC}"
else
    echo -e "${RED}❌ Failed to delete index database${NC}"
    echo "You may need to run this manually: sudo rm -rf /.Spotlight-V100"
fi
echo ""

# Step 3: Clear icon cache
echo -e "${BLUE}Step 3: Clearing icon cache...${NC}"

# Clear various icon cache locations
ICON_CACHES=(
    "$HOME/Library/Caches/com.apple.iconservices.store"
    "$HOME/Library/Caches/com.apple.iconservices"
    "$HOME/Library/Application Support/com.apple.sharedfilelist"
)

for cache in "${ICON_CACHES[@]}"; do
    if [ -d "$cache" ] || [ -f "$cache" ]; then
        if rm -rf "$cache" 2>/dev/null; then
            echo -e "${GREEN}✅ Cleared: $(basename "$cache")${NC}"
        else
            echo -e "${YELLOW}⚠️  Could not clear: $(basename "$cache")${NC}"
        fi
    fi
done

# Clear icon cache database
if [ -d "$HOME/Library/Caches/com.apple.iconservices.store" ]; then
    rm -rf "$HOME/Library/Caches/com.apple.iconservices.store"/* 2>/dev/null || true
fi

echo ""

# Step 4: Rebuild Spotlight index
echo -e "${BLUE}Step 4: Rebuilding Spotlight index...${NC}"
echo "This will start indexing in the background."
if sudo mdutil -E /; then
    echo -e "${GREEN}✅ Spotlight index rebuild started${NC}"
    echo ""
    echo -e "${YELLOW}ℹ️  Indexing will continue in the background${NC}"
    echo -e "${YELLOW}   This may take several minutes to hours depending on disk size${NC}"
else
    echo -e "${RED}❌ Failed to rebuild index${NC}"
    echo "You may need to run this manually: sudo mdutil -E /"
fi
echo ""

# Step 5: Restart Spotlight
echo -e "${BLUE}Step 5: Restarting Spotlight service...${NC}"
if sudo launchctl start com.apple.metadata.mds; then
    echo -e "${GREEN}✅ Spotlight service restarted${NC}"
else
    echo -e "${YELLOW}⚠️  Could not restart Spotlight (may already be running)${NC}"
fi
echo ""

# Step 6: Kill Finder to refresh icons
echo -e "${BLUE}Step 6: Refreshing Finder...${NC}"
if killall Finder 2>/dev/null; then
    echo -e "${GREEN}✅ Finder restarted${NC}"
    echo -e "${YELLOW}   Finder will reopen automatically${NC}"
else
    echo -e "${YELLOW}⚠️  Finder was not running or could not be restarted${NC}"
fi
echo ""

# Summary
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Spotlight Reset Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Next steps:"
echo "  1. Wait a few minutes for indexing to start"
echo "  2. Check indexing status: mdutil -s /"
echo "  3. If app icon still doesn't show:"
echo "     - Right-click app → Get Info"
echo "     - Click the icon in Get Info window"
echo "     - Press Cmd+V to paste a new icon"
echo "     - Or rebuild the app: just build"
echo ""
echo "To check indexing progress:"
echo "  mdutil -s /"
echo ""
echo "To check if indexing is complete:"
echo "  mdutil -s / | grep -q 'Indexing enabled' && echo 'Indexing active'"
echo ""





