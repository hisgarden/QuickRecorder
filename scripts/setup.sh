#!/bin/bash
#
#  QuickRecorder Setup Script
#  Installs dependencies and generates Xcode project using XcodeGen
#
#  Usage:
#    ./setup.sh                    # Full setup
#    ./setup.sh --regenerate       # Regenerate project only
#    ./setup.sh --install-deps     # Install dependencies only
#
#  Requirements:
#    - macOS 12.3+
#    - Homebrew (optional, for XcodeGen installation)
#    - Xcode 15+
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="QuickRecorder"
XCODEGEN_VERSION="2.40.0"
GITHUB_REPO="hisgarden/QuickRecorder"

# Functions
print_step() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}📦 $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Parse arguments
REGENERATE=false
INSTALL_DEPS=false
OPEN_XCODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --regenerate|-r)
            REGENERATE=true
            shift
            ;;
        --install-deps|-i)
            INSTALL_DEPS=true
            shift
            ;;
        --open|-o)
            OPEN_XCODE=true
            shift
            ;;
        --help|-h)
            echo "QuickRecorder Setup Script"
            echo ""
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --regenerate, -r    Regenerate Xcode project only"
            echo "  --install-deps, -i  Install dependencies only"
            echo "  --open, -o         Open Xcode after setup"
            echo "  --help, -h         Show this help message"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Main execution
main() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                                                   ║"
    echo "║   🖥️  QuickRecorder - XcodeGen Setup                  ║"
    echo "║                                                   ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    # Step 1: Check for Homebrew
    if ! command -v brew &> /dev/null; then
        print_step "Installing Homebrew"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        print_success "Homebrew is installed"
    fi

    # Step 2: Install XcodeGen
    if [ "$REGENERATE" = false ] || [ "$INSTALL_DEPS" = true ]; then
        print_step "Checking XcodeGen"
        if command -v xcodegen &> /dev/null; then
            XCODEGEN_CURRENT=$(xcodegen --version)
            print_success "XcodeGen is installed ($XCODEGEN_CURRENT)"
        else
            print_step "Installing XcodeGen $XCODEGEN_VERSION"
            brew install xcodegen
            print_success "XcodeGen installed successfully"
        fi
    fi

    # Step 3: Generate Xcode Project
    if [ "$REGENERATE" = true ] || [ "$INSTALL_DEPS" = false ]; then
        print_step "Generating Xcode Project"
        
        # Check if project.yml exists
        if [ ! -f "project.yml" ]; then
            print_error "project.yml not found!"
            exit 1
        fi
        
        # Backup existing project if it exists
        if [ -d "$PROJECT_NAME.xcodeproj" ]; then
            print_warning "Backing up existing Xcode project"
            mv "$PROJECT_NAME.xcodeproj" "$PROJECT_NAME.xcodeproj.backup.$(date +%Y%m%d%H%M%S)"
        fi
        
        # Generate new project
        xcodegen generate
        
        if [ -d "$PROJECT_NAME.xcodeproj" ]; then
            print_success "Xcode project generated successfully!"
        else
            print_error "Failed to generate Xcode project"
            exit 1
        fi
        
        # Step 4: Resolve Swift Packages
        print_step "Resolving Swift Packages"
        xcodebuild -resolvePackageDependencies -project "$PROJECT_NAME.xcodeproj" -scheme "$PROJECT_NAME"
        print_success "Swift packages resolved"
    fi

    # Step 5: Verify Build
    print_step "Verifying Build"
    if xcodebuild build -project "$PROJECT_NAME.xcodeproj" \
        -scheme "$PROJECT_NAME" \
        -destination 'platform=macOS' \
        -configuration Debug \
        CODE_SIGNING_ALLOWED=NO \
        CODE_SIGNING_REQUIRED=NO \
        | tail -20; then
        print_success "Build verification passed!"
    else
        print_warning "Build verification had issues (this may be expected)"
    fi

    # Final Summary
    print_step "Setup Complete! 🎉"
    echo ""
    echo "Next steps:"
    echo "  1. Open:  ${GREEN}open $PROJECT_NAME.xcodeproj${NC}"
    echo "  2. Build: ${GREEN}⌘ + B${NC}"
    echo "  3. Test:  ${GREEN}⌘ + U${NC}"
    echo ""
    echo "Documentation:"
    echo "  - project.yml:      XcodeGen configuration"
    echo "  - setup.sh:         This setup script"
    echo "  - README.md:        Project documentation"
    echo "  - SETUP_XCODEGEN.md: XcodeGen guide"
    echo ""
    
    # Open Xcode if requested
    if [ "$OPEN_XCODE" = true ]; then
        open "$PROJECT_NAME.xcodeproj"
    fi
}

# Run main function
main "$@"

