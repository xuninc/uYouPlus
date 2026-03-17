#import "uYouPlus.h"

// YTMiniPlayerEnabler: https://github.com/level3tjg/YTMiniplayerEnabler/
%hook YTWatchMiniBarViewController
- (void)updateMiniBarPlayerStateFromRenderer {
    if (!IS_ENABLED(kYTMiniPlayer)) %orig;
}
%end