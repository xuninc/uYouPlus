# uYouPlus - Repository Overview

uYouPlus is a modified version of the YouTube iOS app that bundles [uYou](https://github.com/MiRO92/uYou-for-YouTube) with 15+ additional jailbreak tweaks into a single sideloadable IPA. It uses the [Theos](https://theos.dev) build system and Objective-C runtime hooking (Logos preprocessor `.xm` files) to modify YouTube's behavior at runtime.

## Architecture

```
Sources/            # Main tweak source code (.xm = Logos/Objective-C++, .h = headers)
Tweaks/             # 21 git submodules (dependency tweaks + YouTubeHeader declarations)
Localizations/      # uYouPlus.bundle with 16+ language translations
Extensions/         # Placeholder for .appex app extensions (currently empty)
Bundles/            # Placeholder for resource bundles (currently empty)
Makefile            # Theos build configuration - compiles all Sources/, injects 15 dylibs
build.sh            # Interactive wrapper: prompts for YouTube.ipa path, runs make, outputs SHA256
control             # Debian package metadata (com.qnblackcat.uyouplus)
uYouPlus.plist      # Substrate filter - targets com.google.ios.youtube only
.github/workflows/  # CI: manual dispatch builds IPA on macOS 14 with Theos
```

## Source Files

| File | Purpose |
|------|---------|
| `uYouPlus.h` | Central header: 70+ config keys (`IS_ENABLED(k)` macros), YouTube class forward declarations |
| `uYouPlus.xm` | Main hooks: video player options, overlay controls, Shorts tweaks, promo suppression, ad blocking, misc UI. Initializes default settings in `%ctor` |
| `uYouPlusPatches.xm` | Compatibility fixes: Google Sign-in bundle ID spoof, uYou player conflicts, artwork scaling, dark mode nav bar |
| `uYouPlusThemes.xm` | Three theme groups: Default, Old Dark (grey: 0.129), OLED (pure black). Hooks `YTCommonColorPalette` + keyboard theming |
| `uYouPlusSettings.xm` | Settings UI: injects "uYouPlus" section into YouTube Settings with ~40 toggles across 7 categories. Copy/paste settings support |
| `CsTweaks.h` / `CsTweaks.xm` | 12 additional features: auto-skip idle dialog, time remaining display, custom download manager, clean share links, force original audio, swipe brightness/volume |
| `BigYTMiniPlayer.xm` | Enlarges mini-player on iPhone by forcing layout mode and repositioning frame |
| `YTMiniPlayerEnabler.x` | Enables mini-player for all video types |
| `YTNoPaidPromo.x` | Hides paid promotion cards in video player |

## Build System

**Requirements:** macOS with Theos, ldid, dpkg, iOS 16.5 SDK (arm64 only)

**Target:** iOS 14.0+ (`ARCHS = arm64`, `TARGET = iphone:clang:16.5:14.0`)

**Build locally:**
```bash
./build.sh              # Interactive: prompts for decrypted YouTube.ipa path
# OR
make package THEOS_PACKAGE_SCHEME=rootless IPA=path/to/YouTube.app FINALPACKAGE=1
```

The Makefile automatically downloads uYou v3.0.5 from miro92.com if not cached, extracts its dylib/bundle, then compiles all Sources/ and injects 15 dependency dylibs from Tweaks/.

**CI:** `.github/workflows/buildapp.yml` — manual dispatch, inputs for YouTube IPA URL and uYou version, builds on macOS 14, optionally creates GitHub release.

## Key Patterns

- **Feature toggles:** All features use `IS_ENABLED(@"keyName")` reading from `NSUserDefaults.standardUserDefaults`. Keys defined in `uYouPlus.h`.
- **Logos hooks:** `%hook ClassName` / `%orig` pattern. Groups (`%group`) used for conditional initialization (e.g., themes loaded based on `APP_THEME_IDX`).
- **Localization:** `LOC(@"KEY")` macro loads from `uYouPlus.bundle`. 197 keys across 16+ languages.
- **Settings:** Built with `YTSettingsSectionItemManager` helper methods (`switchItemWithTitle:`, `checkmarkItemWithTitle:`, etc.). Inserted at category index 1 (before General).
- **Restart required:** Most toggles show a snackbar via `GOOHUDManagerInternal` prompting restart.

## Dependencies (Tweaks/ submodules)

Core: uYou, YouTubeHeader, PSHeader
UI: Alderis (color picker), FLEXing (debugger), YouGroupSettings
Video: YTUHD, YouPiP, YTClassicVideoQuality, YouQuality, YouSpeed, YTVideoOverlay
Content: iSponsorBlock, Return-YouTube-Dislikes, NoYTPremium, YouTube-X, DontEatMyContent, YouMute

## Current Branch Changes (vs main)

This fork adds CsTweaks (12 new features in `CsTweaks.h`/`CsTweaks.xm`), modernizes hooks in `uYouPlus.xm`, fixes broken code in patches, and adds corresponding localization strings and settings UI entries.
