#import <Foundation/Foundation.h>
#import "User.h"
#import "Video.h"
#import "Comment.h"

typedef void (^APISuccess)(id _Nullable response);
typedef void (^APIFailure)(NSError *error);

@interface APIClient : NSObject

@property (nonatomic, strong) NSString *baseURL;
@property (nonatomic, strong) NSString *token;

+ (instancetype)sharedClient;

- (void)setToken:(NSString *)token;
- (void)clearToken;

// Auth
- (void)signupWithUsername:(NSString *)username password:(NSString *)password displayName:(NSString *)displayName success:(APISuccess)success failure:(APIFailure)failure;
- (void)loginWithUsername:(NSString *)username password:(NSString *)password success:(APISuccess)success failure:(APIFailure)failure;
- (void)getCurrentUserWithSuccess:(APISuccess)success failure:(APIFailure)failure;

// Videos
- (void)getFeedWithPage:(NSInteger)page limit:(NSInteger)limit success:(APISuccess)success failure:(APIFailure)failure;
- (void)getVideoWithId:(NSString *)videoId success:(APISuccess)success failure:(APIFailure)failure;
- (void)uploadVideoWithData:(NSData *)videoData caption:(NSString *)caption progress:(void (^)(float))progress success:(APISuccess)success failure:(APIFailure)failure;
- (void)likeVideoWithId:(NSString *)videoId success:(APISuccess)success failure:(APIFailure)failure;
- (void)unlikeVideoWithId:(NSString *)videoId success:(APISuccess)success failure:(APIFailure)failure;
- (void)deleteVideoWithId:(NSString *)videoId success:(APISuccess)success failure:(APIFailure)failure;

// Comments
- (void)getCommentsForVideo:(NSString *)videoId success:(APISuccess)success failure:(APIFailure)failure;
- (void)postComment:(NSString *)text forVideo:(NSString *)videoId success:(APISuccess)success failure:(APIFailure)failure;

// Users
- (void)getUserWithId:(NSString *)userId success:(APISuccess)success failure:(APIFailure)failure;
- (void)getUserVideos:(NSString *)userId page:(NSInteger)page limit:(NSInteger)limit success:(APISuccess)success failure:(APIFailure)failure;
- (void)followUser:(NSString *)userId success:(APISuccess)success failure:(APIFailure)failure;
- (void)unfollowUser:(NSString *)userId success:(APISuccess)success failure:(APIFailure)failure;
- (void)updateProfileWithDisplayName:(NSString *)displayName bio:(NSString *)bio success:(APISuccess)success failure:(APIFailure)failure;
- (void)searchUsers:(NSString *)query success:(APISuccess)success failure:(APIFailure)failure;

@end
