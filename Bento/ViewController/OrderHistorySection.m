//
//  OrderHistorySection.m
//  Bento
//
//  Created by Joseph Lau on 1/22/16.
//  Copyright © 2016 bentonow. All rights reserved.
//

#import "OrderHistorySection.h"
#import "OrderHistoryItem.h"

@implementation OrderHistorySection

- (id)initWithDictionary:(NSDictionary *)dictionary {
    if (self = [super init]) {
        self.sectionTitle = dictionary[@"sectionTitle"];
        
        self.items = [[NSMutableArray alloc] init];
        
        for (NSDictionary *item in dictionary[@"items"]) {
            [self.items addObject:[[OrderHistoryItem alloc] initWithDictionary:item]];
        }
    }
    
    return self;
}

@end
