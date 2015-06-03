//
//  CustomServingLunchViewController.m
//  Bento
//
//  Created by Joseph Lau on 6/3/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
#define BORDER_COLOR [UIColor colorWithRed:223.0f / 255.0f green:226.0f / 255.0f blue:226.0f / 255.0f alpha:1.0f]

#import "ServingCustomLunchViewController.h"

#import "BWTitlePagerView.h"

#import "AppDelegate.h"

#import "ChooseMainDishViewController.h"
#import "ChooseSideDishViewController.h"

#import "CompleteOrderViewController.h"
#import "DeliveryLocationViewController.h"

#import "SignedInSettingsViewController.h"
#import "SignedOutSettingsViewController.h"

#import "ServingLunchCell.h"

#import "PreviewCollectionViewCell.h"

#import "MyAlertView.h"

#import "CAGradientLayer+SJSGradients.h"

#import "UIImageView+WebCache.h"

#import "BentoShop.h"
#import "AppStrings.h"
#import "DataManager.h"

#import "SVPlacemark.h"
#import "NSUserDefaults+RMSaveCustomObject.h"

#import <QuartzCore/QuartzCore.h>
#import "JGProgressHUD.h"


@interface ServingCustomLunchViewController ()

@end

@implementation ServingCustomLunchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
