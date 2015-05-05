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

#import "ServingDinnerViewController.h"

#import "BWTitlePagerView.h"
#import "MyBentoViewController.h"

#import "AppDelegate.h"

#import "ChooseMainDishViewController.h"
#import "ChooseSideDishViewController.h"

#import "CompleteOrderViewController.h"
#import "DeliveryLocationViewController.h"

#import "SignedInSettingsViewController.h"
#import "SignedOutSettingsViewController.h"

#import "MyAlertView.h"

#import "CAGradientLayer+SJSGradients.h"

#import "UIImageView+WebCache.h"

#import "BentoShop.h"
#import "AppStrings.h"
#import "DataManager.h"

#import "SVPlacemark.h"
#import "NSUserDefaults+RMSaveCustomObject.h"

#import <QuartzCore/QuartzCore.h>

@interface ServingDinnerViewController () <MyAlertViewDelegate>

@end

@implementation ServingDinnerViewController
{
    UIScrollView *scrollView;
    
    UILabel *lblBanner;
    UILabel *lblTitle;
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
    
    UIStoryboard *storyboard;
    ChooseMainDishViewController *chooseMainDishViewController;
    ChooseSideDishViewController *chooseSideDishViewController;
    DeliveryLocationViewController *deliveryLocationViewController;
    CompleteOrderViewController *completeOrderViewController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    chooseMainDishViewController = [storyboard instantiateViewControllerWithIdentifier:@"ChooseMainDishViewController"];
    chooseSideDishViewController = [storyboard instantiateViewControllerWithIdentifier:@"ChooseSideDishViewController"];
    deliveryLocationViewController = [storyboard instantiateViewControllerWithIdentifier:@"DeliveryLocationViewController"];
    completeOrderViewController = [storyboard instantiateViewControllerWithIdentifier:@"CompleteOrderViewController"];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
//    [lblTitle setText:[[AppStrings sharedInstance] getString:BUILD_TITLE]];
    
/*---Scroll View---*/
    
    scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 45, SCREEN_WIDTH, SCREEN_HEIGHT)];
    scrollView.contentSize = CGSizeMake(SCREEN_WIDTH*2, SCREEN_HEIGHT-65);
    scrollView.pagingEnabled = YES;
    scrollView.backgroundColor = [UIColor colorWithRed:0.910f green:0.925f blue:0.925f alpha:1.0f];
    scrollView.bounces = NO;
    [self.view addSubview:scrollView];
    
/*---Navigation View---*/
    
    UIView *navigationBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 65)];
    navigationBarView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:navigationBarView];
    
/*---BW Title Pager View---*/
    
    BWTitlePagerView *pagingTitleView = [[BWTitlePagerView alloc] init];
    pagingTitleView.frame = CGRectMake(SCREEN_WIDTH/2-100, 32.5 - 10, 200, 40);
    pagingTitleView.font = [UIFont fontWithName:@"OpenSans-Bold" size:16.0f];
    pagingTitleView.currentTintColor = [UIColor colorWithRed:0.341f green:0.376f blue:0.439f alpha:1.0f];
    [pagingTitleView observeScrollView:scrollView];
    [pagingTitleView addObjects:@[@"Now Serving Dinner", @"Upcoming Lunch"]];
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
    
/*---Banner---*/
    
    lblBanner = [[UILabel alloc] initWithFrame:CGRectMake(0, 65, SCREEN_WIDTH, 28)];
    lblBanner.textAlignment = NSTextAlignmentCenter;
    lblBanner.textColor = [UIColor whiteColor];
    lblBanner.backgroundColor = [UIColor colorWithRed:0.882f green:0.361f blue:0.035f alpha:0.8f];
    lblBanner.hidden = YES;
    lblBanner.center = CGPointMake(self.view.frame.size.width * 5 / 6, 64 + self.view.frame.size.width / 6);
    lblBanner.transform = CGAffineTransformMakeRotation(M_PI / 4);
    lblBanner.font = [UIFont fontWithName:@"OpenSans-Bold" size:16.0f];
    [scrollView addSubview:lblBanner];
    
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
    [viewMainEntree addSubview:lblMainDish];
    
    lblSideDish1 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, viewDishs.frame.size.width / 2 + 2, everyDishHeight + 1)];
    lblSideDish1.textColor = [UIColor whiteColor];
    lblSideDish1.font = [UIFont fontWithName:@"OpenSans-Bold" size:14.0f];
    lblSideDish1.textAlignment = NSTextAlignmentCenter;
    [viewSide1 addSubview:lblSideDish1];

    lblSideDish2 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, viewDishs.frame.size.width / 2 + 1, everyDishHeight + 1)];
    lblSideDish2.textColor = [UIColor whiteColor];
    lblSideDish2.font = [UIFont fontWithName:@"OpenSans-Bold" size:14.0f];
    lblSideDish2.textAlignment = NSTextAlignmentCenter;
    [viewSide2 addSubview:lblSideDish2];

    lblSideDish3 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, viewDishs.frame.size.width / 2 + 2, everyDishHeight + 2)];
    lblSideDish3.textColor = [UIColor whiteColor];
    lblSideDish3.font = [UIFont fontWithName:@"OpenSans-Bold" size:14.0f];
    lblSideDish3.textAlignment = NSTextAlignmentCenter;
    [viewSide3 addSubview:lblSideDish3];
    
    lblSideDish4 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, viewDishs.frame.size.width / 2 + 1, everyDishHeight + 2)];
    lblSideDish4.textColor = [UIColor whiteColor];
    lblSideDish4.font = [UIFont fontWithName:@"OpenSans-Bold" size:14.0f];
    lblSideDish4.textAlignment = NSTextAlignmentCenter;
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
    
/*------*/
    
    NSString *strTitle = [[AppStrings sharedInstance] getString:BUILD_ADD_BUTTON];
    if (strTitle != nil)
    {
        [btnAddAnotherBento setTitle:strTitle forState:UIControlStateNormal];
        NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:strTitle];
        float spacing = 1.0f;
        [attributedTitle addAttribute:NSKernAttributeName
                                value:@(spacing)
                                range:NSMakeRange(0, [strTitle length])];
        
        btnAddAnotherBento.titleLabel.attributedText = attributedTitle;
        
        strTitle = [[AppStrings sharedInstance] getString:BUILD_CONTINUE_BUTTON];
        [btnState setTitle:strTitle forState:UIControlStateNormal];
        attributedTitle = [[NSMutableAttributedString alloc] initWithString:strTitle];
        spacing = 1.0f;
        [attributedTitle addAttribute:NSKernAttributeName
                                value:@(spacing)
                                range:NSMakeRange(0, [strTitle length])];
        
        btnState.titleLabel.attributedText = attributedTitle;
        attributedTitle = nil;
    }
    
    if ([[BentoShop sharedInstance] getTotalBentoCount] == 0)
        [[BentoShop sharedInstance] addNewBento];
    
    lblBadge.hidden = NO;
    btnCart.hidden = NO;
    btnAddAnotherBento.hidden = NO;
    btnState.hidden = NO;
    
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    CLLocationCoordinate2D location = [delegate getCurrentLocation];
    BentoShop *globalShop = [BentoShop sharedInstance];
    if (![globalShop checkLocation:location] && [[DataManager shareDataManager] getUserInfo] == nil)
    {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"nextToBuild"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self.navigationController pushViewController:deliveryLocationViewController animated:NO];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateUI];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus:) name:USER_NOTIFICATION_UPDATED_MENU object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus:) name:USER_NOTIFICATION_UPDATED_STATUS object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewWillDisappear:animated];
}

- (void)onUpdatedStatus:(NSNotification *)notification
{
    if ([[BentoShop sharedInstance] isClosed] && ![[DataManager shareDataManager] isAdminUser])
        [self showSoldoutScreen:[NSNumber numberWithInt:0]];
    else if ([[BentoShop sharedInstance] isSoldOut] && ![[DataManager shareDataManager] isAdminUser])
        [self showSoldoutScreen:[NSNumber numberWithInt:1]];
    else
        [self performSelectorOnMainThread:@selector(updateUI) withObject:nil waitUntilDone:NO];
}

- (void)loadSelectedDishes
{
    NSInteger mainDishIndex = 0;
    NSInteger side1DishIndex = 0;
    NSInteger side2DishIndex = 0;
    NSInteger side3DishIndex = 0;
    NSInteger side4DishIndex = 0;
    
    Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];
    if (currentBento != nil) {
        
        mainDishIndex = [currentBento getMainDish];
        side1DishIndex = [currentBento getSideDish1];
        side2DishIndex = [currentBento getSideDish2];
        side3DishIndex = [currentBento getSideDish3];
        side4DishIndex = [currentBento getSideDish4];
    }
    
    if (mainDishIndex > 0) {
        
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
    } else {
        ivMainDish.image = nil;
        ivMainDish.hidden = YES;
        lblMainDish.hidden = YES;
        ivBannerMainDish.hidden = YES;
    }
    
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
    NSDictionary *currentUserInfo = [[DataManager shareDataManager] getUserInfo];
    SVPlacemark *placeInfo = [[NSUserDefaults standardUserDefaults] rm_customObjectForKey:@"delivery_location"];
    if (currentUserInfo == nil)
    {
        if (placeInfo == nil)
            [self openAccountViewController:[DeliveryLocationViewController class]];
        else
            [self openAccountViewController:[CompleteOrderViewController class]];
    }
    else
    {
        if (placeInfo == nil)
            [self.navigationController pushViewController:deliveryLocationViewController animated:YES];
        else
            [self.navigationController pushViewController:completeOrderViewController animated:YES];
    }
}

- (void)onAddMainDish
{
    [self.navigationController pushViewController:chooseMainDishViewController animated:YES];
}

- (void)onAddSideDish:(id)sender
{
    UIButton *selectedButton = (UIButton *)sender;
    
    chooseSideDishViewController.sideDishIndex = selectedButton.tag;
    
    [self.navigationController pushViewController:chooseSideDishViewController animated:YES];
}

- (void)onAddAnotherBento
{
    Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];
    if (currentBento != nil && ![currentBento isCompleted])
        [currentBento completeBento];
    
    [[BentoShop sharedInstance] addNewBento];
    
    [self updateUI];
}

- (void)onContinue
{
    Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];
    
    if (currentBento == nil || [currentBento isEmpty]) {
        
        [self.navigationController pushViewController:chooseMainDishViewController animated:YES];
        
    } else if (![currentBento isCompleted]) {
        
        if ([currentBento getMainDish] == 0)
            [self.navigationController pushViewController:chooseMainDishViewController animated:YES];
        else if ([currentBento getSideDish1] == 0)
            [self.navigationController pushViewController:chooseSideDishViewController animated:YES];
        else if ([currentBento getSideDish2] == 0)
            [self.navigationController pushViewController:chooseSideDishViewController animated:YES];
        else if ([currentBento getSideDish3] == 0)
            [self.navigationController pushViewController:chooseSideDishViewController animated:YES];
        else if ([currentBento getSideDish4] == 0)
            [self.navigationController pushViewController:chooseSideDishViewController animated:YES];
        
    } else { /* Completed Bento */
        
        [[BentoShop sharedInstance] saveBentoArray];
        [self gotoOrderScreen];
    }
}

- (void)updateUI
{
    NSInteger salePrice = [[AppStrings sharedInstance] getInteger:SALE_PRICE];
    NSInteger unitPrice = [[AppStrings sharedInstance] getInteger:ABOUT_PRICE];
    
    lblBanner.hidden = YES;
    if (salePrice != 0 && salePrice < unitPrice)
    {
        lblBanner.hidden = NO;
        lblBanner.text = [NSString stringWithFormat:@"NOW ONLY $%ld", (long)salePrice];
    }
    
    if ([[BentoShop sharedInstance] getTotalBentoCount] == 0)
        [[BentoShop sharedInstance] addNewBento];
    else if ([[BentoShop sharedInstance] getCurrentBento] == nil)
        [[BentoShop sharedInstance] setCurrentBento:[[BentoShop sharedInstance] getLastBento]];
    
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
    
    if ([self isCompletedToMakeMyBento])
    {
        [btnState setBackgroundColor:[UIColor colorWithRed:135.0f / 255.0f green:178.0f / 255.0f blue:96.0f / 255.0f alpha:1.0f]];
        
        NSString *strTitle = [[AppStrings sharedInstance] getString:BUILD_COMPLETE_BUTTON];
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
    
    Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];
    if (currentBento == nil || ![currentBento isCompleted])
    {
        btnAddAnotherBento.enabled = NO;
        [btnAddAnotherBento setBackgroundColor:[UIColor colorWithRed:238.0f / 255.0f green:241.0f / 255.0f blue:241.0f / 255.0f alpha:1.0f]];
    }
    else
    {
        btnAddAnotherBento.enabled = YES;
        [btnAddAnotherBento setBackgroundColor:[UIColor colorWithRed:243.0f / 255.0f green:245.0f / 255.0f blue:245.0f / 255.0f alpha:1.0f]];
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
            [currentBento completeBento];
        
        [self gotoOrderScreen];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
