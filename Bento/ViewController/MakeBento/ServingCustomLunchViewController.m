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
{
    UIScrollView *scrollView;
    
    UILabel *lblBanner;
    UILabel *dinnerTitleLabel;
    UILabel *lblBadge;
    UIButton *btnCart;
    
    UIView *viewDishs;
    
    UIView *viewMainEntree;
    UIView *viewSide1;
    UIView *viewSide2;
    UIView *viewSide3;
    UIView *viewSide4;
    
    UIImageView *ivMainDish;
    UIImageView *ivSideDish1;
    UIImageView *ivSideDish2;
    UIImageView *ivSideDish3;
    UIImageView *ivSideDish4;
    
    UILabel *lblMainDish;
    UILabel *lblSideDish1;
    UILabel *lblSideDish2;
    UILabel *lblSideDish3;
    UILabel *lblSideDish4;
    
    UIButton *btnMainDish;
    UIButton *btnSideDish1;
    UIButton *btnSideDish2;
    UIButton *btnSideDish3;
    UIButton *btnSideDish4;
    
    UIImageView *ivBannerMainDish;
    UIImageView *ivBannerSideDish1;
    UIImageView *ivBannerSideDish2;
    UIImageView *ivBannerSideDish3;
    UIImageView *ivBannerSideDish4;
    
    UIButton *btnAddAnotherBento;
    UIButton *btnState;
    
    // Upcoming Lunch
    UILabel *lblTitle;
    UICollectionView *cvDishes;
    
    NSIndexPath *_selectedPath;
    NSInteger hour;
    int weekday;
    
    BWTitlePagerView *pagingTitleView;
    
    JGProgressHUD *loadingHUD;
    BOOL isThereConnection;
    
    NSString *originalDateString;
    NSString *newDateString;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
