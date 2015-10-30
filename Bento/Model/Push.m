//
//  Push.m
//  Bento
//
//  Created by Joseph Lau on 10/28/15.
//  Copyright © 2015 bentonow. All rights reserved.
//

#import "Push.h"

@implementation Push

- (id)initWith:(NSDictionary *)json {
    self = [super init];
    if (self) {
        self.rid = json[@"rid"];
        self.from = json[@"from"];
        self.to = json[@"to"];
        self.subject = json[@"subject"];
        self.body = json[@"body"];
    }
    return self;
}

@end
