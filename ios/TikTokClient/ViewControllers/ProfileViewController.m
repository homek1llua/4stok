#import "ProfileViewController.h"
#import "APIClient.h"
#import "User.h"
#import "Video.h"
#import "VideoDetailViewController.h"
#import "AppDelegate.h"
#import "LoginViewController.h"

@interface ProfileViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *displayNameLabel;
@property (nonatomic, strong) UILabel *usernameLabel;
@property (nonatomic, strong) UILabel *bioLabel;
@property (nonatomic, strong) UILabel *statsLabel;
@property (nonatomic, strong) UIButton *followButton;
@property (nonatomic, strong) UIButton *editButton;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray<Video *> *videos;
@property (nonatomic, strong) User *profileUser;
@property (nonatomic, assign) BOOL isOwnProfile;

@end

@implementation ProfileViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor blackColor];
  self.videos = [NSMutableArray array];
  self.isOwnProfile = [self.userId isEqualToString:[User currentUser].userId] || !self.userId;

  if (self.isOwnProfile) {
    self.title = @"Profile";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Logout" style:UIBarButtonItemStylePlain target:self action:@selector(logout)];
  }

  [self setupUI];
  [self loadProfile];
}

- (void)setupUI {
  UIScrollView *scroll = [[UIScrollView alloc] init];
  scroll.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:scroll];

  [scroll.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
  [scroll.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
  [scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
  [scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;

  UIView *content = [[UIView alloc] init];
  content.translatesAutoresizingMaskIntoConstraints = NO;
  [scroll addSubview:content];

  [content.topAnchor constraintEqualToAnchor:scroll.topAnchor].active = YES;
  [content.bottomAnchor constraintEqualToAnchor:scroll.bottomAnchor].active = YES;
  [content.leadingAnchor constraintEqualToAnchor:scroll.leadingAnchor].active = YES;
  [content.trailingAnchor constraintEqualToAnchor:scroll.trailingAnchor].active = YES;
  [content.widthAnchor constraintEqualToAnchor:self.view.widthAnchor].active = YES;

  self.avatarView = [[UIImageView alloc] init];
  self.avatarView.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1];
  self.avatarView.layer.cornerRadius = 40;
  self.avatarView.clipsToBounds = YES;
  self.avatarView.contentMode = UIViewContentModeScaleAspectFill;
  self.avatarView.translatesAutoresizingMaskIntoConstraints = NO;
  [content addSubview:self.avatarView];

  self.displayNameLabel = [[UILabel alloc] init];
  self.displayNameLabel.textColor = [UIColor whiteColor];
  self.displayNameLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
  self.displayNameLabel.textAlignment = NSTextAlignmentCenter;
  self.displayNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
  [content addSubview:self.displayNameLabel];

  self.usernameLabel = [[UILabel alloc] init];
  self.usernameLabel.textColor = [UIColor grayColor];
  self.usernameLabel.font = [UIFont systemFontOfSize:14];
  self.usernameLabel.textAlignment = NSTextAlignmentCenter;
  self.usernameLabel.translatesAutoresizingMaskIntoConstraints = NO;
  [content addSubview:self.usernameLabel];

  self.bioLabel = [[UILabel alloc] init];
  self.bioLabel.textColor = [UIColor lightGrayColor];
  self.bioLabel.font = [UIFont systemFontOfSize:13];
  self.bioLabel.textAlignment = NSTextAlignmentCenter;
  self.bioLabel.numberOfLines = 3;
  self.bioLabel.translatesAutoresizingMaskIntoConstraints = NO;
  [content addSubview:self.bioLabel];

  self.statsLabel = [[UILabel alloc] init];
  self.statsLabel.textColor = [UIColor whiteColor];
  self.statsLabel.font = [UIFont systemFontOfSize:14];
  self.statsLabel.textAlignment = NSTextAlignmentCenter;
  self.statsLabel.translatesAutoresizingMaskIntoConstraints = NO;
  [content addSubview:self.statsLabel];

  self.followButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [self.followButton setTitle:@"Follow" forState:UIControlStateNormal];
  [self.followButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  self.followButton.backgroundColor = [UIColor colorWithRed:1 green:0.22 blue:0.42 alpha:1];
  self.followButton.layer.cornerRadius = 8;
  self.followButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
  self.followButton.translatesAutoresizingMaskIntoConstraints = NO;
  [self.followButton addTarget:self action:@selector(followTapped) forControlEvents:UIControlEventTouchUpInside];
  self.followButton.hidden = self.isOwnProfile;
  [content addSubview:self.followButton];

  self.editButton = [UIButton buttonWithType:UIButtonTypeSystem];
  [self.editButton setTitle:@"Edit Profile" forState:UIControlStateNormal];
  [self.editButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  self.editButton.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1];
  self.editButton.layer.cornerRadius = 8;
  self.editButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
  self.editButton.translatesAutoresizingMaskIntoConstraints = NO;
  [self.editButton addTarget:self action:@selector(editTapped) forControlEvents:UIControlEventTouchUpInside];
  self.editButton.hidden = !self.isOwnProfile;
  [content addSubview:self.editButton];

  // Video grid
  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  layout.minimumInteritemSpacing = 1;
  layout.minimumLineSpacing = 1;
  CGFloat itemWidth = (self.view.bounds.size.width - 2) / 3;
  layout.itemSize = CGSizeMake(itemWidth, itemWidth * 1.5);

  self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
  self.collectionView.backgroundColor = [UIColor blackColor];
  self.collectionView.dataSource = self;
  self.collectionView.delegate = self;
  self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"VideoCell"];
  [content addSubview:self.collectionView];

  // Layout constraints
  [self.avatarView.centerXAnchor constraintEqualToAnchor:content.centerXAnchor].active = YES;
  [self.avatarView.topAnchor constraintEqualToAnchor:content.topAnchor constant:20].active = YES;
  [self.avatarView.widthAnchor constraintEqualToConstant:80].active = YES;
  [self.avatarView.heightAnchor constraintEqualToConstant:80].active = YES;

  [self.displayNameLabel.centerXAnchor constraintEqualToAnchor:content.centerXAnchor].active = YES;
  [self.displayNameLabel.topAnchor constraintEqualToAnchor:self.avatarView.bottomAnchor constant:12].active = YES;

  [self.usernameLabel.centerXAnchor constraintEqualToAnchor:content.centerXAnchor].active = YES;
  [self.usernameLabel.topAnchor constraintEqualToAnchor:self.displayNameLabel.bottomAnchor constant:4].active = YES;

  [self.bioLabel.centerXAnchor constraintEqualToAnchor:content.centerXAnchor].active = YES;
  [self.bioLabel.topAnchor constraintEqualToAnchor:self.usernameLabel.bottomAnchor constant:8].active = YES;
  [self.bioLabel.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:40].active = YES;
  [self.bioLabel.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-40].active = YES;

  [self.statsLabel.centerXAnchor constraintEqualToAnchor:content.centerXAnchor].active = YES;
  [self.statsLabel.topAnchor constraintEqualToAnchor:self.bioLabel.bottomAnchor constant:12].active = YES;

  [self.followButton.centerXAnchor constraintEqualToAnchor:content.centerXAnchor].active = YES;
  [self.followButton.topAnchor constraintEqualToAnchor:self.statsLabel.bottomAnchor constant:12].active = YES;
  [self.followButton.widthAnchor constraintEqualToConstant:200].active = YES;
  [self.followButton.heightAnchor constraintEqualToConstant:40].active = YES;

  [self.editButton.centerXAnchor constraintEqualToAnchor:content.centerXAnchor].active = YES;
  [self.editButton.topAnchor constraintEqualToAnchor:self.statsLabel.bottomAnchor constant:12].active = YES;
  [self.editButton.widthAnchor constraintEqualToConstant:200].active = YES;
  [self.editButton.heightAnchor constraintEqualToConstant:40].active = YES;

  [self.collectionView.topAnchor constraintEqualToAnchor:self.followButton.bottomAnchor constant:16].active = YES;
  [self.collectionView.leadingAnchor constraintEqualToAnchor:content.leadingAnchor].active = YES;
  [self.collectionView.trailingAnchor constraintEqualToAnchor:content.trailingAnchor].active = YES;
  [self.collectionView.bottomAnchor constraintEqualToAnchor:content.bottomAnchor].active = YES;
  [self.collectionView.heightAnchor constraintEqualToConstant:500].active = YES;
}

- (void)loadProfile {
  NSString *uid = self.userId ?: [User currentUser].userId;
  [[APIClient sharedClient] getUserWithId:uid success:^(id response) {
    self.profileUser = [[User alloc] initWithDictionary:response];
    [self updateProfileUI];
  } failure:^(NSError *error) {
    NSLog(@"Profile load error: %@", error.localizedDescription);
  }];

  [[APIClient sharedClient] getUserVideos:uid page:1 limit:30 success:^(id response) {
    [self.videos removeAllObjects];
    for (NSDictionary *dict in response[@"videos"]) {
      [self.videos addObject:[[Video alloc] initWithDictionary:dict]];
    }
    [self.collectionView reloadData];
  } failure:nil];
}

- (void)updateProfileUI {
  User *u = self.profileUser;
  self.displayNameLabel.text = u.displayName;
  self.usernameLabel.text = [NSString stringWithFormat:@"@%@", u.username];
  self.bioLabel.text = u.bio;
  self.statsLabel.text = [NSString stringWithFormat:@"%ld videos  %ld followers  %ld following",
                          (long)u.videoCount, (long)u.followerCount, (long)u.followingCount];

  if (u.avatar.length > 0) {
    NSString *baseURL = [APIClient sharedClient].baseURL;
    NSString *baseAPI = [baseURL stringByReplacingOccurrencesOfString:@"/api" withString:@""];
    NSString *avatarURL = [NSString stringWithFormat:@"%@%@", baseAPI, u.avatar];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      NSData *imgData = [NSData dataWithContentsOfURL:[NSURL URLWithString:avatarURL]];
      dispatch_async(dispatch_get_main_queue(), ^{
        if (imgData) self.avatarView.image = [UIImage imageWithData:imgData];
      });
    });
  }

  if (!self.isOwnProfile) {
    NSString *title = u.isFollowing ? @"Following" : @"Follow";
    UIColor *bg = u.isFollowing ? [UIColor colorWithWhite:0.2 alpha:1] : [UIColor colorWithRed:1 green:0.22 blue:0.42 alpha:1];
    [self.followButton setTitle:title forState:UIControlStateNormal];
    self.followButton.backgroundColor = bg;
  }
}

- (void)followTapped {
  if (!self.profileUser) return;
  BOOL wasFollowing = self.profileUser.isFollowing;
  self.profileUser.isFollowing = !wasFollowing;

  [self.followButton setTitle:self.profileUser.isFollowing ? @"Following" : @"Follow" forState:UIControlStateNormal];
  self.followButton.backgroundColor = self.profileUser.isFollowing ? [UIColor colorWithWhite:0.2 alpha:1] : [UIColor colorWithRed:1 green:0.22 blue:0.42 alpha:1];

  if (self.profileUser.isFollowing) {
    [[APIClient sharedClient] followUser:self.profileUser.userId success:nil failure:^(NSError *err) {
      self.profileUser.isFollowing = NO;
      [self updateProfileUI];
    }];
  } else {
    [[APIClient sharedClient] unfollowUser:self.profileUser.userId success:nil failure:^(NSError *err) {
      self.profileUser.isFollowing = YES;
      [self updateProfileUI];
    }];
  }
}

- (void)editTapped {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Edit Profile" message:nil preferredStyle:UIAlertControllerStyleAlert];

  [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
    tf.text = [User currentUser].displayName;
    tf.placeholder = @"Display Name";
  }];
  [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
    tf.text = [User currentUser].bio;
    tf.placeholder = @"Bio";
  }];

  [alert addAction:[UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    NSString *name = alert.textFields[0].text;
    NSString *bio = alert.textFields[1].text;
    [[APIClient sharedClient] updateProfileWithDisplayName:name bio:bio success:^(id response) {
      User *u = [User currentUser];
      u.displayName = response[@"displayName"];
      u.bio = response[@"bio"];
      [self updateProfileUI];
    } failure:nil];
  }]];
  [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
  [self presentViewController:alert animated:YES completion:nil];
}

- (void)logout {
  [[APIClient sharedClient] clearToken];
  [User setCurrentUser:nil];
  AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
  [delegate showAuth];
}

#pragma mark - CollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  return self.videos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"VideoCell" forIndexPath:indexPath];
  cell.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1];

  Video *video = self.videos[indexPath.row];

  // Remove old image view
  for (UIView *v in cell.contentView.subviews) [v removeFromSuperview];

  UIImageView *iv = [[UIImageView alloc] initWithFrame:cell.contentView.bounds];
  iv.contentMode = UIViewContentModeScaleAspectFill;
  iv.clipsToBounds = YES;
  iv.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1];
  [cell.contentView addSubview:iv];

  if (video.thumbnail.length > 0) {
    NSString *baseURL = [APIClient sharedClient].baseURL;
    NSString *baseAPI = [baseURL stringByReplacingOccurrencesOfString:@"/api" withString:@""];
    NSString *thumbURL = [NSString stringWithFormat:@"%@%@", baseAPI, video.thumbnail];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
      NSData *imgData = [NSData dataWithContentsOfURL:[NSURL URLWithString:thumbURL]];
      dispatch_async(dispatch_get_main_queue(), ^{
        if (imgData) iv.image = [UIImage imageWithData:imgData];
      });
    });
  }

  // Play icon overlay
  UILabel *playIcon = [[UILabel alloc] init];
  playIcon.text = @"▶️";
  playIcon.font = [UIFont systemFontOfSize:20];
  playIcon.translatesAutoresizingMaskIntoConstraints = NO;
  [cell.contentView addSubview:playIcon];
  [playIcon.centerXAnchor constraintEqualToAnchor:cell.contentView.centerXAnchor].active = YES;
  [playIcon.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor].active = YES;

  return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  Video *video = self.videos[indexPath.row];
  VideoDetailViewController *vc = [[VideoDetailViewController alloc] init];
  vc.video = video;
  [self.navigationController pushViewController:vc animated:YES];
}

@end
