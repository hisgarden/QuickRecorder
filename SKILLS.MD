# QuickRecorder Skills Documentation

This document outlines the skills and workflows used in the QuickRecorder project.

## Repository Cleanup and Maintenance

### Auto-Generated Documentation Cleanup

**Purpose:** Remove automatically generated markdown files from git tracking and prevent them from being committed in the future.

**Files to Ignore:**
- Process reports and summaries: `CODE_IMPROVEMENTS_SUMMARY.md`, `IMMEDIATE_IMPROVEMENTS_*.md`
- Refactoring documentation: `REFACTORING_DOCUMENTATION.md`, `REFACTORING_SUMMARY.md`
- TDD documentation: `TDD_*.md` (all TDD-related files)
- Testing reports: `TESTING_VALIDATION_REPORT.md`
- Status files: `NOTARIZATION_STATUS.md`, `NOTARIZATION_ISSUES.md`
- Fix documentation: `PERMISSION_DIALOG_FIX.md`, `SECURITY_TEST.md`
- Comparison documents: `UPDATE_MECHANISMS_COMPARISON.md`
- Warning fixes: `XCODE_WARNINGS_FIXES.md`
- Date-based auto-generated files: `*_*-*-*.md` (pattern for files like `DEADLOCK_FIX_2025-12-26.md`)

**Workflow:**
1. Add patterns to `.gitignore` to exclude auto-generated markdown files
2. Remove tracked files using `git rm --cached <file>`
3. Commit changes with descriptive message
4. Push to remote repository

**Commands:**
```bash
# Add to .gitignore
echo "CODE_IMPROVEMENTS_SUMMARY.md" >> .gitignore
echo "TDD_*.md" >> .gitignore
echo "*_*-*-*.md" >> .gitignore
# ... (add all patterns)

# Remove from git tracking
git rm --cached CODE_IMPROVEMENTS_SUMMARY.md TDD_*.md ...

# Commit and push
git add .gitignore
git commit -m "Ignore auto-generated markdown documentation files"
git push origin main
```

### Test Screenshot Cleanup

**Purpose:** Remove test screenshots and prevent them from being committed to the repository.

**Files to Ignore:**
- Test screenshots: `*test*.png`, `*test*.jpg`, `*test*.jpeg`
- Screenshot files: `*screenshot*.png`, `*screenshot*.jpg`, `*screenshot*.jpeg`
- Screenshot directories: `test_screenshots/`, `screenshots/`

**Note:** App icons and assets in `Assets.xcassets/` should NOT be ignored as they are part of the application.

**Workflow:**
1. Add screenshot patterns to `.gitignore`
2. Remove any tracked screenshot files using `git rm --cached`
3. Commit and push changes

**Commands:**
```bash
# Add to .gitignore
cat >> .gitignore << EOF
# Test screenshots and images
*test*.png
*test*.jpg
*test*.jpeg
*screenshot*.png
*screenshot*.jpg
*screenshot*.jpeg
*Screenshot*.png
*Screenshot*.jpg
*Screenshot*.jpeg
test_screenshots/
screenshots/
EOF

# Remove tracked screenshots (if any)
git rm --cached *screenshot*.png *test*.png 2>/dev/null || true

# Commit and push
git add .gitignore
git commit -m "Add test screenshot patterns to .gitignore"
git push origin main
```

### Build Artifacts Cleanup

**Purpose:** Remove build artifacts and distribution packages from git tracking.

**Files to Ignore:**
- App bundles: `*.app/`, `QuickRecorder.app/`, `QuickRecorder_Distribution.app/`
- Distribution packages: `*.dmg`, `*.zip` (except checksum files like `*.sha256.txt`)
- Build directories: `build/`, `DerivedData/`
- Archives: `*.xcarchive/`

**Workflow:**
1. Add patterns to `.gitignore`
2. Remove tracked files using `git rm --cached -r <directory>` for directories
3. Commit and push changes

**Commands:**
```bash
# Add to .gitignore
cat >> .gitignore << EOF
## Built app bundles (should not be committed)
*.app/
QuickRecorder.app/
QuickRecorder_Distribution.app/

## Distribution packages (upload to GitHub releases instead)
*.dmg
*.zip
!*.sha256.txt
!*.SHA256.txt

## Build artifacts
build/
DerivedData/
*.xcarchive/
EOF

# Remove tracked files
git rm --cached -r QuickRecorder.app/ QuickRecorder_Distribution.app/ 2>/dev/null || true
git rm --cached *.dmg *.zip 2>/dev/null || true

# Commit and push
git add .gitignore
git commit -m "Remove build artifacts and distribution packages from git"
git push origin main
```

## Best Practices

1. **Always update `.gitignore` first** before removing files from tracking
2. **Use `git rm --cached`** to remove files from git without deleting them locally
3. **Verify patterns** in `.gitignore` match the files you want to exclude
4. **Test locally** before pushing to ensure important files aren't accidentally ignored
5. **Keep user-facing documentation** like `README.md`, `NOTARIZATION_GUIDE.md`, and `RELEASE_NOTES_v*.md` in the repository
6. **Distribution packages** (DMG, ZIP) should be uploaded to GitHub Releases, not committed to the repository

## Pre-Commit Testing and Security Checks

**Purpose:** Ensure code quality and security before commits are made to the repository.

### Pre-Commit Hook Setup

The project includes a pre-commit hook that automatically runs:
1. **Full test suite** - All unit and integration tests
2. **Security tests** - Permission and error handling tests
3. **Visual build check** - Builds and opens app for visual inspection
4. **Security code analysis** - Checks for force unwraps and assertion failures

**Location:** `.git/hooks/pre-commit`

**Manual Script:** `scripts/run-pre-commit-checks.sh`

**Usage:**
```bash
# The hook runs automatically on git commit
git commit -m "Your commit message"
# → Opens app for visual inspection
# → Press Enter after verifying app looks correct

# To run manually:
./scripts/run-pre-commit-checks.sh

# Non-interactive mode (for CI/automation):
NON_INTERACTIVE=true ./scripts/run-pre-commit-checks.sh

# To skip checks (not recommended):
git commit --no-verify
```

**Visual Check Process:**
1. App is built in Debug configuration
2. App bundle is copied to `QuickRecorder_VisualCheck.app`
3. App is automatically opened for inspection
4. User verifies:
   - App launches without crashes
   - UI displays correctly
   - No obvious visual issues
5. Press Enter to continue or Ctrl+C to cancel
6. App is automatically closed and cleaned up

### GitHub Actions CI/CD

**Location:** `.github/workflows/tests.yml`

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches

**Jobs:**
1. **Full Test Suite** - Runs all tests with code coverage
2. **Security Tests** - Runs permission and error handling tests
3. **Code Quality** - Build verification and lint checks

**Status:** All checks must pass before merging pull requests.

### Test Requirements

Before committing to GitHub:
- ✅ All tests must pass (currently 47+ tests)
- ✅ Security tests must pass
- ✅ No compilation errors
- ✅ Code quality checks pass

### Bypassing Checks

**Not Recommended:** Only bypass checks in emergency situations:
```bash
# Skip pre-commit hook
git commit --no-verify

# Note: GitHub Actions will still run on push
```

## Related Skills

- **macOS App Release**: See `.claude/skills/macos-app-release/` for build, signing, and notarization workflows

