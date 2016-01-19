//
//  FiveHomeViewController.m
//  Bento
//
//  Created by Joseph Lau on 1/13/16.
//  Copyright © 2016 bentonow. All rights reserved.
//

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

#import "FiveHomeViewController.h"

#import "FiveCustomViewController.h"
#import "CustomViewController.h"
#import "MenuPreviewViewController.h"

#import "AppDelegate.h"

#import "ChooseMainDishViewController.h"
#import "ChooseSideDishViewController.h"

#import "CompleteOrderViewController.h"
#import "DeliveryLocationViewController.h"

#import "SignedInSettingsViewController.h"
#import "SignedOutSettingsViewController.h"

#import "MyAlertView.h"

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

#import "AddonsViewController.h"
#import "AddonList.h"

@interface FiveHomeViewController () <CustomViewControllerDelegate, FiveCustomViewControllerDelegate, MyAlertViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic) CustomViewController *fourCustomVC;
@property (nonatomic) FiveCustomViewController *customVC;
@property (nonatomic) MenuPreviewViewController *menuPreviewVC;
@property (nonatomic) OrderMode orderMode;

@end

@implementation FiveHomeViewController
{
    AddonsViewController *addonsVC;
    JGProgressHUD *loadingHUD;
    
    UILabel *dinnerTitleLabel;
    
    BOOL isThereConnection;
    
    NSArray *myDatabase;
    NSString *menuOnDemand;
    NSString *timeOnDemand;
    NSString *menuOrderAhead;
    NSString *timeOrderAhead;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // order ahead mock
    myDatabase = @[
                    @[@"Today, Dinner", @"Tomorrow, Lunch", @"Tomorrow, Dinner", @"Jan 16, Lunch", @"Jan 16, Dinner"],
                    @[@"11:00-11:30 AM", @"11:30-12:00 PM", @"12:00-12:30 PM", @"12:30-1:00 PM (sold-out)", @"1:00-1:30 PM", @"1:30-2:00 PM", @"5:00-5:30 PM", @"5:30-6:00 PM"]
                    ];
    
    // mock
//    [self enableOnDemand];
    [self enableOrderAhead];
    
    isThereConnection = YES;
    
    /*---Custom---*/
    if ([[BentoShop sharedInstance] is4PodMode]) {
        self.fourCustomVC = [[CustomViewController alloc] init];
        [self addChildViewController:self.fourCustomVC];
        [self.bgView addSubview:self.fourCustomVC.view];
        [self.fourCustomVC didMoveToParentViewController:self];
        self.fourCustomVC.delegate = self;
    }
    else {
        self.customVC = [[FiveCustomViewController alloc] init];
        [self addChildViewController:self.customVC];
        [self.bgView addSubview:self.customVC.view];
        [self.customVC didMoveToParentViewController:self];
        self.customVC.delegate = self;
    }
    
    /*---Picker View---*/
    self.pickerButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    
    /*---ASAP---*/
    self.asapDescriptionLabel.lineBreakMode = NSLineBreakByWordWrapping; // do i really need this?
    [self.asapDescriptionLabel sizeToFit];
    self.asapViewHeightConstraint.constant = self.asapDescriptionLabel.frame.size.height + 60; //
    
    /*---Count Badge---*/
    self.countBadgeLabel.layer.cornerRadius = self.countBadgeLabel.frame.size.width / 2;
    self.countBadgeLabel.clipsToBounds = YES;
    
    // an empty is created the FIRST time app is launched - there will always be at least one empty bento in defaults
    if ([[BentoShop sharedInstance] getTotalBentoCount] == 0) {
        [[BentoShop sharedInstance] addNewBento];
    }
    
    [self checkLocationOnLoad];
}

- (void)setUpWidget {
    NSDictionary *widget = [[BentoShop sharedInstance] getOnDemandWidget];
    self.asapMenuLabel.text = widget[@"title"];
    self.asapDescriptionLabel.text = widget[@"text"];
    
    NSNumber *isSelectedNum = (NSNumber *)widget[@"selected"];
    BOOL isSelected = [isSelectedNum boolValue];
    
    if (isSelected) {
        // default to on-demand
    }
    else {
        // default to first order-ahead
    }
}

// check meal mode

// on demand

- (void)checkLocationOnLoad {
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    CLLocationCoordinate2D gpsLocation = [appDelegate getGPSLocation];
    
    // no gps
    if (gpsLocation.latitude == 0 && gpsLocation.longitude == 0) {
        // yes saved location
        SVPlacemark *placemark = [[NSUserDefaults standardUserDefaults] rm_customObjectForKey:@"delivery_location"];
        if (placemark != nil) {
            [[BentoShop sharedInstance] checkIfSelectedLocationIsInAnyZone:placemark.location.coordinate completion:^(BOOL isSelectedLocationInZone, NSString *appState) {
                if (isSelectedLocationInZone == NO) {
                    [self nextToBuildShowMap];
                }
                else {
                    [self checkIfInZoneButNoMenuAndNotClosed:appState];
                }
            }];
        }
        // no saved location
        else {
            [self nextToBuildShowMap];
        }
    }
    // yes gps
    else {
        [[BentoShop sharedInstance] checkIfSelectedLocationIsInAnyZone:gpsLocation completion:^(BOOL isSelectedLocationInZone, NSString *appState) {
            if (isSelectedLocationInZone == NO) {
                [self nextToBuildShowMap];
            }
            else {
                [self checkIfInZoneButNoMenuAndNotClosed:appState];
            }
        }];
    }
    
//    [[DataManager shareDataManager] getUserInfo] == nil
}

- (void)checkIfInZoneButNoMenuAndNotClosed:(NSString *)appState {
    if ([appState isEqualToString:@"map,no_service_wall"]) {
        [self nextToBuildShowMap];
    }
}

- (void)nextToBuildShowMap {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    DeliveryLocationViewController *deliveryLocationViewController = [storyboard instantiateViewControllerWithIdentifier:@"DeliveryLocationViewController"];
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"nextToBuild"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self.navigationController pushViewController:deliveryLocationViewController animated:NO];
}

- (void)checkAppState {
    NSString *appState = [[BentoShop sharedInstance] getAppState];
    if ([appState isEqualToString:@"closed_wall"]) {
        [self showSoldoutScreen:[NSNumber numberWithInt:0]];
    }
    else if ([appState isEqualToString:@"soldout_wall"]) {
        [self showSoldoutScreen:[NSNumber numberWithInt:1]];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([[BentoShop sharedInstance] is4PodMode]) {
        if ([[[BentoShop sharedInstance] getCurrentBento] getMainDish] == 0 &&
            [[[BentoShop sharedInstance] getCurrentBento] getSideDish1] == 0 &&
            [[[BentoShop sharedInstance] getCurrentBento] getSideDish2] == 0 &&
            [[[BentoShop sharedInstance] getCurrentBento] getSideDish3] == 0) {
            
            [[[BentoShop sharedInstance] getCurrentBento] setSideDish4:0];
        }
        else {
            [[[BentoShop sharedInstance] getCurrentBento] setSideDish4:-1]; // dummy item for 4-pod
        }
    }
    
    addonsVC = [[AddonsViewController alloc] init];
    addonsVC.delegate = self;
    
    [self updateUI];
    
    [self startTimerOnViewedScreen];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus:) name:USER_NOTIFICATION_UPDATED_MENU object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus:) name:USER_NOTIFICATION_UPDATED_STATUS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedMenu:) name:USER_NOTIFICATION_UPDATED_NEXTMENU object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noConnection) name:@"networkError" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yesConnection) name:@"networkConnected" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startTimerOnViewedScreen) name:@"enteredForeground" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endTimerOnViewedScreen) name:@"enteringBackground" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkAppState) name:@"checkAppState" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkAppState) name:@"enteredForeground" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewWillDisappear:animated];
    
    [self endTimerOnViewedScreen];
    
    NSLog(@"dropdownheight - %f", self.dropDownView.center.y);
}

#pragma mark Order Mode Check
- (void)checkOrderMode {
    /*---Menu Preview---*/
    if (self.orderMode == OnDemand) { // MOCK
        self.menuPreviewVC = [[MenuPreviewViewController alloc] init];
        [self addChildViewController:self.menuPreviewVC]; // 1. notify the prent VC that a child is being added
        self.bgView.frame = self.menuPreviewVC.view.bounds; // 2. before adding the child's view to its view hierarchy, the parent VC sets the child's size and position
        [self.bgView addSubview:self.menuPreviewVC.view];
        [self.menuPreviewVC didMoveToParentViewController:self]; // tell the child VC of its new parent
        
        self.bottomButton.hidden = YES;
    }
    else {
        [self.menuPreviewVC willMoveToParentViewController:nil]; // 1. let the child VC know that it will be removed
        [self.menuPreviewVC.view removeFromSuperview]; // 2. remove the child VC's view
        [self.menuPreviewVC removeFromParentViewController]; // 3. remove the child VC
        
        self.bottomButton.hidden = NO;
    }
}

#pragma mark Load Dishes

- (void)loadSelectedDishes {
    if ([[BentoShop sharedInstance] is4PodMode]) {
        [self loadSelectedDishes4];
    }
    else {
        [self loadSelectedDishes5];
    }
}

- (void)loadSelectedDishes4 {
    NSMutableArray *aryBentos = [[NSMutableArray alloc] init];
    for (NSInteger index = 0; index < [[BentoShop sharedInstance] getTotalBentoCount]; index++) {
        Bento *bento = [[BentoShop sharedInstance] getBento:index];
        if ([bento isCompleted]) {
            [aryBentos addObject:bento];
        }
    }
    
    NSInteger mainDishIndex = 0;
    NSInteger side1DishIndex = 0;
    NSInteger side2DishIndex = 0;
    NSInteger side3DishIndex = 0;
    NSInteger side4DishIndex = 0;
    
    Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];
    
    // Current Bento is not empty
    if (currentBento != nil) {
        mainDishIndex = [currentBento getMainDish];
        side1DishIndex = [currentBento getSideDish1];
        side2DishIndex = [currentBento getSideDish2];
        side3DishIndex = [currentBento getSideDish3];
        side4DishIndex = [currentBento getSideDish4];
    }
    
    /*---Main---*/
    if (mainDishIndex > 0) {
        
        NSDictionary *dishInfo = [[BentoShop sharedInstance] getMainDish:mainDishIndex];
        if (dishInfo != nil) {
            
            self.fourCustomVC.mainDishImageView.hidden = NO;
            self.fourCustomVC.mainDishLabel.hidden = NO;
            [self.fourCustomVC.addMainDishButton setTitle:@"" forState:UIControlStateNormal];
            
            self.fourCustomVC.mainDishLabel.text = [[dishInfo objectForKey:@"name"] uppercaseString];
            
            NSString *strImageURL = [dishInfo objectForKey:@"image1"];
            if (strImageURL == nil || [strImageURL isEqualToString:@""]) {
                // if there's no image string from backend
                self.fourCustomVC.mainDishImageView.image = [UIImage imageNamed:@"empty-main"];
            }
            else {
                [self.fourCustomVC.mainDishImageView setImageWithURL:[NSURL URLWithString:strImageURL] placeholderImage:[UIImage imageNamed:@"gradient-placeholder2"] usingActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            }
            
            if ([[BentoShop sharedInstance] isDishSoldOut:mainDishIndex]) {
                self.fourCustomVC.mainDishBannerImageView.hidden = NO;
            }
            else {
                self.fourCustomVC.mainDishBannerImageView.hidden = YES;
            }
        }
        // if dish info is nil, remove item from bento
        else {
            [currentBento setMainDish:0];
            
            self.fourCustomVC.mainDishImageView.image = nil;
            self.fourCustomVC.mainDishImageView.hidden = YES;
            self.fourCustomVC.mainDishLabel.hidden = YES;
            self.fourCustomVC.mainDishBannerImageView.hidden = YES;
            [self.fourCustomVC.addMainDishButton setTitle:[[AppStrings sharedInstance] getString:BUILD_MAIN_BUTTON] forState:UIControlStateNormal];
        }
    }
    else {
        self.fourCustomVC.mainDishImageView.image = nil;
        self.fourCustomVC.mainDishImageView.hidden = YES;
        self.fourCustomVC.mainDishLabel.hidden = YES;
        self.fourCustomVC.mainDishBannerImageView.hidden = YES;
        [self.fourCustomVC.addMainDishButton setTitle:[[AppStrings sharedInstance] getString:BUILD_MAIN_BUTTON] forState:UIControlStateNormal];
    }
    
    /*---Side 1---*/
    if (side1DishIndex > 0) {
        
        NSDictionary *dishInfo = [[BentoShop sharedInstance] getSideDish:side1DishIndex];
        if (dishInfo != nil) {
            
            self.fourCustomVC.sideDish1ImageView.hidden = NO;
            self.fourCustomVC.sideDish1Label.hidden = NO;
            [self.fourCustomVC.addSideDish1Button setTitle:@"" forState:UIControlStateNormal];
            
            self.fourCustomVC.sideDish1Label.text = [[dishInfo objectForKey:@"name"] uppercaseString];
            
            NSString *strImageURL = [dishInfo objectForKey:@"image1"];
            if (strImageURL == nil || [strImageURL isEqualToString:@""]) {
                // if there's no image string from backend
                self.fourCustomVC.sideDish1ImageView.image = [UIImage imageNamed:@"empty-main"];
            }
            else {
                [self.fourCustomVC.sideDish1ImageView setImageWithURL:[NSURL URLWithString:strImageURL] placeholderImage:[UIImage imageNamed:@"gradient-placeholder2"] usingActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            }
            
            if ([[BentoShop sharedInstance] isDishSoldOut:side1DishIndex]) {
                self.fourCustomVC.sideDish1BannerImageView.hidden = NO;
            }
            else {
                self.fourCustomVC.sideDish1BannerImageView.hidden = YES;
            }
        }
        // if dish info is nil, remove item from bento
        else {
            [currentBento setSideDish1:0];
            
            self.fourCustomVC.sideDish1ImageView.image = nil;
            self.fourCustomVC.sideDish1ImageView.hidden = YES;
            self.fourCustomVC.sideDish1Label.hidden = YES;
            self.fourCustomVC.sideDish1BannerImageView.hidden = YES;
            [self.fourCustomVC.addSideDish1Button setTitle:[[AppStrings sharedInstance] getString:BUILD_SIDE1_BUTTON] forState:UIControlStateNormal];
        }
    }
    else {
        self.fourCustomVC.sideDish1ImageView.image = nil;
        self.fourCustomVC.sideDish1ImageView.hidden = YES;
        self.fourCustomVC.sideDish1Label.hidden = YES;
        self.fourCustomVC.sideDish1BannerImageView.hidden = YES;
        [self.fourCustomVC.addSideDish1Button setTitle:[[AppStrings sharedInstance] getString:BUILD_SIDE1_BUTTON] forState:UIControlStateNormal];
    }
    
    /*---Side 2---*/
    if (side2DishIndex > 0) {
        
        NSDictionary *dishInfo = [[BentoShop sharedInstance] getSideDish:side2DishIndex];
        if (dishInfo != nil) {
            
            self.fourCustomVC.sideDish2Imageview.hidden = NO;
            self.fourCustomVC.sideDish2Label.hidden = NO;
            [self.fourCustomVC.addSideDish2Button setTitle:@"" forState:UIControlStateNormal];
            
            self.fourCustomVC.sideDish2Label.text = [[dishInfo objectForKey:@"name"] uppercaseString];
            
            NSString *strImageURL = [dishInfo objectForKey:@"image1"];
            if (strImageURL == nil || [strImageURL isEqualToString:@""]) {
                // if there's no image string from backend
                self.fourCustomVC.sideDish2Imageview.image = [UIImage imageNamed:@"empty-main"];
            }
            else {
                [self.fourCustomVC.sideDish2Imageview setImageWithURL:[NSURL URLWithString:strImageURL] placeholderImage:[UIImage imageNamed:@"gradient-placeholder2"] usingActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            }
            
            if ([[BentoShop sharedInstance] isDishSoldOut:side2DishIndex]) {
                self.fourCustomVC.sideDish2BannerImageView.hidden = NO;
            }
            else {
                self.fourCustomVC.sideDish2BannerImageView.hidden = YES;
            }
        }
        // if dish info is nil, remove item from bento
        else {
            [currentBento setSideDish2:0];
            
            // this block of code is same as below
            self.fourCustomVC.sideDish2Imageview.image = nil;
            self.fourCustomVC.sideDish2Imageview.hidden = YES;
            self.fourCustomVC.sideDish2Label.hidden = YES;
            self.fourCustomVC.sideDish2BannerImageView.hidden = YES;
            [self.fourCustomVC.addSideDish2Button setTitle:[[AppStrings sharedInstance] getString:BUILD_SIDE2_BUTTON] forState:UIControlStateNormal];
        }
    }
    else {
        self.fourCustomVC.sideDish2Imageview.image = nil;
        self.fourCustomVC.sideDish2Imageview.hidden = YES;
        self.fourCustomVC.sideDish2Label.hidden = YES;
        self.fourCustomVC.sideDish2BannerImageView.hidden = YES;
        [self.fourCustomVC.addSideDish2Button setTitle:[[AppStrings sharedInstance] getString:BUILD_SIDE2_BUTTON] forState:UIControlStateNormal];
    }
    
    /*-Side 3-*/
    if (side3DishIndex > 0) {
        
        NSDictionary *dishInfo = [[BentoShop sharedInstance] getSideDish:side3DishIndex];
        if (dishInfo != nil) {
            self.fourCustomVC.sideDish3ImageView.hidden = NO;
            self.fourCustomVC.sideDish3Label.hidden = NO;
            [self.fourCustomVC.addSideDish3Button setTitle:@"" forState:UIControlStateNormal];
            
            self.fourCustomVC.sideDish3Label.text = [[dishInfo objectForKey:@"name"] uppercaseString];
            
            NSString *strImageURL = [dishInfo objectForKey:@"image1"];
            if (strImageURL == nil || [strImageURL isEqualToString:@""]) {
                // if there's no image string from backend
                self.fourCustomVC.sideDish3ImageView.image = [UIImage imageNamed:@"empty-main"];
            }
            else {
                [self.fourCustomVC.sideDish3ImageView setImageWithURL:[NSURL URLWithString:strImageURL] placeholderImage:[UIImage imageNamed:@"gradient-placeholder2"] usingActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            }
            
            if ([[BentoShop sharedInstance] isDishSoldOut:side3DishIndex]) {
                self.fourCustomVC.sideDish3BannerImageView.hidden = NO;
            }
            else {
                self.fourCustomVC.sideDish3BannerImageView.hidden = YES;
            }
        }
        // if dish info is nil, remove item from bento
        else {
            [currentBento setSideDish3:0];
            
            // this block of code is same as below
            self.fourCustomVC.sideDish3ImageView.image = nil;
            self.fourCustomVC.sideDish3ImageView.hidden = YES;
            self.fourCustomVC.sideDish3Label.hidden = YES;
            self.fourCustomVC.sideDish3BannerImageView.hidden = YES;
            [self.fourCustomVC.addSideDish3Button setTitle:[[AppStrings sharedInstance] getString:BUILD_SIDE3_BUTTON] forState:UIControlStateNormal];
        }
    }
    else {
        self.fourCustomVC.sideDish3ImageView.image = nil;
        self.fourCustomVC.sideDish3ImageView.hidden = YES;
        self.fourCustomVC.sideDish3Label.hidden = YES;
        self.fourCustomVC.sideDish3BannerImageView.hidden = YES;
        [self.fourCustomVC.addSideDish3Button setTitle:[[AppStrings sharedInstance] getString:BUILD_SIDE3_BUTTON] forState:UIControlStateNormal];
    }
}

- (void)loadSelectedDishes5 {
    NSMutableArray *aryBentos = [[NSMutableArray alloc] init];
    for (NSInteger index = 0; index < [[BentoShop sharedInstance] getTotalBentoCount]; index++) {
        Bento *bento = [[BentoShop sharedInstance] getBento:index];
        if ([bento isCompleted]) {
            [aryBentos addObject:bento];
        }
    }
    
    NSInteger mainDishIndex = 0;
    NSInteger side1DishIndex = 0;
    NSInteger side2DishIndex = 0;
    NSInteger side3DishIndex = 0;
    NSInteger side4DishIndex = 0;
    
    Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];
    
    // Current Bento is not empty
    if (currentBento != nil) {
        mainDishIndex = [currentBento getMainDish];
        side1DishIndex = [currentBento getSideDish1];
        side2DishIndex = [currentBento getSideDish2];
        side3DishIndex = [currentBento getSideDish3];
        side4DishIndex = [currentBento getSideDish4];
    }
    
    /*---Main---*/
    if (mainDishIndex > 0) {
        
        NSDictionary *dishInfo = [[BentoShop sharedInstance] getMainDish:mainDishIndex];
        if (dishInfo != nil) {
            
            self.customVC.mainDishImageView.hidden = NO;
            self.customVC.mainDishLabel.hidden = NO;
            [self.customVC.addMainDishButton setTitle:@"" forState:UIControlStateNormal];
            
            self.customVC.mainDishLabel.text = [[dishInfo objectForKey:@"name"] uppercaseString];
            
            NSString *strImageURL = [dishInfo objectForKey:@"image1"];
            if (strImageURL == nil || [strImageURL isEqualToString:@""]) {
                // if there's no image string from backend
                self.customVC.mainDishImageView.image = [UIImage imageNamed:@"empty-main"];
            }
            else {
                [self.customVC.mainDishImageView setImageWithURL:[NSURL URLWithString:strImageURL] placeholderImage:[UIImage imageNamed:@"gradient-placeholder2"] usingActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            }
            
            if ([[BentoShop sharedInstance] isDishSoldOut:mainDishIndex]) {
                self.customVC.mainDishBannerImageView.hidden = NO;
            }
            else {
                self.customVC.mainDishBannerImageView.hidden = YES;
            }
        }
        // if dish info is nil, remove item from bento
        else {
            [currentBento setMainDish:0];
            
            self.customVC.mainDishImageView.image = nil;
            self.customVC.mainDishImageView.hidden = YES;
            self.customVC.mainDishLabel.hidden = YES;
            self.customVC.mainDishBannerImageView.hidden = YES;
            [self.customVC.addMainDishButton setTitle:[[AppStrings sharedInstance] getString:BUILD_MAIN_BUTTON] forState:UIControlStateNormal];
        }
    }
    else {
        self.customVC.mainDishImageView.image = nil;
        self.customVC.mainDishImageView.hidden = YES;
        self.customVC.mainDishLabel.hidden = YES;
        self.customVC.mainDishBannerImageView.hidden = YES;
        [self.customVC.addMainDishButton setTitle:[[AppStrings sharedInstance] getString:BUILD_MAIN_BUTTON] forState:UIControlStateNormal];
    }
    
    /*---Side 1---*/
    if (side1DishIndex > 0) {
        
        NSDictionary *dishInfo = [[BentoShop sharedInstance] getSideDish:side1DishIndex];
        if (dishInfo != nil) {
            
            self.customVC.sideDish1ImageView.hidden = NO;
            self.customVC.sideDish1Label.hidden = NO;
            [self.customVC.addSideDish1Button setTitle:@"" forState:UIControlStateNormal];
            
            self.customVC.sideDish1Label.text = [[dishInfo objectForKey:@"name"] uppercaseString];
            
            NSString *strImageURL = [dishInfo objectForKey:@"image1"];
            if (strImageURL == nil || [strImageURL isEqualToString:@""]) {
                // if there's no image string from backend
                self.customVC.sideDish1ImageView.image = [UIImage imageNamed:@"empty-main"];
            }
            else {
                [self.customVC.sideDish1ImageView setImageWithURL:[NSURL URLWithString:strImageURL] placeholderImage:[UIImage imageNamed:@"gradient-placeholder2"] usingActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            }
            
            if ([[BentoShop sharedInstance] isDishSoldOut:side1DishIndex]) {
                self.customVC.sideDish1BannerImageView.hidden = NO;
            }
            else {
                self.customVC.sideDish1BannerImageView.hidden = YES;
            }
        }
        // if dish info is nil, remove item from bento
        else {
            [currentBento setSideDish1:0];
            
            self.customVC.sideDish1ImageView.image = nil;
            self.customVC.sideDish1ImageView.hidden = YES;
            self.customVC.sideDish1Label.hidden = YES;
            self.customVC.sideDish1BannerImageView.hidden = YES;
            [self.customVC.addSideDish1Button setTitle:[[AppStrings sharedInstance] getString:BUILD_SIDE1_BUTTON] forState:UIControlStateNormal];
        }
    }
    else {
        self.customVC.sideDish1ImageView.image = nil;
        self.customVC.sideDish1ImageView.hidden = YES;
        self.customVC.sideDish1Label.hidden = YES;
        self.customVC.sideDish1BannerImageView.hidden = YES;
        [self.customVC.addSideDish1Button setTitle:[[AppStrings sharedInstance] getString:BUILD_SIDE1_BUTTON] forState:UIControlStateNormal];
    }
    
    /*---Side 2---*/
    if (side2DishIndex > 0) {
        
        NSDictionary *dishInfo = [[BentoShop sharedInstance] getSideDish:side2DishIndex];
        if (dishInfo != nil) {
            
            self.customVC.sideDish2Imageview.hidden = NO;
            self.customVC.sideDish2Label.hidden = NO;
            [self.customVC.addSideDish2Button setTitle:@"" forState:UIControlStateNormal];
            
            self.customVC.sideDish2Label.text = [[dishInfo objectForKey:@"name"] uppercaseString];
            
            NSString *strImageURL = [dishInfo objectForKey:@"image1"];
            if (strImageURL == nil || [strImageURL isEqualToString:@""]) {
                // if there's no image string from backend
                self.customVC.sideDish2Imageview.image = [UIImage imageNamed:@"empty-main"];
            }
            else {
                [self.customVC.sideDish2Imageview setImageWithURL:[NSURL URLWithString:strImageURL] placeholderImage:[UIImage imageNamed:@"gradient-placeholder2"] usingActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            }
            
            if ([[BentoShop sharedInstance] isDishSoldOut:side2DishIndex]) {
                self.customVC.sideDish2BannerImageView.hidden = NO;
            }
            else {
                self.customVC.sideDish2BannerImageView.hidden = YES;
            }
        }
        // if dish info is nil, remove item from bento
        else {
            [currentBento setSideDish2:0];
            
            // this block of code is same as below
            self.customVC.sideDish2Imageview.image = nil;
            self.customVC.sideDish2Imageview.hidden = YES;
            self.customVC.sideDish2Label.hidden = YES;
            self.customVC.sideDish2BannerImageView.hidden = YES;
            [self.customVC.addSideDish2Button setTitle:[[AppStrings sharedInstance] getString:BUILD_SIDE2_BUTTON] forState:UIControlStateNormal];
        }
    }
    else {
        self.customVC.sideDish2Imageview.image = nil;
        self.customVC.sideDish2Imageview.hidden = YES;
        self.customVC.sideDish2Label.hidden = YES;
        self.customVC.sideDish2BannerImageView.hidden = YES;
        [self.customVC.addSideDish2Button setTitle:[[AppStrings sharedInstance] getString:BUILD_SIDE2_BUTTON] forState:UIControlStateNormal];
    }
    
    /*-Side 3-*/
    if (side3DishIndex > 0) {
        
        NSDictionary *dishInfo = [[BentoShop sharedInstance] getSideDish:side3DishIndex];
        if (dishInfo != nil) {
            self.customVC.sideDish3ImageView.hidden = NO;
            self.customVC.sideDish3Label.hidden = NO;
            [self.customVC.addSideDish3Button setTitle:@"" forState:UIControlStateNormal];
            
            self.customVC.sideDish3Label.text = [[dishInfo objectForKey:@"name"] uppercaseString];
            
            NSString *strImageURL = [dishInfo objectForKey:@"image1"];
            if (strImageURL == nil || [strImageURL isEqualToString:@""]) {
                // if there's no image string from backend
                self.customVC.sideDish3ImageView.image = [UIImage imageNamed:@"empty-main"];
            }
            else {
                [self.customVC.sideDish3ImageView setImageWithURL:[NSURL URLWithString:strImageURL] placeholderImage:[UIImage imageNamed:@"gradient-placeholder2"] usingActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            }
            
            if ([[BentoShop sharedInstance] isDishSoldOut:side3DishIndex]) {
                self.customVC.sideDish3BannerImageView.hidden = NO;
            }
            else {
                self.customVC.sideDish3BannerImageView.hidden = YES;
            }
        }
        // if dish info is nil, remove item from bento
        else {
            [currentBento setSideDish3:0];
            
            // this block of code is same as below
            self.customVC.sideDish3ImageView.image = nil;
            self.customVC.sideDish3ImageView.hidden = YES;
            self.customVC.sideDish3Label.hidden = YES;
            self.customVC.sideDish3BannerImageView.hidden = YES;
            [self.customVC.addSideDish3Button setTitle:[[AppStrings sharedInstance] getString:BUILD_SIDE3_BUTTON] forState:UIControlStateNormal];
        }
    }
    else {
        self.customVC.sideDish3ImageView.image = nil;
        self.customVC.sideDish3ImageView.hidden = YES;
        self.customVC.sideDish3Label.hidden = YES;
        self.customVC.sideDish3BannerImageView.hidden = YES;
        [self.customVC.addSideDish3Button setTitle:[[AppStrings sharedInstance] getString:BUILD_SIDE3_BUTTON] forState:UIControlStateNormal];
    }
    
    /*-Side 4-*/
    if (side4DishIndex > 0) {
        
        NSDictionary *dishInfo = [[BentoShop sharedInstance] getSideDish:side4DishIndex];
        if (dishInfo != nil) {
            
            self.customVC.sideDish4ImageView.hidden = NO;
            self.customVC.sideDish4Label.hidden = NO;
            [self.customVC.addSideDish4Button setTitle:@"" forState:UIControlStateNormal];
            
            self.customVC.sideDish4Label.text = [[dishInfo objectForKey:@"name"] uppercaseString];
            
            NSString *strImageURL = [dishInfo objectForKey:@"image1"];
            if (strImageURL == nil || [strImageURL isEqualToString:@""]) {
                // if there's no image string from backend
                self.customVC.sideDish4ImageView.image = [UIImage imageNamed:@"empty-main"];
            }
            else {
                [self.customVC.sideDish4ImageView setImageWithURL:[NSURL URLWithString:strImageURL] placeholderImage:[UIImage imageNamed:@"gradient-placeholder2"] usingActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            }
            
            if ([[BentoShop sharedInstance] isDishSoldOut:side4DishIndex]) {
                self.customVC.sideDish4BannerImageView.hidden = NO;
            }
            else {
                self.customVC.sideDish4BannerImageView.hidden = YES;
            }
        }
        // if dish info is nil, remove item from bento
        else {
            [currentBento setSideDish4:0];
            
            // this block of code is same as below
            self.customVC.sideDish4ImageView.image = nil;
            self.customVC.sideDish4ImageView.hidden = YES;
            self.customVC.sideDish4Label.hidden = YES;
            self.customVC.sideDish4BannerImageView.hidden = YES;
            [self.customVC.addSideDish4Button setTitle:[[AppStrings sharedInstance] getString:BUILD_SIDE4_BUTTON] forState:UIControlStateNormal];
        }
    }
    else {
        self.customVC.sideDish4ImageView.image = nil;
        self.customVC.sideDish4ImageView.hidden = YES;
        self.customVC.sideDish4Label.hidden = YES;
        self.customVC.sideDish4BannerImageView.hidden = YES;
        [self.customVC.addSideDish4Button setTitle:[[AppStrings sharedInstance] getString:BUILD_SIDE4_BUTTON] forState:UIControlStateNormal];
    }
}

#pragma mark Update UI

- (void)updateUI {
    
    Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];
    NSString *strTitle;
    
    // current mains
    NSMutableArray *mainDishesArray;
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Lunch"]) {
        mainDishesArray = [[[BentoShop sharedInstance] getMainDishes:@"todayLunch"] mutableCopy];
    }
    else {
        mainDishesArray = [[[BentoShop sharedInstance] getMainDishes:@"todayDinner"] mutableCopy];
    }
    
    /*----------------------*/
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
        
        // if exists, show normal
        if (cents == 0) {
            self.startingPriceLabel.text = [NSString stringWithFormat:@"STARTING AT $%.0f", [sortedMainPrices[0] floatValue]];
        }
        // if no cents, just show whole number
        else {
            self.startingPriceLabel.text = [NSString stringWithFormat:@"STARTING AT $%@", sortedMainPrices[0]];
        }
    }
    /*----------------------*/
    
    [self setETA];
    
    /*----------------------*/
    
    [self showOrHideAddAnotherBentoAndViewAddons];
    
    // current bento is empty
    if ([currentBento isEmpty] == YES || currentBento == nil) {
        strTitle = [[AppStrings sharedInstance] getString:BUILD_TITLE]; // BUILD YOUR BENTO
    }
    // current bento has at least 1 item
    else if ([currentBento isCompleted] == NO) {
        strTitle = [[AppStrings sharedInstance] getString:BUILD_CONTINUE_BUTTON]; // CONTINUE
    }
    // current bento is complete
    else if ([currentBento isCompleted]) {
        strTitle = [[AppStrings sharedInstance] getString:BUILD_ADD_BUTTON]; // ADD ANOTHER BENTO
    }
    
    if (strTitle != nil) {
        // Add Another Bento Button
        NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:strTitle];
        float spacing = 1.0f;
        [attributedTitle addAttribute:NSKernAttributeName
                                value:@(spacing)
                                range:NSMakeRange(0, [strTitle length])];
        
        [attributedTitle addAttribute:NSForegroundColorAttributeName
                                value:[UIColor bentoBrandGreen]
                                range:NSMakeRange(0, [strTitle length])];
        
        if ([[BentoShop sharedInstance] is4PodMode]) {
            [self.fourCustomVC.buildButton setAttributedTitle:attributedTitle forState:UIControlStateNormal];
        }
        else {
            [self.customVC.buildButton setAttributedTitle:attributedTitle forState:UIControlStateNormal];
        }
    }
    
    /*----------------------*/
    
    // Bentos
    if ([[BentoShop sharedInstance] getTotalBentoCount] == 0) {// no bento
        [[BentoShop sharedInstance] addNewBento]; // add an empty one
    }
    else if ([[BentoShop sharedInstance] getCurrentBento] == nil) {
        [[BentoShop sharedInstance] setCurrentBento:[[BentoShop sharedInstance] getLastBento]]; // set current with current one in array
    }
    
    /*---Load Bento---*/
    [self loadSelectedDishes];
    
    if ([[BentoShop sharedInstance] getCompletedBentoCount] > 0) {
        self.cartButton.enabled = YES;
        self.cartButton.selected = YES;
        [self.cartButton setImage:[UIImage imageNamed:@"mybento_nav_cart_act"] forState:UIControlStateNormal];
    }
    else {
        self.cartButton.enabled = NO;
        self.cartButton.selected = NO;
    }
    
    /*---Finalize Button---*/
    [self updateBottomButton];
    
    /*---Cart Badge---*/
    if ([[BentoShop sharedInstance] getCompletedBentoCount] > 0) {
        self.countBadgeLabel.text = [NSString stringWithFormat:@"%ld", (long)[[BentoShop sharedInstance] getCompletedBentoCount] + (long)[[AddonList sharedInstance] getTotalCount]];
        self.countBadgeLabel.hidden = NO;
    }
    else {
        self.countBadgeLabel.text = @"";
        self.countBadgeLabel.hidden = YES;
    }
}

- (void)onUpdatedMenu:(NSNotification *)notification {
    if (isThereConnection) {
        [self updateUI];
    }
}

- (void)setETA {
    self.etaLabel.text = [NSString stringWithFormat:@"ETA: %ld-%ld MIN.", (long)[[BentoShop sharedInstance] getETAMin], (long)[[BentoShop sharedInstance] getETAMax]];
}

#pragma mark Show or Hide AddAnotherBento & View Add-ons

- (void)showOrHideAddAnotherBentoAndViewAddons {
    if ([[BentoShop sharedInstance] is4PodMode]) {
        // 1 or more bentos in cart
        if ([[BentoShop sharedInstance] getCompletedBentoCount] > 0) {
            self.fourCustomVC.buildButton.hidden = NO;
            self.fourCustomVC.viewAddonsButton.hidden = NO;
        }
        else {
            self.fourCustomVC.buildButton.hidden = YES;
            self.fourCustomVC.viewAddonsButton.hidden = YES;
        }
    }
    else {
        // 1 or more bentos in cart
        if ([[BentoShop sharedInstance] getCompletedBentoCount] > 0) {
            self.customVC.buildButton.hidden = NO;
            self.customVC.viewAddonsButton.hidden = NO;
        }
        else {
            self.customVC.buildButton.hidden = YES;
            self.customVC.viewAddonsButton.hidden = YES;
        }
    }
}

#pragma mark Mixpanel - Screen Duration
- (void)startTimerOnViewedScreen {
    [[Mixpanel sharedInstance] timeEvent:@"Viewed Custom Home Screen"];
}

- (void)endTimerOnViewedScreen {
    [[Mixpanel sharedInstance] track:@"Viewed Custom Home Screen"];
}

#pragma mark Connection Handlers

- (void)yesConnection {
    [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(callUpdate) userInfo:nil repeats:NO];
}

- (void)noConnection {
    isThereConnection = NO;
    
    if (loadingHUD == nil) {
        loadingHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
        loadingHUD.textLabel.text = @"Waiting for internet connectivity...";
        [loadingHUD showInView:self.view];
    }
}

- (void)callUpdate {
    isThereConnection = YES;
    
    [loadingHUD dismiss];
    loadingHUD = nil;
    [self viewWillAppear:YES];
}

#pragma mark Updated Status
- (void)onUpdatedStatus:(NSNotification *)notification {
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

#pragma mark AddonsViewController Delegate Method
- (void)addonsViewControllerDidTapOnFinalize:(BOOL)didTapOnFinalize {
    if (didTapOnFinalize == YES) {
        [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(onFinalize) userInfo:nil repeats:NO];
    }
}

#pragma mark MyAlertViewDelegate

- (void)alertView:(MyAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];
        if (currentBento != nil && ![currentBento isCompleted]) {
            // 00:00 - 16:29
            if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Lunch"]) {
                [currentBento completeBento:@"todayLunch"];
            }
            // 16:30 - 23:59
            else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Dinner"]) {
                [currentBento completeBento:@"todayDinner"];
            }
        }
        
        [self onFinalize];
    }
}

#pragma mark CustomViewController Delegate Methods
- (void)customVCAddMainButtonPressed:(id)sender {
    [self onAddMainDish];
}

- (void)customVCAddSideDish1Pressed:(id)sender {
    [self onAddSideDish:sender];
}

- (void)customVCAddSideDish2Pressed:(id)sender {
    [self onAddSideDish:sender];
}

- (void)customVCAddSideDish3Pressed:(id)sender {
    [self onAddSideDish:sender];
}

- (void)customVCAddSideDish4Pressed:(id)sender {
    [self onAddSideDish:sender];
}

- (void)customVCBuildButtonPressed:(id)sender {
    [self onAddAnotherBento];
}

- (void)customVCViewAddonsButtonPressed:(id)sender {
    [self onViewAddons];
}

- (void)onAddMainDish {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ChooseMainDishViewController *chooseMainDishViewController = [storyboard instantiateViewControllerWithIdentifier:@"ChooseMainDishViewController"];
    [self.navigationController pushViewController:chooseMainDishViewController animated:YES];
}

- (void)onAddSideDish:(id)sender {
    UIButton *selectedButton = (UIButton *)sender;
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ChooseSideDishViewController *chooseSideDishViewController = [storyboard instantiateViewControllerWithIdentifier:@"ChooseSideDishViewController"];
    chooseSideDishViewController.sideDishIndex = selectedButton.tag;
    
    [self.navigationController pushViewController:chooseSideDishViewController animated:YES];
}

- (void)onAddAnotherBento {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ChooseMainDishViewController *chooseMainDishViewController = [storyboard instantiateViewControllerWithIdentifier:@"ChooseMainDishViewController"];
    ChooseSideDishViewController *chooseSideDishViewController = [storyboard instantiateViewControllerWithIdentifier:@"ChooseSideDishViewController"];
    
    Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];
    
    if (currentBento == nil || [currentBento isEmpty]) {
        [self.navigationController pushViewController:chooseMainDishViewController animated:YES];
    }
    else if (![currentBento isCompleted]) {
        
        if ([currentBento getMainDish] == 0) {
            [self.navigationController pushViewController:chooseMainDishViewController animated:YES];
        }
        else if ([currentBento getSideDish1] == 0) {
            chooseSideDishViewController.sideDishIndex = 0;
            [self.navigationController pushViewController:chooseSideDishViewController animated:YES];
        }
        else if ([currentBento getSideDish2] == 0) {
            chooseSideDishViewController.sideDishIndex = 1;
            [self.navigationController pushViewController:chooseSideDishViewController animated:YES];
        }
        else if ([currentBento getSideDish3] == 0) {
            chooseSideDishViewController.sideDishIndex = 2;
            [self.navigationController pushViewController:chooseSideDishViewController animated:YES];
        }
        else if ([currentBento getSideDish4] == 0) {
            chooseSideDishViewController.sideDishIndex = 3;
            [self.navigationController pushViewController:chooseSideDishViewController animated:YES];
        }
    }
    else {
        if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Lunch"]) {
            [currentBento completeBento:@"todayLunch"];
        }
        else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Dinner"]) {
            [currentBento completeBento:@"todayDinner"];
        }
        
        [[BentoShop sharedInstance] addNewBento];
        
        [self updateUI];
    }
}

- (void)onViewAddons {
    [[Mixpanel sharedInstance] track:@"Tapped on View Add-ons"];
    [self.navigationController presentViewController:addonsVC animated:YES completion:nil];
}

#pragma mark Button Handlers

- (IBAction)settingsButtonPressed:(id)sender {
    [self onSettings];
}

- (IBAction)cartButtonPressed:(id)sender {
    [self onCart];
}

- (IBAction)pickerButtonPressed:(id)sender {
    [self toggleDropDownPicker];
}

- (IBAction)fadedViewButtonPressed:(id)sender {
    [self toggleDropDownPicker];
}

- (IBAction)enableOnDemandButtonPressed:(id)sender {
    [self enableOnDemand];
}

- (IBAction)enableOrderAheadButtonPressed:(id)sender {
    [self enableOrderAhead];
}

- (IBAction)bottomButtonPressed:(id)sender {
    // 1 or more bentos in cart
    if ([[BentoShop sharedInstance] getCompletedBentoCount] > 0) {
        [self onFinalize];
    }
    else {
        [self onAddAnotherBento];
    }
}

- (void)updateBottomButton {
    NSString *strTitle;
    if ([[BentoShop sharedInstance] getCompletedBentoCount] > 0) {
        strTitle = [[AppStrings sharedInstance] getString:BUILD_COMPLETE_BUTTON];
        
        [self.bottomButton setBackgroundColor:[UIColor bentoBrandGreen]];
    }
    else {
        Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];
        
        // current bento is empty
        if ([currentBento isEmpty] == YES || currentBento == nil) {
            strTitle = [[AppStrings sharedInstance] getString:BUILD_TITLE]; // BUILD YOUR BENTO
        }
        // current bento has at least 1 item
        else if ([currentBento isCompleted] == NO) {
            strTitle = [[AppStrings sharedInstance] getString:BUILD_CONTINUE_BUTTON]; // CONTINUE
        }
        // current bento is complete
        else if ([currentBento isCompleted]) {
            strTitle = [[AppStrings sharedInstance] getString:BUILD_ADD_BUTTON]; // ADD ANOTHER BENTO
        }
        
        [self.bottomButton setBackgroundColor:[UIColor bentoButtonGray]];
    }
    
    if (strTitle != nil) {
        NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:strTitle];
        
        float spacing = 1.0f;
        
        [attributedTitle addAttribute:NSKernAttributeName
                                value:@(spacing)
                                range:NSMakeRange(0, [strTitle length])];
        
        [attributedTitle addAttribute:NSForegroundColorAttributeName
                                value:[UIColor whiteColor]
                                range:NSMakeRange(0, [strTitle length])];
        
        [self.bottomButton setAttributedTitle:attributedTitle forState:UIControlStateNormal];
    }
}

#pragma mark Button Events

- (void)toggleDropDownPicker {
    [self.view layoutIfNeeded];
    
    if (self.fadedViewButton.alpha == 0) {
        [UIView animateWithDuration:0.5 animations:^{
            self.fadedViewButton.alpha = 0.8;
            
            self.dropDownViewTopConstraint.constant = self.dropDownView.frame.origin.y + self.dropDownView.frame.size.height + 20;
            
            [self.view layoutIfNeeded];
        }];
    }
    else {
        [UIView animateWithDuration:0.5 animations:^{
            self.fadedViewButton.alpha = 0;
            
            self.dropDownViewTopConstraint.constant = self.dropDownView.frame.origin.y - self.dropDownView.frame.size.height - 20;
            
            [self.view layoutIfNeeded];
        }];
    }
    
    NSLog(@"dropdownheight - %f", self.dropDownView.center.y);
}

- (void)onSettings {
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
    }
    else {
        // navigate to signed in settings vc
        navC = [[UINavigationController alloc] initWithRootViewController:signedInSettingsViewController];
        navC.navigationBar.hidden = YES;
        [self.navigationController presentViewController:navC animated:YES completion:nil];
    }
}

- (void)onCart {
    Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];
    if (currentBento != nil && ![currentBento isEmpty] && ![currentBento isCompleted]) {
        [self showConfirmMsg];
    }
    else {
        [self gotoOrderScreen];
    }
}

- (void)showConfirmMsg {
    NSString *strText = [[AppStrings sharedInstance] getString:ALERT_BNF_TEXT];
    NSString *strCancel = [[AppStrings sharedInstance] getString:ALERT_BNF_BUTTON_CANCEL];
    NSString *strConfirm = [[AppStrings sharedInstance] getString:ALERT_BNF_BUTTON_CONFIRM];
    MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"" message:strText delegate:self cancelButtonTitle:strCancel otherButtonTitle:strConfirm];
    
    [alertView showInView:self.view];
    alertView = nil;
}

- (void)gotoOrderScreen {
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
            [[BentoShop sharedInstance] checkIfSelectedLocationIsInAnyZone:placeInfo.location.coordinate completion:^(BOOL isSelectedLocationInZone, NSString *appState) {
                if (isSelectedLocationInZone) {
                    [self openAccountViewController:[CompleteOrderViewController class]];
                }
                else {
                    [self openAccountViewController:[DeliveryLocationViewController class]];
                }
            }];
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
            [[BentoShop sharedInstance] checkIfSelectedLocationIsInAnyZone:placeInfo.location.coordinate completion:^(BOOL isSelectedLocationInZone, NSString *appState) {
                if (isSelectedLocationInZone) {
                    [self.navigationController pushViewController:completeOrderViewController animated:YES];
                }
                else {
                    [self.navigationController pushViewController:deliveryLocationViewController animated:YES];
                }
            }];
        }
    }
}

- (void)enableOnDemand {
    self.orderMode = OnDemand;
    
    self.onDemandGreenView1.alpha = 1.0;
    self.onDemandGreenViewWidthConstraint.constant = 10;
    
    self.orderAheadGreenView1.alpha = 0.5;
    self.orderAheadGreenViewWidthConstraint.constant = 5;
    
    self.enabledOnDemandButton.hidden = YES;
    self.enabledOrderAheadButton.hidden = NO;
    
    // on demand mennu and time are set on tap
    menuOnDemand = self.asapMenuLabel.text;
    timeOnDemand = self.asapTimeLabel.text;
    
    [self updatePickerButtonTitle];
    [self checkOrderMode];
}

- (void)enableOrderAhead {
    self.orderMode = OrderAhead;
    
    self.onDemandGreenView1.alpha = 0.5;
    self.onDemandGreenViewWidthConstraint.constant = 5;
    
    self.orderAheadGreenView1.alpha = 1.0;
    self.orderAheadGreenViewWidthConstraint.constant = 10;
    
    
    self.enabledOnDemandButton.hidden = NO;
    self.enabledOrderAheadButton.hidden = YES;
    
    if (menuOrderAhead == nil || timeOrderAhead == nil) {
        menuOrderAhead = [self pickerView:self.orderAheadPickerView titleForRow:[self.orderAheadPickerView selectedRowInComponent:0] forComponent:0];
        timeOrderAhead = [self pickerView:self.orderAheadPickerView titleForRow:[self.orderAheadPickerView selectedRowInComponent:0] forComponent:1];
    }
    
    [self updatePickerButtonTitle];
    [self checkOrderMode];
}

- (void)onFinalize {
    if ([self isInMiddleOfBuildingBento]) {
        [self showConfirmMsg];
    }
    else {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"AutoShowAddons"] == YES) {
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"didAutoShowAddons"] != YES) {
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"didAutoShowAddons"];
                [self.navigationController presentViewController:addonsVC animated:YES completion:nil];
            }
            else {
                [self gotoOrderScreen];
            }
        }
        else {
            [self gotoOrderScreen];
        }
    }
}

- (BOOL)isInMiddleOfBuildingBento {
    Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];
    if (currentBento != nil && ![currentBento isEmpty] && ![currentBento isCompleted]) {
        return YES;
    }
    
    return NO;
}

#pragma mark Picker View

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    UILabel *pickerLabel = [[UILabel alloc] init];
    pickerLabel.text = myDatabase[component][row];
    
    // if time range is sold-out
    if ([pickerLabel.text containsString:@"sold-out"]) {
        pickerLabel.textColor = [UIColor bentoErrorTextOrange];
    }
    else {
        pickerLabel.textColor = [UIColor bentoTitleGray];
    }
    
    pickerLabel.adjustsFontSizeToFitWidth = YES;
    pickerLabel.textAlignment = NSTextAlignmentCenter;
    pickerLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:13];
    
    return pickerLabel;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return myDatabase.count;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [myDatabase[component] count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return myDatabase[component][row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    switch (component) {
        case 0:
            menuOrderAhead = myDatabase[component][row];
            break;
            
        default:
            // if time range is sold-out
            if ([myDatabase[component][row] containsString:@"sold-out"]) {
                [pickerView selectRow:row+1 inComponent:component animated:YES];
                timeOrderAhead = myDatabase[component][row+1];
            }
            else {
                timeOrderAhead = myDatabase[component][row];
            }
            
            break;
    }
    
    [self updatePickerButtonTitle];
}

- (void)updatePickerButtonTitle {
    if (self.orderMode == OnDemand) {
        [self.pickerButton setTitle:[NSString stringWithFormat:@"%@, %@ ▾", menuOnDemand, timeOnDemand] forState:UIControlStateNormal];
    }
    else if (self.orderMode == OrderAhead) {
        [self.pickerButton setTitle:[NSString stringWithFormat:@"%@, %@ ▾", menuOrderAhead, timeOrderAhead] forState:UIControlStateNormal];
    }
}


@end
