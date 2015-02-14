//
//  AppDelegate.h
//  Bento
//
//  Created by hanjinghe on 1/6/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MyCLController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

// Get my current location using CLLocationManager
- (CLLocationCoordinate2D )getCurrentLocation;

@end

