#import "VideoDetailViewController.h"
#import "APIClient.h"
#import "Comment.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

@interface VideoDetailViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong) UIView *videoContainer;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *commentInputView;
@property (nonatomic, strong) UITextField *commentField;
@property (nonatomic, strong) UIButton *sendButton;
@property (nonatomic, strong) NSMutableArray<Comment *> *comments;
@property (nonatomic, strong) UILabel *captionLabel;
@property (nonatomic, strong) UIButton *likeButton;
@property (nonatomic, strong) UILabel *likeCountLabel;

@end

@implementation VideoDetailViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor blackColor];
  self.comments = [NSMutableArray array];

  [self setupVideo];
  [self setupUI];
  [self loadComments];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupVideo {
  NSString *baseURL = [APIClient sharedClient].baseURL;
  NSString *baseAPI = [baseURL stringByReplacingOccurrencesOfString:@"/api" withString:@""];
  NSString *fullURL = [NSString stringWithFormat:@"%@%@", baseAPI, self.video.videoUrl];

  self.player = [AVPlayer playerWithURL:[NSURL URLWithString:fullURL]];
  self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
  [self.player play];
}

- (void)setupUI {
  CGFloat videoHeight = self.view.bounds.size.width * (9.0 / 16.0);

  self.videoContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 64, self.view.bounds.size.width, videoHeight)];
  self.videoContainer.backgroundColor = [UIColor blackColor];
  self.playerLayer.frame = self.videoContainer.bounds;
  self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
  [self.videoContainer.layer addSublayer:self.playerLayer];
  [self.view addSubview:self.videoContainer];

  // Caption
  self.captionLabel = [[UILabel alloc] init];
  self.captionLabel.text = [NSString stringWithFormat:@"@%@ %@", self.video.user.username, self.video.caption];
  self.captionLabel.textColor = [UIColor whiteColor];
  self.captionLabel.font = [UIFont systemFontOfSize:14];
  self.captionLabel.numberOfLines = 2;
  self.captionLabel.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:self.captionLabel];

  // Like button
  self.likeButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [self.likeButton setTitle:self.video.liked ? @"❤️" : @"🤍" forState:UIControlStateNormal];
  [self.likeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  self.likeButton.titleLabel.font = [UIFont systemFontOfSize:22];
  self.likeButton.translatesAutoresizingMaskIntoConstraints = NO;
  [self.likeButton addTarget:self action:@selector(likeTapped) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:self.likeButton];

  self.likeCountLabel = [[UILabel alloc] init];
  self.likeCountLabel.text = [self formatCount:self.video.likesCount];
  self.likeCountLabel.textColor = [UIColor whiteColor];
  self.likeCountLabel.font = [UIFont systemFontOfSize:12];
  self.likeCountLabel.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:self.likeCountLabel];

  // Comments table
  self.tableView = [[UITableView alloc] init];
  self.tableView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1];
  self.tableView.dataSource = self;
  self.tableView.delegate = self;
  self.tableView.separatorColor = [UIColor colorWithWhite:0.2 alpha:1];
  self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"CommentCell"];
  [self.view addSubview:self.tableView];

  // Comment input
  self.commentInputView = [[UIView alloc] init];
  self.commentInputView.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1];
  self.commentInputView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:self.commentInputView];

  self.commentField = [[UITextField alloc] init];
  self.commentField.placeholder = @"Add a comment...";
  self.commentField.textColor = [UIColor whiteColor];
  self.commentField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Add a comment..." attributes:@{NSForegroundColorAttributeName: [UIColor grayColor]}];
  self.commentField.delegate = self;
  self.commentField.translatesAutoresizingMaskIntoConstraints = NO;
  [self.commentInputView addSubview:self.commentField];

  self.sendButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [self.sendButton setTitle:@"Send" forState:UIControlStateNormal];
  [self.sendButton setTitleColor:[UIColor colorWithRed:1 green:0.22 blue:0.42 alpha:1] forState:UIControlStateNormal];
  self.sendButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
  self.sendButton.translatesAutoresizingMaskIntoConstraints = NO;
  [self.sendButton addTarget:self action:@selector(sendComment) forControlEvents:UIControlEventTouchUpInside];
  [self.commentInputView addSubview:self.sendButton];

  // Layout
  [self.captionLabel.topAnchor constraintEqualToAnchor:self.videoContainer.bottomAnchor constant:8].active = YES;
  [self.captionLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16].active = YES;
  [self.captionLabel.trailingAnchor constraintEqualToAnchor:self.likeButton.leadingAnchor constant:-8].active = YES;

  [self.likeButton.topAnchor constraintEqualToAnchor:self.videoContainer.bottomAnchor constant:8].active = YES;
  [self.likeButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16].active = YES;

  [self.likeCountLabel.centerXAnchor constraintEqualToAnchor:self.likeButton.centerXAnchor].active = YES;
  [self.likeCountLabel.topAnchor constraintEqualToAnchor:self.likeButton.bottomAnchor constant:2].active = YES;

  [self.tableView.topAnchor constraintEqualToAnchor:self.captionLabel.bottomAnchor constant:8].active = YES;
  [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
  [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
  [self.tableView.bottomAnchor constraintEqualToAnchor:self.commentInputView.topAnchor].active = YES;

  [self.commentInputView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
  [self.commentInputView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
  [self.commentInputView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
  [self.commentInputView.heightAnchor constraintEqualToConstant:50].active = YES;

  [self.commentField.leadingAnchor constraintEqualToAnchor:self.commentInputView.leadingAnchor constant:16].active = YES;
  [self.commentField.centerYAnchor constraintEqualToAnchor:self.commentInputView.centerYAnchor].active = YES;
  [self.commentField.trailingAnchor constraintEqualToAnchor:self.sendButton.leadingAnchor constant:-8].active = YES;

  [self.sendButton.trailingAnchor constraintEqualToAnchor:self.commentInputView.trailingAnchor constant:-16].active = YES;
  [self.sendButton.centerYAnchor constraintEqualToAnchor:self.commentInputView.centerYAnchor].active = YES;
}

- (void)loadComments {
  [[APIClient sharedClient] getCommentsForVideo:self.video.videoId success:^(id response) {
    if ([response isKindOfClass:[NSArray class]]) {
      [self.comments removeAllObjects];
      for (NSDictionary *dict in response) {
        Comment *c = [[Comment alloc] initWithDictionary:dict];
        [self.comments addObject:c];
      }
      [self.tableView reloadData];
    }
  } failure:^(NSError *error) {
    NSLog(@"Failed to load comments: %@", error.localizedDescription);
  }];
}

- (void)likeTapped {
  self.video.liked = !self.video.liked;
  self.video.likesCount += self.video.liked ? 1 : -1;
  [self.likeButton setTitle:self.video.liked ? @"❤️" : @"🤍" forState:UIControlStateNormal];
  self.likeCountLabel.text = [self formatCount:self.video.likesCount];

  if (self.video.liked) {
    [[APIClient sharedClient] likeVideoWithId:self.video.videoId success:nil failure:nil];
  } else {
    [[APIClient sharedClient] unlikeVideoWithId:self.video.videoId success:nil failure:nil];
  }
}

- (void)sendComment {
  NSString *text = self.commentField.text;
  if (!text || text.length == 0) return;

  self.commentField.text = @"";
  [self.commentField resignFirstResponder];

  [[APIClient sharedClient] postComment:text forVideo:self.video.videoId success:^(id response) {
    Comment *c = [[Comment alloc] initWithDictionary:response];
    [self.comments insertObject:c atIndex:0];
    [self.tableView reloadData];
    self.video.commentsCount++;
  } failure:^(NSError *error) {
    NSLog(@"Comment failed: %@", error.localizedDescription);
  }];
}

#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.comments.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CommentCell" forIndexPath:indexPath];
  Comment *c = self.comments[indexPath.row];
  cell.backgroundColor = [UIColor clearColor];
  cell.textLabel.textColor = [UIColor whiteColor];
  cell.textLabel.font = [UIFont systemFontOfSize:13];
  cell.textLabel.numberOfLines = 0;
  cell.textLabel.text = [NSString stringWithFormat:@"@%@: %@", c.user.username, c.text];
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 44;
}

#pragma mark - Keyboard

- (void)keyboardWillShow:(NSNotification *)notification {
  CGRect rect = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
  NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
  [UIView animateWithDuration:duration animations:^{
    self.commentInputView.transform = CGAffineTransformMakeTranslation(0, -rect.size.height);
  }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
  NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
  [UIView animateWithDuration:duration animations:^{
    self.commentInputView.transform = CGAffineTransformIdentity;
  }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [self sendComment];
  return YES;
}

- (NSString *)formatCount:(NSInteger)count {
  if (count < 1000) return [NSString stringWithFormat:@"%ld", (long)count];
  if (count < 1000000) return [NSString stringWithFormat:@"%.1fK", count / 1000.0];
  return [NSString stringWithFormat:@"%.1fM", count / 1000000.0];
}

@end
