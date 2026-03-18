# YTLite Changes

These files are from the xuninc/YTLite repo, commit 4e171c3.

## How to apply

The patch file `0001-Fix-crashes-improve-downloads-and-clean-up-codebase.patch` can be applied to the YTLite repo with:

```bash
cd /path/to/YTLite
git am /path/to/0001-Fix-crashes-improve-downloads-and-clean-up-codebase.patch
```

Or the individual files (Makefile, Settings.x, Sideloading.x, YTLite.h, YTLite.x) can be copied directly into the YTLite repo root.

## Summary of changes

- **Settings.x**: Extracted repeated picker UI code into reusable `pickerItemWithTitle()` helper; added bounds checking
- **Sideloading.x**: Fixed brace logic bug in `accessGroupID()` keychain query
- **YTLite.h**: Uncommented `yogaChildren` property declaration
- **YTLite.x**: Thread safety (`_Atomic`), null checks, async image downloads for profile pictures, `UIGraphicsImageRenderer` migration, bounds checking on array indices, proper `dispatch_async` for UI updates
- **Makefile**: Added Photos/Security frameworks, enabled warnings
