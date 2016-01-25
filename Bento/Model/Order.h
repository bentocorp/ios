//
//  Order.h
//  Bento
//
//  Created by Joseph Lau on 11/5/15.
//  Copyright © 2015 bentonow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface Order : NSObject

typedef enum : NSInteger {
    Pending,
    Rejected,
    Accepted,
    Completed,
} OrderStatus;



@property (nonatomic) NSInteger driverId;
@property (nonatomic) NSString *orderId;
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *phone;

// Address
@property (nonatomic) NSString *street;
@property (nonatomic) NSString *residence;
@property (nonatomic) NSString *city;
@property (nonatomic) NSString *region;
@property (nonatomic) NSString *zipCode;
@property (nonatomic) NSString *country;
@property (nonatomic) CLLocationCoordinate2D coordinate;

@property (nonatomic) NSString *orderString;
@property (nonatomic) OrderStatus status;

// order or generic
@property (nonatomic) NSMutableArray *itemArray;
@property (nonatomic) NSString *itemString;

@end
