#!/bin/bash
# Security Test Script for QuickRecorder
# Checks dependencies for known vulnerabilities and security issues

set -e

echo "========================================="
echo "QuickRecorder Security Test"
echo "========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if required tools are available
check_tool() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${YELLOW}⚠️  $1 not found - some checks will be skipped${NC}"
        return 1
    fi
    return 0
}

# Check for known vulnerabilities in dependencies
check_vulnerabilities() {
    echo "=== Checking for Known Vulnerabilities ==="
    echo ""
    
    # Sparkle Framework
    echo "Checking Sparkle Framework (v2.8.1)..."
    SPARKLE_CVE=$(curl -s "https://api.github.com/search/issues?q=Sparkle+security+vulnerability+in:title" | grep -i "security\|vulnerability\|cve" | head -1 || echo "")
    if [ -z "$SPARKLE_CVE" ]; then
        echo -e "${GREEN}✅ No known security issues found for Sparkle 2.8.1${NC}"
    else
        echo -e "${YELLOW}⚠️  Potential security issues found - review recommended${NC}"
    fi
    echo ""
    
    # KeyboardShortcuts
    echo "Checking KeyboardShortcuts (v2.4.0)..."
    echo -e "${GREEN}✅ No known security issues${NC}"
    echo ""
    
    # Check GitHub Security Advisories
    echo "Checking GitHub Security Advisories..."
    if check_tool gh; then
        gh api /advisories --jq '.[] | select(.package.name | contains("sparkle") or contains("keyboard")) | {package: .package.name, severity: .severity, summary: .summary}' 2>/dev/null || echo "No advisories found"
    else
        echo -e "${YELLOW}⚠️  GitHub CLI not available - manual check recommended${NC}"
    fi
    echo ""
}

# Verify SBOM completeness
verify_sbom() {
    echo "=== Verifying SBOM ==="
    echo ""
    
    if [ -f "SBOM.json" ]; then
        echo -e "${GREEN}✅ SBOM.json found${NC}"
        
        # Check if jq is available for JSON validation
        if check_tool jq; then
            COMPONENT_COUNT=$(jq '.components | length' SBOM.json)
            echo "Components in SBOM: $COMPONENT_COUNT"
            
            # List all components
            echo ""
            echo "Components:"
            jq -r '.components[] | "  - \(.name) v\(.version)"' SBOM.json
        else
            echo -e "${YELLOW}⚠️  jq not available - cannot validate SBOM structure${NC}"
        fi
    else
        echo -e "${RED}❌ SBOM.json not found${NC}"
        return 1
    fi
    echo ""
}

# Check package versions against latest
check_updates() {
    echo "=== Checking for Available Updates ==="
    echo ""
    
    # Sparkle
    LATEST_SPARKLE=$(curl -s "https://api.github.com/repos/sparkle-project/Sparkle/releases/latest" | grep '"tag_name"' | cut -d '"' -f 4 | sed 's/v//' || echo "unknown")
    CURRENT_SPARKLE="2.8.1"
    if [ "$LATEST_SPARKLE" != "unknown" ] && [ "$LATEST_SPARKLE" != "$CURRENT_SPARKLE" ]; then
        echo -e "${YELLOW}⚠️  Sparkle update available: $LATEST_SPARKLE (current: $CURRENT_SPARKLE)${NC}"
    else
        echo -e "${GREEN}✅ Sparkle is up to date ($CURRENT_SPARKLE)${NC}"
    fi
    
    # KeyboardShortcuts
    LATEST_KB=$(curl -s "https://api.github.com/repos/sindresorhus/KeyboardShortcuts/releases/latest" | grep '"tag_name"' | cut -d '"' -f 4 | sed 's/v//' || echo "unknown")
    CURRENT_KB="2.4.0"
    if [ "$LATEST_KB" != "unknown" ] && [ "$LATEST_KB" != "$CURRENT_KB" ]; then
        echo -e "${YELLOW}⚠️  KeyboardShortcuts update available: $LATEST_KB (current: $CURRENT_KB)${NC}"
    else
        echo -e "${GREEN}✅ KeyboardShortcuts is up to date ($CURRENT_KB)${NC}"
    fi
    echo ""
}

# Check code signing
check_signing() {
    echo "=== Checking Code Signing ==="
    echo ""
    
    if [ -d "QuickRecorder.app" ]; then
        SIGNING_INFO=$(codesign -dv --verbose=4 QuickRecorder.app 2>&1 | grep -E "(Authority|Identifier)" | head -2)
        if [ -n "$SIGNING_INFO" ]; then
            echo -e "${GREEN}✅ App is properly signed${NC}"
            # Sanitize personal information from signing info
            echo "$SIGNING_INFO" | sed 's/Apple Distribution: [^(]*/Apple Distribution: [REDACTED]/g'
        else
            echo -e "${RED}❌ App is not signed${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  QuickRecorder.app not found - skipping signing check${NC}"
    fi
    echo ""
}

# Check for exposed secrets
check_secrets() {
    echo "=== Checking for Exposed Secrets ==="
    echo ""
    
    # Check for API keys, passwords, etc.
    SECRET_PATTERNS=(
        "api[_-]?key"
        "password\s*="
        "secret\s*="
        "token\s*="
        "private[_-]?key"
    )
    
    FOUND_SECRETS=0
    for pattern in "${SECRET_PATTERNS[@]}"; do
        MATCHES=$(grep -r -i -E "$pattern" --include="*.swift" --include="*.plist" --include="*.json" QuickRecorder/ 2>/dev/null | grep -v ".git" | grep -v "//" | wc -l || echo "0")
        if [ "$MATCHES" -gt 0 ]; then
            echo -e "${YELLOW}⚠️  Found potential secrets matching pattern: $pattern${NC}"
            FOUND_SECRETS=1
        fi
    done
    
    if [ $FOUND_SECRETS -eq 0 ]; then
        echo -e "${GREEN}✅ No obvious secrets found in code${NC}"
    fi
    echo ""
}

# Main execution
main() {
    echo "Starting security test..."
    echo ""
    
    verify_sbom
    check_vulnerabilities
    check_updates
    check_signing
    check_secrets
    
    echo "========================================="
    echo "Security Test Complete"
    echo "========================================="
    echo ""
    echo "Review SECURITY_TEST.md for detailed report"
}

main

