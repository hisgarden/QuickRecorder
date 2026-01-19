# ScreenCaptureKit (SCREENAGER) WiFi Network Troubleshooting

## Overview
While ScreenCaptureKit doesn't require network connectivity for local screen capture, WiFi issues can affect system services and permissions that ScreenCaptureKit depends on. This guide helps diagnose and resolve network-related issues.

## Common Symptoms

### ScreenCaptureKit Errors
- `SCStreamError` when starting capture
- "Failed to fetch available content" errors
- Screen capture fails to initialize
- Display detection issues
- Stream connection timeouts

### Network-Related Issues
- WiFi connection drops during capture
- System services unavailable
- Permission dialogs not appearing
- App hangs when accessing screen content

## Step-by-Step Troubleshooting

### Step 1: Verify WiFi Connection
Check basic WiFi connectivity:

```sh
# Check WiFi status
networksetup -getairportnetwork en0

# Check network interface status
ifconfig en0 | grep "status"

# Test internet connectivity
ping -c 3 8.8.8.8

# Check DNS resolution
nslookup google.com
```

**Expected Results:**
- WiFi network name should be displayed
- Interface status should be "active"
- Ping should succeed
- DNS should resolve

### Step 2: Check System Network Services
ScreenCaptureKit may depend on system services that require network:

```sh
# Check system network services status
scutil --nc list

# Check network reachability
scutil --nc status "Wi-Fi"

# Verify network configuration
scutil --dns
```

### Step 3: Verify ScreenCaptureKit Permissions
Network issues can sometimes prevent permission dialogs from appearing:

1. **Check Screen Recording Permission:**
   ```sh
   # Check if QuickRecorder has screen recording permission
   tccutil reset ScreenCapture dev.hisgarden.QuickRecorder
   ```

2. **Manually Grant Permissions:**
   - System Settings > Privacy & Security > Screen Recording
   - Ensure QuickRecorder is enabled
   - If not listed, add it manually

3. **Check Accessibility Permission:**
   - System Settings > Privacy & Security > Accessibility
   - Ensure QuickRecorder is enabled

### Step 4: Test ScreenCaptureKit Directly
Create a test to verify ScreenCaptureKit functionality:

```swift
// Test SCShareableContent access
SCShareableContent.getExcludingDesktopWindows(false, onScreenWindowsOnly: true) { content, error in
    if let error = error {
        print("SCShareableContent error: \(error)")
    } else if let content = content {
        print("Successfully retrieved \(content.displays.count) displays")
    }
}
```

### Step 5: Check Firewall Settings
macOS Firewall might be blocking system services:

1. **Check Firewall Status:**
   ```sh
   /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
   ```

2. **System Settings > Network > Firewall:**
   - Check if Firewall is enabled
   - Verify QuickRecorder is allowed
   - Check "Block all incoming connections" setting

3. **Temporarily disable Firewall for testing:**
   ```sh
   # Note: Only for testing, re-enable after
   sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate off
   ```

### Step 6: Network Interface Diagnostics
Check for network interface issues:

```sh
# Check all network interfaces
ifconfig -a

# Check WiFi signal strength
/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I

# Check network statistics
netstat -i

# Check for network errors
netstat -s | grep -i error
```

### Step 7: Reset Network Configuration
If network issues persist, try resetting network settings:

```sh
# Flush DNS cache
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder

# Reset network location (if using multiple locations)
networksetup -switchtolocation "Automatic"

# Renew DHCP lease
sudo ipconfig set en0 DHCP
```

### Step 8: Check System Logs
Look for network-related errors in system logs:

```sh
# Check Console for network errors
log show --predicate 'subsystem == "com.apple.network"' --last 1h

# Check ScreenCaptureKit errors
log show --predicate 'subsystem == "com.apple.ScreenCaptureKit"' --last 1h

# Check for permission errors
log show --predicate 'eventMessage contains "ScreenCapture" OR eventMessage contains "SCShareableContent"' --last 1h
```

### Step 9: WiFi-Specific Troubleshooting

#### Check WiFi Hardware
```sh
# Check WiFi adapter status
system_profiler SPAirPortDataType

# Check WiFi power management
pmset -g | grep -i wifi
```

#### Reset WiFi Connection
```sh
# Turn WiFi off and on
networksetup -setairportpower en0 off
sleep 2
networksetup -setairportpower en0 on

# Or use System Settings:
# System Settings > Wi-Fi > Toggle off/on
```

#### Check WiFi Security Settings
- Verify WiFi network security (WPA2/WPA3)
- Check if network requires special authentication
- Verify network isn't blocking certain protocols

### Step 10: App-Specific Network Checks

#### Verify App Entitlements
Check that network client entitlement is enabled:

```xml
<!-- QuickRecorder.entitlements -->
<key>com.apple.security.network.client</key>
<true/>
```

#### Test Network Access from App
```swift
// Test network connectivity from within app
let url = URL(string: "https://www.apple.com")!
let task = URLSession.shared.dataTask(with: url) { data, response, error in
    if let error = error {
        print("Network error: \(error)")
    } else {
        print("Network connection successful")
    }
}
task.resume()
```

## Common Solutions

### Solution 1: Restart Network Services
```sh
# Restart network services
sudo launchctl unload /System/Library/LaunchDaemons/com.apple.networkd.plist
sudo launchctl load /System/Library/LaunchDaemons/com.apple.networkd.plist

# Restart mDNSResponder
sudo launchctl unload /System/Library/LaunchDaemons/com.apple.mDNSResponder.plist
sudo launchctl load /System/Library/LaunchDaemons/com.apple.mDNSResponder.plist
```

### Solution 2: Reset Network Location
1. System Settings > Network
2. Click the location dropdown (top of window)
3. Select "Edit Locations..."
4. Create a new location or reset to "Automatic"
5. Apply the new location

### Solution 3: Reinstall Network Drivers
```sh
# Reset network preferences (backup first!)
# This will remove all network settings
sudo rm /Library/Preferences/SystemConfiguration/com.apple.network.identification.plist
sudo rm /Library/Preferences/SystemConfiguration/NetworkInterfaces.plist
sudo rm /Library/Preferences/SystemConfiguration/preferences.plist

# Restart required after this
```

### Solution 4: Check for VPN/Proxy Interference
- Disable VPN temporarily
- Check proxy settings: System Settings > Network > [Interface] > Details > Proxies
- Disable proxy if not needed

### Solution 5: Update macOS
Network issues can be resolved in system updates:

```sh
# Check for updates
softwareupdate -l

# Install available updates
softwareupdate -i -a
```

## Advanced Diagnostics

### Network Quality Test
```sh
# Test network latency and packet loss
ping -c 100 -i 0.2 8.8.8.8

# Test bandwidth
# Install: brew install speedtest-cli
speedtest-cli
```

### Check for Network Conflicts
```sh
# Check for duplicate IP addresses
arp -a

# Check routing table
netstat -rn

# Check for network interface conflicts
ifconfig | grep -A 5 "inet "
```

### Monitor Network Activity
```sh
# Monitor network connections
lsof -i

# Monitor network traffic
sudo tcpdump -i en0 -n

# Check network statistics
netstat -s
```

## Prevention

1. **Keep macOS Updated**
   - System updates often include network fixes
   - Check: System Settings > General > Software Update

2. **Maintain Stable WiFi Connection**
   - Use 5GHz band when possible (less interference)
   - Keep router firmware updated
   - Position device closer to router if signal is weak

3. **Monitor Network Health**
   - Use WiFi diagnostics: Option+Click WiFi icon in menu bar
   - Check signal strength regularly
   - Monitor for connection drops

4. **Backup Network Settings**
   - Export network locations before major changes
   - Document custom network configurations

## When ScreenCaptureKit Doesn't Need Network

**Important:** ScreenCaptureKit for local screen capture should work without network:
- Local display capture doesn't require internet
- Screen content retrieval is local
- Stream creation is local

If capture fails only when WiFi is off, the issue is likely:
- System service dependency on network
- Permission system requiring network
- App update/verification requiring network

## Related Resources

- [Apple ScreenCaptureKit Documentation](https://developer.apple.com/documentation/screencapturekit)
- [macOS Network Troubleshooting](https://support.apple.com/guide/mac-help/troubleshoot-network-issues-mh27990/mac)
- [QuickRecorder GitHub Issues](https://github.com/hisgarden/QuickRecorder/issues)

## Quick Reference

```sh
# Quick WiFi reset
networksetup -setairportpower en0 off && sleep 2 && networksetup -setairportpower en0 on

# Quick DNS flush
sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder

# Check ScreenCaptureKit permission
tccutil reset ScreenCapture dev.hisgarden.QuickRecorder

# View recent network errors
log show --predicate 'subsystem == "com.apple.network"' --last 30m | grep -i error
```



