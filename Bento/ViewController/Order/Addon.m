//
//  Addon.m
//  Bento
//
//  Created by Joseph Lau on 11/17/15.
//  Copyright © 2015 bentonow. All rights reserved.
//

#import "Addon.h"

@implementation Addon

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    if (self = [super init]) {

        self.type = dictionary[@"type"];
        self.name = dictionary[@"name"];
        self.descript = dictionary[@"description"];
        self.price = [dictionary[@"price"] floatValue];
        self.image1 = dictionary[@"image1"];
        self.itemId = [dictionary[@"itemId"] intValue];
        self.maxPerOrder = [dictionary[@"max_per_order"] intValue];
    }
    
    return self;
}

@end
