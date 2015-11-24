//
//  Addon.m
//  Bento
//
//  Created by Joseph Lau on 11/17/15.
//  Copyright © 2015 bentonow. All rights reserved.
//

#import "Addon.h"

@implementation Addon

- (id)initWithDictionary:(NSDictionary *)dictionary {
    
    if (self = [super init]) {

        self.itemId = [dictionary[@"id"] integerValue];
        self.qty = 0;
        self.unitPrice = [dictionary[@"unit_price"] floatValue];
    }
    
    return self;
}

- (void)addOneCount {
    self.qty += 1;
}

- (void)removeOneCount {
    if (self.qty > 0) {
        self.qty -= 1;
    }
}

@end
