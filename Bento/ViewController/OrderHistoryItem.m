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
        self.orderId = [@([dictionary[@"orderId"] intValue]) stringValue];
        self.orderStatus = [self setEnumStatus:dictionary[@"order_status"]];
        
        if (dictionary[@"driverId"] != nil && [dictionary[@"driverId"] isEqual:[NSNull null]] == NO) {
            self.driverId = [@([dictionary[@"driverId"] intValue]) stringValue];
        }
        
        self.lat = [dictionary[@"lat"] floatValue];
        self.lng = [dictionary[@"long"] floatValue];
    }
    
    return self;
}

- (OrderStatus)setEnumStatus: (NSString *)statusString {
    
    NSString *lowerCaseTypeString = [statusString lowercaseString];
    
    NSArray *statuses = @[@"assigned", @"en_route", @"arrived", @"rejected"];
    
    NSInteger status = [statuses indexOfObject:lowerCaseTypeString];
    
    switch (status) {
        case 0:
            return Assigned;
        case 1:
            return Enroute;
        case 2:
            return Arrived;
        default:
            return Rejected;
    }
}

@end
