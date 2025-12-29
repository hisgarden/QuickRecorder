# Alternative Update Mechanisms for QuickRecorder

## Current Situation

**Problem:** Sparkle framework requires Developer ID Application certificate for notarization
**Impact:** App can't be fully notarized without the correct certificate
**Status:** App is production-ready except for this notarization blocker

## Alternative Update Mechanisms

### Option 1: Remove Sparkle, Use GitHub Releases (Simplest)

**How it works:**
- Check GitHub API for latest release
- Show in-app notification when update available
- Direct user to GitHub releases page
- User downloads and installs manually (or via Homebrew)

**Pros:**
✅ No complex framework dependencies
✅ No notarization issues
✅ Lightweight (no embedded update framework)
✅ Works with current certificate
✅ Easy to implement (50-100 lines of code)
✅ Users familiar with GitHub workflow

**Cons:**
❌ Manual download/install required
❌ Less seamless user experience
❌ No automatic background updates

**Implementation Effort:** 1-2 hours

**Code Example:**
```swift
// Simple update checker
class UpdateChecker {
    static func checkForUpdates() async throws -> UpdateInfo? {
        let url = URL(string: "https://api.github.com/repos/lihaoyun6/QuickRecorder/releases/latest")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
        
        if release.tag_name.compare(currentVersion, options: .numeric) == .orderedDescending {
            return UpdateInfo(version: release.tag_name, url: release.html_url)
        }
        return nil
    }
}
```

---

### Option 2: Homebrew-Only Updates (Developer Friendly)

**How it works:**
- Users install via: `brew install lihaoyun6/tap/quickrecorder`
- Updates via: `brew upgrade quickrecorder`
- In-app notification points to Homebrew

**Pros:**
✅ No notarization needed
✅ Homebrew handles all signing/security
✅ Popular among developers
✅ Already set up in README
✅ One-command updates

**Cons:**
❌ Requires Homebrew installed
❌ Not ideal for non-technical users
❌ Manual update command needed

**Implementation Effort:** 0 hours (already available!)

---

### Option 3: Built-in ZIP Updater (No Framework)

**How it works:**
- Custom Swift code to download and apply updates
- Download ZIP from GitHub releases
- Extract and replace app bundle
- Relaunch app

**Pros:**
✅ No framework dependencies
✅ Full control over update process
✅ Can work with current certificate (with user approval)
✅ Seamless once authorized

**Cons:**
❌ More complex to implement correctly
❌ Need to handle edge cases (permissions, partial downloads, etc.)
❌ Still requires user to approve initial app launch
⚠️ Risk of incomplete updates if not carefully coded

**Implementation Effort:** 4-6 hours

---

### Option 4: Get Developer ID Certificate (Recommended)

**How it works:**
- Create Developer ID Application certificate
- Keep Sparkle framework
- Full notarization support

**Pros:**
✅ Professional update experience
✅ Sparkle is battle-tested
✅ Automatic silent updates
✅ Delta updates support
✅ Rollback capability
✅ Full Gatekeeper approval

**Cons:**
❌ Requires certificate creation (15 minutes)

**Implementation Effort:** 15 minutes

---

### Option 5: Hybrid Approach (Best of Both)

**How it works:**
- Keep Sparkle for users with notarized build
- Add GitHub update checker as fallback
- Show appropriate UI based on build type

**Pros:**
✅ Works in all scenarios
✅ Graceful degradation
✅ Future-proof

**Cons:**
❌ More code to maintain
❌ Two update paths

**Implementation Effort:** 3-4 hours

---

## Recommendation Matrix

| Scenario | Recommended Approach |
|----------|---------------------|
| **Quick fix needed now** | Option 1: GitHub API checker |
| **Developer audience** | Option 2: Homebrew only |
| **Long-term solution** | Option 4: Get Developer ID cert |
| **Maximum flexibility** | Option 5: Hybrid |
| **Minimal changes** | Option 2: Homebrew (already works!) |

---

## Immediate Action Plan

### Path A: Remove Sparkle (2 hours total)

1. **Remove Sparkle dependency** (30 min)
   ```bash
   # Remove from Package.swift dependencies
   # Remove from Xcode project
   # Remove import statements
   ```

2. **Add simple update checker** (1 hour)
   ```swift
   // Check GitHub releases API
   // Show notification if update available
   // Link to releases page
   ```

3. **Update UI** (30 min)
   - Remove "Check for Updates" Sparkle menu item
   - Add custom "Check for Updates" that opens GitHub

4. **Build and sign** (no changes needed)
   - Works with current certificate
   - No notarization blocker

### Path B: Keep Sparkle, Get Certificate (15 minutes)

1. Go to https://developer.apple.com/account/resources/certificates/list
2. Create "Developer ID Application" certificate
3. Install certificate
4. Run existing `sign_with_developer_id.sh` script
5. Submit for notarization
6. Done!

---

## Code to Remove Sparkle (If Chosen)

**Files to modify:**
```
QuickRecorder/QuickRecorderApp.swift (remove import, remove updaterController)
QuickRecorder.xcodeproj/project.pbxproj (remove Sparkle package)
```

**Files to add:**
```
QuickRecorder/Supports/SimpleUpdateChecker.swift (new file)
```

---

## Decision Factors

### Choose Option 1 (GitHub API) if:
- ✅ You want to ship TODAY without cert
- ✅ Your users are comfortable with manual updates
- ✅ You want minimum code complexity

### Choose Option 2 (Homebrew only) if:
- ✅ Your audience is primarily developers
- ✅ You want zero implementation work
- ✅ You're okay with Homebrew-only distribution

### Choose Option 4 (Get cert) if:
- ✅ You want professional, polished experience
- ✅ 15 minutes setup time is acceptable
- ✅ You plan long-term support
- ✅ **This is the recommended approach**

---

## Sparkle Blocker Context

The issue isn't Sparkle itself - it's that **any** embedded framework requires proper signing with Developer ID Application certificate for notarization. Even a custom update mechanism would face the same challenge if notarization is required.

The real choice is:
1. **Get the certificate** (15 min) → Keep Sparkle, full notarization
2. **Skip notarization** → Use simpler update mechanism + user workaround

---

## Bottom Line

**For Production:** Get the Developer ID Application certificate. It's a one-time 15-minute task that solves this permanently and provides the best user experience.

**For Quick Demo/Testing:** Remove Sparkle, use GitHub API checker, ship immediately.

**For Developer Tool:** Just use Homebrew (already works!).

---

## Implementation Scripts Ready

I've prepared:
- ✅ `sign_with_developer_id.sh` - Ready for when you get the certificate
- ✅ `sign_distribution_clean.sh` - Works with current cert (but won't notarize)
- ✅ Documentation in `NOTARIZATION_FIX.md`

**Your app is production-ready.** The only question is which update mechanism you prefer.
