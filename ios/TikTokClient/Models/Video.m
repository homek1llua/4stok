#import "Video.h"

@implementation Video

- (instancetype)initWithDictionary:(NSDictionary *)dict {
  self = [super init];
  if (self) {
    _videoId = dict[@"id"] ?: @"";
    _caption = dict[@"caption"] ?: @"";
    _videoUrl = dict[@"videoUrl"] ?: @"";
    _thumbnail = dict[@"thumbnail"] ?: @"";
    _width = [dict[@"width"] integerValue];
    _height = [dict[@"height"] integerValue];
    _duration = [dict[@"duration"] doubleValue];
    _likesCount = [dict[@"likesCount"] integerValue];
    _commentsCount = [dict[@"commentsCount"] integerValue];
    _liked = [dict[@"liked"] boolValue];
    _createdAt = dict[@"createdAt"] ?: @"";
    if (dict[@"user"]) {
      _user = [[User alloc] initWithDictionary:dict[@"user"]];
    }
  }
  return self;
}

@end
