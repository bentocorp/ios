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

#import "WebManager.h"

#import "OrderAheadMenu.h"

#import "CountdownTimer.h"

@interface FiveHomeViewController () <CustomViewControllerDelegate, FiveCustomViewControllerDelegate, MyAlertViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic) CustomViewController *fourCustomVC;
@property (nonatomic) FiveCustomViewController *customVC;
@property (nonatomic) MenuPreviewViewController *menuPreviewVC;

@property (nonatomic) OrderMode orderMode;
@property (nonatomic) PickerState pickerState;

@property (nonatomic) BOOL isToggledOn;
@property (nonatomic) OrderAheadMenu *orderAheadMenu;

@property (nonatomic) NSDictionary *widget;

@property (nonatomic) NSLayoutConstraint *xCenterConstraintForStartingPriceLabel;

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
    
    NSInteger selectedOrderAheadIndex;
    NSInteger selectedOrderAheadIndexForConfirm;
    
    NSMutableArray *menuNames; // [date, date, date]
    NSMutableArray *menuTimes; // [[time range, time ranges, time ranges], [time range, time ranges, time ranges], [time range, time ranges, time ranges]]
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [CountdownTimer sharedInstance];
    
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
    
    /*---Order Ahead View Menu---*/
    self.orderAheadView.clipsToBounds = YES; // to avoid subviews from coming out of bounds
    
    // picker data
    menuNames = [@[] mutableCopy]; // [date, date, date]
    menuTimes = [@[] mutableCopy]; // [[time range, time range], [time range, time range], [time range, time range]]
    
    /*---Count Badge---*/
    self.countBadgeLabel.layer.cornerRadius = self.countBadgeLabel.frame.size.width / 2;
    self.countBadgeLabel.clipsToBounds = YES;
    
    /*---Starting Price Label---*/
    self.xCenterConstraintForStartingPriceLabel = [NSLayoutConstraint constraintWithItem:self.startingPriceLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.etaBannerView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0];
    
    // an empty is created the FIRST time app is launched - there will always be at least one empty bento in defaults
    if ([[BentoShop sharedInstance] getTotalBentoCount] == 0) {
        [[BentoShop sharedInstance] addNewBento];
    }
    
    [self checkLocationOnLoad];
    [self refreshStateOnLaunch];
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
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedMenu:) name:USER_NOTIFICATION_UPDATED_NEXTMENU object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noConnection) name:@"networkError" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yesConnection) name:@"networkConnected" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startTimerOnViewedScreen) name:@"enteredForeground" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endTimerOnViewedScreen) name:@"enteringBackground" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus:) name:@"enteredForeground" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateBottomButton) name:@"showCountDownTimer" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewWillDisappear:animated];
    
    [self endTimerOnViewedScreen];
    
    NSLog(@"dropdownheight - %f", self.dropDownView.center.y);
}

#pragma  mark Check Location
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
        // never saved an address before
        if ([[NSUserDefaults standardUserDefaults] rm_customObjectForKey:@"delivery_location"] == nil) {
            [self nextToBuildShowMap];
        }
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
    deliveryLocationViewController.nextToBuild = YES;
    
    [self.navigationController pushViewController:deliveryLocationViewController animated:NO];
}

#pragma mark Closed / Sold-out
- (void)checkAppState {
    if ([[BentoShop sharedInstance] isClosed]) {
        [self showSoldoutScreen:[NSNumber numberWithInt:0]];
    }
    else if ([[BentoShop sharedInstance] isSoldOut]) {
        [self showSoldoutScreen:[NSNumber numberWithInt:1]];
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
        
        NSDictionary *dishInfo;
        
        if (self.orderMode == OnDemand) {
            dishInfo = [[BentoShop sharedInstance] getMainDish:mainDishIndex];
        }
        else if (self.orderMode == OrderAhead) {
            dishInfo = [self.orderAheadMenu getMainDish:mainDishIndex];
        }
        
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
            
            if (self.orderMode == OnDemand) {
                if ([[BentoShop sharedInstance] isDishSoldOut:mainDishIndex]) {
                    self.fourCustomVC.mainDishBannerImageView.hidden = NO;
                }
                else {
                    self.fourCustomVC.mainDishBannerImageView.hidden = YES;
                }
            }
            else if (self.orderMode == OrderAhead) {
                if ([self.orderAheadMenu isDishSoldOut:mainDishIndex]) {
                    self.fourCustomVC.mainDishBannerImageView.hidden = NO;
                }
                else {
                    self.fourCustomVC.mainDishBannerImageView.hidden = YES;
                }
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
        
        NSDictionary *dishInfo;
        
        if (self.orderMode == OnDemand) {
            dishInfo = [[BentoShop sharedInstance] getSideDish:side1DishIndex];
        }
        else if (self.orderMode == OrderAhead) {
            dishInfo = [self.orderAheadMenu getSideDish:side1DishIndex];
        }
        
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
            
            if (self.orderMode == OnDemand) {
                if ([[BentoShop sharedInstance] isDishSoldOut:side1DishIndex]) {
                    self.fourCustomVC.sideDish1BannerImageView.hidden = NO;
                }
                else {
                    self.fourCustomVC.sideDish1BannerImageView.hidden = YES;
                }
            }
            else if (self.orderMode == OrderAhead) {
                if ([self.orderAheadMenu isDishSoldOut:side1DishIndex]) {
                    self.fourCustomVC.sideDish1BannerImageView.hidden = NO;
                }
                else {
                    self.fourCustomVC.sideDish1BannerImageView.hidden = YES;
                }
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
        
        NSDictionary *dishInfo;
        
        if (self.orderMode == OnDemand) {
            dishInfo = [[BentoShop sharedInstance] getSideDish:side2DishIndex];
        }
        else if (self.orderMode == OrderAhead) {
            dishInfo = [self.orderAheadMenu getSideDish:side2DishIndex];
        }
        
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
            
            if (self.orderMode == OnDemand) {
                if ([[BentoShop sharedInstance] isDishSoldOut:side2DishIndex]) {
                    self.fourCustomVC.sideDish2BannerImageView.hidden = NO;
                }
                else {
                    self.fourCustomVC.sideDish2BannerImageView.hidden = YES;
                }
            }
            else if (self.orderMode == OrderAhead) {
                if ([self.orderAheadMenu isDishSoldOut:side2DishIndex]) {
                    self.fourCustomVC.sideDish2BannerImageView.hidden = NO;
                }
                else {
                    self.fourCustomVC.sideDish2BannerImageView.hidden = YES;
                }
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
        
        NSDictionary *dishInfo;
        
        if (self.orderMode == OnDemand) {
            dishInfo = [[BentoShop sharedInstance] getSideDish:side3DishIndex];
        }
        else if (self.orderMode == OrderAhead) {
            dishInfo = [self.orderAheadMenu getSideDish:side3DishIndex];
        }
        
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
            
            if (self.orderMode == OnDemand) {
                if ([[BentoShop sharedInstance] isDishSoldOut:side3DishIndex]) {
                    self.fourCustomVC.sideDish3BannerImageView.hidden = NO;
                }
                else {
                    self.fourCustomVC.sideDish3BannerImageView.hidden = YES;
                }
            }
            else if (self.orderMode == OrderAhead) {
                if ([self.orderAheadMenu isDishSoldOut:side3DishIndex]) {
                    self.fourCustomVC.sideDish3BannerImageView.hidden = NO;
                }
                else {
                    self.fourCustomVC.sideDish3BannerImageView.hidden = YES;
                }
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
        
        NSDictionary *dishInfo;
        
        if (self.orderMode == OnDemand) {
            dishInfo = [[BentoShop sharedInstance] getMainDish:mainDishIndex];
        }
        else if (self.orderMode == OrderAhead) {
            dishInfo = [self.orderAheadMenu getMainDish:mainDishIndex];
        }
        
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
            
            if (self.orderMode == OnDemand) {
                if ([[BentoShop sharedInstance] isDishSoldOut:mainDishIndex]) {
                    self.customVC.mainDishBannerImageView.hidden = NO;
                }
                else {
                    self.customVC.mainDishBannerImageView.hidden = YES;
                }
            }
            else if (self.orderMode == OrderAhead) {
                if ([self.orderAheadMenu isDishSoldOut:mainDishIndex]) {
                    self.customVC.mainDishBannerImageView.hidden = NO;
                }
                else {
                    self.customVC.mainDishBannerImageView.hidden = YES;
                }
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
        
        NSDictionary *dishInfo;
        
        if (self.orderMode == OnDemand) {
            dishInfo = [[BentoShop sharedInstance] getSideDish:side1DishIndex];
        }
        else if (self.orderMode == OrderAhead) {
            dishInfo = [self.orderAheadMenu getSideDish:side1DishIndex];
        }
        
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
            
            if (self.orderMode == OnDemand) {
                if ([[BentoShop sharedInstance] isDishSoldOut:side1DishIndex]) {
                    self.customVC.sideDish1BannerImageView.hidden = NO;
                }
                else {
                    self.customVC.sideDish1BannerImageView.hidden = YES;
                }
            }
            else if (self.orderMode == OrderAhead) {
                if ([self.orderAheadMenu isDishSoldOut:side1DishIndex]) {
                    self.customVC.sideDish1BannerImageView.hidden = NO;
                }
                else {
                    self.customVC.sideDish1BannerImageView.hidden = YES;
                }
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
        
        NSDictionary *dishInfo;
        
        if (self.orderMode == OnDemand) {
            dishInfo = [[BentoShop sharedInstance] getSideDish:side2DishIndex];
        }
        else if (self.orderMode == OrderAhead) {
            dishInfo = [self.orderAheadMenu getSideDish:side2DishIndex];
        }
        
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
            
            if (self.orderMode == OnDemand) {
                if ([[BentoShop sharedInstance] isDishSoldOut:side2DishIndex]) {
                    self.customVC.sideDish2BannerImageView.hidden = NO;
                }
                else {
                    self.customVC.sideDish2BannerImageView.hidden = YES;
                }
            }
            else if (self.orderMode == OrderAhead) {
                if ([self.orderAheadMenu isDishSoldOut:side2DishIndex]) {
                    self.customVC.sideDish2BannerImageView.hidden = NO;
                }
                else {
                    self.customVC.sideDish2BannerImageView.hidden = YES;
                }
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
        
        NSDictionary *dishInfo;
        
        if (self.orderMode == OnDemand) {
            dishInfo = [[BentoShop sharedInstance] getSideDish:side3DishIndex];
        }
        else if (self.orderMode == OrderAhead) {
            dishInfo = [self.orderAheadMenu getSideDish:side3DishIndex];
        }
        
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
            
            if (self.orderMode == OnDemand) {
                if ([[BentoShop sharedInstance] isDishSoldOut:side3DishIndex]) {
                    self.customVC.sideDish3BannerImageView.hidden = NO;
                }
                else {
                    self.customVC.sideDish3BannerImageView.hidden = YES;
                }
            }
            else if (self.orderMode == OrderAhead) {
                if ([self.orderAheadMenu isDishSoldOut:side3DishIndex]) {
                    self.customVC.sideDish3BannerImageView.hidden = NO;
                }
                else {
                    self.customVC.sideDish3BannerImageView.hidden = YES;
                }
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
        
        NSDictionary *dishInfo;
        
        if (self.orderMode == OnDemand) {
            dishInfo = [[BentoShop sharedInstance] getSideDish:side4DishIndex];
        }
        else if (self.orderMode == OrderAhead) {
            dishInfo = [self.orderAheadMenu getSideDish:side4DishIndex];
        }
        
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
            
            if (self.orderMode == OnDemand) {
                if ([[BentoShop sharedInstance] isDishSoldOut:side4DishIndex]) {
                    self.customVC.sideDish4BannerImageView.hidden = NO;
                }
                else {
                    self.customVC.sideDish4BannerImageView.hidden = YES;
                }
            }
            else if (self.orderMode == OrderAhead) {
                if ([self.orderAheadMenu isDishSoldOut:side4DishIndex]) {
                    self.customVC.sideDish4BannerImageView.hidden = NO;
                }
                else {
                    self.customVC.sideDish4BannerImageView.hidden = YES;
                }
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
    dispatch_async(dispatch_get_main_queue(), ^{
        [self checkAppState];
        [self setETA];
        [self setStartingPrice];
        [self showOrHideAddAnotherBentoAndViewAddons];
        [self setBuildButtonText];
        [self checkBentoCount];
        [self loadSelectedDishes];
        [self setCart];
        [self updateBottomButton];
        [self checkPickerState];
        [self setUpPickerData];
        [self updateWidget];
    });
}

- (void)setStartingPrice {
    NSMutableArray *mainDishesArray;
    
    if (self.orderMode == OnDemand) {
        if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Lunch"]) {
            mainDishesArray = [[[BentoShop sharedInstance] getMainDishes:@"todayLunch"] mutableCopy];
        }
        else {
            mainDishesArray = [[[BentoShop sharedInstance] getMainDishes:@"todayDinner"] mutableCopy];
        }
    }
    else if (self.orderMode == OrderAhead) {
        mainDishesArray = [self.orderAheadMenu.mainDishes mutableCopy];
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
        
        // if exists, show normal
        if (cents == 0) {
            self.startingPriceLabel.text = [NSString stringWithFormat:@"STARTING AT $%.0f", [sortedMainPrices[0] floatValue]];
        }
        // if no cents, just show whole number
        else {
            self.startingPriceLabel.text = [NSString stringWithFormat:@"STARTING AT $%@", sortedMainPrices[0]];
        }
    }
}

- (void)checkBentoCount {
    if ([[BentoShop sharedInstance] getTotalBentoCount] == 0) { // no bento
        [[BentoShop sharedInstance] addNewBento]; // add an empty one
    }
    else if ([[BentoShop sharedInstance] getCurrentBento] == nil) {
        [[BentoShop sharedInstance] setCurrentBento:[[BentoShop sharedInstance] getLastBento]]; // set current with current one in array
    }
}

- (void)setBuildButtonText {
    
    Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];
    NSString *strTitle;
    
    if ([currentBento isEmpty] == YES || currentBento == nil) {
        strTitle = [[AppStrings sharedInstance] getString:BUILD_TITLE]; // BUILD YOUR BENTO
    }
    else if ([currentBento isCompleted] == NO) {
        strTitle = [[AppStrings sharedInstance] getString:BUILD_CONTINUE_BUTTON]; // CONTINUE
    }
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
}

- (void)setCart {
    if ([[BentoShop sharedInstance] getCompletedBentoCount] > 0) {
        self.cartButton.enabled = YES;
        self.cartButton.selected = YES;
        [self.cartButton setImage:[UIImage imageNamed:@"mybento_nav_cart_act"] forState:UIControlStateNormal];
        
        self.countBadgeLabel.text = [NSString stringWithFormat:@"%ld", (long)[[BentoShop sharedInstance] getCompletedBentoCount] + (long)[[AddonList sharedInstance] getTotalCount]];
        self.countBadgeLabel.hidden = NO;
    }
    else {
        self.cartButton.enabled = NO;
        self.cartButton.selected = NO;
        
        self.countBadgeLabel.text = @"";
        self.countBadgeLabel.hidden = YES;
    }
}

//- (void)onUpdatedMenu:(NSNotification *)notification {
//    if (isThereConnection) {
//        [self refreshState];
//        [self updateUI];
//    }
//}

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
            [self updateUI];
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
    if (alertView.tag == 2016 && buttonIndex == 1) {
        Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];
        if (currentBento != nil && ![currentBento isCompleted]) {
            if (self.orderMode == OnDemand) {
                if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Lunch"]) {
                    [currentBento completeBento:@"todayLunch"];
                }
                else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Dinner"]) {
                    [currentBento completeBento:@"todayDinner"];
                }
            }
            else if (self.orderMode == OrderAhead) {
                [currentBento completeBentoWithOrderAheadMenu];
            }
        }
        
        [self onFinalize];
    }
    else if (alertView.tag == 2017 && buttonIndex == 1) {
        [self enableOnDemand];
        [self clearCart];
    }
    else if (alertView.tag == 2018 && buttonIndex == 1) {
        [self enableOrderAhead];
        [self clearCart];
    }
    else if (alertView.tag == 2019) {
        if (buttonIndex == 0){
            [self.orderAheadPickerView selectRow:selectedOrderAheadIndex inComponent:0 animated:YES];
        }
        else if (buttonIndex == 1) {
            [self clearCart];
            selectedOrderAheadIndex = selectedOrderAheadIndexForConfirm;
            [self updateUI];
        }
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
    chooseMainDishViewController.orderAheadMenu = self.orderAheadMenu;
    chooseMainDishViewController.orderMode = self.orderMode;
    
    [self.navigationController pushViewController:chooseMainDishViewController animated:YES];
}

- (void)onAddSideDish:(id)sender {
    UIButton *selectedButton = (UIButton *)sender;
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    ChooseSideDishViewController *chooseSideDishViewController = [storyboard instantiateViewControllerWithIdentifier:@"ChooseSideDishViewController"];
    chooseSideDishViewController.orderAheadMenu = self.orderAheadMenu;
    chooseSideDishViewController.orderMode = self.orderMode;
    chooseSideDishViewController.sideDishIndex = selectedButton.tag;
    
    [self.navigationController pushViewController:chooseSideDishViewController animated:YES];
}

- (void)onAddAnotherBento {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    ChooseMainDishViewController *chooseMainDishViewController = [storyboard instantiateViewControllerWithIdentifier:@"ChooseMainDishViewController"];
    chooseMainDishViewController.orderAheadMenu = self.orderAheadMenu;
    chooseMainDishViewController.orderMode = self.orderMode;
    
    ChooseSideDishViewController *chooseSideDishViewController = [storyboard instantiateViewControllerWithIdentifier:@"ChooseSideDishViewController"];
    chooseSideDishViewController.orderAheadMenu = self.orderAheadMenu;
    chooseSideDishViewController.orderMode = self.orderMode;
    
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
        if (self.orderMode == OnDemand) {
            if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Lunch"]) {
                [currentBento completeBento:@"todayLunch"];
            }
            else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Dinner"]) {
                [currentBento completeBento:@"todayDinner"];
            }
        }
        else if (self.orderMode == OrderAhead) {
            [currentBento completeBentoWithOrderAheadMenu];
        }
        
        [[BentoShop sharedInstance] addNewBento];
        
        [self updateUI];
    }
}

- (void)onViewAddons {
    [[Mixpanel sharedInstance] track:@"Tapped on View Add-ons"];
    [self presentAddOns];
}

- (void)presentAddOns {
    addonsVC.orderMode = self.orderMode;
    addonsVC.orderAheadMenu = self.orderAheadMenu;
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
    [self toggleDropDown];
}

- (IBAction)fadedViewButtonPressed:(id)sender {
    [self toggleDropDown];
}

- (IBAction)enableOnDemandButtonPressed:(id)sender {
    if ([self isCartEmpty]) {
        [self enableOnDemand];
    }
    else {
        MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"Items In Cart"
                                                            message:@"Clear cart to switch menus?"
                                                           delegate:self
                                                  cancelButtonTitle:@"NO"
                                                   otherButtonTitle:@"YES"];
        alertView.tag = 2017;
        [alertView showInView:self.view];
        alertView = nil;
    }
}

- (IBAction)enableOrderAheadButtonPressed:(id)sender {
    if ([self isCartEmpty]) {
        [self enableOrderAhead];
    }
    else {
        MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"Items In Cart"
                                                            message:@"Clear cart to switch menus?"
                                                           delegate:self
                                                  cancelButtonTitle:@"NO"
                                                   otherButtonTitle:@"YES"];
        alertView.tag = 2018;
        [alertView showInView:self.view];
        alertView = nil;
    }
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
    
    if (self.orderMode == OrderAhead && selectedOrderAheadIndex == 0) {
        if ([[CountdownTimer sharedInstance] shouldShowCountDown]) {
            
            if (![[CountdownTimer sharedInstance].finalCountDownTimerValue isEqualToString:@"0:00"]) {
                strTitle = [NSString stringWithFormat:@"%@ - TIME REMAINING %@", strTitle, [CountdownTimer sharedInstance].finalCountDownTimerValue];
            }
            else {
                [self clearCart];
//                [self updateUI];
                [self.navigationController popToRootViewControllerAnimated:YES];
            }
        }
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

#pragma mark Cart Status
- (BOOL)isCartEmpty {
    return [[BentoShop sharedInstance] getTotalBentoCount] == 0 || ([[BentoShop sharedInstance] getTotalBentoCount] == 1 && [[[BentoShop sharedInstance] getLastBento] isEmpty] && [AddonList sharedInstance].addonList.count == 0);
}

- (void)clearCart {
    [[BentoShop sharedInstance] resetBentoArray];
    [[AddonList sharedInstance] emptyList];
}

#pragma mark Refresh State

- (void)refreshStateOnLaunch {
    
    if ([[BentoShop sharedInstance] isThereOrderAhead]) {
        
        [self setUpPickerData];
        BOOL exists = NO;
        
        for (OrderAheadMenu *orderAheadMenu in [[BentoShop sharedInstance] getOrderAheadMenus]) {
            
            NSDictionary *savedOrderAheadMenuIdAndName = [[NSUserDefaults standardUserDefaults] rm_customObjectForKey:@"savedOrderAheadMenu"];
            if (savedOrderAheadMenuIdAndName != nil) {
                
                // does menu_id still exist?
                if (savedOrderAheadMenuIdAndName[@"menuId"] == orderAheadMenu.menuId) {
                    
                    // yes menuId exists, set UI to the selection of the saved menu
                    exists = YES;
                    
                    for (int i = 0; i < menuNames.count; i++) {
                        // match saved menu with the list of available order ahead menus
                        if ([menuNames[i] isEqualToString:savedOrderAheadMenuIdAndName[@"name"]]) {
                            [self enableOrderAhead];
                            selectedOrderAheadIndex = i;
                            [self.orderAheadPickerView selectRow:i inComponent:0 animated:YES];
                            [self updatePickerButtonTitle];
                        }
                    }
                }
            }
        }
        
        if (exists == NO) {
            [self clearCart];
            NSNumber *isSelectedNum = (NSNumber *)self.widget[@"selected"];
            if ([isSelectedNum boolValue]) {
                [self enableOnDemand];
            }
            else {
                [self enableOrderAhead];
            }
            
            selectedOrderAheadIndex = 0;
        }
        
        
        self.selectedOrderAheadTimeRangeIndex = 0;
    }
    
    if ([[BentoShop sharedInstance] isThereOnDemand] && [[BentoShop sharedInstance] isThereOrderAhead]) {
        self.pickerState = Both;
        [self installOnDemand];
        [self installOrderAhead];
        [self updateWidget];
        
        if ([self isCartEmpty] == YES) {
            [self defaultToOnDemandOrOrderAhead];
        }
    }
    else if ([[BentoShop sharedInstance] isThereOnDemand]) {
        self.pickerState = OnDemandOnly;
        [self removeOrderAhead];
        [self installOnDemand];
        [self updateWidget];
        [self enableOnDemand];
        
        // if it is on demand only -> clear any orderahead
    }
    else if ([[BentoShop sharedInstance] isThereOrderAhead]) {
        self.pickerState = OrderAheadOnly;
        [self removeOnDemand];
        [self installOrderAhead];
        [self enableOrderAhead];
        
        // if it is order ahead only -> clear any on demand
    }
}

- (void)refreshState {
    if ([[BentoShop sharedInstance] isThereOrderAhead]) {
        selectedOrderAheadIndex = 0;
        self.selectedOrderAheadTimeRangeIndex = 0;
        [self setUpPickerData];
    }
    
    if ([[BentoShop sharedInstance] isThereOnDemand] && [[BentoShop sharedInstance] isThereOrderAhead]) {
        self.pickerState = Both;
        [self installOnDemand];
        [self installOrderAhead];
        [self updateWidget];
    }
    else if ([[BentoShop sharedInstance] isThereOnDemand]) {
        self.pickerState = OnDemandOnly;
        [self removeOrderAhead];
        [self installOnDemand];
        [self updateWidget];
        [self enableOnDemand];
    }
    else if ([[BentoShop sharedInstance] isThereOrderAhead]) {
        self.pickerState = OrderAheadOnly;
        [self removeOnDemand];
        [self installOrderAhead];
        [self enableOrderAhead];
    }
}

- (void)checkPickerState {
    PickerState newState;
    if ([[BentoShop sharedInstance] isThereOnDemand] && [[BentoShop sharedInstance] isThereOrderAhead]) {
        newState = Both;
    }
    else if ([[BentoShop sharedInstance] isThereOnDemand]) {
        newState = OnDemandOnly;
    }
    else if ([[BentoShop sharedInstance] isThereOrderAhead]) {
        newState = OrderAheadOnly;
    }

    // state changed!
    if (newState != self.pickerState) {
    
        self.pickerState = newState;
        
        [self.view layoutIfNeeded];
        
        [UIView animateWithDuration:0.5 animations:^{
            [self refreshState];
            
            if (self.isToggledOn == NO) {
                [self toggleOn];
            }
            
//            [self.view layoutIfNeeded];
        }];
    }
}

- (void)viewDidLayoutSubviews {
    [self.view layoutIfNeeded];
}

- (void)defaultToOnDemandOrOrderAhead {
    NSNumber *isSelectedNum = (NSNumber *)self.widget[@"selected"];
    if ([isSelectedNum boolValue]) {
        [self enableOnDemand];
    }
    else {
        [self enableOrderAhead];
    }
}

#pragma mark Install / Remove

- (void)removeOnDemand {
    if (self.onDemandView.hidden == NO) {
        self.onDemandView.hidden = YES;
        self.onDemandViewHeightConstraint.constant = 0;
    }
}

- (void)installOnDemand {
    if (self.onDemandView.hidden == YES) {
        self.onDemandView.hidden = NO;
        self.onDemandViewHeightConstraint.constant = 59;
    }
}

- (void)removeOrderAhead {
    if (self.orderAheadView.hidden == NO) {
        self.orderAheadView.hidden = YES;
        self.orderAheadView.hidden = YES;
    }
    
    self.orderAheadHeightConstraint.constant = 0;
    self.orderAheadHeightConstraint.constant = 0;
}

- (void)installOrderAhead {
    if (self.orderAheadView.hidden == YES) {
        self.orderAheadView.hidden = NO;
        self.orderAheadView.hidden = NO;
        
        self.orderAheadHeightConstraint.constant = 140;
        self.orderAheadHeightConstraint.constant = 140;
    }
}

#pragma mark Toggle

- (void)toggleDropDown {
    [self.view layoutIfNeeded];
    
    if (self.fadedViewButton.alpha == 0) {
        [UIView animateWithDuration:0.5 animations:^{
            [self toggleOn];
        }];
    }
    else {
        [UIView animateWithDuration:0.5 animations:^{
            [self toggleOff];
        }];
    }
}

- (void)toggleOn {
    self.isToggledOn = YES;
    
    self.fadedViewButton.alpha = 0.6;
    
    self.dropDownViewTopConstraint.constant = 64;
    
//    [self.view layoutIfNeeded];
}

- (void)toggleOff {
    self.isToggledOn = NO;
    
    self.fadedViewButton.alpha = 0;
    
    self.dropDownViewTopConstraint.constant = 64 - self.dropDownView.frame.size.height;
    
    [self.view layoutIfNeeded];
}

#pragma mark Update Menu
- (void)updateMenu {
    if (self.orderMode == OrderAhead) {
        for (OrderAheadMenu *orderAheadMenu in [[BentoShop sharedInstance] getOrderAheadMenus]) {
            if ([menuOrderAhead isEqualToString:orderAheadMenu.name]) {
                self.orderAheadMenu = orderAheadMenu;
                
                [[NSUserDefaults standardUserDefaults] rm_setCustomObject:@{
                                                                            @"menuId": self.orderAheadMenu.menuId,
                                                                            @"name": self.orderAheadMenu.name
                                                                            }
                                                                   forKey:@"savedOrderAheadMenu"];
            }
        }
    }
}

#pragma mark Widget
- (void)updateWidget {
    if ([[BentoShop sharedInstance] isThereWidget]) {
        
        self.widget = [[BentoShop sharedInstance] getOnDemandWidget];
        
        /*---ASAP---*/
        self.asapMenuLabel.text = self.widget[@"title"];
        self.asapDescriptionLabel.text = self.widget[@"text"];
        
        // resize to make room for text
        self.asapDescriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [self.asapDescriptionLabel sizeToFit];
        self.asapViewHeightConstraint.constant = self.asapDescriptionLabel.frame.size.height + 60;
        
        [self showOrHidePreview];
    }
}

- (void)showOrHidePreview {
    if (self.orderMode == OnDemand) {
        if ([self.widget[@"state"] isEqualToString:@"open"]) {
            [self hidePreview];
        }
        else if (self.orderMode == OnDemand) {
            [self showPreview];
        }
    }
    else {
        [self hidePreview];
    }
}

- (void)showPreview {
    if (self.menuPreviewVC == nil) {
        self.menuPreviewVC = [[MenuPreviewViewController alloc] init];
    }
    [self addChildViewController:self.menuPreviewVC]; // 1. notify the prent VC that a child is being added
    self.bgView.frame = self.menuPreviewVC.view.bounds; // 2. before adding the child's view to its view hierarchy, the parent VC sets the child's size and position
    [self.bgView addSubview:self.menuPreviewVC.view];
    [self.menuPreviewVC didMoveToParentViewController:self]; // tell the child VC of its new parent
    
    self.bottomButton.hidden = YES;
}

- (void)hidePreview {
    // store is open, no preview
    [self.menuPreviewVC willMoveToParentViewController:nil]; // 1. let the child VC know that it will be removed
    [self.menuPreviewVC.view removeFromSuperview]; // 2. remove the child VC's view
    [self.menuPreviewVC removeFromParentViewController]; // 3. remove the child VC
    
    self.bottomButton.hidden = NO;
}

#pragma mark Other Button Methods

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
    alertView.tag = 2016;
    [alertView showInView:self.view];
    alertView = nil;
}

- (void)gotoOrderScreen {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    DeliveryLocationViewController *deliveryLocationViewController = [storyboard instantiateViewControllerWithIdentifier:@"DeliveryLocationViewController"];
    CompleteOrderViewController *completeOrderViewController = [storyboard instantiateViewControllerWithIdentifier:@"CompleteOrderViewController"];
    self.orderAheadMenu.deliveryPrice = self.orderAheadMenu.rawTimeRangesArray[selectedOrderAheadIndex][@"delivery_price"];
    self.orderAheadMenu.scheduledWindowStartTime = self.orderAheadMenu.rawTimeRangesArray[selectedOrderAheadIndex][@"start"];
    self.orderAheadMenu.scheduledWindowEndTime = self.orderAheadMenu.rawTimeRangesArray[selectedOrderAheadIndex][@"end"];
    completeOrderViewController.orderAheadMenu = self.orderAheadMenu;
    completeOrderViewController.orderMode = self.orderMode;
    completeOrderViewController.selectedOrderAheadIndex = selectedOrderAheadIndex;
    
    
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
            if (loadingHUD == nil) {
                loadingHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
                [loadingHUD showInView:self.view];
            }
            
            // check if saved address is inside CURRENT service area
            [[BentoShop sharedInstance] checkIfSelectedLocationIsInAnyZone:placeInfo.location.coordinate completion:^(BOOL isSelectedLocationInZone, NSString *appState) {
                [loadingHUD dismiss];
                loadingHUD = nil;
                
                if (isSelectedLocationInZone) {
                    [self openAccountViewController:[CompleteOrderViewController class]];
//                    [self openAccountViewController:completeOrderViewController];
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
            if (loadingHUD == nil) {
                loadingHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
                [loadingHUD showInView:self.view];
            }
            
            [[BentoShop sharedInstance] checkIfSelectedLocationIsInAnyZone:placeInfo.location.coordinate completion:^(BOOL isSelectedLocationInZone, NSString *appState) {
                [loadingHUD dismiss];
                loadingHUD = nil;
                
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
    [self.view layoutIfNeeded];
    
    self.orderMode = OnDemand;
    
    self.onDemandGreenView1.alpha = 1.0;
    self.onDemandGreenViewWidthConstraint.constant = 10;
    
    self.orderAheadGreenView1.alpha = 0.5;
    self.orderAheadGreenViewWidthConstraint.constant = 5;
    
    self.enabledOnDemandButton.hidden = YES;
    self.enabledOrderAheadButton.hidden = NO;
    
    [self setOnDemandTitle];
    
    [self showOrHideETA];
    
    [self updateUI];
    
    [self showOrHidePreview];
    
    [self.view layoutIfNeeded];
}

- (void)enableOrderAhead {
    [self.view layoutIfNeeded];
    
    self.orderMode = OrderAhead;
    
    self.onDemandGreenView1.alpha = 0.5;
    self.onDemandGreenViewWidthConstraint.constant = 5;
    
    self.orderAheadGreenView1.alpha = 1.0;
    self.orderAheadGreenViewWidthConstraint.constant = 10;
    
    self.enabledOnDemandButton.hidden = NO;
    self.enabledOrderAheadButton.hidden = YES;
    
    [self updatePickerButtonTitle];
    
    [self showOrHideETA];
    
    [self updateUI];
    
    [self hidePreview];
    
    [self.view layoutIfNeeded];
}

- (void)showOrHideETA {
    if (self.orderMode == OnDemand) {
        self.etaLabel.hidden = NO;
        self.etaBannerDivider.hidden = NO;
        
        [self.view removeConstraint:self.xCenterConstraintForStartingPriceLabel];
    }
    else if (self.orderMode == OrderAhead) {
        self.etaLabel.hidden = YES;
        self.etaBannerDivider.hidden = YES;
        
        [self.view addConstraint:self.xCenterConstraintForStartingPriceLabel];
    }
    
    [self.view layoutIfNeeded];
}

- (void)setOnDemandTitle {
    menuOnDemand = self.asapMenuLabel.text;
    timeOnDemand = self.asapTimeLabel.text;
    [self updatePickerButtonTitle];
}

- (void)onFinalize {
    if ([self isInMiddleOfBuildingBento]) {
        [self showConfirmMsg];
    }
    else {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"AutoShowAddons"] == YES) {
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"didAutoShowAddons"] != YES) {
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"didAutoShowAddons"];
                [self presentAddOns];
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

- (void)setUpPickerData {
    [menuNames removeAllObjects];
    [menuTimes removeAllObjects];
    
    for (OrderAheadMenu *orderAheadMenu in [[BentoShop sharedInstance] getOrderAheadMenus]) {
        [menuNames addObject: orderAheadMenu.name];
        [menuTimes addObject: orderAheadMenu.times];
    }
    
    // if selectedOrderAheadIndex was say for example at 3 (4 menus), but one OA was remove and now there's only 3 menus. then menuNames[3] would not work because there's no more index 3.
    // in this case, push selectedOrderAheadIndex back 1
    if ((menuNames.count - 1) < selectedOrderAheadIndex) {
        selectedOrderAheadIndex = menuNames.count - 1;
    }
    
    [self.orderAheadPickerView reloadAllComponents];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 2;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (component == 0) {
        if (menuNames.count == 0) {
            return 0;
        }
        return menuNames.count;
    }
    else {
        if (menuTimes.count == 0) {
            return 0;
        }
        return [menuTimes[selectedOrderAheadIndex] count];
    }
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (component == 0) {
        if (menuNames.count == 0) {
            return nil;
        }
        return menuNames[row];
    }
    else {
        if (menuTimes.count == 0) {
            return nil;
        }
        return menuTimes[selectedOrderAheadIndex][row];
    }
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    
    UILabel *pickerLabel = [[UILabel alloc] init];
    
    if (component == 0) {
        pickerLabel.text = menuNames[row];
    }
    else {
        pickerLabel.text = menuTimes[selectedOrderAheadIndex][row];
    }
    
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
    
    [self updatePickerButtonTitle];
    
    return pickerLabel;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {

    if (component == 0) {
        if ([self isCartEmpty]) {
            menuOrderAhead = menuNames[row];
            selectedOrderAheadIndex = row;
            [pickerView reloadComponent:1];
            [pickerView selectRow:0 inComponent:1 animated:YES];
        }
        else if (selectedOrderAheadIndex != row) {
            MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"Items In Cart"
                                                                message:@"Clear cart to switch menus?"
                                                               delegate:self
                                                      cancelButtonTitle:@"NO"
                                                       otherButtonTitle:@"YES"];
            alertView.tag = 2019;
            [alertView showInView:self.view];
            alertView = nil;
            
            selectedOrderAheadIndexForConfirm = row;
        }
    }
    else {
        // if time range is sold-out
        if ([menuTimes[selectedOrderAheadIndex][row] containsString:@"sold-out"]) {
            [pickerView selectRow:row + 1 inComponent:component animated:YES];
            timeOrderAhead = menuTimes[selectedOrderAheadIndex][row + 1];
            self.selectedOrderAheadTimeRangeIndex = row + 1;
        }
        else {
            timeOrderAhead = menuTimes[selectedOrderAheadIndex][row];
            
            self.selectedOrderAheadTimeRangeIndex = row;
        }
    }
}

- (void)updatePickerButtonTitle {
    menuOrderAhead = [self pickerView:self.orderAheadPickerView titleForRow:[self.orderAheadPickerView selectedRowInComponent:0] forComponent:0];
    timeOrderAhead = [self pickerView:self.orderAheadPickerView titleForRow:[self.orderAheadPickerView selectedRowInComponent:1] forComponent:1];
    
    if (self.orderMode == OnDemand) {
        [self.pickerButton setTitle:[NSString stringWithFormat:@"%@, %@ ▾", menuOnDemand, timeOnDemand] forState:UIControlStateNormal];
    }
    else if (self.orderMode == OrderAhead) {
        [self.pickerButton setTitle:[NSString stringWithFormat:@"%@, %@ ▾", menuOrderAhead, timeOrderAhead] forState:UIControlStateNormal];
    }
    
    [self updateMenu];
}


@end
