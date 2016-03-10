//
//  OrderHistoryItem.h
//  Bento
//
//  Created by Joseph Lau on 1/22/16.
//  Copyright © 2016 bentonow. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSInteger {
    Assigned,
    Enroute,
    Arrived,
    Rejected
} OrderStatus;

@interface OrderHistoryItem : NSObject

@property (nonatomic) NSString *title;
@property (nonatomic) NSString *price;
@property (nonatomic) NSString *orderId;
@property (nonatomic) OrderStatus orderStatus;
@property (nonatomic) NSString *driverId;
@property (nonatomic) NSString *driverName;
@property (nonatomic) float lat;
@property (nonatomic) float lng;

- (id)initWithDictionary:(NSDictionary *)dictionary;

@end
