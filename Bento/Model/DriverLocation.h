//
//  DriverLocation.h
//  Bento
//
//  Created by Joseph Lau on 10/29/15.
//  Copyright © 2015 bentonow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface DriverLocation : NSObject

@property (nonatomic) NSString *clientId;
@property (nonatomic) CLLocationCoordinate2D coordinates;

@end