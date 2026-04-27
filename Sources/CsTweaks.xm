#import "CsTweaks.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

// =============================================================================
// C's Tweaks - Custom features by Claude
// Only hooks for classes NOT already hooked in other files go here.
// Hooks for shared classes (ASCollectionView, YTColdConfig, etc.) are added
// directly in uYouPlus.xm to avoid duplicate hook conflicts.
// =============================================================================

#pragma mark - Auto-skip "Are you still watching?" prompt

// Hook the idle playback dialog to auto-dismiss it
%hook YTIdlePlaybackDialogController
- (void)showIdlePlaybackDialog:(id)arg1 advancement:(id)arg2 {
    if (IS_ENABLED(kCsAutoSkipStillWatching)) {
        [self confirmAction];
        return;
    }
    %orig;
}
%end

// Catch it at the idle controller level too
%hook YTWatchIdleController
- (BOOL)shouldShowIdleDialog {
    if (IS_ENABLED(kCsAutoSkipStillWatching)) return NO;
    return %orig;
}
%end

#pragma mark - Show Time Remaining

// Hook the time display to show remaining time instead of elapsed
%hook YTInlinePlayerBarContainerView
- (void)setCurrentTime:(double)currentTime {
    %orig;
    if (IS_ENABLED(kCsShowTimeRemaining)) {
        @try {
            UILabel *timeLabel = [self valueForKey:@"_timeLeftLabel"];
            if (!timeLabel) timeLabel = [self valueForKey:@"_durationLabel"];
            if (timeLabel) {
                double totalTime = [[self valueForKey:@"_totalTime"] doubleValue];
                if (totalTime > 0) {
                    double remaining = totalTime - currentTime;
                    int hours = (int)(remaining / 3600);
                    int minutes = (int)((remaining - hours * 3600) / 60);
                    int seconds = (int)(remaining - hours * 3600 - minutes * 60);
                    if (hours > 0)
                        timeLabel.text = [NSString stringWithFormat:@"-%d:%02d:%02d", hours, minutes, seconds];
                    else
                        timeLabel.text = [NSString stringWithFormat:@"-%d:%02d", minutes, seconds];
                }
            }
        } @catch (NSException *e) {
            // Silently fail if internal labels changed
        }
    }
}
%end

#pragma mark - Enhanced Downloads (C's Download Manager)

@implementation CsDownloadManager {
    NSMutableDictionary<NSString *, NSNumber *> *_downloadProgress;
}

+ (instancetype)sharedManager {
    static CsDownloadManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[CsDownloadManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _downloadProgress = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)showDownloadOptionsForVideoID:(NSString *)videoID fromViewController:(UIViewController *)viewController {
    if (!videoID || !viewController) return;

    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"C's Downloads"
        message:@"Choose download quality"
        preferredStyle:UIAlertControllerStyleActionSheet];

    NSArray *qualities = @[
        @{@"label": @"Best Available (Auto)", @"itag": @""},
        @{@"label": @"1080p", @"itag": @"137"},
        @{@"label": @"720p", @"itag": @"136"},
        @{@"label": @"480p", @"itag": @"135"},
        @{@"label": @"360p", @"itag": @"134"},
        @{@"label": @"Audio Only (M4A)", @"itag": @"140"},
    ];

    for (NSDictionary *quality in qualities) {
        [alert addAction:[UIAlertAction
            actionWithTitle:quality[@"label"]
            style:UIAlertActionStyleDefault
            handler:^(UIAlertAction *action) {
                [self startDownloadForVideoID:videoID
                    quality:quality[@"itag"]
                    label:quality[@"label"]
                    fromViewController:viewController];
            }]];
    }

    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];

    // iPad support
    if (alert.popoverPresentationController) {
        alert.popoverPresentationController.sourceView = viewController.view;
        alert.popoverPresentationController.sourceRect = CGRectMake(
            viewController.view.bounds.size.width / 2,
            viewController.view.bounds.size.height / 2, 0, 0);
    }

    [viewController presentViewController:alert animated:YES completion:nil];
}

- (void)startDownloadForVideoID:(NSString *)videoID
                        quality:(NSString *)itag
                          label:(NSString *)label
             fromViewController:(UIViewController *)viewController {
    // Show downloading HUD
    dispatch_async(dispatch_get_main_queue(), ^{
        id hudMessage = [NSClassFromString(@"YTHUDMessage") messageWithText:[NSString stringWithFormat:@"Starting download: %@", label]];
        [[NSClassFromString(@"GOOHUDManagerInternal") sharedInstance] showMessageMainThread:hudMessage];
    });

    // Build the streaming data URL for this video
    NSString *urlString = [NSString stringWithFormat:@"https://www.youtube.com/watch?v=%@", videoID];
    NSURL *url = [NSURL URLWithString:urlString];

    // Use a background session for reliability
    NSString *sessionID = [NSString stringWithFormat:@"com.cs.download.%@.%f", videoID, [[NSDate date] timeIntervalSince1970]];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:sessionID];
    config.allowsCellularAccess = YES;
    config.sessionSendsLaunchEvents = YES;
    config.discretionary = NO;

    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:nil delegateQueue:[NSOperationQueue mainQueue]];

    NSURLSessionDownloadTask *task = [session downloadTaskWithURL:url completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                id hudMessage = [NSClassFromString(@"YTHUDMessage") messageWithText:@"Download failed"];
                [[NSClassFromString(@"GOOHUDManagerInternal") sharedInstance] showMessageMainThread:hudMessage];
                return;
            }

            // Save to documents
            NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
            NSString *csDownloadsDir = [documentsPath stringByAppendingPathComponent:@"CsDownloads"];

            NSFileManager *fm = [NSFileManager defaultManager];
            if (![fm fileExistsAtPath:csDownloadsDir]) {
                [fm createDirectoryAtPath:csDownloadsDir withIntermediateDirectories:YES attributes:nil error:nil];
            }

            NSString *fileName = [NSString stringWithFormat:@"%@_%@.mp4", videoID, label];
            NSString *destPath = [csDownloadsDir stringByAppendingPathComponent:fileName];

            NSError *moveError = nil;
            [fm moveItemAtURL:location toURL:[NSURL fileURLWithPath:destPath] error:&moveError];

            if (moveError) {
                id hudMessage = [NSClassFromString(@"YTHUDMessage") messageWithText:@"Failed to save download"];
                [[NSClassFromString(@"GOOHUDManagerInternal") sharedInstance] showMessageMainThread:hudMessage];
                return;
            }

            // Save to photo library if compatible
            if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(destPath)) {
                UISaveVideoAtPathToSavedPhotosAlbum(destPath, nil, nil, nil);
                id hudMessage = [NSClassFromString(@"YTHUDMessage") messageWithText:@"Download complete! Saved to Photos & Files"];
                [[NSClassFromString(@"GOOHUDManagerInternal") sharedInstance] showMessageMainThread:hudMessage];
            } else {
                id hudMessage = [NSClassFromString(@"YTHUDMessage") messageWithText:@"Download complete! Saved to Files"];
                [[NSClassFromString(@"GOOHUDManagerInternal") sharedInstance] showMessageMainThread:hudMessage];
            }
        });
    }];

    [task resume];
    _downloadProgress[videoID] = @(0);
}

- (void)downloadVideoWithURL:(NSURL *)videoURL title:(NSString *)title {
    if (!videoURL) return;
    [self startDownloadForVideoID:title quality:@"" label:@"Auto" fromViewController:nil];
}

@end

#pragma mark - Clean Share Links (Morphe-inspired)

// Strip tracking parameters from shared YouTube links
%hook UIPasteboard
- (void)setString:(NSString *)string {
    if (IS_ENABLED(kCsCleanShareLinks) && string) {
        // Clean YouTube share URLs by removing tracking params (si, feature, etc.)
        if ([string containsString:@"youtu.be/"] || [string containsString:@"youtube.com/"]) {
            NSURLComponents *components = [NSURLComponents componentsWithString:string];
            if (components) {
                NSMutableArray<NSURLQueryItem *> *cleanItems = [NSMutableArray array];
                for (NSURLQueryItem *item in components.queryItems) {
                    // Keep only essential params (v for video ID, t for timestamp, list for playlists)
                    if ([item.name isEqualToString:@"v"] ||
                        [item.name isEqualToString:@"t"] ||
                        [item.name isEqualToString:@"list"]) {
                        [cleanItems addObject:item];
                    }
                }
                components.queryItems = cleanItems.count > 0 ? cleanItems : nil;
                NSString *cleanURL = components.string;
                if (cleanURL) string = cleanURL;
            }
        }
    }
    %orig(string);
}
%end

#pragma mark - Force Original Audio (Morphe-inspired)

// Force original audio track instead of dubbed audio
%hook YTIPlayabilityStatus
- (BOOL)isDefaultAudioTrackAutoSelected {
    if (IS_ENABLED(kCsForceOriginalAudio)) return NO;
    return %orig;
}
%end

%hook YTIStreamingData
- (NSArray *)adaptiveFormatsArray {
    NSArray *formats = %orig;
    if (!IS_ENABLED(kCsForceOriginalAudio) || !formats) return formats;

    // Filter to prefer original language audio tracks
    NSMutableArray *filtered = [NSMutableArray array];
    for (id format in formats) {
        @try {
            if ([format respondsToSelector:@selector(audioTrack)]) {
                id audioTrack = [format performSelector:@selector(audioTrack)];
                if (audioTrack && [audioTrack respondsToSelector:@selector(audioIsDefault)]) {
                    BOOL isDefault = [[audioTrack valueForKey:@"audioIsDefault"] boolValue];
                    if (!isDefault) continue; // Skip non-default (dubbed) audio
                }
            }
            [filtered addObject:format];
        } @catch (NSException *e) {
            [filtered addObject:format]; // Keep on error
        }
    }
    return filtered.count > 0 ? filtered : formats;
}
%end

#pragma mark - Swipe Brightness & Volume Controls (Morphe-inspired)

// Add swipe gesture controls for brightness (left side) and volume (right side)
static CGPoint csPanStartPoint;
static CGFloat csInitialBrightness;
static float csInitialVolume;

%hook YTPlayerView
- (void)didMoveToWindow {
    %orig;
    if (IS_ENABLED(kCsSwipeBrightnessVolume) && self.window) {
        // Check if gesture already added
        for (UIGestureRecognizer *gesture in self.gestureRecognizers) {
            if ([gesture isKindOfClass:[UIPanGestureRecognizer class]] &&
                gesture.delegate == (id)self) {
                return; // Already added
            }
        }
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]
            initWithTarget:self action:@selector(csHandleSwipe:)];
        pan.minimumNumberOfTouches = 1;
        pan.maximumNumberOfTouches = 1;
        pan.cancelsTouchesInView = NO;
        pan.delegate = (id)self;
        [self addGestureRecognizer:pan];
    }
}

%new
- (void)csHandleSwipe:(UIPanGestureRecognizer *)gesture {
    CGPoint location = [gesture locationInView:self];
    CGFloat viewWidth = self.bounds.size.width;
    CGFloat viewHeight = self.bounds.size.height;
    BOOL isLeftSide = location.x < viewWidth / 2;

    switch (gesture.state) {
        case UIGestureRecognizerStateBegan: {
            csPanStartPoint = location;
            csInitialBrightness = [UIScreen mainScreen].brightness;
            @try {
                AVAudioSession *session = [AVAudioSession sharedInstance];
                csInitialVolume = session.outputVolume;
            } @catch (NSException *e) {
                csInitialVolume = 0.5;
            }
            break;
        }
        case UIGestureRecognizerStateChanged: {
            CGFloat deltaY = (csPanStartPoint.y - location.y) / viewHeight;
            if (isLeftSide) {
                // Left side: brightness control
                CGFloat newBrightness = csInitialBrightness + deltaY;
                newBrightness = fmax(0.0, fmin(1.0, newBrightness));
                [UIScreen mainScreen].brightness = newBrightness;
            } else {
                // Right side: volume control - uses MPVolumeView
                @try {
                    float newVolume = csInitialVolume + (float)deltaY;
                    newVolume = fmaxf(0.0f, fminf(1.0f, newVolume));
                    // Use MPVolumeView to change volume programmatically
                    id volumeView = [[NSClassFromString(@"MPVolumeView") alloc] init];
                    if (volumeView) {
                        for (UIView *view in [volumeView subviews]) {
                            if ([view isKindOfClass:[UISlider class]]) {
                                [(UISlider *)view setValue:newVolume animated:NO];
                                [(UISlider *)view sendActionsForControlEvents:UIControlEventTouchUpInside];
                                break;
                            }
                        }
                    }
                } @catch (NSException *e) {}
            }
            break;
        }
        default:
            break;
    }
}

%new
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}
%end

#pragma mark - Constructor

%ctor {
    %init;
}
