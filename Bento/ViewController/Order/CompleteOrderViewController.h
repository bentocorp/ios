//
//  CompleteOrderViewController.h
//  Bento
//
//  Created by hanjinghe on 1/8/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

#import "DataManager.h"
#import "BaseViewController.h"

#import "OrderAheadMenu.h"
#import "FiveHomeViewController.h"


@protocol CompleteOrderViewControllerDelegate <NSObject>

@optional
- (void)completeOrderViewControllerDidTapBento:(NSString *)bentoName;

@end

@interface CompleteOrderViewController : BaseViewController

@property (nonatomic) id delegate;

@property (nonatomic) OrderAheadMenu *orderAheadMenu;
@property (nonatomic) OrderMode orderMode;
@property (nonatomic) NSInteger selectedOrderAheadIndex;

@end