//
//  OrderHistoryItem.m
//  Bento
//
//  Created by Joseph Lau on 1/22/16.
//  Copyright © 2016 bentonow. All rights reserved.
//

#import "OrderHistoryItem.h"

@implementation OrderHistoryItem

- (id)initWithDictionary:(NSDictionary *)dictionary {
    if (self = [super init]) {
        self.title = dictionary[@"title"];
        self.price = dictionary[@"price"];
        self.orderId = dictionary[@"orderId"];
        self.orderStatus = dictionary[@"order_status"];
        self.driverId = dictionary[@"driverId"];
        self.lat = [dictionary[@"lat"] floatValue];
        self.lng = [dictionary[@"long"] floatValue];
    }
    
    return self;
}

@end
