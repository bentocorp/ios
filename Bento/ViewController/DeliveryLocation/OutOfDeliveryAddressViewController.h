//
//  OutOfDeliveryAddressViewController.h
//  Bento
//
//  Created by hanjinghe on 1/8/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DataManager.h"

#import "SVPlacemark.h"

@interface OutOfDeliveryAddressViewController : UIViewController

@property (nonatomic) SVPlacemark *placeInfo;

@property (nonatomic) BOOL cameFromCompleteOrderVC;

@end
