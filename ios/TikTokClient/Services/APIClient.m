#import "APIClient.h"

#define DEFAULT_BASE_URL @"http://localhost:3000/api"

@implementation APIClient

+ (instancetype)sharedClient {
  static APIClient *shared = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    shared = [[APIClient alloc] init];
    shared.baseURL = [[NSUserDefaults standardUserDefaults] stringForKey:@"server_url"] ?: DEFAULT_BASE_URL;
    shared.token = [[NSUserDefaults standardUserDefaults] stringForKey:@"auth_token"];
  });
  return shared;
}

- (void)setToken:(NSString *)token {
  _token = token;
  [[NSUserDefaults standardUserDefaults] setObject:token forKey:@"auth_token"];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)clearToken {
  _token = nil;
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"auth_token"];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Auth

- (void)signupWithUsername:(NSString *)username password:(NSString *)password displayName:(NSString *)displayName success:(APISuccess)success failure:(APIFailure)failure {
  NSDictionary *body = @{@"username": username, @"password": password};
  if (displayName) {
    NSMutableDictionary *m = [NSMutableDictionary dictionaryWithDictionary:body];
    m[@"displayName"] = displayName;
    body = m;
  }
  [self POST:@"/auth/signup" body:body success:success failure:failure];
}

- (void)loginWithUsername:(NSString *)username password:(NSString *)password success:(APISuccess)success failure:(APIFailure)failure {
  [self POST:@"/auth/login" body:@{@"username": username, @"password": password} success:success failure:failure];
}

- (void)getCurrentUserWithSuccess:(APISuccess)success failure:(APIFailure)failure {
  [self GET:@"/auth/me" success:success failure:failure];
}

#pragma mark - Videos

- (void)getFeedWithPage:(NSInteger)page limit:(NSInteger)limit success:(APISuccess)success failure:(APIFailure)failure {
  NSString *path = [NSString stringWithFormat:@"/videos/feed?page=%ld&limit=%ld", (long)page, (long)limit];
  [self GET:path success:success failure:failure];
}

- (void)getVideoWithId:(NSString *)videoId success:(APISuccess)success failure:(APIFailure)failure {
  NSString *path = [NSString stringWithFormat:@"/videos/%@", videoId];
  [self GET:path success:success failure:failure];
}

- (void)uploadVideoWithData:(NSData *)videoData caption:(NSString *)caption progress:(void (^)(float))progress success:(APISuccess)success failure:(APIFailure)failure {
  NSString *urlStr = [NSString stringWithFormat:@"%@/videos/upload", self.baseURL];
  NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
  req.HTTPMethod = @"POST";
  if (self.token) {
    [req setValue:[NSString stringWithFormat:@"Bearer %@", self.token] forHTTPHeaderField:@"Authorization"];
  }

  NSString *boundary = [NSString stringWithFormat:@"Boundary-%@", [[NSUUID UUID] UUIDString]];
  NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
  [req setValue:contentType forHTTPHeaderField:@"Content-Type"];

  NSMutableData *body = [NSMutableData data];
  [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
  [body appendData:[@"Content-Disposition: form-data; name=\"video\"; filename=\"video.mp4\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
  [body appendData:[@"Content-Type: video/mp4\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
  [body appendData:videoData];
  [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
  [body appendData:[@"Content-Disposition: form-data; name=\"caption\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
  [body appendData:[[caption ?: @"" stringByAppendingFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];

  req.HTTPBody = body;

  [[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (error) { failure(error); return; }
      NSError *jsonErr;
      id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonErr];
      if (jsonErr) { failure(jsonErr); return; }
      NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
      if (httpResp.statusCode >= 400) {
        failure([NSError errorWithDomain:@"APIError" code:httpResp.statusCode userInfo:@{NSLocalizedDescriptionKey: [json objectForKey:@"error"] ?: @"Upload failed"}]);
        return;
      }
      success(json);
    });
  }] resume];
}

- (void)likeVideoWithId:(NSString *)videoId success:(APISuccess)success failure:(APIFailure)failure {
  NSString *path = [NSString stringWithFormat:@"/videos/%@/like", videoId];
  [self POST:path body:nil success:success failure:failure];
}

- (void)unlikeVideoWithId:(NSString *)videoId success:(APISuccess)success failure:(APIFailure)failure {
  NSString *path = [NSString stringWithFormat:@"/videos/%@/unlike", videoId];
  [self POST:path body:nil success:success failure:failure];
}

- (void)deleteVideoWithId:(NSString *)videoId success:(APISuccess)success failure:(APIFailure)failure {
  NSString *path = [NSString stringWithFormat:@"/videos/%@", videoId];
  [self DELETE:path success:success failure:failure];
}

#pragma mark - Comments

- (void)getCommentsForVideo:(NSString *)videoId success:(APISuccess)success failure:(APIFailure)failure {
  NSString *path = [NSString stringWithFormat:@"/videos/%@/comments", videoId];
  [self GET:path success:success failure:failure];
}

- (void)postComment:(NSString *)text forVideo:(NSString *)videoId success:(APISuccess)success failure:(APIFailure)failure {
  NSString *path = [NSString stringWithFormat:@"/videos/%@/comments", videoId];
  [self POST:path body:@{@"text": text} success:success failure:failure];
}

#pragma mark - Users

- (void)getUserWithId:(NSString *)userId success:(APISuccess)success failure:(APIFailure)failure {
  NSString *path = [NSString stringWithFormat:@"/users/%@", userId];
  [self GET:path success:success failure:failure];
}

- (void)getUserVideos:(NSString *)userId page:(NSInteger)page limit:(NSInteger)limit success:(APISuccess)success failure:(APIFailure)failure {
  NSString *path = [NSString stringWithFormat:@"/users/%@/videos?page=%ld&limit=%ld", userId, (long)page, (long)limit];
  [self GET:path success:success failure:failure];
}

- (void)followUser:(NSString *)userId success:(APISuccess)success failure:(APIFailure)failure {
  NSString *path = [NSString stringWithFormat:@"/users/follow/%@", userId];
  [self POST:path body:nil success:success failure:failure];
}

- (void)unfollowUser:(NSString *)userId success:(APISuccess)success failure:(APIFailure)failure {
  NSString *path = [NSString stringWithFormat:@"/users/unfollow/%@", userId];
  [self POST:path body:nil success:success failure:failure];
}

- (void)updateProfileWithDisplayName:(NSString *)displayName bio:(NSString *)bio success:(APISuccess)success failure:(APIFailure)failure {
  NSMutableDictionary *body = [NSMutableDictionary dictionary];
  if (displayName) body[@"displayName"] = displayName;
  if (bio) body[@"bio"] = bio;
  [self PUT:@"/users/profile" body:body success:success failure:failure];
}

- (void)searchUsers:(NSString *)query success:(APISuccess)success failure:(APIFailure)failure {
  NSString *encoded = [query stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
  NSString *path = [NSString stringWithFormat:@"/users/search/%@", encoded];
  [self GET:path success:success failure:failure];
}

#pragma mark - HTTP Methods

- (void)GET:(NSString *)path success:(APISuccess)success failure:(APIFailure)failure {
  NSString *urlStr = [NSString stringWithFormat:@"%@%@", self.baseURL, path];
  NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
  req.HTTPMethod = @"GET";
  [self addAuthHeader:req];
  [self sendRequest:req success:success failure:failure];
}

- (void)POST:(NSString *)path body:(NSDictionary *)body success:(APISuccess)success failure:(APIFailure)failure {
  NSString *urlStr = [NSString stringWithFormat:@"%@%@", self.baseURL, path];
  NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
  req.HTTPMethod = @"POST";
  [self addAuthHeader:req];
  if (body) {
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    req.HTTPBody = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
  }
  [self sendRequest:req success:success failure:failure];
}

- (void)PUT:(NSString *)path body:(NSDictionary *)body success:(APISuccess)success failure:(APIFailure)failure {
  NSString *urlStr = [NSString stringWithFormat:@"%@%@", self.baseURL, path];
  NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
  req.HTTPMethod = @"PUT";
  [self addAuthHeader:req];
  if (body) {
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    req.HTTPBody = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
  }
  [self sendRequest:req success:success failure:failure];
}

- (void)DELETE:(NSString *)path success:(APISuccess)success failure:(APIFailure)failure {
  NSString *urlStr = [NSString stringWithFormat:@"%@%@", self.baseURL, path];
  NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
  req.HTTPMethod = @"DELETE";
  [self addAuthHeader:req];
  [self sendRequest:req success:success failure:failure];
}

- (void)addAuthHeader:(NSMutableURLRequest *)req {
  if (self.token) {
    [req setValue:[NSString stringWithFormat:@"Bearer %@", self.token] forHTTPHeaderField:@"Authorization"];
  }
}

- (void)sendRequest:(NSURLRequest *)req success:(APISuccess)success failure:(APIFailure)failure {
  [[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (error) { failure(error); return; }
      NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
      NSError *jsonErr;
      id json = nil;
      if (data.length > 0) {
        json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonErr];
      }
      if (httpResp.statusCode >= 400) {
        NSString *msg = [json objectForKey:@"error"] ?: @"Unknown error";
        failure([NSError errorWithDomain:@"APIError" code:httpResp.statusCode userInfo:@{NSLocalizedDescriptionKey: msg}]);
        return;
      }
      success(json);
    });
  }] resume];
}

@end
