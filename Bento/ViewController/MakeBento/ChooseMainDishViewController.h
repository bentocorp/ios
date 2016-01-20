//
//  ChooseMainDishViewController.h
//  Bento
//
//  Created by hanjinghe on 1/6/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Bento.h"
#import "OrderAheadMenu.h"
#import "FiveHomeViewController.h"

@interface ChooseMainDishViewController : UIViewController

@property (nonatomic) OrderAheadMenu *orderAheadMenu;
@property (nonatomic) OrderMode orderMode;

@end
