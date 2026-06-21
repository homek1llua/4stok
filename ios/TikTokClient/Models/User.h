#import <Foundation/Foundation.h>

@interface User : NSObject

@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) NSString *bio;
@property (nonatomic, strong) NSString *avatar;
@property (nonatomic, assign) NSInteger videoCount;
@property (nonatomic, assign) NSInteger followerCount;
@property (nonatomic, assign) NSInteger followingCount;
@property (nonatomic, assign) BOOL isFollowing;

- (instancetype)initWithDictionary:(NSDictionary *)dict;
+ (User *)currentUser;
+ (void)setCurrentUser:(User *)user;

@end
