#
<p align="center">
<img src="./QuickRecorder/Assets.xcassets/AppIcon.appiconset/icon_128x128@2x.png" width="200" height="200" />
<h1 align="center">QuickRecorder</h1>
<h3 align="center">A lightweight and high-performance screen recorder for macOS<br><a href="./README_zh.md">[中文版本]</a><br><a href="https://lihaoyun6.github.io/quickrecorder/">[Landing Page]</a>
</p>

> **Note:** This is a maintained fork of [lihaoyun6/QuickRecorder](https://github.com/lihaoyun6/QuickRecorder) with additional improvements and enhancements. See [Modifications](#modifications) section below for details.

## Screenshot
<p align="center">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="./img/preview_en_dark.png">
  <source media="(prefers-color-scheme: light)" srcset="./img/preview_en.png">
  <img alt="QuickRecorder Screenshots" src="./img/preview_en.png" width="840"/>
</picture>
</p>

## Installation and Usage
### System Requirements:
- macOS 12.3 and Later

### Install:
Download the latest installation file from [GitHub Releases](https://github.com/hisgarden/QuickRecorder/releases/latest) or install via Homebrew:

```bash
# Original upstream (recommended for stable releases)
brew install lihaoyun6/tap/quickrecorder

# This fork (if you have a Homebrew tap set up)
# brew install hisgarden/tap/quickrecorder
```

### Features/Usage:
- You can use QuickRecorder to record your screens / windows / applications / mobile devices... etc.

- QuickRecorder supports driver-free audio loopback recording, mouse highlighting, screen magnifier and many more useful features.  
- The new **"[Presenter Overlay](https://support.apple.com/guide/facetime/presenter-overlay-video-conferencing-fctm6333f4bd/mac)"** in macOS 14 was fully supported by QuickRecorder, which can overlay the camera in real time on your recording *(macOS 12/13 can only use camera floating window)*  
- QuickRecorder is able to record `HEVC with Alpha` video format, that can contain alpha channel in the output file *(currently only iMovie and FCPX support this feature)*  

## Modifications

This fork includes the following enhancements and improvements beyond the original [lihaoyun6/QuickRecorder](https://github.com/lihaoyun6/QuickRecorder) repository:

### Key Enhancements

- **Dependency Minimization**: Removed SwiftLAME dependency, reducing SPM dependencies from 5 to 3 packages (40% smaller binary size)
- **Enhanced Permission Handling**: Automatic permission detection and app restart when screen recording permission is granted
- **Sentry Integration**: Error tracking and crash reporting (enabled in Debug builds only, disabled in Release for privacy)
- **Build System Improvements**: Migrated from Justfile to Taskfile with automatic dependency management and smart caching
- **SBOM Support**: Comprehensive Software Bill of Materials generation and validation for security compliance
- **Test Suite**: Enhanced TDD test suite with improved coverage and test infrastructure
- **Xcode Project Files**: Included pre-generated Xcode project files for users without XcodeGen
- **Improved Error Handling**: Better error recovery and user feedback throughout the application

### Technical Details

- **Audio Formats**: Streamlined to AAC (recommended), ALAC, FLAC, and Opus (MP3 removed)
- **Build Tools**: Taskfile.yml with automatic dependency resolution and build caching
- **CI/CD**: Enhanced GitHub Actions workflows with automated testing and release management
- **Documentation**: Comprehensive documentation for permissions, testing, and build processes

### Compatibility

This fork maintains full compatibility with the original QuickRecorder functionality while adding these enhancements. All original features remain intact and functional.

For the original upstream repository, please visit: [lihaoyun6/QuickRecorder](https://github.com/lihaoyun6/QuickRecorder)

## Q&A
**1. Where can I reopen the main panel after closing it?**
> Click the Dock tile or Menubar icon of QuickRecorder to reopen the main panel at any time.

**2. Why does QuickRecorder not a sandbox app?**
> QuickRecorder has no plans to be uploaded to the App Store, so it does not need to be designed as a sandbox app.  

**3. How to independently control the volume of system sound and sound from microphone in other video editor?**
> QuickRecorder will merge the audio input from the microphone to the main audio track after recording by default. If you need to edit the video, you can turn off the `Record Microphone to Main Track` option in the settings panel. After turning off, the system sound and sound from microphone will be recorded into two audio tracks and can be edited independently.  

## Donate
<img src="./img/donate.png" width="350"/>

## Thanks
[Azayaka](https://github.com/Mnpn/Azayaka) @Mnpn
> The source of inspiration and part of the code of the screen recording engine comes from the Azayaka project, and I am also one of the code contributors to this project

[KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) @sindresorhus  
> QuickRecorder uses this swift library to handle shortcut key events  

[Sparkle](https://github.com/sparkle-project/Sparkle) @sparkle-project
> QuickRecorder uses this framework for automatic updates

[Sentry](https://github.com/getsentry/sentry-cocoa) @getsentry
> QuickRecorder uses Sentry for error tracking in development builds
