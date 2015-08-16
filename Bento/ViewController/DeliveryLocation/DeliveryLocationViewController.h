//
//  DeliveryLocationViewController.h
//  Bento
//
//  Created by hanjinghe on 1/8/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "BaseViewController.h"

@interface DeliveryLocationViewController : BaseViewController <CLLocationManagerDelegate>

@property (nonatomic) BOOL isFromOrder;

@end
