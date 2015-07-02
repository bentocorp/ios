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

#import "BentoShop.h"
#import "AppStrings.h"
#import "DataManager.h"

#import "SVPlacemark.h"
#import "NSUserDefaults+RMSaveCustomObject.h"

#import <QuartzCore/QuartzCore.h>
#import "JGProgressHUD.h"

@interface CustomBentoViewController () <MyAlertViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@end

@implementation CustomBentoViewController
{
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
    
    // Upcoming Lunch
    UILabel *lblTitle;
    UICollectionView *cvDishes;
    
    NSIndexPath *_selectedPath;
    NSInteger hour;
    int weekday;
    
    BWTitlePagerView *pagingTitleView;
    
    JGProgressHUD *loadingHUD;
    BOOL isThereConnection;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // initialize to yes
    isThereConnection = YES;
    
    self.view.backgroundColor = [UIColor whiteColor];
    
/*---Scroll View---*/
    
    scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 45, SCREEN_WIDTH, SCREEN_HEIGHT)];
    scrollView.contentSize = CGSizeMake(SCREEN_WIDTH*2, SCREEN_HEIGHT-65);
    scrollView.pagingEnabled = YES;
    scrollView.backgroundColor = [UIColor colorWithRed:0.910f green:0.925f blue:0.925f alpha:1.0f];
    scrollView.bounces = NO;
    [self.view addSubview:scrollView];
    
/*---Navigation View---*/
    
    navigationBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 65)];
    navigationBarView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:navigationBarView];
    
/*---BW Title Pager View---*/
    
    NSString *currentMenuTitle;
    NSString *nextMenuTitle;
    
    
    /* All-DAY */
    if ([[BentoShop sharedInstance] isAllDay])
    {
        // Left Side
        if([[BentoShop sharedInstance] isThereLunchMenu])
            currentMenuTitle = @"Serving All-day Lunch";
        else if ([[BentoShop sharedInstance] isThereDinnerMenu])
            currentMenuTitle = @"Serving All-day Dinner";
        
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
            else if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                nextMenuTitle = [NSString stringWithFormat:@"%@'s Lunch Menu", [[BentoShop sharedInstance] getNextMenuWeekdayString]];
            else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                nextMenuTitle = [NSString stringWithFormat:@"%@'s Dinner Menu", [[BentoShop sharedInstance] getNextMenuWeekdayString]];
        }
        // 16:30 - 23:59 Dinner
        else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Dinner"])
        {
            // Left Side
            if ([[BentoShop sharedInstance] isThereDinnerMenu])
                currentMenuTitle = @"Now Serving Dinner";
            
            // Right Side
            if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                nextMenuTitle = [NSString stringWithFormat:@"%@'s Lunch Menu", [[BentoShop sharedInstance] getNextMenuWeekdayString]];
            else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                nextMenuTitle = [NSString stringWithFormat:@"%@'s Dinner Menu", [[BentoShop sharedInstance] getNextMenuWeekdayString]];
        }
    }
    
    // just in case
    if (currentMenuTitle == nil)
        currentMenuTitle = @"No Available Menu";
    if (nextMenuTitle == nil)
        nextMenuTitle = @"No Available Menu";
    
    pagingTitleView = [[BWTitlePagerView alloc] init];
    pagingTitleView.frame = CGRectMake(SCREEN_WIDTH/2-100, 32.5 - 10, 200, 40);
    pagingTitleView.font = [UIFont fontWithName:@"OpenSans-Bold" size:16.0f];
    pagingTitleView.currentTintColor = [UIColor colorWithRed:0.341f green:0.376f blue:0.439f alpha:1.0f];
    [pagingTitleView observeScrollView:scrollView];
    [pagingTitleView addObjects:@[currentMenuTitle, nextMenuTitle]];
    [navigationBarView addSubview:pagingTitleView];
    
/*---Line Separator---*/
    
    UIView *longLineSepartor1 = [[UIView alloc] initWithFrame:CGRectMake(0, 65, SCREEN_WIDTH, 1)];
    longLineSepartor1.backgroundColor = [UIColor colorWithRed:0.827f green:0.835f blue:0.835f alpha:1.0f];
    [navigationBarView addSubview:longLineSepartor1];
    
/*---Back button---*/
    
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
    [btnAddAnotherBento setTitleColor:[UIColor colorWithRed:0.533f green:0.686f blue:0.376f alpha:1.0f] forState:UIControlStateNormal];
    btnAddAnotherBento.titleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:12.0f];
    [btnAddAnotherBento addTarget:self action:@selector(onAddAnotherBento) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:btnAddAnotherBento];
    
/*---Button State---*/
    
    btnState = [[UIButton alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT-45-65, SCREEN_WIDTH, 45)];
    [btnState setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btnState setBackgroundColor:[UIColor colorWithRed:0.475f green:0.522f blue:0.569f alpha:1.0f]];
    btnState.backgroundColor = [UIColor blackColor];
    btnState.titleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:13.0f];
    [btnState addTarget:self action:@selector(onContinue) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:btnState];
    
/*---Banner---*/
    
    lblBanner = [[UILabel alloc] initWithFrame:CGRectMake(0, 65, SCREEN_WIDTH, 28)];
    lblBanner.textAlignment = NSTextAlignmentCenter;
    lblBanner.textColor = [UIColor whiteColor];
    lblBanner.backgroundColor = [UIColor colorWithRed:0.882f green:0.361f blue:0.035f alpha:0.8f];
    lblBanner.hidden = YES;
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
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
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
    NSLog(@"current hour - %ld", hour);
    
    // Sunday = 1, Saturday = 7
    weekday = (int)[[calendar components:NSCalendarUnitWeekday fromDate:currentDate] weekday];
    NSLog(@"today is - %ld", (long)weekday);
    
    _selectedPath = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateUI];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus:) name:USER_NOTIFICATION_UPDATED_MENU object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus:) name:USER_NOTIFICATION_UPDATED_STATUS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedMenu:) name:USER_NOTIFICATION_UPDATED_NEXTMENU object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noConnection) name:@"networkError" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yesConnection) name:@"networkConnected" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkCurrentMode) name:@"enteredForeground" object:nil];
}

- (void)noConnection
{
    isThereConnection = NO;
    
    if (loadingHUD == nil)
    {
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

//- (void)preloadCheckCurrentMode
//{
//
//    [[BentoShop sharedInstance] refreshStop]; 
//    // so date string can refresh first
//    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(checkCurrentMode) userInfo:nil repeats:NO];
//}

- (void)checkCurrentMode
{
    if ([[BentoShop sharedInstance] didModeOrDateChange])
    {
        [(UINavigationController *)self.presentingViewController popToRootViewControllerAnimated:NO];
        [self dismissViewControllerAnimated:YES completion:nil];
        
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewWillDisappear:animated];
}

- (void)dealloc
{
    @try
    {
        [scrollView removeObserver:pagingTitleView.self forKeyPath:@"contentOffset" context:nil];
    }
    @catch(id anException)
    {
        //do nothing, obviously it wasn't attached because an exception was thrown
    }
}

- (void)onUpdatedStatus:(NSNotification *)notification
{
    if (isThereConnection)
    {
        if ([[BentoShop sharedInstance] isClosed] && ![[DataManager shareDataManager] isAdminUser])
        {
            [self showSoldoutScreen:[NSNumber numberWithInt:0]];
        }
        else if ([[BentoShop sharedInstance] isSoldOut] && ![[DataManager shareDataManager] isAdminUser])
        {
            [self showSoldoutScreen:[NSNumber numberWithInt:1]];
        }
        else
        {
            [self performSelectorOnMainThread:@selector(updateUI) withObject:nil waitUntilDone:NO];
        }
    }
}

- (void)loadSelectedDishes
{
    NSMutableArray *aryBentos = [[NSMutableArray alloc] init];
    for (NSInteger index = 0; index < [[BentoShop sharedInstance] getTotalBentoCount]; index++)
    {
        Bento *bento = [[BentoShop sharedInstance] getBento:index];
        if ([bento isCompleted])
            [aryBentos addObject:bento];
    }
    
    NSLog(@"TOTAL BENTOS: %ld", [[BentoShop sharedInstance] getTotalBentoCount]);
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
    if (mainDishIndex > 0)
    {
        ivMainDish.hidden = NO;
        lblMainDish.hidden = NO;
        
        NSDictionary *dishInfo = [[BentoShop sharedInstance] getMainDish:mainDishIndex];
        if (dishInfo != nil)
        {
            lblMainDish.text = [[dishInfo objectForKey:@"name"] uppercaseString];
            
            NSString *strImageURL = [dishInfo objectForKey:@"image1"];
            [ivMainDish sd_setImageWithURL:[NSURL URLWithString:strImageURL] placeholderImage:[UIImage imageNamed:@"sample"]];
            
            if ([[BentoShop sharedInstance] isDishSoldOut:mainDishIndex])
                ivBannerMainDish.hidden = NO;
            else
                ivBannerMainDish.hidden = YES;
        }
    }
    else
    {
        ivMainDish.image = nil;
        ivMainDish.hidden = YES;
        lblMainDish.hidden = YES;
        ivBannerMainDish.hidden = YES;
    }
    
/*-Side 1-*/
    if (side1DishIndex > 0)
    {
        ivSideDish1.hidden = NO;
        lblSideDish1.hidden = NO;
    
        NSDictionary *dishInfo = [[BentoShop sharedInstance] getSideDish:side1DishIndex];
        if (dishInfo != nil)
        {
            lblSideDish1.text = [[dishInfo objectForKey:@"name"] uppercaseString];
            
            NSString *strImageURL = [dishInfo objectForKey:@"image1"];
            [ivSideDish1 sd_setImageWithURL:[NSURL URLWithString:strImageURL] placeholderImage:[UIImage imageNamed:@"sample"]];
            
            if ([[BentoShop sharedInstance] isDishSoldOut:side1DishIndex])
                ivBannerSideDish1.hidden = NO;
            else
                ivBannerSideDish1.hidden = YES;
        }
    }
    else
    {
        ivSideDish1.image = nil;
        ivSideDish1.hidden = YES;
        lblSideDish1.hidden = YES;
        ivBannerSideDish1.hidden = YES;
    }
    
/*-Side 2-*/
    if (side2DishIndex > 0)
    {
        ivSideDish2.hidden = NO;
        lblSideDish2.hidden = NO;
        
        NSDictionary *dishInfo = [[BentoShop sharedInstance] getSideDish:side2DishIndex];
        if (dishInfo != nil)
        {
            lblSideDish2.text = [[dishInfo objectForKey:@"name"] uppercaseString];
            
            NSString *strImageURL = [dishInfo objectForKey:@"image1"];
            [ivSideDish2 sd_setImageWithURL:[NSURL URLWithString:strImageURL] placeholderImage:[UIImage imageNamed:@"sample"]];
            
            if ([[BentoShop sharedInstance] isDishSoldOut:side2DishIndex])
                ivBannerSideDish2.hidden = NO;
            else
                ivBannerSideDish2.hidden = YES;
        }
    }
    else
    {
        ivSideDish2.image = nil;
        ivSideDish2.hidden = YES;
        lblSideDish2.hidden = YES;
        ivBannerSideDish2.hidden = YES;
    }

/*-Side 3-*/
    if (side3DishIndex > 0)
    {
        ivSideDish3.hidden = NO;
        lblSideDish3.hidden = NO;
        
        NSDictionary *dishInfo = [[BentoShop sharedInstance] getSideDish:side3DishIndex];
        if (dishInfo != nil)
        {
            lblSideDish3.text = [[dishInfo objectForKey:@"name"] uppercaseString];
            
            NSString *strImageURL = [dishInfo objectForKey:@"image1"];
            [ivSideDish3 sd_setImageWithURL:[NSURL URLWithString:strImageURL] placeholderImage:[UIImage imageNamed:@"sample"]];
            
            if ([[BentoShop sharedInstance] isDishSoldOut:side3DishIndex])
                ivBannerSideDish3.hidden = NO;
            else
                ivBannerSideDish3.hidden = YES;
        }
    }
    else
    {
        ivSideDish3.image = nil;
        ivSideDish3.hidden = YES;
        lblSideDish3.hidden = YES;
        ivBannerSideDish3.hidden = YES;
    }
    
/*-Side 4-*/
    if (side4DishIndex > 0)
    {
        ivSideDish4.hidden = NO;
        lblSideDish4.hidden = NO;
        
        
        NSDictionary *dishInfo = [[BentoShop sharedInstance] getSideDish:side4DishIndex];
        if (dishInfo != nil)
        {
            lblSideDish4.text = [[dishInfo objectForKey:@"name"] uppercaseString];
            
            NSString *strImageURL = [dishInfo objectForKey:@"image1"];
            [ivSideDish4 sd_setImageWithURL:[NSURL URLWithString:strImageURL] placeholderImage:[UIImage imageNamed:@"sample"]];
        }
        
        if ([[BentoShop sharedInstance] isDishSoldOut:side4DishIndex])
            ivBannerSideDish4.hidden = NO;
        else
            ivBannerSideDish4.hidden = YES;
    }
    else
    {
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
    if (currentUserInfo == nil) {
        
        // navigate to signed out settings vc
        navC = [[UINavigationController alloc] initWithRootViewController:signedOutSettingsViewController];
        navC.navigationBar.hidden = YES;
        [self.navigationController presentViewController:navC animated:YES completion:nil];
        
    } else {
        
        // navigate to signed in settings vc
        navC = [[UINavigationController alloc] initWithRootViewController:signedInSettingsViewController];
        navC.navigationBar.hidden = YES;
        [self.navigationController presentViewController:navC animated:YES completion:nil];
    }
}

- (void)onCart
{
    Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];
    if (currentBento != nil && ![currentBento isEmpty] && ![currentBento isCompleted])
        [self showConfirmMsg];
    else
        [self gotoOrderScreen];
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
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    DeliveryLocationViewController *deliveryLocationViewController = [storyboard instantiateViewControllerWithIdentifier:@"DeliveryLocationViewController"];
    CompleteOrderViewController *completeOrderViewController = [storyboard instantiateViewControllerWithIdentifier:@"CompleteOrderViewController"];
    
    NSDictionary *currentUserInfo = [[DataManager shareDataManager] getUserInfo];
    SVPlacemark *placeInfo = [[NSUserDefaults standardUserDefaults] rm_customObjectForKey:@"delivery_location"];
    
    if (currentUserInfo == nil)
    {
        if (placeInfo == nil)
        {
            [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"isFromHomepage"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [self openAccountViewController:[DeliveryLocationViewController class]];
        }
        else // if bento user already has saved address
        {
            // check if saved address is within CURRENT service area
            CLLocationCoordinate2D location = placeInfo.location.coordinate;
            
            // not within service area
            if (![[BentoShop sharedInstance] checkLocation:location])
                [self openAccountViewController:[DeliveryLocationViewController class]];
            
            // within service area
            else
                [self openAccountViewController:[CompleteOrderViewController class]];
        }
    }
    else
    {
        if (placeInfo == nil)
            [self.navigationController pushViewController:deliveryLocationViewController animated:YES];
        else
        {
            // check if saved address is within CURRENT service area
            CLLocationCoordinate2D location = placeInfo.location.coordinate;
            
            // not within service area
            if (![[BentoShop sharedInstance] checkLocation:location])
                [self.navigationController pushViewController:deliveryLocationViewController animated:YES];
                
            // within service area
            else
                [self.navigationController pushViewController:completeOrderViewController animated:YES];
            
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
    [cvDishes reloadData];
    
    NSInteger salePrice = [[AppStrings sharedInstance] getInteger:SALE_PRICE];
    NSInteger unitPrice = [[AppStrings sharedInstance] getInteger:ABOUT_PRICE];
    Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];
    NSString *strTitle;
    
    /*---On Sale---*/
    if (salePrice != 0 && salePrice < unitPrice)
    {
        lblBanner.hidden = NO;
        lblBanner.text = [NSString stringWithFormat:@"NOW ONLY $%ld", (long)salePrice];
        
        if (currentBento == nil || ![currentBento isCompleted])
        {
//            strTitle = [NSString stringWithFormat:@"%@ - $%ld", [[AppStrings sharedInstance] getString:BUILD_TITLE], salePrice]; // show price
            strTitle = [[AppStrings sharedInstance] getString:BUILD_TITLE];
            btnAddAnotherBento.enabled = NO;
            [btnAddAnotherBento setBackgroundColor:[UIColor colorWithRed:238.0f / 255.0f green:241.0f / 255.0f blue:241.0f / 255.0f alpha:1.0f]];
        }
        else
        {
//            strTitle = [NSString stringWithFormat:@"%@ - $%ld", [[AppStrings sharedInstance] getString:BUILD_ADD_BUTTON], salePrice]; // show price
            strTitle = [[AppStrings sharedInstance] getString:BUILD_ADD_BUTTON];
            btnAddAnotherBento.enabled = YES;
            [btnAddAnotherBento setBackgroundColor:[UIColor colorWithRed:243.0f / 255.0f green:245.0f / 255.0f blue:245.0f / 255.0f alpha:1.0f]];
        }
        
        if (strTitle != nil)
        {
            // Add Another Bento Button
            [btnAddAnotherBento setTitle:strTitle forState:UIControlStateNormal];
            NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:strTitle];
            float spacing = 1.0f;
            [attributedTitle addAttribute:NSKernAttributeName
                                    value:@(spacing)
                                    range:NSMakeRange(0, [strTitle length])];
            btnAddAnotherBento.titleLabel.attributedText = attributedTitle;
        }
    }
    /*---Regular Price---*/
    else
    {
        lblBanner.hidden = YES;
        
        if (currentBento == nil || ![currentBento isCompleted])
        {
//            strTitle = [NSString stringWithFormat:@"%@ - $%ld", [[AppStrings sharedInstance] getString:BUILD_TITLE], unitPrice]; // show price
            strTitle = [[AppStrings sharedInstance] getString:BUILD_TITLE];
            btnAddAnotherBento.enabled = NO;
            [btnAddAnotherBento setBackgroundColor:[UIColor colorWithRed:238.0f / 255.0f green:241.0f / 255.0f blue:241.0f / 255.0f alpha:1.0f]];
        }
        else
        {
//            strTitle = [NSString stringWithFormat:@"%@ - $%ld", [[AppStrings sharedInstance] getString:BUILD_ADD_BUTTON], unitPrice]; // show price
            strTitle = [[AppStrings sharedInstance] getString:BUILD_ADD_BUTTON];
            btnAddAnotherBento.enabled = YES;
            [btnAddAnotherBento setBackgroundColor:[UIColor colorWithRed:243.0f / 255.0f green:245.0f / 255.0f blue:245.0f / 255.0f alpha:1.0f]];
        }
        
        if (strTitle != nil)
        {
            // Add Another Bento Button
            [btnAddAnotherBento setTitle:strTitle forState:UIControlStateNormal];
            NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:strTitle];
            float spacing = 1.0f;
            [attributedTitle addAttribute:NSKernAttributeName
                                    value:@(spacing)
                                    range:NSMakeRange(0, [strTitle length])];
            btnAddAnotherBento.titleLabel.attributedText = attributedTitle;
        }
    }
    
    
    // Bentos
    if ([[BentoShop sharedInstance] getTotalBentoCount] == 0) // no bento
        [[BentoShop sharedInstance] addNewBento]; // add an empty one
    else if ([[BentoShop sharedInstance] getCurrentBento] == nil)
        [[BentoShop sharedInstance] setCurrentBento:[[BentoShop sharedInstance] getLastBento]]; // set current with current one in array
    
    [self loadSelectedDishes]; // load bento
    
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
        [btnState setBackgroundColor:[UIColor colorWithRed:135.0f / 255.0f green:178.0f / 255.0f blue:96.0f / 255.0f alpha:1.0f]];
        
        
        NSMutableString *strTitle = [[[AppStrings sharedInstance] getString:BUILD_COMPLETE_BUTTON] mutableCopy];
        if (strTitle == nil)
        {
            strTitle = [@"FINALIZE ORDER!" mutableCopy];
        }
            
        [btnState setTitle:strTitle forState:UIControlStateNormal];
        NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:strTitle];
        float spacing = 1.0f;
        [attributedTitle addAttribute:NSKernAttributeName
                                value:@(spacing)
                                range:NSMakeRange(0, [strTitle length])];
        
        btnState.titleLabel.attributedText = attributedTitle;
        attributedTitle = nil;
    }
    else
    {
        [btnState setBackgroundColor:[UIColor colorWithRed:122.0f / 255.0f green:133.0f / 255.0f blue:146.0f / 255.0f alpha:1.0f]];
        
        NSString *strTitle = [[AppStrings sharedInstance] getString:BUILD_CONTINUE_BUTTON];
        if (strTitle != nil)
        {
            [btnState setTitle:strTitle forState:UIControlStateNormal];
            NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:strTitle];
            float spacing = 1.0f;
            [attributedTitle addAttribute:NSKernAttributeName
                                    value:@(spacing)
                                    range:NSMakeRange(0, [strTitle length])];
            
            btnState.titleLabel.attributedText = attributedTitle;
            attributedTitle = nil;
        }
    }
    
    //    if (self.currentBento == nil)
    {
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
    }
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
            if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Lunch"])
                [currentBento completeBento:@"todayLunch"];
            else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Dinner"])
                [currentBento completeBento:@"todayDinner"];
        }
        
        [self gotoOrderScreen];
    }
}

/*------------------------------------------Next Menu Preview---------------------------------------------*/

- (void)onUpdatedMenu:(NSNotification *)notification
{
    if (isThereConnection)
    [self updateUI];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 2;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (section == 0)
    {
        NSArray *aryMainDishes;
        
        if ([[BentoShop sharedInstance] isAllDay])
        {
            if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                aryMainDishes = [[BentoShop sharedInstance] getNextMainDishes:@"nextLunchPreview"];
            else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                aryMainDishes = [[BentoShop sharedInstance] getNextMainDishes:@"nextDinnerPreview"];
        }
        else
        {
            if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Lunch"])
            {
                if ([[BentoShop sharedInstance] isThereDinnerMenu])
                    aryMainDishes = [[BentoShop sharedInstance] getMainDishes:@"todayDinner"];
                else if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                    aryMainDishes = [[BentoShop sharedInstance] getNextMainDishes:@"nextLunchPreview"];
                else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                    aryMainDishes = [[BentoShop sharedInstance] getNextMainDishes:@"nextDinnerPreview"];
            }
            else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Dinner"])
            {
                if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                    aryMainDishes = [[BentoShop sharedInstance] getNextMainDishes:@"nextLunchPreview"];
                else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                    aryMainDishes = [[BentoShop sharedInstance] getNextMainDishes:@"nextDinnerPreview"];
            }
        }
        
        if (aryMainDishes == nil)
            return 0;
        
        return aryMainDishes.count;
    }
    else if (section == 1)
    {
        NSArray *arySideDishes;
        
        if ([[BentoShop sharedInstance] isAllDay])
        {
            if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                arySideDishes = [[BentoShop sharedInstance] getNextSideDishes:@"nextLunchPreview"];
            else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                arySideDishes = [[BentoShop sharedInstance] getNextSideDishes:@"nextDinnerPreview"];
        }
        else
        {
            if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Lunch"])
            {
                if ([[BentoShop sharedInstance] isThereDinnerMenu])
                    arySideDishes = [[BentoShop sharedInstance] getSideDishes:@"todayDinner"];
                else if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                    arySideDishes = [[BentoShop sharedInstance] getNextSideDishes:@"nextLunchPreview"];
                else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                    arySideDishes = [[BentoShop sharedInstance] getNextSideDishes:@"nextDinnerPreview"];
            }
            else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Dinner"])
            {
                if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                    arySideDishes = [[BentoShop sharedInstance] getNextSideDishes:@"nextLunchPreview"];
                else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                    arySideDishes = [[BentoShop sharedInstance] getNextSideDishes:@"nextDinnerPreview"];
            }
        }
        
        if (arySideDishes == nil)
            return 0;
        
        return arySideDishes.count;
    }
    
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PreviewCollectionViewCell *cell = (PreviewCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"PreviewCollectionViewCell" forIndexPath:indexPath];
    
    [cell initView];
    
    if (indexPath.section == 1)
        [cell setSmallDishCell];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    PreviewCollectionViewCell *myCell = (PreviewCollectionViewCell *)cell;
    
    if (indexPath.section == 0) // Main Dish
    {
        NSArray *aryMainDishes;
        
        if ([[BentoShop sharedInstance] isAllDay])
        {
            if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                aryMainDishes = [[BentoShop sharedInstance] getNextMainDishes:@"nextLunchPreview"];
            else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                aryMainDishes = [[BentoShop sharedInstance] getNextMainDishes:@"nextDinnerPreview"];
        }
        else
        {
            if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Lunch"])
            {
                if ([[BentoShop sharedInstance] isThereDinnerMenu])
                    aryMainDishes = [[BentoShop sharedInstance] getMainDishes:@"todayDinner"];
                else if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                    aryMainDishes = [[BentoShop sharedInstance] getNextMainDishes:@"nextLunchPreview"];
                else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                    aryMainDishes = [[BentoShop sharedInstance] getNextMainDishes:@"nextDinnerPreview"];
            }
            else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Dinner"])
            {
                if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                    aryMainDishes = [[BentoShop sharedInstance] getNextMainDishes:@"nextLunchPreview"];
                else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                    aryMainDishes = [[BentoShop sharedInstance] getNextMainDishes:@"nextDinnerPreview"];
            }
        }
        
        NSDictionary *dishInfo = [aryMainDishes objectAtIndex:indexPath.row];
        [myCell setDishInfo:dishInfo];
    }
    else if (indexPath.section == 1) // Side Dish
    {
        NSArray *arySideDishes = [[BentoShop sharedInstance] getNextSideDishes:@"nextLunchPreview"];
        
        if ([[BentoShop sharedInstance] isAllDay])
        {
            if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                arySideDishes = [[BentoShop sharedInstance] getNextSideDishes:@"nextLunchPreview"];
            else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                arySideDishes = [[BentoShop sharedInstance] getNextSideDishes:@"nextDinnerPreview"];
        }
        else
        {
            if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Lunch"])
            {
                if ([[BentoShop sharedInstance] isThereDinnerMenu])
                    arySideDishes = [[BentoShop sharedInstance] getSideDishes:@"todayDinner"];
                else if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                    arySideDishes = [[BentoShop sharedInstance] getNextSideDishes:@"nextLunchPreview"];
                else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                    arySideDishes = [[BentoShop sharedInstance] getNextSideDishes:@"nextDinnerPreview"];
            }
            else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Dinner"])
            {
                if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                    arySideDishes = [[BentoShop sharedInstance] getNextSideDishes:@"nextLunchPreview"];
                else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                    arySideDishes = [[BentoShop sharedInstance] getNextSideDishes:@"nextDinnerPreview"];
            }
        }
        
        NSDictionary *dishInfo = [arySideDishes objectAtIndex:indexPath.row];
        [myCell setDishInfo:dishInfo];
    }
    
    if (_selectedPath != nil && _selectedPath == indexPath)
    {
        [myCell setCellState:YES];
    }
    else
    {
        [myCell setCellState:NO];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) // Main Dish
    {
        return CGSizeMake(cvDishes.frame.size.width, cvDishes.frame.size.width * 3 / 5);
    }
    else if (indexPath.section == 1) // Side Dish
    {
        return CGSizeMake(cvDishes.frame.size.width / 2, cvDishes.frame.size.width / 2);
    }
    
    return CGSizeMake(0, 0);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (_selectedPath == indexPath)
    {
        _selectedPath = nil;
    }
    else
    {
        _selectedPath = indexPath;
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
    {
        return CGSizeMake(cvDishes.frame.size.width, 44);
    }
    
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

@end
