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
        
        if ([dictionary[@"title"] isEqual:[NSNull null]] == NO) {
            self.title = dictionary[@"title"];
        }
        else {
            self.title = nil;
        }
        
        if ([dictionary[@"price"] isEqual:[NSNull null]] == NO) {
            self.price = dictionary[@"price"];
        }
        else {
            self.price = nil;
        }
        
        self.orderId = [@([dictionary[@"orderId"] intValue]) stringValue];
        self.orderStatus = [self setEnumStatus:dictionary[@"order_status"]];
        
        if ([dictionary[@"driverId"] isEqual:[NSNull null]] == NO) {
            self.driverId = [@([dictionary[@"driverId"] intValue]) stringValue];
        }
        
        if ([dictionary[@"driverName"] isEqual:[NSNull null]]) {
            self.driverName = dictionary[@"driverName"];
        }
        
        self.lat = [dictionary[@"lat"] floatValue];
        self.lng = [dictionary[@"long"] floatValue];
    }
    
    return self;
}

- (OrderStatus)setEnumStatus: (NSString *)statusString {
    
    NSString *lowerCaseTypeString = [statusString lowercaseString];
    
    NSArray *statuses = @[@"assigned", @"en route", @"arrived", @"rejected"];
    
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
