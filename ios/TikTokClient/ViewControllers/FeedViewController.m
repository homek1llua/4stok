#import "FeedViewController.h"
#import "VideoDetailViewController.h"
#import "APIClient.h"
#import "Video.h"
#import "User.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

@interface FeedViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSMutableArray<Video *> *videos;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, assign) BOOL isLoadingMore;
@property (nonatomic, assign) NSInteger currentPage;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, assign) BOOL isPlaying;
@property (nonatomic, strong) NSMutableDictionary *playerItems;
@property (nonatomic, strong) NSMutableDictionary *playerLayers;

@end

@implementation FeedViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.videos = [NSMutableArray array];
  self.playerItems = [NSMutableDictionary dictionary];
  self.playerLayers = [NSMutableDictionary dictionary];
  self.currentIndex = 0;
  self.currentPage = 1;
  self.isPlaying = NO;

  self.view.backgroundColor = [UIColor blackColor];
  self.navigationController.navigationBarHidden = YES;

  [self setupScrollView];
  [self loadFeed];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupScrollView {
  self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
  self.scrollView.pagingEnabled = YES;
  self.scrollView.showsVerticalScrollIndicator = NO;
  self.scrollView.delegate = self;
  self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:self.scrollView];

  [self.scrollView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
  [self.scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
  [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
  [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
}

- (void)loadFeed {
  [self loadFeedWithPage:self.currentPage];
}

- (void)loadFeedWithPage:(NSInteger)page {
  self.isLoadingMore = YES;

  [[APIClient sharedClient] getFeedWithPage:page limit:10 success:^(id response) {
    NSArray *videoDicts = response[@"videos"];
    for (NSDictionary *dict in videoDicts) {
      Video *video = [[Video alloc] initWithDictionary:dict];
      [self.videos addObject:video];
    }
    [self layoutVideoViews];
    self.isLoadingMore = NO;
    if (page == 1 && self.videos.count > 0) {
      [self playVideoAtIndex:0];
    }
  } failure:^(NSError *error) {
    self.isLoadingMore = NO;
    NSLog(@"Feed load error: %@", error.localizedDescription);
  }];
}

- (void)layoutVideoViews {
  for (UIView *subview in self.scrollView.subviews) {
    [subview removeFromSuperview];
  }

  CGFloat width = self.view.bounds.size.width;
  CGFloat height = self.view.bounds.size.height;

  self.scrollView.contentSize = CGSizeMake(width, height * self.videos.count);

  for (NSInteger i = 0; i < self.videos.count; i++) {
    Video *video = self.videos[i];
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, i * height, width, height)];
    container.backgroundColor = [UIColor blackColor];
    container.clipsToBounds = YES;
    container.tag = i;

    // Video player layer
    AVPlayerLayer *playerLayer = [AVPlayerLayer layer];
    playerLayer.frame = container.bounds;
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [container.layer addSublayer:playerLayer];

    // Overlay gradient
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = container.bounds;
    gradient.colors = @[(id)[UIColor clearColor].CGColor, (id)[UIColor colorWithWhite:0 alpha:0.6].CGColor];
    gradient.locations = @[@0.6, @1.0];
    [container.layer addSublayer:gradient];

    // Caption label
    UILabel *captionLabel = [[UILabel alloc] init];
    captionLabel.text = video.caption;
    captionLabel.textColor = [UIColor whiteColor];
    captionLabel.font = [UIFont systemFontOfSize:14];
    captionLabel.numberOfLines = 2;
    captionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [container addSubview:captionLabel];

    // Username label
    UILabel *userLabel = [[UILabel alloc] init];
    userLabel.text = [NSString stringWithFormat:@"@%@", video.user.username];
    userLabel.textColor = [UIColor whiteColor];
    userLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    userLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [container addSubview:userLabel];

    // Like button
    UIButton *likeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    NSString *likeIcon = video.liked ? @"❤️" : @"🤍";
    [likeBtn setTitle:likeIcon forState:UIControlStateNormal];
    [likeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    likeBtn.titleLabel.font = [UIFont systemFontOfSize:28];
    likeBtn.translatesAutoresizingMaskIntoConstraints = NO;
    likeBtn.tag = i;
    [likeBtn addTarget:self action:@selector(likeTapped:) forControlEvents:UIControlEventTouchUpInside];
    [container addSubview:likeBtn];

    // Like count
    UILabel *likeCount = [[UILabel alloc] init];
    likeCount.text = [self formatCount:video.likesCount];
    likeCount.textColor = [UIColor whiteColor];
    likeCount.font = [UIFont systemFontOfSize:12];
    likeCount.textAlignment = NSTextAlignmentCenter;
    likeCount.translatesAutoresizingMaskIntoConstraints = NO;
    likeCount.tag = 100;
    [container addSubview:likeCount];

    // Comment button
    UIButton *commentBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [commentBtn setTitle:@"💬" forState:UIControlStateNormal];
    [commentBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    commentBtn.titleLabel.font = [UIFont systemFontOfSize:28];
    commentBtn.translatesAutoresizingMaskIntoConstraints = NO;
    commentBtn.tag = i;
    [commentBtn addTarget:self action:@selector(commentTapped:) forControlEvents:UIControlEventTouchUpInside];
    [container addSubview:commentBtn];

    // Comment count
    UILabel *commentCount = [[UILabel alloc] init];
    commentCount.text = [self formatCount:video.commentsCount];
    commentCount.textColor = [UIColor whiteColor];
    commentCount.font = [UIFont systemFontOfSize:12];
    commentCount.textAlignment = NSTextAlignmentCenter;
    commentCount.translatesAutoresizingMaskIntoConstraints = NO;
    commentCount.tag = 101;
    [container addSubview:commentCount];

    // Constraints for right-side buttons
    [likeBtn.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-16].active = YES;
    [likeBtn.centerYAnchor constraintEqualToAnchor:container.centerYAnchor constant:-40].active = YES;

    [likeCount.centerXAnchor constraintEqualToAnchor:likeBtn.centerXAnchor].active = YES;
    [likeCount.topAnchor constraintEqualToAnchor:likeBtn.bottomAnchor constant:4].active = YES;

    [commentBtn.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-16].active = YES;
    [commentBtn.topAnchor constraintEqualToAnchor:likeCount.bottomAnchor constant:24].active = YES;

    [commentCount.centerXAnchor constraintEqualToAnchor:commentBtn.centerXAnchor].active = YES;
    [commentCount.topAnchor constraintEqualToAnchor:commentBtn.bottomAnchor constant:4].active = YES;

    // Bottom labels
    [userLabel.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:16].active = YES;
    [userLabel.bottomAnchor constraintEqualToAnchor:container.bottomAnchor constant:-80].active = YES;

    [captionLabel.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:16].active = YES;
    [captionLabel.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-60].active = YES;
    [captionLabel.topAnchor constraintEqualToAnchor:userLabel.bottomAnchor constant:4].active = YES;

    // Tap gesture for pause/play
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(videoTapped:)];
    [container addGestureRecognizer:tap];

    // Double tap for like
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(videoDoubleTapped:)];
    doubleTap.numberOfTapsRequired = 2;
    [container addGestureRecognizer:doubleTap];
    [tap requireGestureRecognizerToFail:doubleTap];

    [self.scrollView addSubview:container];

    // Setup player
    [self setupPlayerForVideo:video atIndex:i withLayer:playerLayer];
  }
}

- (void)setupPlayerForVideo:(Video *)video atIndex:(NSInteger)index withLayer:(AVPlayerLayer *)playerLayer {
  NSString *baseURL = [APIClient sharedClient].baseURL;
  NSString *baseAPI = [baseURL stringByReplacingOccurrencesOfString:@"/api" withString:@""];
  NSString *fullURL = [NSString stringWithFormat:@"%@%@", baseAPI, video.videoUrl];
  NSURL *url = [NSURL URLWithString:fullURL];

  AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
  AVPlayer *player = [AVPlayer playerWithPlayerItem:item];
  playerLayer.player = player;

  self.playerItems[@(index)] = item;
  self.playerLayers[@(index)] = player;

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:item];
}

- (void)videoFinished:(NSNotification *)notification {
  AVPlayerItem *item = notification.object;
  [item seekToTime:kCMTimeZero];
  // Find which player this belongs to and replay
  for (NSNumber *key in self.playerItems.allKeys) {
    if (self.playerItems[key] == item) {
      AVPlayer *player = self.playerLayers[key];
      [player play];
      break;
    }
  }
}

- (void)playVideoAtIndex:(NSInteger)index {
  if (index < 0 || index >= self.videos.count) return;

  // Pause all
  for (NSNumber *key in self.playerLayers.allKeys) {
    AVPlayer *player = self.playerLayers[key];
    [player pause];
  }

  // Play current
  AVPlayer *player = self.playerLayers[@(index)];
  if (player) {
    [player play];
    self.isPlaying = YES;
  }
  self.currentIndex = index;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
  NSInteger index = (NSInteger)(scrollView.contentOffset.y / scrollView.bounds.size.height);
  if (index >= 0 && index < self.videos.count) {
    [self playVideoAtIndex:index];
  }

  // Load more if near the end
  if (index >= self.videos.count - 3 && !self.isLoadingMore) {
    self.currentPage++;
    [self loadFeedWithPage:self.currentPage];
  }
}

- (void)videoTapped:(UITapGestureRecognizer *)tap {
  NSInteger index = tap.view.tag;
  AVPlayer *player = self.playerLayers[@(index)];
  if (player) {
    if (player.rate > 0) {
      [player pause];
      self.isPlaying = NO;
    } else {
      [player play];
      self.isPlaying = YES;
    }
  }
}

- (void)videoDoubleTapped:(UITapGestureRecognizer *)tap {
  NSInteger index = tap.view.tag;
  if (index < self.videos.count) {
    Video *video = self.videos[index];

    // Show heart animation
    UILabel *heart = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
    heart.text = @"❤️";
    heart.font = [UIFont systemFontOfSize:60];
    heart.textAlignment = NSTextAlignmentCenter;
    heart.center = CGPointMake(tap.view.bounds.size.width / 2, tap.view.bounds.size.height / 2);
    heart.alpha = 0;
    heart.transform = CGAffineTransformMakeScale(0.3, 0.3);
    [tap.view addSubview:heart];

    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
      heart.alpha = 1;
      heart.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
      [UIView animateWithDuration:0.3 delay:0.5 options:UIViewAnimationOptionCurveEaseIn animations:^{
        heart.alpha = 0;
        heart.transform = CGAffineTransformMakeScale(1.5, 1.5);
      } completion:^(BOOL finished2) {
        [heart removeFromSuperview];
      }];
    }];

    // API call if not already liked
    if (!video.liked) {
      video.liked = YES;
      video.likesCount++;
      [self updateLikeButtonForIndex:index];

      [[APIClient sharedClient] likeVideoWithId:video.videoId success:^(id resp) {
        if ([resp isKindOfClass:[NSDictionary class]]) {
          video.likesCount = [resp[@"likesCount"] integerValue];
          [self updateLikeButtonForIndex:index];
        }
      } failure:nil];
    }
  }
}

- (void)likeTapped:(UIButton *)sender {
  NSInteger index = sender.tag;
  if (index >= self.videos.count) return;
  Video *video = self.videos[index];

  video.liked = !video.liked;
  video.likesCount += video.liked ? 1 : -1;
  [self updateLikeButtonForIndex:index];

  if (video.liked) {
    [[APIClient sharedClient] likeVideoWithId:video.videoId success:nil failure:^(NSError *err) {
      video.liked = NO;
      video.likesCount--;
      [self updateLikeButtonForIndex:index];
    }];
  } else {
    [[APIClient sharedClient] unlikeVideoWithId:video.videoId success:nil failure:^(NSError *err) {
      video.liked = YES;
      video.likesCount++;
      [self updateLikeButtonForIndex:index];
    }];
  }
}

- (void)updateLikeButtonForIndex:(NSInteger)index {
  if (index >= self.videos.count) return;
  Video *video = self.videos[index];
  UIView *container = self.scrollView.subviews[index];
  for (UIView *sub in container.subviews) {
    if ([sub isKindOfClass:[UIButton class]] && [[(UIButton *)sub titleForState:UIControlStateNormal] isEqual:@"❤️"] || [[(UIButton *)sub titleForState:UIControlStateNormal] isEqual:@"🤍"]) {
      [(UIButton *)sub setTitle:video.liked ? @"❤️" : @"🤍" forState:UIControlStateNormal];
    }
    if ([sub isKindOfClass:[UILabel class]] && sub.tag == 100) {
      [(UILabel *)sub setText:[self formatCount:video.likesCount]];
    }
  }
}

- (void)commentTapped:(UIButton *)sender {
  NSInteger index = sender.tag;
  if (index >= self.videos.count) return;
  Video *video = self.videos[index];

  VideoDetailViewController *vc = [[VideoDetailViewController alloc] init];
  vc.video = video;
  [self.navigationController pushViewController:vc animated:YES];
}

- (NSString *)formatCount:(NSInteger)count {
  if (count < 1000) return [NSString stringWithFormat:@"%ld", (long)count];
  if (count < 1000000) return [NSString stringWithFormat:@"%.1fK", count / 1000.0];
  return [NSString stringWithFormat:@"%.1fM", count / 1000000.0];
}

- (void)appDidEnterBackground {
  AVPlayer *player = self.playerLayers[@(self.currentIndex)];
  [player pause];
}

- (void)appWillEnterForeground {
  AVPlayer *player = self.playerLayers[@(self.currentIndex)];
  [player play];
}

- (BOOL)prefersStatusBarHidden {
  return YES;
}

@end
