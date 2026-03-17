#import <YouTubeHeader/YTCommonColorPalette.h>
#import <YouTubeHeader/YTPlayerViewController.h>
#import <YouTubeHeader/YTSingleVideoController.h>
#import <YouTubeHeader/GOODialogView.h>
#import "uYouPlus.h"

@interface PlayerManager : NSObject
// Prevent uYou player bar from showing when not playing downloaded media
- (float)progress;
// Prevent uYou's playback from colliding with YouTube's
- (void)setSource:(id)source;
- (void)pause;
+ (id)sharedInstance;
@end

// Fix uYou's appearance not updating if the app is backgrounded
@interface DownloadsPagerVC : UIViewController
- (NSArray<UIViewController *> *)viewControllers;
- (void)updatePageStyles;
@end
@interface DownloadingVC : UIViewController
- (void)updatePageStyles;
- (UITableView *)tableView;
@end
@interface DownloadingCell : UITableViewCell
- (void)updatePageStyles;
@end
@interface DownloadedVC : UIViewController
- (void)updatePageStyles;
- (UITableView *)tableView;
@end
@interface DownloadedCell : UITableViewCell
- (void)updatePageStyles;
@end
@interface UILabel (uYou)
+ (id)_defaultColor;
@end