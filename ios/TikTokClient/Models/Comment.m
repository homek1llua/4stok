#import "Comment.h"

@implementation Comment

- (instancetype)initWithDictionary:(NSDictionary *)dict {
  self = [super init];
  if (self) {
    _commentId = dict[@"id"] ?: @"";
    _text = dict[@"text"] ?: @"";
    _createdAt = dict[@"createdAt"] ?: @"";
    if (dict[@"user"]) {
      _user = [[User alloc] initWithDictionary:dict[@"user"]];
    }
  }
  return self;
}

@end
