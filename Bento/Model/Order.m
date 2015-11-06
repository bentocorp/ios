//
//  Order.m
//  Bento
//
//  Created by Joseph Lau on 11/5/15.
//  Copyright © 2015 bentonow. All rights reserved.
//

#import "Order.h"
#import "BentoBox.h"

@implementation Order

- (id)initWithJSON: (NSDictionary *)json {
    self = [super init];
    
    if (self) {
        self.driverId = [json[@"driverId"] integerValue];
        self.orderId = json[@"id"];
        self.name = json[@"name"];
        self.phone = json[@"phone"];
        
        // Address
        NSDictionary *address = json[@"address"];
        self.street = address[@"street"];
        self.residence = address[@"residence"];
        self.city = address[@"city"];
        self.region = address[@"region"];
        self.zipCode = address[@"zipCode"];
        self.country = address[@"country"];
        self.coordinate = CLLocationCoordinate2DMake([address[@"lat"] doubleValue], [address[@"lng"] doubleValue]);
        
        [self setEnumStatus:json[@"status"]];
        
        // check first letter of Order.id
        NSString *firstLetterofOrderId = [self.orderId substringFromIndex:1];
        if ([firstLetterofOrderId isEqualToString:@"o"]) {
            
            self.itemArray = [@[] mutableCopy];
            
            NSArray *itemsArray = json[@"item"];
            
            // set self.itemArray with BentoBoxes
            for (int i = 0; i < itemsArray.count; i++) {
                [self.itemArray addObject:[[BentoBox alloc] initWithJSON:itemsArray[i]]];
            }
        }
        else if ([firstLetterofOrderId isEqualToString:@"g"]) {
            self.itemString = json[@"item"];
        }
        
        self.orderString = json[@"orderString"];
    }
    
    return self;
}

- (void)setEnumStatus: (NSString *)statusString {
    
    NSString *lowerCaseTypeString = [statusString lowercaseString];
    
    NSArray *statuses = @[@"pending", @"rejected", @"accepted", @"completed"];
    
    NSInteger status = [statuses indexOfObject:lowerCaseTypeString];
    
    switch (status) {
        case 0:
            self.status = Pending;
            break;
        case 1:
            self.status = Rejected;
            break;
        case 2:
            self.status = Accepted;
            break;
        default:
            self.status = Completed;
            break;
    }
}

@end
