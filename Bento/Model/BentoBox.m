//
//  BentoBox.m
//  Bento
//
//  Created by Joseph Lau on 11/6/15.
//  Copyright © 2015 bentonow. All rights reserved.
//

#import "BentoBox.h"

@implementation BentoBox

- (id)initWithJSON: (NSDictionary *)json {
    self = [super init];
    
    if (self) {
        self.items = [@[] mutableCopy];
        
        NSMutableArray *itemsArray = [json[@"items"] mutableCopy];
        
        for (int i = 0; i < itemsArray.count; i++) {

            [self.items addObject:[[DishInfo alloc] initWithJSON:itemsArray[i]]];
        }
    }
    
    return self;
}

@end
