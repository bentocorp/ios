//
//  DriverLocation.m
//  Bento
//
//  Created by Joseph Lau on 10/29/15.
//  Copyright © 2015 bentonow. All rights reserved.
//

#import "DriverLocation.h"

@implementation DriverLocation

- (id)initWith:(NSDictionary *)json {
    self = [super init];
    if (self) {
        self.clientId = json[@"clientId"];
        self.coordinates = CLLocationCoordinate2DMake([json[@"lat"] doubleValue], [json[@"lng"] doubleValue]);
    }
    return self;
}

@end
