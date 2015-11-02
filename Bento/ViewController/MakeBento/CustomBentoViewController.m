//
//  ServingDinnerViewController.m
//  Bento
//
//  Created by Joseph Lau on 5/3/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
#define BORDER_COLOR [UIColor colorWithRed:223.0f / 255.0f green:226.0f / 255.0f blue:226.0f / 255.0f alpha:1.0f]

#import "CustomBentoViewController.h"

#import "BWTitlePagerView.h"

#import "AppDelegate.h"

#import "ChooseMainDishViewController.h"
#import "ChooseSideDishViewController.h"

#import "CompleteOrderViewController.h"
#import "DeliveryLocationViewController.h"

#import "SignedInSettingsViewController.h"
#import "SignedOutSettingsViewController.h"

#import "FixedBentoCell.h"

#import "PreviewCollectionViewCell.h"

#import "MyAlertView.h"

#import "CAGradientLayer+SJSGradients.h"

#import "UIImageView+WebCache.h"
#import <UIImageView+UIActivityIndicatorForSDWebImage.h>

#import "BentoShop.h"
#import "AppStrings.h"
#import "DataManager.h"

#import "SVPlacemark.h"
#import "NSUserDefaults+RMSaveCustomObject.h"

#import <QuartzCore/QuartzCore.h>
#import "JGProgressHUD.h"

#import "Mixpanel/MPTweakInline.h"
#import "Mixpanel.h"

#import "UIColor+CustomColors.h"

#import "OrderListViewController.h"
#import "OrderStatusViewController.h"

@interface CustomBentoViewController () <MyAlertViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@end

@implementation CustomBentoViewController
{
    NSInteger _selectedPathMainRight;
    NSInteger _selectedPathSideRight;
    
    NSArray *aryMainDishes;
    NSArray *arySideDishes;
    
    UIView *navigationBarView;
    
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
    
    // RIGHT SIDE
    UILabel *lblTitle;
    UICollectionView *cvDishes;
    
    NSInteger hour;
    int weekday;
    
    BWTitlePagerView *pagingTitleView;
    
    JGProgressHUD *loadingHUD;
    BOOL isThereConnection;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _selectedPathMainRight = -1;
    _selectedPathSideRight = -1;
    
    // initialize to yes
    isThereConnection = YES;
    
    self.view.backgroundColor = [UIColor whiteColor];
    
/*---Scroll View---*/
    
    scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 45, SCREEN_WIDTH, SCREEN_HEIGHT)];
    scrollView.pagingEnabled = YES;
    scrollView.backgroundColor = [UIColor colorWithRed:0.910f green:0.925f blue:0.925f alpha:1.0f];
    scrollView.bounces = NO;
    [self.view addSubview:scrollView];
    
/*---Navigation View---*/
    
    navigationBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 65)];
    navigationBarView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:navigationBarView];
    
/*---BW Title Pager View---*/
    
    [self setPageAndScrollView];
    
/*---Line Separator---*/
    
    UIView *longLineSepartor1 = [[UIView alloc] initWithFrame:CGRectMake(0, 65, SCREEN_WIDTH, 1)];
    longLineSepartor1.backgroundColor = [UIColor colorWithRed:0.827f green:0.835f blue:0.835f alpha:1.0f];
    [navigationBarView addSubview:longLineSepartor1];
    
/*---Settings Image button---*/
    
    UIImageView *settingsImageView = [[UIImageView alloc] initWithFrame:CGRectMake(12, 30, 25, 25)];
    settingsImageView.image = [UIImage imageNamed:@"icon-user"];
    [navigationBarView addSubview:settingsImageView];

/*---Settings Button---*/
    
    UIButton *settingsButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 20, 50, 45)];
    [settingsButton addTarget:self action:@selector(onSettings) forControlEvents:UIControlEventTouchUpInside];
    [navigationBarView addSubview:settingsButton];
    
/*---Cart Button---*/
    
    btnCart = [[UIButton alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 50, 20, 50, 45)];
    [btnCart setImage:[UIImage imageNamed:@"mybento_nav_cart_inact"] forState:UIControlStateNormal];
    [btnCart addTarget:self action:@selector(onCart) forControlEvents:UIControlEventTouchUpInside];
    [navigationBarView addSubview:btnCart];
    
    // Tracking
    UIButton *orderStatusButton = [[UIButton alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 90, 27, 30, 30)];
    [orderStatusButton addTarget:self action:@selector(onOrderStatus) forControlEvents:UIControlEventTouchUpInside];
    [orderStatusButton setImage:[UIImage imageNamed:@"in-transit-64"] forState:UIControlStateNormal];
    [navigationBarView addSubview:orderStatusButton];
    
/*---Count Badge---*/
    
    lblBadge = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 42.5, 25, 14, 14)];
    lblBadge.textAlignment = NSTextAlignmentCenter;
    lblBadge.font = [UIFont fontWithName:@"OpenSans-Semibold" size:10];
    lblBadge.backgroundColor = [UIColor colorWithRed:0.890f green:0.247f blue:0.373f alpha:1.0f];
    lblBadge.textColor = [UIColor whiteColor];
    lblBadge.layer.cornerRadius = lblBadge.frame.size.width / 2;
    lblBadge.clipsToBounds = YES;
    [navigationBarView addSubview:lblBadge];
    
/*---Full Dishes View---*/
    
    viewDishs = [[UIView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH / 2 - ((SCREEN_WIDTH - 60) / 2), 20, SCREEN_WIDTH - 60, SCREEN_HEIGHT - 220)];
    viewDishs.layer.cornerRadius = 3;
    viewDishs.clipsToBounds = YES;
    viewDishs.layer.borderColor = BORDER_COLOR.CGColor;
    viewDishs.layer.borderWidth = 1.0f;
    [scrollView addSubview:viewDishs];
    
    int everyDishHeight = viewDishs.frame.size.height / 3;
    
/*---View Dishes---*/
    
    viewMainEntree = [[UIView alloc] initWithFrame:CGRectMake(-1, -1, viewDishs.frame.size.width + 2, everyDishHeight + 2)];
    viewMainEntree.backgroundColor = [UIColor colorWithRed:0.918f green:0.929f blue:0.929f alpha:1.0f];
    [viewDishs addSubview:viewMainEntree];
    
    viewSide1 = [[UIView alloc] initWithFrame:CGRectMake(-1, everyDishHeight, viewDishs.frame.size.width / 2 + 2, everyDishHeight + 1)];
    viewSide1.layer.borderWidth = 1.0f;
    viewSide1.layer.borderColor = BORDER_COLOR.CGColor;
    viewSide1.backgroundColor = [UIColor colorWithRed:0.918f green:0.929f blue:0.929f alpha:1.0f];
    [viewDishs addSubview:viewSide1];
    
    viewSide2 = [[UIView alloc] initWithFrame:CGRectMake(viewDishs.frame.size.width / 2, everyDishHeight, viewDishs.frame.size.width / 2 + 1, everyDishHeight + 1)];
    viewSide2.layer.borderWidth = 1.0f;
    viewSide2.backgroundColor = [UIColor colorWithRed:0.918f green:0.929f blue:0.929f alpha:1.0f];
    viewSide2.layer.borderColor = BORDER_COLOR.CGColor;
    [viewDishs addSubview:viewSide2];
    
    viewSide3 = [[UIView alloc] initWithFrame:CGRectMake(-1, everyDishHeight * 2, viewDishs.frame.size.width / 2 + 2, everyDishHeight + 2)];
    viewSide3.layer.borderWidth = 1.0f;
    viewSide3.backgroundColor = [UIColor colorWithRed:0.918f green:0.929f blue:0.929f alpha:1.0f];
    viewSide3.layer.borderColor = BORDER_COLOR.CGColor;
    [viewDishs addSubview:viewSide3];

    viewSide4 = [[UIView alloc] initWithFrame:CGRectMake(viewDishs.frame.size.width / 2, everyDishHeight * 2, viewDishs.frame.size.width / 2 + 1, everyDishHeight + 2)];
    viewSide4.layer.borderWidth = 1.0f;
    viewSide4.backgroundColor = [UIColor colorWithRed:0.918f green:0.929f blue:0.929f alpha:1.0f];
    viewSide4.layer.borderColor = BORDER_COLOR.CGColor;
    [viewDishs addSubview:viewSide4];
    
/*---Button Dishes---*/
    
    btnMainDish = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, viewDishs.frame.size.width + 2, everyDishHeight + 2)];
    btnMainDish.backgroundColor = [UIColor colorWithRed:0.918f green:0.929f blue:0.929f alpha:1.0f];
    [btnMainDish setTitle:[[AppStrings sharedInstance] getString:BUILD_MAIN_BUTTON] forState:UIControlStateNormal];
    [btnMainDish setTitleColor:[UIColor colorWithRed:0.533f green:0.686f blue:0.376f alpha:1.0f] forState:UIControlStateNormal];
    btnMainDish.titleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:12.0f];
    [btnMainDish addTarget:self action:@selector(onAddMainDish) forControlEvents:UIControlEventTouchUpInside];
    [viewMainEntree addSubview:btnMainDish];

    btnSideDish1 = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, viewDishs.frame.size.width / 2 + 2, everyDishHeight + 1)];
    [btnSideDish1 setTitle:[[AppStrings sharedInstance] getString:BUILD_SIDE1_BUTTON] forState:UIControlStateNormal];
    [btnSideDish1 setTitleColor:[UIColor colorWithRed:0.533f green:0.686f blue:0.376f alpha:1.0f] forState:UIControlStateNormal];
    btnSideDish1.titleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:12.0f];
    btnSideDish1.tag = 0;
    [btnSideDish1 addTarget:self action:@selector(onAddSideDish:) forControlEvents:UIControlEventTouchUpInside];
    [viewSide1 addSubview:btnSideDish1];

    btnSideDish2 = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, viewDishs.frame.size.width / 2 + 1, everyDishHeight + 1)];
    [btnSideDish2 setTitle:[[AppStrings sharedInstance] getString:BUILD_SIDE2_BUTTON] forState:UIControlStateNormal];
    [btnSideDish2 setTitleColor:[UIColor colorWithRed:0.533f green:0.686f blue:0.376f alpha:1.0f] forState:UIControlStateNormal];
    btnSideDish2.titleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:12.0f];
    btnSideDish2.tag = 1;
    [btnSideDish2 addTarget:self action:@selector(onAddSideDish:) forControlEvents:UIControlEventTouchUpInside];
    [viewSide2 addSubview:btnSideDish2];

    btnSideDish3 = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, viewDishs.frame.size.width / 2 + 2, everyDishHeight + 2)];
    [btnSideDish3 setTitle:[[AppStrings sharedInstance] getString:BUILD_SIDE3_BUTTON] forState:UIControlStateNormal];
    [btnSideDish3 setTitleColor:[UIColor colorWithRed:0.533f green:0.686f blue:0.376f alpha:1.0f] forState:UIControlStateNormal];
    btnSideDish3.titleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:12.0f];
    btnSideDish3.tag = 2;
    [btnSideDish3 addTarget:self action:@selector(onAddSideDish:) forControlEvents:UIControlEventTouchUpInside];
    [viewSide3 addSubview:btnSideDish3];
    
    btnSideDish4 = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, viewDishs.frame.size.width / 2 + 1, everyDishHeight + 2)];
    [btnSideDish4 setTitle:[[AppStrings sharedInstance] getString:BUILD_SIDE4_BUTTON] forState:UIControlStateNormal];
    [btnSideDish4 setTitleColor:[UIColor colorWithRed:0.533f green:0.686f blue:0.376f alpha:1.0f] forState:UIControlStateNormal];
    btnSideDish4.titleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:12.0f];
    btnSideDish4.tag = 3;
    [btnSideDish4 addTarget:self action:@selector(onAddSideDish:) forControlEvents:UIControlEventTouchUpInside];
    [viewSide4 addSubview:btnSideDish4];
    
/*---Image Dishes*---*/
    
    ivMainDish = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, viewDishs.frame.size.width + 2, everyDishHeight + 2)];
    [ivMainDish setClipsToBounds:YES];
    ivMainDish.contentMode = UIViewContentModeScaleAspectFill;
    [viewMainEntree addSubview:ivMainDish];
    
    ivSideDish1 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, viewDishs.frame.size.width / 2 + 2, everyDishHeight + 1)];
    ivSideDish1.contentMode = UIViewContentModeScaleAspectFill;
    [ivSideDish1 setClipsToBounds:YES];
    [viewSide1 addSubview:ivSideDish1];

    ivSideDish2 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, viewDishs.frame.size.width / 2 + 1, everyDishHeight + 1)];
    [ivSideDish2 setClipsToBounds:YES];
    ivSideDish2.contentMode = UIViewContentModeScaleAspectFill;
    [viewSide2 addSubview:ivSideDish2];

    ivSideDish3 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, viewDishs.frame.size.width / 2 + 2, everyDishHeight + 2)];
    [ivSideDish3 setClipsToBounds:YES];
    ivSideDish3.contentMode = UIViewContentModeScaleAspectFill;
    [viewSide3 addSubview:ivSideDish3];
    
    ivSideDish4 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, viewDishs.frame.size.width / 2 + 1, everyDishHeight + 2)];
    [ivSideDish4 setClipsToBounds:YES];
    ivSideDish4.contentMode = UIViewContentModeScaleAspectFill;
    [viewSide4 addSubview:ivSideDish4];
    
/*---Gradient Layer---*/
    
    CAGradientLayer *backgroundLayer = [CAGradientLayer blackGradientLayer];
    backgroundLayer.frame = ivMainDish.frame;
    backgroundLayer.opacity = 0.8f;
    [ivMainDish.layer insertSublayer:backgroundLayer atIndex:0];

    backgroundLayer = [CAGradientLayer blackGradientLayer];
    backgroundLayer.frame = ivSideDish1.frame;
    backgroundLayer.opacity = 0.8f;
    [ivSideDish1.layer insertSublayer:backgroundLayer atIndex:0];

    backgroundLayer = [CAGradientLayer blackGradientLayer];
    backgroundLayer.frame = ivSideDish2.frame;
    backgroundLayer.opacity = 0.8f;
    [ivSideDish2.layer insertSublayer:backgroundLayer atIndex:0];

    backgroundLayer = [CAGradientLayer blackGradientLayer];
    backgroundLayer.frame = ivSideDish3.frame;
    backgroundLayer.opacity = 0.8f;
    [ivSideDish3.layer insertSublayer:backgroundLayer atIndex:0];

    backgroundLayer = [CAGradientLayer blackGradientLayer];
    backgroundLayer.frame = ivSideDish4.frame;
    backgroundLayer.opacity = 0.8f;
    [ivSideDish4.layer insertSublayer:backgroundLayer atIndex:0];
    
/*---Label Dishes---*/
    
    lblMainDish = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, viewDishs.frame.size.width + 2, everyDishHeight + 2)];
    lblMainDish.textColor = [UIColor whiteColor];
    lblMainDish.font = [UIFont fontWithName:@"OpenSans-Bold" size:18.0f];
    lblMainDish.textAlignment = NSTextAlignmentCenter;
    lblMainDish.adjustsFontSizeToFitWidth = YES;
    [viewMainEntree addSubview:lblMainDish];
    
    lblSideDish1 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, viewDishs.frame.size.width / 2 + 2, everyDishHeight + 1)];
    lblSideDish1.textColor = [UIColor whiteColor];
    lblSideDish1.font = [UIFont fontWithName:@"OpenSans-Bold" size:14.0f];
    lblSideDish1.textAlignment = NSTextAlignmentCenter;
    lblSideDish1.adjustsFontSizeToFitWidth = YES;
    [viewSide1 addSubview:lblSideDish1];

    lblSideDish2 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, viewDishs.frame.size.width / 2 + 1, everyDishHeight + 1)];
    lblSideDish2.textColor = [UIColor whiteColor];
    lblSideDish2.font = [UIFont fontWithName:@"OpenSans-Bold" size:14.0f];
    lblSideDish2.textAlignment = NSTextAlignmentCenter;
    lblSideDish2.adjustsFontSizeToFitWidth = YES;
    [viewSide2 addSubview:lblSideDish2];

    lblSideDish3 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, viewDishs.frame.size.width / 2 + 2, everyDishHeight + 2)];
    lblSideDish3.textColor = [UIColor whiteColor];
    lblSideDish3.font = [UIFont fontWithName:@"OpenSans-Bold" size:14.0f];
    lblSideDish3.textAlignment = NSTextAlignmentCenter;
    lblSideDish3.adjustsFontSizeToFitWidth = YES;
    [viewSide3 addSubview:lblSideDish3];
    
    lblSideDish4 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, viewDishs.frame.size.width / 2 + 1, everyDishHeight + 2)];
    lblSideDish4.textColor = [UIColor whiteColor];
    lblSideDish4.font = [UIFont fontWithName:@"OpenSans-Bold" size:14.0f];
    lblSideDish4.textAlignment = NSTextAlignmentCenter;
    lblSideDish4.adjustsFontSizeToFitWidth = YES;
    [viewSide4 addSubview:lblSideDish4];
    

/*---Image Banner---*/
    
    UIImage *soldOutBannerImage = [UIImage imageNamed:@"banner_sold_out"];

    ivBannerMainDish = [[UIImageView alloc] initWithFrame:CGRectMake(viewMainEntree.frame.size.width - viewMainEntree.frame.size.height / 2, 0, viewMainEntree.frame.size.height / 2, viewMainEntree.frame.size.height / 2)];
    ivBannerMainDish.image = soldOutBannerImage;
    [viewMainEntree addSubview:ivBannerMainDish];

    ivBannerSideDish1 = [[UIImageView alloc] initWithFrame:CGRectMake(viewSide1.frame.size.width - viewSide1.frame.size.height / 2, 0, viewSide1.frame.size.height / 2, viewSide1.frame.size.height / 2)];
    ivBannerSideDish1.image = soldOutBannerImage;
    [viewSide1 addSubview:ivBannerSideDish1];
    
    ivBannerSideDish2 = [[UIImageView alloc] initWithFrame: CGRectMake(viewSide2.frame.size.width - viewSide2.frame.size.height / 2, 0, viewSide2.frame.size.height / 2, viewSide2.frame.size.height / 2)];
    ivBannerSideDish2.image = soldOutBannerImage;
    [viewSide2 addSubview:ivBannerSideDish2];
    
    ivBannerSideDish3 = [[UIImageView alloc] initWithFrame:CGRectMake(viewSide3.frame.size.width - viewSide3.frame.size.height / 2, 0, viewSide3.frame.size.height / 2, viewSide3.frame.size.height / 2)];
    ivBannerSideDish3.image = soldOutBannerImage;
    [viewSide3 addSubview:ivBannerSideDish3];
    
    ivBannerSideDish4 = [[UIImageView alloc] initWithFrame:CGRectMake(viewSide4.frame.size.width - viewSide4.frame.size.height / 2, 0, viewSide4.frame.size.height / 2, viewSide4.frame.size.height / 2)];
    ivBannerSideDish4.image = soldOutBannerImage;
    [viewSide4 addSubview:ivBannerSideDish4];
    
/*---Add Another Bento Button---*/
    
    btnAddAnotherBento = [[UIButton alloc] initWithFrame:CGRectMake(SCREEN_WIDTH / 2 - ((SCREEN_WIDTH - 60) / 2), viewDishs.frame.size.height + 45, SCREEN_WIDTH - 60, 45)];
    btnAddAnotherBento.layer.borderColor = BORDER_COLOR.CGColor;
    btnAddAnotherBento.layer.borderWidth = 1.0f;
    [btnAddAnotherBento setTitleColor:[UIColor bentoButtonGray] forState:UIControlStateNormal];
    btnAddAnotherBento.titleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:12.0f];
    [btnAddAnotherBento addTarget:self action:@selector(onAddAnotherBento) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:btnAddAnotherBento];
    
/*---Button State---*/
    
    btnState = [[UIButton alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT-45-65, SCREEN_WIDTH, 45)];
    [btnState setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btnState.titleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:13.0f];
    [btnState addTarget:self action:@selector(onContinue) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:btnState];
    
/*---Banner---*/
    
    lblBanner = [[UILabel alloc] initWithFrame:CGRectMake(0, 65, SCREEN_WIDTH, 28)];
    lblBanner.textAlignment = NSTextAlignmentCenter;
    lblBanner.textColor = [UIColor whiteColor];
    
    if (MPTweakValue(@"Show green banner for regular price", NO)) {
        // test, show banner
        lblBanner.hidden = NO;
    }
    else {
        // original, don't show banner
        lblBanner.hidden = YES;
    }
    
    lblBanner.center = CGPointMake(self.view.frame.size.width * 5 / 6, self.view.frame.size.width / 6);
    lblBanner.transform = CGAffineTransformMakeRotation(M_PI / 4);
    lblBanner.font = [UIFont fontWithName:@"OpenSans-Bold" size:16.0f];
    [scrollView addSubview:lblBanner];
    
/*------*/
    
    NSString *strTitle = [[AppStrings sharedInstance] getString:BUILD_ADD_BUTTON];
    if (strTitle == nil)
        strTitle = @"BUILD YOUR BENTO";
    
//    NSString *strTitle = @"BUILD YOUR BENTO - $12";
    
    if (strTitle != nil)
    {
        // Add Another Bento Button
        [btnAddAnotherBento setTitle:strTitle forState:UIControlStateNormal];
        NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:strTitle];
        float spacing = 1.0f;
        [attributedTitle addAttribute:NSKernAttributeName
                                value:@(spacing)
                                range:NSMakeRange(0, [strTitle length])];
        // Anything less than iOS 8.0
        if ([[UIDevice currentDevice].systemVersion intValue] < 8)
            btnAddAnotherBento.titleLabel.text = strTitle;
        else
            btnAddAnotherBento.titleLabel.attributedText = attributedTitle;
        
        // Continue Button
        strTitle = [[AppStrings sharedInstance] getString:BUILD_CONTINUE_BUTTON];
        [btnState setTitle:strTitle forState:UIControlStateNormal];
        if (strTitle != nil)
            attributedTitle = [[NSMutableAttributedString alloc] initWithString:strTitle];
        spacing = 1.0f;
        [attributedTitle addAttribute:NSKernAttributeName
                                value:@(spacing)
                                range:NSMakeRange(0, [strTitle length])];
        // Anything less than iOS 8.0
        if ([[UIDevice currentDevice].systemVersion intValue] < 8)
            btnState.titleLabel.text = strTitle;
        else
            btnState.titleLabel.attributedText = attributedTitle;
        attributedTitle = nil;
    }
    
    // an empty empty is created the FIRST time app is launched - there will always be at least one empty bento in defaults
    if ([[BentoShop sharedInstance] getTotalBentoCount] == 0)
        [[BentoShop sharedInstance] addNewBento];
    
    lblBadge.hidden = NO;
    btnCart.hidden = NO;
    btnAddAnotherBento.hidden = NO;
    btnState.hidden = NO;
    
    // If no location set
    AppDelegate *delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    CLLocationCoordinate2D location = [delegate getCurrentLocation];
    BentoShop *globalShop = [BentoShop sharedInstance];
    if (![globalShop checkLocation:location] && [[DataManager shareDataManager] getUserInfo] == nil)
    {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        DeliveryLocationViewController *deliveryLocationViewController = [storyboard instantiateViewControllerWithIdentifier:@"DeliveryLocationViewController"];
   
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"nextToBuild"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self.navigationController pushViewController:deliveryLocationViewController animated:NO];
    }
    
/*-------------------------------------RIGHT---------------------------------------*/
    
    /*---Collection View---*/
    
    // this sets the layout of the cells
    UICollectionViewFlowLayout *collectionViewFlowLayout = [[UICollectionViewFlowLayout alloc] init];
    [collectionViewFlowLayout setMinimumLineSpacing:0];
    [collectionViewFlowLayout setMinimumInteritemSpacing:0];
    [cvDishes setCollectionViewLayout:collectionViewFlowLayout];
    
    cvDishes = [[UICollectionView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH, 0, SCREEN_WIDTH, SCREEN_HEIGHT-65) collectionViewLayout:collectionViewFlowLayout];
    cvDishes.backgroundColor = [UIColor colorWithRed:0.910f green:0.925f blue:0.925f alpha:1.0f];
    cvDishes.dataSource = self;
    cvDishes.delegate = self;
    
    UINib *cellNib = [UINib nibWithNibName:@"PreviewCollectionViewCell" bundle:nil];
    [cvDishes registerNib:cellNib forCellWithReuseIdentifier:@"PreviewCollectionViewCell"];
    [cvDishes registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView"];
    
    [scrollView addSubview:cvDishes];
    
    // Get current hour
    NSDate *currentDate = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitHour fromDate:currentDate];
    
    hour = [components hour];
    NSLog(@"current hour - %ld", (long)hour);
    
    // Sunday = 1, Saturday = 7
    weekday = (int)[[calendar components:NSCalendarUnitWeekday fromDate:currentDate] weekday];
    NSLog(@"today is - %ld", (long)weekday);
}

#pragma mark Set PageView and ScrollView

- (void)setPageAndScrollView
{
    NSString *currentMenuTitle;
    NSString *nextMenuTitle;
    
    BOOL shouldShowOneMenu = NO;
    
    /* IS All-DAY */
    if ([[BentoShop sharedInstance] isAllDay])
    {
        // Left Side
        if([[BentoShop sharedInstance] isThereLunchMenu])
            currentMenuTitle = @"Serving All-day Lunch";
        else if ([[BentoShop sharedInstance] isThereDinnerMenu])
            currentMenuTitle = @"Serving All-day Dinner";
        
        // Right Side
        
        // No Next Available Menu
        if ([[BentoShop sharedInstance] isThereLunchNextMenu] == NO && [[BentoShop sharedInstance] isThereDinnerNextMenu] == NO)
            shouldShowOneMenu = YES;
        
        // Next Menu Available
        else
        {
            if ([[BentoShop sharedInstance] nextIsAllDay])
            {
                if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                    nextMenuTitle = [NSString stringWithFormat:@"%@'s All-day Lunch Menu", [[BentoShop sharedInstance] getNextMenuWeekdayString]];
                else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                    nextMenuTitle = [NSString stringWithFormat:@"%@'s All-day Dinner Menu", [[BentoShop sharedInstance] getNextMenuWeekdayString]];
            }
            else if ([[BentoShop sharedInstance] nextIsAllDay] == NO)
            {
                if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                    nextMenuTitle = [NSString stringWithFormat:@"%@'s Lunch Menu", [[BentoShop sharedInstance] getNextMenuWeekdayString]];
                else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                    nextMenuTitle = [NSString stringWithFormat:@"%@'s Dinner Menu", [[BentoShop sharedInstance] getNextMenuWeekdayString]];
            }
        }
    }
    
    /* IS NOT ALL-DAY */
    else
    {
        // 00:00 - 16:29 Lunch
        if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Lunch"])
        {
            // Left Side
            if ([[BentoShop sharedInstance] isThereLunchMenu])
                currentMenuTitle = @"Now Serving Lunch";
            
            // Right Side
            if ([[BentoShop sharedInstance] isThereDinnerMenu])
                nextMenuTitle = @"Tonight's Dinner Menu";
            else if ([[BentoShop sharedInstance] nextIsAllDay])
            {
                if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                    nextMenuTitle = [NSString stringWithFormat:@"%@'s All-Day Lunch Menu", [[BentoShop sharedInstance] getNextMenuWeekdayString]];
                else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                    nextMenuTitle = [NSString stringWithFormat:@"%@'s All-Day Dinner Menu", [[BentoShop sharedInstance] getNextMenuWeekdayString]];
            }
            else
            {
                if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                    nextMenuTitle = [NSString stringWithFormat:@"%@'s Lunch Menu", [[BentoShop sharedInstance] getNextMenuWeekdayString]];
                else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                    nextMenuTitle = [NSString stringWithFormat:@"%@'s Dinner Menu", [[BentoShop sharedInstance] getNextMenuWeekdayString]];
                else
                    shouldShowOneMenu = YES;
            }
        }
        
        // 16:30 - 23:59 Dinner
        else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Dinner"])
        {
            // Left Side
            if ([[BentoShop sharedInstance] isThereDinnerMenu])
                currentMenuTitle = @"Now Serving Dinner";
            
            // Right Side
            if ([[BentoShop sharedInstance] nextIsAllDay])
            {
                if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                    nextMenuTitle = [NSString stringWithFormat:@"%@'s All-day Lunch Menu", [[BentoShop sharedInstance] getNextMenuWeekdayString]];
                else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                    nextMenuTitle = [NSString stringWithFormat:@"%@'s All-day Dinner Menu", [[BentoShop sharedInstance] getNextMenuWeekdayString]];
            }
            else if ([[BentoShop sharedInstance] nextIsAllDay] == NO)
            {
                if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                    nextMenuTitle = [NSString stringWithFormat:@"%@'s Lunch Menu", [[BentoShop sharedInstance] getNextMenuWeekdayString]];
                else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                    nextMenuTitle = [NSString stringWithFormat:@"%@'s Dinner Menu", [[BentoShop sharedInstance] getNextMenuWeekdayString]];
                else
                    shouldShowOneMenu = YES;
            }
        }
    }
    
    // No Available Menu
    if (currentMenuTitle == nil)
        currentMenuTitle = @"No Available Menu";
    if (nextMenuTitle == nil)
        nextMenuTitle = @"No Available Menu";
    
    
    pagingTitleView = [[BWTitlePagerView alloc] init];
    pagingTitleView.frame = CGRectMake(SCREEN_WIDTH/2-100, 32.5 - 10, 200, 40);
    pagingTitleView.font = [UIFont fontWithName:@"OpenSans-Bold" size:16.0f];
    pagingTitleView.currentTintColor = [UIColor bentoTitleGray];
    [pagingTitleView observeScrollView:scrollView];
    
    if (shouldShowOneMenu)
    {
        scrollView.contentSize = CGSizeMake(SCREEN_WIDTH, SCREEN_HEIGHT-65);
        [pagingTitleView addObjects:@[currentMenuTitle]];
    }
    else
    {
        scrollView.contentSize = CGSizeMake(SCREEN_WIDTH*2, SCREEN_HEIGHT-65);
        [pagingTitleView addObjects:@[currentMenuTitle, nextMenuTitle]];
    }
    
    [navigationBarView addSubview:pagingTitleView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateUI];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus:) name:USER_NOTIFICATION_UPDATED_MENU object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus:) name:USER_NOTIFICATION_UPDATED_STATUS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedMenu:) name:USER_NOTIFICATION_UPDATED_NEXTMENU object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noConnection) name:@"networkError" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yesConnection) name:@"networkConnected" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkCurrentMode) name:@"checkModeOrDateChange" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkCurrentMode) name:@"enteredForeground" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startTimerOnViewedScreen) name:@"enteredForeground" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endTimerOnViewedScreen) name:@"enteringBackground" object:nil];

    NSLog(@"DISTINCT ID - %@", [[Mixpanel sharedInstance] distinctId]);
    
    [self startTimerOnViewedScreen];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewWillDisappear:animated];
    
    [self endTimerOnViewedScreen];
}

- (void)dealloc
{
    @try {
        [scrollView removeObserver:pagingTitleView.self forKeyPath:@"contentOffset" context:nil];
    }@catch(id anException){
        //do nothing, obviously it wasn't attached because an exception was thrown
    }
}

#pragma mark Duration on screen
- (void)startTimerOnViewedScreen
{
    [[Mixpanel sharedInstance] timeEvent:@"Viewed Custom Home Screen"];
}

- (void)endTimerOnViewedScreen
{
    [[Mixpanel sharedInstance] track:@"Viewed Custom Home Screen"];
}

- (void)noConnection
{
    isThereConnection = NO;
    
    if (loadingHUD == nil) {
        
        loadingHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
        loadingHUD.textLabel.text = @"Waiting for internet connectivity...";
        [loadingHUD showInView:self.view];
    }
}

- (void)yesConnection
{
    [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(callUpdate) userInfo:nil repeats:NO];
}

- (void)callUpdate
{
    isThereConnection = YES;
    
    [loadingHUD dismiss];
    loadingHUD = nil;
    [self viewWillAppear:YES];
}

- (void)checkCurrentMode
{
    if ([[BentoShop sharedInstance] didModeOrDateChange]) {
        [(UINavigationController *)self.presentingViewController popToRootViewControllerAnimated:NO];
        [self dismissViewControllerAnimated:YES completion:nil];
        
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)onUpdatedStatus:(NSNotification *)notification
{
    if (isThereConnection) {
        if ([[BentoShop sharedInstance] isClosed] && ![[DataManager shareDataManager] isAdminUser]) {
            [self showSoldoutScreen:[NSNumber numberWithInt:0]];
        }
        else if ([[BentoShop sharedInstance] isSoldOut] && ![[DataManager shareDataManager] isAdminUser]) {
            [self showSoldoutScreen:[NSNumber numberWithInt:1]];
        }
        else {
            [self performSelectorOnMainThread:@selector(updateUI) withObject:nil waitUntilDone:NO];
        }
    }
}

- (void)loadSelectedDishes
{
    NSMutableArray *aryBentos = [[NSMutableArray alloc] init];
    for (NSInteger index = 0; index < [[BentoShop sharedInstance] getTotalBentoCount]; index++) {
        
        Bento *bento = [[BentoShop sharedInstance] getBento:index];
        if ([bento isCompleted]) {
            [aryBentos addObject:bento];
        }
    }
    
//    NSLog(@"TOTAL BENTOS: %ld", (long)[[BentoShop sharedInstance] getTotalBentoCount]);
    NSInteger mainDishIndex = 0;
    NSInteger side1DishIndex = 0;
    NSInteger side2DishIndex = 0;
    NSInteger side3DishIndex = 0;
    NSInteger side4DishIndex = 0;
    
    Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];

    // Current Bento is not empty
    if (currentBento != nil)
    {
        mainDishIndex = [currentBento getMainDish];
        side1DishIndex = [currentBento getSideDish1];
        side2DishIndex = [currentBento getSideDish2];
        side3DishIndex = [currentBento getSideDish3];
        side4DishIndex = [currentBento getSideDish4];
    }
    
/*-Main-*/
    if (mainDishIndex > 0) {
        
        ivMainDish.hidden = NO;
        lblMainDish.hidden = NO;
        
        NSDictionary *dishInfo = [[BentoShop sharedInstance] getMainDish:mainDishIndex];
        if (dishInfo != nil) {
            lblMainDish.text = [[dishInfo objectForKey:@"name"] uppercaseString];
            
            NSString *strImageURL = [dishInfo objectForKey:@"image1"];
            if (strImageURL == nil || [strImageURL isEqualToString:@""]) {
                // if there's no image string from backend
                ivMainDish.image = [UIImage imageNamed:@"empty-main"];
            }
            else {
                // download image and display activity indicator in process
//                [ivMainDish setImageWithURL:[NSURL URLWithString:strImageURL] usingActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
                
                [ivMainDish setImageWithURL:[NSURL URLWithString:strImageURL] placeholderImage:[UIImage imageNamed:@"gradient-placeholder2"] usingActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            }
            
            if ([[BentoShop sharedInstance] isDishSoldOut:mainDishIndex]) {
                ivBannerMainDish.hidden = NO;
            }
            else {
                ivBannerMainDish.hidden = YES;
            }
        }
    }
    else {
        ivMainDish.image = nil;
        ivMainDish.hidden = YES;
        lblMainDish.hidden = YES;
        ivBannerMainDish.hidden = YES;
    }
    
/*-Side 1-*/
    if (side1DishIndex > 0) {
        
        ivSideDish1.hidden = NO;
        lblSideDish1.hidden = NO;
    
        NSDictionary *dishInfo = [[BentoShop sharedInstance] getSideDish:side1DishIndex];
        if (dishInfo != nil) {
            
            lblSideDish1.text = [[dishInfo objectForKey:@"name"] uppercaseString];
            
            NSString *strImageURL = [dishInfo objectForKey:@"image1"];
            if (strImageURL == nil || [strImageURL isEqualToString:@""]) {
                // if there's no image string from backend
                ivSideDish1.image = [UIImage imageNamed:@"empty-main"];
            }
            else {
                // download image and display activity indicator in process
//                [ivSideDish1 setImageWithURL:[NSURL URLWithString:strImageURL] usingActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
                
                [ivSideDish1 setImageWithURL:[NSURL URLWithString:strImageURL] placeholderImage:[UIImage imageNamed:@"gradient-placeholder2"] usingActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            }
            
            if ([[BentoShop sharedInstance] isDishSoldOut:side1DishIndex]) {
                ivBannerSideDish1.hidden = NO;
            }
            else {
                ivBannerSideDish1.hidden = YES;
            }
        }
    }
    else {
        ivSideDish1.image = nil;
        ivSideDish1.hidden = YES;
        lblSideDish1.hidden = YES;
        ivBannerSideDish1.hidden = YES;
    }
    
/*-Side 2-*/
    if (side2DishIndex > 0) {
        
        ivSideDish2.hidden = NO;
        lblSideDish2.hidden = NO;
        
        NSDictionary *dishInfo = [[BentoShop sharedInstance] getSideDish:side2DishIndex];
        if (dishInfo != nil) {
            
            lblSideDish2.text = [[dishInfo objectForKey:@"name"] uppercaseString];
            
            NSString *strImageURL = [dishInfo objectForKey:@"image1"];
            if (strImageURL == nil || [strImageURL isEqualToString:@""]) {
                // if there's no image string from backend
                ivSideDish2.image = [UIImage imageNamed:@"empty-main"];
            }
            else {
                // download image and display activity indicator in process
//                [ivSideDish2 setImageWithURL:[NSURL URLWithString:strImageURL] usingActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
                
                [ivSideDish2 setImageWithURL:[NSURL URLWithString:strImageURL] placeholderImage:[UIImage imageNamed:@"gradient-placeholder2"] usingActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            }
            
            if ([[BentoShop sharedInstance] isDishSoldOut:side2DishIndex]) {
                ivBannerSideDish2.hidden = NO;
            }
            else {
                ivBannerSideDish2.hidden = YES;
            }
        }
    }
    else {
        ivSideDish2.image = nil;
        ivSideDish2.hidden = YES;
        lblSideDish2.hidden = YES;
        ivBannerSideDish2.hidden = YES;
    }

/*-Side 3-*/
    if (side3DishIndex > 0) {
        
        ivSideDish3.hidden = NO;
        lblSideDish3.hidden = NO;
        
        NSDictionary *dishInfo = [[BentoShop sharedInstance] getSideDish:side3DishIndex];
        if (dishInfo != nil) {
            lblSideDish3.text = [[dishInfo objectForKey:@"name"] uppercaseString];
            
            NSString *strImageURL = [dishInfo objectForKey:@"image1"];
            if (strImageURL == nil || [strImageURL isEqualToString:@""]) {
                // if there's no image string from backend
                ivSideDish3.image = [UIImage imageNamed:@"empty-main"];
            }
            else {
                // download image and display activity indicator in process
//                [ivSideDish3 setImageWithURL:[NSURL URLWithString:strImageURL] usingActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
                
                [ivSideDish3 setImageWithURL:[NSURL URLWithString:strImageURL] placeholderImage:[UIImage imageNamed:@"gradient-placeholder2"] usingActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            }
            
            if ([[BentoShop sharedInstance] isDishSoldOut:side3DishIndex]) {
                ivBannerSideDish3.hidden = NO;
            }
            else {
                ivBannerSideDish3.hidden = YES;
            }
        }
    }
    else {
        ivSideDish3.image = nil;
        ivSideDish3.hidden = YES;
        lblSideDish3.hidden = YES;
        ivBannerSideDish3.hidden = YES;
    }
    
/*-Side 4-*/
    if (side4DishIndex > 0) {
        
        ivSideDish4.hidden = NO;
        lblSideDish4.hidden = NO;
        
        NSDictionary *dishInfo = [[BentoShop sharedInstance] getSideDish:side4DishIndex];
        if (dishInfo != nil) {
            
            lblSideDish4.text = [[dishInfo objectForKey:@"name"] uppercaseString];
            
            NSString *strImageURL = [dishInfo objectForKey:@"image1"];
            if (strImageURL == nil || [strImageURL isEqualToString:@""]) {
                // if there's no image string from backend
                ivSideDish4.image = [UIImage imageNamed:@"empty-main"];
            }
            else {
                // download image and display activity indicator in process
//                [ivSideDish4 setImageWithURL:[NSURL URLWithString:strImageURL] usingActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
                
                [ivSideDish4 setImageWithURL:[NSURL URLWithString:strImageURL] placeholderImage:[UIImage imageNamed:@"gradient-placeholder2"] usingActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            }
            
            if ([[BentoShop sharedInstance] isDishSoldOut:side4DishIndex]) {
                ivBannerSideDish4.hidden = NO;
            }
            else {
                ivBannerSideDish4.hidden = YES;
            }
        }
    }
    else {
        ivSideDish4.image = nil;
        ivSideDish4.hidden = YES;
        lblSideDish4.hidden = YES;
        ivBannerSideDish4.hidden = YES;
    }
}

- (void)onSettings
{
    // get current user info
    NSDictionary *currentUserInfo = [[DataManager shareDataManager] getUserInfo];
    
    SignedInSettingsViewController *signedInSettingsViewController = [[SignedInSettingsViewController alloc] init];
    SignedOutSettingsViewController *signedOutSettingsViewController = [[SignedOutSettingsViewController alloc] init];
    UINavigationController *navC;
    
    // signed in or not?
    if (currentUserInfo == nil)
    {
        // navigate to signed out settings vc
        navC = [[UINavigationController alloc] initWithRootViewController:signedOutSettingsViewController];
        navC.navigationBar.hidden = YES;
        [self.navigationController presentViewController:navC animated:YES completion:nil];
    }
    else
    {
        // navigate to signed in settings vc
        navC = [[UINavigationController alloc] initWithRootViewController:signedInSettingsViewController];
        navC.navigationBar.hidden = YES;
        [self.navigationController presentViewController:navC animated:YES completion:nil];
    }
}

- (void)onOrderStatus {
    
    // if more than one order, show orderlist
//    if () {
//        [self.navigationController presentViewController:[[OrderListViewController alloc] init] animated:YES completion:nil];
//    }
    // if only one order, just show order
//    else {
        [self.navigationController presentViewController:[[OrderStatusViewController alloc] init] animated:YES completion:nil];
//    }
}

- (void)onCart
{
    Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];
    if (currentBento != nil && ![currentBento isEmpty] && ![currentBento isCompleted]) {
        [self showConfirmMsg];
    }
    else {
        [self gotoOrderScreen];
    }
}

- (void)showConfirmMsg
{
    NSString *strText = [[AppStrings sharedInstance] getString:ALERT_BNF_TEXT];
    NSString *strCancel = [[AppStrings sharedInstance] getString:ALERT_BNF_BUTTON_CANCEL];
    NSString *strConfirm = [[AppStrings sharedInstance] getString:ALERT_BNF_BUTTON_CONFIRM];
    MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"" message:strText delegate:self cancelButtonTitle:strCancel otherButtonTitle:strConfirm];
    
    [alertView showInView:self.view];
    alertView = nil;
}

- (void)gotoOrderScreen
{
    // instantiate view controllers
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    DeliveryLocationViewController *deliveryLocationViewController = [storyboard instantiateViewControllerWithIdentifier:@"DeliveryLocationViewController"];
    CompleteOrderViewController *completeOrderViewController = [storyboard instantiateViewControllerWithIdentifier:@"CompleteOrderViewController"];
    
    // user and place info
    NSDictionary *currentUserInfo = [[DataManager shareDataManager] getUserInfo];
    SVPlacemark *placeInfo = [[NSUserDefaults standardUserDefaults] rm_customObjectForKey:@"delivery_location"];
    
    // logged out
    if (currentUserInfo == nil) {
        // no saved address
        if (placeInfo == nil) {
            [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"isFromHomepage"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [self openAccountViewController:[DeliveryLocationViewController class]];
        }
        // has saved address
        else {
            // check if saved address is inside CURRENT service area
            CLLocationCoordinate2D location = placeInfo.location.coordinate;
            
            // outside service area
            if (![[BentoShop sharedInstance] checkLocation:location]) {
                [self openAccountViewController:[DeliveryLocationViewController class]];
            }
            // inside service area
            else {
                [self openAccountViewController:[CompleteOrderViewController class]];
            }
        }
    }
    // logged in
    else {
        // no saved address
        if (placeInfo == nil) {
            [self.navigationController pushViewController:deliveryLocationViewController animated:YES];
        }
        // has saved address
        else {
            // check if saved address is inside CURRENT service area
            CLLocationCoordinate2D location = placeInfo.location.coordinate;
            
            // outside service area
            if (![[BentoShop sharedInstance] checkLocation:location]) {
                [self.navigationController pushViewController:deliveryLocationViewController animated:YES];
            }
            // inisde service area
            else {
                [self.navigationController pushViewController:completeOrderViewController animated:YES];
            }
        }
    }
}

- (void)onAddMainDish
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ChooseMainDishViewController *chooseMainDishViewController = [storyboard instantiateViewControllerWithIdentifier:@"ChooseMainDishViewController"];
    [self.navigationController pushViewController:chooseMainDishViewController animated:YES];
}

- (void)onAddSideDish:(id)sender
{
    UIButton *selectedButton = (UIButton *)sender;
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ChooseSideDishViewController *chooseSideDishViewController = [storyboard instantiateViewControllerWithIdentifier:@"ChooseSideDishViewController"];
    chooseSideDishViewController.sideDishIndex = selectedButton.tag;
    
    [self.navigationController pushViewController:chooseSideDishViewController animated:YES];
}

- (void)onAddAnotherBento
{
    Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];
    if (currentBento != nil && ![currentBento isCompleted])
    {
        if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Lunch"])
            [currentBento completeBento:@"todayLunch"];
        else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Dinner"])
            [currentBento completeBento:@"todayDinner"];
    }
     
    [[BentoShop sharedInstance] addNewBento];
    
    [self updateUI];
}

- (void)onContinue
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ChooseMainDishViewController *chooseMainDishViewController = [storyboard instantiateViewControllerWithIdentifier:@"ChooseMainDishViewController"];
    ChooseSideDishViewController *chooseSideDishViewController = [storyboard instantiateViewControllerWithIdentifier:@"ChooseSideDishViewController"];
    
    Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];
    
    if (currentBento == nil || [currentBento isEmpty]) {
        
        [self.navigationController pushViewController:chooseMainDishViewController animated:YES];
        
    } else if (![currentBento isCompleted]) {
        
        if ([currentBento getMainDish] == 0) {
            
            [self.navigationController pushViewController:chooseMainDishViewController animated:YES];
            
        } else if ([currentBento getSideDish1] == 0) {
            
            chooseSideDishViewController.sideDishIndex = 0;
            [self.navigationController pushViewController:chooseSideDishViewController animated:YES];
            
        } else if ([currentBento getSideDish2] == 0) {
            
            chooseSideDishViewController.sideDishIndex = 1;
            [self.navigationController pushViewController:chooseSideDishViewController animated:YES];
            
        } else if ([currentBento getSideDish3] == 0) {
            
            chooseSideDishViewController.sideDishIndex = 2;
            [self.navigationController pushViewController:chooseSideDishViewController animated:YES];
            
        } else if ([currentBento getSideDish4] == 0) {
            
            chooseSideDishViewController.sideDishIndex = 3;
            [self.navigationController pushViewController:chooseSideDishViewController animated:YES];
        }
        
    } else { /* Completed Bento */
        
        [[BentoShop sharedInstance] saveBentoArray];
        [self gotoOrderScreen];
    }
}

- (void)updateUI
{
//    NSInteger salePrice = [[[BentoShop sharedInstance] getSalePrice] integerValue];
//    NSInteger unitPrice = [[[BentoShop sharedInstance] getUnitPrice] integerValue];
    Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];
    NSString *strTitle;
    
//    /*---On Sale---*/
//    if (salePrice != 0 && salePrice < unitPrice)
//    {
//        lblBanner.hidden = NO;
//        lblBanner.backgroundColor = [UIColor colorWithRed:0.882f green:0.361f blue:0.035f alpha:0.8f];
//        
//        lblBanner.text = [NSString stringWithFormat:@"NOW ONLY $%ld", (long)salePrice];
//        
//        if (currentBento == nil || ![currentBento isCompleted])
//        {
////            strTitle = [NSString stringWithFormat:@"%@ - $%ld", [[AppStrings sharedInstance] getString:BUILD_TITLE], salePrice]; // show price
//            strTitle = [[AppStrings sharedInstance] getString:BUILD_TITLE];
//            btnAddAnotherBento.enabled = NO;
//            btnAddAnotherBento.titleLabel.textColor = [UIColor bentoButtonGray];
//            [btnAddAnotherBento setBackgroundColor:[UIColor colorWithRed:238.0f / 255.0f green:241.0f / 255.0f blue:241.0f / 255.0f alpha:1.0f]];
//        }
//        else
//        {
////            strTitle = [NSString stringWithFormat:@"%@ - $%ld", [[AppStrings sharedInstance] getString:BUILD_ADD_BUTTON], salePrice]; // show price
//            strTitle = [[AppStrings sharedInstance] getString:BUILD_ADD_BUTTON];
//            btnAddAnotherBento.enabled = YES;
//            btnAddAnotherBento.titleLabel.textColor = [UIColor colorWithRed:0.533f green:0.686f blue:0.376f alpha:1.0f];
//            [btnAddAnotherBento setBackgroundColor:[UIColor colorWithRed:243.0f / 255.0f green:245.0f / 255.0f blue:245.0f / 255.0f alpha:1.0f]];
//        }
//        
//        if (strTitle != nil)
//        {
//            // Add Another Bento Button
//            NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:strTitle];
//            float spacing = 1.0f;
//            [attributedTitle addAttribute:NSKernAttributeName
//                                    value:@(spacing)
//                                    range:NSMakeRange(0, [strTitle length])];
//            [btnAddAnotherBento setAttributedTitle:attributedTitle forState:UIControlStateNormal];
//        }
//    }
//    
//    /*---Regular Price---*/
//    else
//    {
        // get current main dishes
        NSMutableArray *mainDishesArray;
        if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Lunch"]) {
            mainDishesArray = [[[BentoShop sharedInstance] getMainDishes:@"todayLunch"] mutableCopy];
        }
        else {
            mainDishesArray = [[[BentoShop sharedInstance] getMainDishes:@"todayDinner"] mutableCopy];
        }
        
        // get main prices
        NSMutableArray *mainPrices = [@[] mutableCopy];
        for (int i = 0; i < mainDishesArray.count; i++) {
            
            NSString *price = mainDishesArray[i][@"price"];
            
            if (price == nil || [price isEqual:[NSNull null]] || [price isEqualToString:@"0"] || [price isEqualToString:@""]) {
                [mainPrices addObject:[[BentoShop sharedInstance] getUnitPrice]]; // default settings.price
            }
            else {
                [mainPrices addObject:price]; // custom price
            }
        }
        
        // sort prices, lowest first
        NSArray *sortedMainPrices = [mainPrices sortedArrayUsingDescriptors: @[[NSSortDescriptor sortDescriptorWithKey:@"doubleValue"ascending:YES]]];
        NSLog(@"main prices: %@", sortedMainPrices);
        
        // get and then check if cents are 0
        double integral;
    
        // check for empty before trying to set to prevent crash in case there is no menu defined for current mode
        if (sortedMainPrices.count != 0 && sortedMainPrices != nil) {
            double cents = modf([sortedMainPrices[0] floatValue], &integral);
            
            // if no cents, just show whole number
            if (cents == 0) {
                lblBanner.text = [NSString stringWithFormat:@"STARTING AT $%.0f", [sortedMainPrices[0] floatValue]];
            }
            // if exists, show normal
            else {
                lblBanner.text = [NSString stringWithFormat:@"STARTING AT $%@", sortedMainPrices[0]];
            }
            
            lblBanner.hidden = NO;
            lblBanner.backgroundColor = [UIColor colorWithRed:0.533f green:0.686f blue:0.376f alpha:1.0f];
            lblBanner.font = [UIFont fontWithName:@"OpenSans-Bold" size:14];
        }
    
        if (currentBento == nil || ![currentBento isCompleted])
        {
//            strTitle = [NSString stringWithFormat:@"%@ - $%ld", [[AppStrings sharedInstance] getString:BUILD_TITLE], unitPrice]; // show price
            strTitle = [[AppStrings sharedInstance] getString:BUILD_TITLE];
            btnAddAnotherBento.enabled = NO;
            btnAddAnotherBento.titleLabel.textColor = [UIColor bentoButtonGray];
            [btnAddAnotherBento setBackgroundColor:[UIColor colorWithRed:238.0f / 255.0f green:241.0f / 255.0f blue:241.0f / 255.0f alpha:1.0f]];
        }
        else
        {
//            strTitle = [NSString stringWithFormat:@"%@ - $%ld", [[AppStrings sharedInstance] getString:BUILD_ADD_BUTTON], unitPrice]; // show price
            strTitle = [[AppStrings sharedInstance] getString:BUILD_ADD_BUTTON];
            btnAddAnotherBento.enabled = YES;
            btnAddAnotherBento.titleLabel.textColor = [UIColor colorWithRed:0.533f green:0.686f blue:0.376f alpha:1.0f];
            [btnAddAnotherBento setBackgroundColor:[UIColor colorWithRed:243.0f / 255.0f green:245.0f / 255.0f blue:245.0f / 255.0f alpha:1.0f]];
        }
        
        if (strTitle != nil)
        {
            // Add Another Bento Button
            NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:strTitle];
            float spacing = 1.0f;
            [attributedTitle addAttribute:NSKernAttributeName
                                    value:@(spacing)
                                    range:NSMakeRange(0, [strTitle length])];
            [btnAddAnotherBento setAttributedTitle:attributedTitle forState:UIControlStateNormal];
        }
//    }
    
    // Bentos
    if ([[BentoShop sharedInstance] getTotalBentoCount] == 0) // no bento
        [[BentoShop sharedInstance] addNewBento]; // add an empty one
    else if ([[BentoShop sharedInstance] getCurrentBento] == nil)
        [[BentoShop sharedInstance] setCurrentBento:[[BentoShop sharedInstance] getLastBento]]; // set current with current one in array
    
    // load bento
    [self loadSelectedDishes];
    
    if ([[BentoShop sharedInstance] getCompletedBentoCount] > 0)
    {
        btnCart.enabled = YES;
        btnCart.selected = YES;
        [btnCart setImage:[UIImage imageNamed:@"mybento_nav_cart_act"] forState:UIControlStateNormal];
    }
    else
    {
        btnCart.enabled = NO;
        btnCart.selected = NO;
    }
    
    /*---Finalize Button---*/
    if ([self isCompletedToMakeMyBento])
    {
        [btnState setBackgroundColor:[UIColor bentoBrandGreen]];
        
        NSMutableString *strTitle = [[[AppStrings sharedInstance] getString:BUILD_COMPLETE_BUTTON] mutableCopy];
        if (strTitle == nil)
            strTitle = [@"FINALIZE ORDER!" mutableCopy];
        
        NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:strTitle];
        float spacing = 1.0f;
        [attributedTitle addAttribute:NSKernAttributeName
                                value:@(spacing)
                                range:NSMakeRange(0, [strTitle length])];
        [btnState setAttributedTitle:attributedTitle forState:UIControlStateNormal];
        attributedTitle = nil;
    }
    else
    {
        [btnState setBackgroundColor:[UIColor bentoButtonGray]];
        
        NSString *strTitle = [[AppStrings sharedInstance] getString:BUILD_CONTINUE_BUTTON];
        if (strTitle != nil)
        {
            NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:strTitle];
            float spacing = 1.0f;
            [attributedTitle addAttribute:NSKernAttributeName
                                    value:@(spacing)
                                    range:NSMakeRange(0, [strTitle length])];
            [btnState setAttributedTitle:attributedTitle forState:UIControlStateNormal];
            attributedTitle = nil;
        }
    }

    NSInteger bentoCount = [[BentoShop sharedInstance] getCompletedBentoCount];
    if (bentoCount > 0)
    {
        lblBadge.text = [NSString stringWithFormat:@"%ld", (long)bentoCount];
        lblBadge.hidden = NO;
    }
    else
    {
        lblBadge.text = @"";
        lblBadge.hidden = YES;
    }
    
    [cvDishes reloadData];
}

- (BOOL)isCompletedToMakeMyBento
{
    Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];
    if (currentBento == nil)
        return NO;
    
    return [currentBento isCompleted];
}

#pragma mark MyAlertViewDelegate

- (void)alertView:(MyAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];
        if (currentBento != nil && ![currentBento isCompleted])
        {
            // 00:00 - 16:29
            if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Lunch"])
                [currentBento completeBento:@"todayLunch"];
            
            // 16:30 - 23:59
            else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Dinner"])
                [currentBento completeBento:@"todayDinner"];
        }
        
        [self gotoOrderScreen];
    }
}

/*------------------------------------------RIGHT SIDE---------------------------------------------*/

#pragma mark RIGHT SIDE

- (void)onUpdatedMenu:(NSNotification *)notification
{
    if (isThereConnection)
    [self updateUI];
}

#pragma mark - COLLECTION VIEW

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 2;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    [self setDishesBySection0MainOrSection1Side:section];
    
    // MAINS
    if (section == 0)
    {
        if (aryMainDishes == nil)
            return 0;
        
        return aryMainDishes.count;
    }
    
    // SIDES
    else if (section == 1)
    {
        if (arySideDishes == nil)
            return 0;
        
        return arySideDishes.count;
    }
    
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PreviewCollectionViewCell *cell = (PreviewCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"PreviewCollectionViewCell"
                                                                                                             forIndexPath:indexPath];
    [cell initView];
    
    if (indexPath.section == 1)
        [cell setSmallDishCell];
    
    // Anything less than iOS 8.0
    if ([[UIDevice currentDevice].systemVersion intValue] < 8)
    {
        [self setDishesBySection0MainOrSection1Side:indexPath.section];
        
        // MAINS
        if (indexPath.section == 0)
        {
            NSDictionary *dishInfo = [aryMainDishes objectAtIndex:indexPath.row];
            [cell setDishInfo:dishInfo];
            
            if (_selectedPathMainRight == indexPath.row)
                [cell setCellState:YES];
            else
                [cell setCellState:NO];
        }
        
        // SIDES
        else if (indexPath.section == 1)
        {
            NSDictionary *dishInfo = [arySideDishes objectAtIndex:indexPath.row];
            [cell setDishInfo:dishInfo];
            
            if (_selectedPathSideRight == indexPath.row)
                [cell setCellState:YES];
            else
                [cell setCellState:NO];
        }
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    PreviewCollectionViewCell *myCell = (PreviewCollectionViewCell *)cell;
    
    [self setDishesBySection0MainOrSection1Side:indexPath.section];
    
    // MAINS
    if (indexPath.section == 0)
    {
        NSDictionary *dishInfo = [aryMainDishes objectAtIndex:indexPath.row];
        [myCell setDishInfo:dishInfo];
        
        if (_selectedPathMainRight == indexPath.row)
            [myCell setCellState:YES];
        else
            [myCell setCellState:NO];
    }
    
    // SIDES
    else if (indexPath.section == 1)
    {
        NSDictionary *dishInfo = [arySideDishes objectAtIndex:indexPath.row];
        [myCell setDishInfo:dishInfo];
        
        if (_selectedPathSideRight == indexPath.row)
            [myCell setCellState:YES];
        else
            [myCell setCellState:NO];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) // Main Dish
        return CGSizeMake(cvDishes.frame.size.width, cvDishes.frame.size.width * 3 / 5);
    else if (indexPath.section == 1) // Side Dish
        return CGSizeMake(cvDishes.frame.size.width / 2, cvDishes.frame.size.width / 2);
    
    return CGSizeMake(0, 0);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        if (_selectedPathMainRight == indexPath.row)
            _selectedPathMainRight = -1;
        else
        {
            _selectedPathMainRight = indexPath.row;
            _selectedPathSideRight = -1;
        }
    }
    else
    {
        if (_selectedPathSideRight == indexPath.row)
            _selectedPathSideRight = -1;
        else
        {
            _selectedPathSideRight = indexPath.row;
            _selectedPathMainRight = -1;
        }
    }
    
    [collectionView reloadData];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

// header
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    if (section == 0 || section == 1)
        return CGSizeMake(cvDishes.frame.size.width, 44);
    
    return CGSizeMake(0, 0);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:UICollectionElementKindSectionHeader])
    {
        UICollectionReusableView *reusableview = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView" forIndexPath:indexPath];
        
        if (reusableview == nil)
            reusableview = [[UICollectionReusableView alloc] initWithFrame:CGRectMake(0, 0, cvDishes.frame.size.width, 44)];
        
        UILabel *label = (UILabel *)[reusableview viewWithTag:1];
        if (label == nil)
        {
            label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, reusableview.frame.size.width, reusableview.frame.size.height)];
            label.tag = 1;
            [reusableview addSubview:label];
        }
        
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont fontWithName:@"OpenSans-Semibold" size:16.0f];
        
        if (indexPath.section == 0)
            label.text = @"Main Dishes";
        else if (indexPath.section == 1)
            label.text = @"Side Dishes";
        
        reusableview.backgroundColor = [UIColor darkGrayColor];
        
        return reusableview;
    }
    
    return nil;
}

#pragma mark Set Arrays

// No need to create method for today dishes array because we're only using todayDinner twice

- (void)setNextMainDishesArray:(NSString *)lunchOrDinner
{
    if ([lunchOrDinner isEqualToString:@"Lunch"])
        aryMainDishes = [[BentoShop sharedInstance] getNextMainDishes:@"nextLunchPreview"];
    
    else if ([lunchOrDinner isEqualToString:@"Dinner"])
        aryMainDishes = [[BentoShop sharedInstance] getNextMainDishes:@"nextDinnerPreview"];
}

- (void)setNextSideDishesArray:(NSString *)lunchOrDinner
{
    if ([lunchOrDinner isEqualToString:@"Lunch"])
        arySideDishes = [[BentoShop sharedInstance] getNextSideDishes:@"nextLunchPreview"];

    else if ([lunchOrDinner isEqualToString:@"Dinner"])
        arySideDishes = [[BentoShop sharedInstance] getNextSideDishes:@"nextDinnerPreview"];
}

- (void)setDishesBySection0MainOrSection1Side:(NSInteger)section
{
    // MAIN DISHES
    if (section == 0)
    {
        /* IS ALL-DAY */
        if ([[BentoShop sharedInstance] isAllDay])
        {
            if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                [self setNextMainDishesArray:@"Lunch"];
            else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                [self setNextMainDishesArray:@"Dinner"];
        }
        
        /* IS NOT ALL-DAY */
        else
        {
            // 00:00 - 16:29
            if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Lunch"])
            {
                if ([[BentoShop sharedInstance] isThereDinnerMenu])
                    aryMainDishes = [[BentoShop sharedInstance] getMainDishes:@"todayDinner"];
                else if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                    [self setNextMainDishesArray:@"Lunch"];
                else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                    [self setNextMainDishesArray:@"Dinner"];
            }
            
            // 16:30 - 23:59
            else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Dinner"])
            {
                if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                    [self setNextMainDishesArray:@"Lunch"];
                else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                    [self setNextMainDishesArray:@"Dinner"];
            }
        }
    }
    
    // SIDE DISHES
    else
    {
        /* IS ALL-DAY */
        if ([[BentoShop sharedInstance] isAllDay])
        {
            if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                [self setNextSideDishesArray:@"Lunch"];
            else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                [self setNextSideDishesArray:@"Dinner"];
        }
        
        /* IS NOT ALL-DAY */
        else
        {
            // 00:00 - 16:29
            if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Lunch"])
            {
                if ([[BentoShop sharedInstance] isThereDinnerMenu])
                    arySideDishes = [[BentoShop sharedInstance] getSideDishes:@"todayDinner"];
                else if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                    [self setNextSideDishesArray:@"Lunch"];
                else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                    [self setNextSideDishesArray:@"Dinner"];
            }
            
            // 16:30 - 23:59
            else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Dinner"])
            {
                if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                    [self setNextSideDishesArray:@"Lunch"];
                else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                    [self setNextSideDishesArray:@"Dinner"];
            }
        }
    }
}

@end





