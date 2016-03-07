//
//  DishInfo.m
//  Bento
//
//  Created by Joseph Lau on 11/6/15.
//  Copyright © 2015 bentonow. All rights reserved.
//

#import "DishInfo.h"

@implementation DishInfo

- (void)setEnumType: (NSString *)typeString {
    
    NSString *lowerCaseTypeString = [typeString lowercaseString];
    
    NSArray *types = @[@"main", @"side", @"addon"];
    
    NSInteger type = [types indexOfObject:lowerCaseTypeString];
    
    switch (type) {
        case 0:
            self.type = Main;
            break;
        case 1:
            self.type = Side;
            break;
        default:
            self.type = AddOn;
            break;
    }
}

- (id)initWithJSON: (NSDictionary *)json {
    self = [super init];
    
    if (self) {
        self.dishId = [json[@"id"] integerValue];
        self.label = json[@"label"];
        self.name = json[@"name"];
        [self setEnumType:json[@"type"]];
    }
    return self;
}

@end
