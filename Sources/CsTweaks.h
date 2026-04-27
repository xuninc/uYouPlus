#import "uYouPlus.h"

// C's Tweaks keys
static NSString *const kCsAutoSkipStillWatching = @"csAutoSkipStillWatching_enabled";
static NSString *const kCsHideComments = @"csHideComments_enabled";
static NSString *const kCsHideShareButton = @"csHideShareButton_enabled";
static NSString *const kCsHideThanksButton = @"csHideThanksButton_enabled";
static NSString *const kCsDisableLongPressSpeed = @"csDisableLongPressSpeed_enabled";
static NSString *const kCsShowTimeRemaining = @"csShowTimeRemaining_enabled";
static NSString *const kCsEnhancedDownloads = @"csEnhancedDownloads_enabled";
static NSString *const kCsDisableAmbientMode = @"csDisableAmbientMode_enabled";
static NSString *const kCsHideNotificationButton = @"csHideNotificationButton_enabled";
static NSString *const kCsCleanShareLinks = @"csCleanShareLinks_enabled";
static NSString *const kCsForceOriginalAudio = @"csForceOriginalAudio_enabled";
static NSString *const kCsSwipeBrightnessVolume = @"csSwipeBrightnessVolume_enabled";

// Class declarations for hooks

@interface YTWatchController : NSObject
@end

@interface YTIdlePlaybackDialogController : NSObject
- (void)dismiss;
- (void)confirmAction;
@end

@interface YTWatchIdleController : NSObject
@end

@interface YTPlayerBarController : NSObject
@property (nonatomic, readonly) double totalTime;
@property (nonatomic, readonly) double currentTime;
@end

@interface YTInlinePlayerBarContainerView : UIView
@property (nonatomic, strong) UILabel *timeRemainingLabel;
@end

// Download helpers
@interface CsDownloadManager : NSObject

+ (instancetype)sharedManager;
- (void)downloadVideoWithURL:(NSURL *)videoURL title:(NSString *)title;
- (void)showDownloadOptionsForVideoID:(NSString *)videoID fromViewController:(UIViewController *)viewController;

@end

// Playback speed gesture
@interface YTVarispeedSwitchControllerV2 : NSObject
@end

@interface YTColdConfig (CsTweaks)
- (BOOL)speedMasterArm2FastForwardWithoutSeekBySliding;
@end

@interface YTMainAppVideoPlayerOverlayView : UIView
@end

@interface YTCommentsPanelController : NSObject
@end

// Clean share links
@interface YTShareRequestConfig : NSObject
@property (nonatomic, copy) NSString *videoID;
@end

// Swipe brightness/volume
@interface YTPlayerViewController (CsTweaks)
@property (nonatomic, assign) CGFloat csInitialBrightness;
@property (nonatomic, assign) CGPoint csPanStartPoint;
@end
