#import <Foundation/Foundation.h>
#import "User.h"

@interface Video : NSObject

@property (nonatomic, strong) NSString *videoId;
@property (nonatomic, strong) NSString *caption;
@property (nonatomic, strong) NSString *videoUrl;
@property (nonatomic, strong) NSString *thumbnail;
@property (nonatomic, assign) NSInteger width;
@property (nonatomic, assign) NSInteger height;
@property (nonatomic, assign) double duration;
@property (nonatomic, assign) NSInteger likesCount;
@property (nonatomic, assign) NSInteger commentsCount;
@property (nonatomic, assign) BOOL liked;
@property (nonatomic, strong) NSString *createdAt;
@property (nonatomic, strong) User *user;

- (instancetype)initWithDictionary:(NSDictionary *)dict;

@end
