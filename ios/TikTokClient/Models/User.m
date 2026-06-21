#import "User.h"

static User *_currentUser = nil;

@implementation User

- (instancetype)initWithDictionary:(NSDictionary *)dict {
  self = [super init];
  if (self) {
    _userId = dict[@"id"] ?: @"";
    _username = dict[@"username"] ?: @"";
    _displayName = dict[@"displayName"] ?: _username;
    _bio = dict[@"bio"] ?: @"";
    _avatar = dict[@"avatar"] ?: @"";
    _videoCount = [dict[@"videoCount"] integerValue];
    _followerCount = [dict[@"followerCount"] integerValue];
    _followingCount = [dict[@"followingCount"] integerValue];
    _isFollowing = [dict[@"isFollowing"] boolValue];
  }
  return self;
}

+ (User *)currentUser {
  return _currentUser;
}

+ (void)setCurrentUser:(User *)user {
  _currentUser = user;
}

@end
