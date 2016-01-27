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

#import "OrdersViewController.h"

@interface FiveHomeViewController () <CustomViewControllerDelegate, FiveCustomViewControllerDelegate, MyAlertViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic) CustomViewController *fourCustomVC;
@property (nonatomic) FiveCustomViewController *customVC;
@property (nonatomic) MenuPreviewViewController *menuPreviewVC;

@property (nonatomic) BOOL isFirstSelection;
@property (nonatomic) BOOL isToggledOn;

@property (nonatomic) NSDictionary *widget;

@property (nonatomic) NSLayoutConstraint *xCenterConstraintForStartingPriceLabel;

@property (nonatomic) NSInteger selectedOrderAheadIndex;
@property (nonatomic) NSInteger selectedOrderAheadIndexForConfirm;

@end

static OrderMode orderMode;
static OrderAheadMenu *orderAheadMenu;

@implementation FiveHomeViewController
{
    AddonsViewController *addonsVC;
    JGProgressHUD *loadingHUD;
    
    UILabel *dinnerTitleLabel;
    
    BOOL isThereConnection;
    
    NSArray *myDatabase;
    NSString *menuOnDemand;
    NSString *menuOrderAhead;
    NSString *timeOrderAhead;
    
    NSMutableArray *menuNames; // [date, date, date]
    NSMutableArray *menuTimes; // [[time range, time ranges, time ranges], [time range, time ranges, time ranges], [time range, time ranges, time ranges]]
    
    OrderMode tempOrderMode;
    NSInteger tempSelectedOrderAheadIndex;
    NSInteger tempSelectedOrderAheadTimeRangeIndex;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus:) name:USER_NOTIFICATION_UPDATED_MENU object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus:) name:USER_NOTIFICATION_UPDATED_STATUS object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noConnection) name:@"networkError" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yesConnection) name:@"networkConnected" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startTimerOnViewedScreen) name:@"enteredForeground" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endTimerOnViewedScreen) name:@"enteringBackground" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus:) name:@"enteredForeground" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateBottomButton) name:@"showCountDownTimer" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(presentSignedInVCThenPushToOrdersVC) name:@"didPopBackFromViewAllOrdersButton" object:nil];
    
    [[BentoShop sharedInstance] resetBentoArray];
    [[AddonList sharedInstance] emptyList];
    
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
    
    self.isToggledOn = YES;
    
    self.isFirstSelection = YES;
    
    self.cancelButton.hidden = YES;
    
    self.doneButtonWidthConstraint.constant = SCREEN_WIDTH;
    
    self.onDemandCheckMarkImageView.hidden = YES;
    self.orderAheadCheckMarkImageView.hidden = YES;
    
    self.asapMenuLabel.hidden = YES;
    self.asapDescriptionLabel.hidden = YES;
    self.orderAheadTitleLabel.hidden = YES;
    
    self.asapMenuLabel.adjustsFontSizeToFitWidth = YES;
    self.orderAheadTitleLabel.adjustsFontSizeToFitWidth = YES;
    
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
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"checkedForLocationOnLaunch"] == NO) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"checkedForLocationOnLaunch"];
        [self checkLocationOnLoad];
    }
    
    self.fourCustomVC.buildButton.hidden = YES;
    self.fourCustomVC.viewAddonsButton.hidden = YES;

    [self beginLoadingData];
}

- (void)beginLoadingData {
    if (loadingHUD == nil) {
        loadingHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
        [loadingHUD showInView:self.view];
    }
    
    SVPlacemark *placemark = [[NSUserDefaults standardUserDefaults] rm_customObjectForKey:@"delivery_location"];
    if (placemark != nil) {
        [[BentoShop sharedInstance] checkIfSelectedLocationIsInAnyZone:placemark.location.coordinate completion:^(BOOL isSelectedLocationInZone, NSString *appState) {
            
            self.asapMenuLabel.hidden = NO;
            self.asapDescriptionLabel.hidden = NO;
            self.orderAheadTitleLabel.hidden = NO;
            self.orderAheadTitleLabel.text = [[BentoShop sharedInstance] getOrderAheadTitleString];
            
            [self.doneButton setTitle:[[[AppStrings sharedInstance] getString:DONE_BUTTON_TEXT] uppercaseString] forState:UIControlStateNormal];
            
            [self refreshStateOnLaunch];
            
            [self checkAppState];
            [self setETA];
            [self setStartingPrice];
            [self showOrHideAddAnotherBentoAndViewAddons];
            [self setBuildButtonText];
            [self updateBottomButton];
            
            [self checkBentoCount];
            [self loadSelectedDishes];
            [self setCart];
            
            [self performSelector:@selector(finishedLoadingData) withObject:nil afterDelay:1];
        }];
    }
}

- (void)finishedLoadingData {
    [loadingHUD dismiss];
    loadingHUD = nil;
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
    

    
    // don't run updateUI when loading for first time
    if (loadingHUD == nil) {
        [self checkAppState];
        [self setETA];
        [self setStartingPrice];
        [self showOrHideAddAnotherBentoAndViewAddons];
        [self setBuildButtonText];
        [self updateBottomButton];

        [self checkBentoCount];
        [self loadSelectedDishes];
        [self setCart];
    }
    
    [self startTimerOnViewedScreen];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self endTimerOnViewedScreen];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)presentSignedInVCThenPushToOrdersVC {
    SignedInSettingsViewController *signedInVC = [[SignedInSettingsViewController alloc] init];
    signedInVC.didComeFromViewAllOrdersButton = YES;
    
    UINavigationController *navC = [[UINavigationController alloc] initWithRootViewController:signedInVC];
    navC.navigationBar.hidden = YES;
    
    [self.navigationController presentViewController:navC animated:YES completion:nil];
}

#pragma  mark Check Location
- (void)checkLocationOnLoad {
//    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
//    CLLocationCoordinate2D gpsLocation = [appDelegate getGPSLocation];
    
//     no gps
//    if (gpsLocation.latitude == 0 && gpsLocation.longitude == 0) {
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
//    }
//    // yes gps
//    else {
//        // never saved an address before
//        if ([[NSUserDefaults standardUserDefaults] rm_customObjectForKey:@"delivery_location"] == nil) {
//            [self nextToBuildShowMap];
//        }
//        else {
//            [[BentoShop sharedInstance] checkIfSelectedLocationIsInAnyZone:gpsLocation completion:^(BOOL isSelectedLocationInZone, NSString *appState) {
//                if (isSelectedLocationInZone == NO) {
//                    [self nextToBuildShowMap];
//                }
//                else {
//                    [self checkIfInZoneButNoMenuAndNotClosed:appState];
//                }
//            }];
//        }
//    }

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
        
        if (orderMode == OnDemand) {
            dishInfo = [[BentoShop sharedInstance] getMainDish:mainDishIndex];
        }
        else {
            dishInfo = [orderAheadMenu getMainDish:mainDishIndex];
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
            
            if (orderMode == OnDemand) {
                if ([[BentoShop sharedInstance] isDishSoldOut:mainDishIndex]) {
                    self.fourCustomVC.mainDishBannerImageView.hidden = NO;
                }
                else {
                    self.fourCustomVC.mainDishBannerImageView.hidden = YES;
                }
            }
            else {
                if ([orderAheadMenu isDishSoldOut:mainDishIndex]) {
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
        
        if (orderMode == OnDemand) {
            dishInfo = [[BentoShop sharedInstance] getSideDish:side1DishIndex];
        }
        else {
            dishInfo = [orderAheadMenu getSideDish:side1DishIndex];
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
            
            if (orderMode == OnDemand) {
                if ([[BentoShop sharedInstance] isDishSoldOut:side1DishIndex]) {
                    self.fourCustomVC.sideDish1BannerImageView.hidden = NO;
                }
                else {
                    self.fourCustomVC.sideDish1BannerImageView.hidden = YES;
                }
            }
            else {
                if ([orderAheadMenu isDishSoldOut:side1DishIndex]) {
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
        
        if (orderMode == OnDemand) {
            dishInfo = [[BentoShop sharedInstance] getSideDish:side2DishIndex];
        }
        else {
            dishInfo = [orderAheadMenu getSideDish:side2DishIndex];
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
            
            if (orderMode == OnDemand) {
                if ([[BentoShop sharedInstance] isDishSoldOut:side2DishIndex]) {
                    self.fourCustomVC.sideDish2BannerImageView.hidden = NO;
                }
                else {
                    self.fourCustomVC.sideDish2BannerImageView.hidden = YES;
                }
            }
            else {
                if ([orderAheadMenu isDishSoldOut:side2DishIndex]) {
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
        
        if (orderMode == OnDemand) {
            dishInfo = [[BentoShop sharedInstance] getSideDish:side3DishIndex];
        }
        else {
            dishInfo = [orderAheadMenu getSideDish:side3DishIndex];
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
            
            if (orderMode == OnDemand) {
                if ([[BentoShop sharedInstance] isDishSoldOut:side3DishIndex]) {
                    self.fourCustomVC.sideDish3BannerImageView.hidden = NO;
                }
                else {
                    self.fourCustomVC.sideDish3BannerImageView.hidden = YES;
                }
            }
            else {
                if ([orderAheadMenu isDishSoldOut:side3DishIndex]) {
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
        
        if (orderMode == OnDemand) {
            dishInfo = [[BentoShop sharedInstance] getMainDish:mainDishIndex];
        }
        else if (orderMode == OrderAhead) {
            dishInfo = [orderAheadMenu getMainDish:mainDishIndex];
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
            
            if (orderMode == OnDemand) {
                if ([[BentoShop sharedInstance] isDishSoldOut:mainDishIndex]) {
                    self.customVC.mainDishBannerImageView.hidden = NO;
                }
                else {
                    self.customVC.mainDishBannerImageView.hidden = YES;
                }
            }
            else if (orderMode == OrderAhead) {
                if ([orderAheadMenu isDishSoldOut:mainDishIndex]) {
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
        
        if (orderMode == OnDemand) {
            dishInfo = [[BentoShop sharedInstance] getSideDish:side1DishIndex];
        }
        else if (orderMode == OrderAhead) {
            dishInfo = [orderAheadMenu getSideDish:side1DishIndex];
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
            
            if (orderMode == OnDemand) {
                if ([[BentoShop sharedInstance] isDishSoldOut:side1DishIndex]) {
                    self.customVC.sideDish1BannerImageView.hidden = NO;
                }
                else {
                    self.customVC.sideDish1BannerImageView.hidden = YES;
                }
            }
            else if (orderMode == OrderAhead) {
                if ([orderAheadMenu isDishSoldOut:side1DishIndex]) {
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
        
        if (orderMode == OnDemand) {
            dishInfo = [[BentoShop sharedInstance] getSideDish:side2DishIndex];
        }
        else if (orderMode == OrderAhead) {
            dishInfo = [orderAheadMenu getSideDish:side2DishIndex];
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
            
            if (orderMode == OnDemand) {
                if ([[BentoShop sharedInstance] isDishSoldOut:side2DishIndex]) {
                    self.customVC.sideDish2BannerImageView.hidden = NO;
                }
                else {
                    self.customVC.sideDish2BannerImageView.hidden = YES;
                }
            }
            else if (orderMode == OrderAhead) {
                if ([orderAheadMenu isDishSoldOut:side2DishIndex]) {
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
        
        if (orderMode == OnDemand) {
            dishInfo = [[BentoShop sharedInstance] getSideDish:side3DishIndex];
        }
        else if (orderMode == OrderAhead) {
            dishInfo = [orderAheadMenu getSideDish:side3DishIndex];
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
            
            if (orderMode == OnDemand) {
                if ([[BentoShop sharedInstance] isDishSoldOut:side3DishIndex]) {
                    self.customVC.sideDish3BannerImageView.hidden = NO;
                }
                else {
                    self.customVC.sideDish3BannerImageView.hidden = YES;
                }
            }
            else if (orderMode == OrderAhead) {
                if ([orderAheadMenu isDishSoldOut:side3DishIndex]) {
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
        
        if (orderMode == OnDemand) {
            dishInfo = [[BentoShop sharedInstance] getSideDish:side4DishIndex];
        }
        else if (orderMode == OrderAhead) {
            dishInfo = [orderAheadMenu getSideDish:side4DishIndex];
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
            
            if (orderMode == OnDemand) {
                if ([[BentoShop sharedInstance] isDishSoldOut:side4DishIndex]) {
                    self.customVC.sideDish4BannerImageView.hidden = NO;
                }
                else {
                    self.customVC.sideDish4BannerImageView.hidden = YES;
                }
            }
            else if (orderMode == OrderAhead) {
                if ([orderAheadMenu isDishSoldOut:side4DishIndex]) {
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
    
        [self checkBentoCount];
        [self setCart];
        [self loadSelectedDishes];
    
        [self setETA];
        [self setStartingPrice];
        
        [self showOrHideAddAnotherBentoAndViewAddons];
        [self setBuildButtonText];
        
        [self updateBottomButton];
        [self setUpPickerData];
        [self updateWidget];
        [self updateOrderAheadWidget];
        NSLog(@"Order Mode - %ld", (unsigned long)orderMode);
        [self updatePickerButtonTitle];
    });
}

- (void)setStartingPrice {
    NSMutableArray *mainDishesArray;
    
    if (orderMode == OnDemand) {
        if ([[[BentoShop sharedInstance] getOnDemandMealMode] isEqualToString:@"lunch"]) {
            mainDishesArray = [[[BentoShop sharedInstance] getMainDishes:@"todayLunch"] mutableCopy];
        }
        else if ([[[BentoShop sharedInstance] getOnDemandMealMode] isEqualToString:@"dinner"]) {
            mainDishesArray = [[[BentoShop sharedInstance] getMainDishes:@"todayDinner"] mutableCopy];
        }
    }
    else if (orderMode == OrderAhead) {
        mainDishesArray = [orderAheadMenu.mainDishes mutableCopy];
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
            if (orderMode == OnDemand) {
                if ([[[BentoShop sharedInstance] getOnDemandMealMode] isEqualToString:@"lunch"]) {
                    [currentBento completeBento:@"todayLunch"];
                }
                else if ([[[BentoShop sharedInstance] getOnDemandMealMode] isEqualToString:@"dinner"]) {
                    [currentBento completeBento:@"todayDinner"];
                }
            }
            else if (orderMode == OrderAhead) {
                [currentBento completeBentoWithOrderAheadMenu];
            }
        }
        
        [self onFinalize];
    }
    else if (alertView.tag == 2017 && buttonIndex == 1) {
        
        [self clearCart];
        
        // set selected flags with temp flags
        orderMode = tempOrderMode;
        self.selectedOrderAheadIndex = tempSelectedOrderAheadIndex;
        self.selectedOrderAheadTimeRangeIndex = tempSelectedOrderAheadTimeRangeIndex;
        
        [self showOrHideETA];
        [self showOrHidePreview];
        
        [self updateMenu];
        [self toggleDropDown];
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
    chooseMainDishViewController.orderAheadMenu = orderAheadMenu;
    chooseMainDishViewController.orderMode = orderMode;
    
    [self.navigationController pushViewController:chooseMainDishViewController animated:YES];
}

- (void)onAddSideDish:(id)sender {
    UIButton *selectedButton = (UIButton *)sender;
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    ChooseSideDishViewController *chooseSideDishViewController = [storyboard instantiateViewControllerWithIdentifier:@"ChooseSideDishViewController"];
    chooseSideDishViewController.orderAheadMenu = orderAheadMenu;
    chooseSideDishViewController.orderMode = orderMode;
    chooseSideDishViewController.sideDishIndex = selectedButton.tag;
    
    [self.navigationController pushViewController:chooseSideDishViewController animated:YES];
}

- (void)onAddAnotherBento {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    ChooseMainDishViewController *chooseMainDishViewController = [storyboard instantiateViewControllerWithIdentifier:@"ChooseMainDishViewController"];
    chooseMainDishViewController.orderAheadMenu = orderAheadMenu;
    chooseMainDishViewController.orderMode = orderMode;
    
    ChooseSideDishViewController *chooseSideDishViewController = [storyboard instantiateViewControllerWithIdentifier:@"ChooseSideDishViewController"];
    chooseSideDishViewController.orderAheadMenu = orderAheadMenu;
    chooseSideDishViewController.orderMode = orderMode;
    
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
        if (orderMode == OnDemand) {
            if ([[[BentoShop sharedInstance] getOnDemandMealMode] isEqualToString:@"lunch"]) {
                [currentBento completeBento:@"todayLunch"];
            }
            else if ([[[BentoShop sharedInstance] getOnDemandMealMode] isEqualToString:@"dinner"]) {
                [currentBento completeBento:@"todayDinner"];
            }
        }
        else if (orderMode == OrderAhead) {
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
    addonsVC.orderMode = orderMode;
    addonsVC.orderAheadMenu = orderAheadMenu;
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
    if (self.isToggledOn == NO) {
        
        if (orderMode == OnDemand) {
            [self.view layoutIfNeeded];
            
            tempOrderMode = OnDemand;
            
            self.orderAheadCheckMarkImageView.hidden = YES;
            self.onDemandCheckMarkImageView.hidden = NO;
            self.orderAheadPickerContainerViewHeightConstraint.constant = 0;
            self.orderAheadPickerView.hidden = YES;
            
//            [self setOnDemandTitle];
            
            [self.view layoutIfNeeded];
        }
        else {
            [self.view layoutIfNeeded];
            
            tempOrderMode = OrderAhead;
            
            self.onDemandCheckMarkImageView.hidden = YES;
            self.orderAheadCheckMarkImageView.hidden = NO;
            self.orderAheadPickerContainerViewHeightConstraint.constant = 150;
            self.orderAheadPickerView.hidden = NO;
            
//            [self updatePickerButtonTitle];
            
            [self.view layoutIfNeeded];
            
            [self.orderAheadPickerView selectRow:self.selectedOrderAheadIndex inComponent:0 animated:YES];
            [self.orderAheadPickerView selectRow:self.selectedOrderAheadTimeRangeIndex inComponent:1 animated:YES];
        }
        
        [self toggleDropDown];
    }
}

- (IBAction)doneButtonPressed:(id)sender {
    
    // items in cart + different menu selected, ignore different time selection
    if ([self isCartEmpty] == NO && (self.selectedOrderAheadIndex != tempSelectedOrderAheadIndex || orderMode != tempOrderMode))
    {
        
        MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:[[AppStrings sharedInstance] getString:CHANGE_WARNING_TITLE]
                                                            message:[[AppStrings sharedInstance] getString:CHANGE_WARNING_TEXT]
                                                           delegate:self
                                                  cancelButtonTitle:@"No"
                                                   otherButtonTitle:@"Yes"];
        alertView.tag = 2017;
        [alertView showInView:self.view];
        alertView = nil;
    }
    else {
        // set selected flags with temp flags
        orderMode = tempOrderMode;
        self.selectedOrderAheadIndex = tempSelectedOrderAheadIndex;
        self.selectedOrderAheadTimeRangeIndex = tempSelectedOrderAheadTimeRangeIndex;
    
        [self showOrHideETA];
        [self showOrHidePreview];
    
        [self updateMenu];
        [self toggleDropDown];
        
        [self updateUI];
    }
}

- (IBAction)cancelButtonPressed:(id)sender {
    tempOrderMode = orderMode;
    [self.orderAheadPickerView selectRow:self.selectedOrderAheadIndex inComponent:0 animated:YES];
    [self.orderAheadPickerView selectRow:self.selectedOrderAheadTimeRangeIndex inComponent:1 animated:YES];
    
    [self updatePickerButtonTitle];
    [self toggleDropDown];
}

- (IBAction)enableOnDemandButtonPressed:(id)sender {
    [self.view layoutIfNeeded];
    
    tempOrderMode = OnDemand;
    
    self.orderAheadCheckMarkImageView.hidden = YES;
    self.onDemandCheckMarkImageView.hidden = NO;
    self.orderAheadPickerContainerViewHeightConstraint.constant = 0;
    self.orderAheadPickerView.hidden = YES;
    
    [self setOnDemandTitle];
    
    [self.view layoutIfNeeded];
}

- (IBAction)enableOrderAheadButtonPressed:(id)sender {
    [self.view layoutIfNeeded];
    
    tempOrderMode = OrderAhead;
    
    self.onDemandCheckMarkImageView.hidden = YES;
    self.orderAheadCheckMarkImageView.hidden = NO;
    self.orderAheadPickerContainerViewHeightConstraint.constant = 150;
    self.orderAheadPickerView.hidden = NO;
    
    [self updatePickerButtonTitle];
    
    [self.view layoutIfNeeded];
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
    
    if (orderMode == OrderAhead && self.selectedOrderAheadIndex == 0) {
        if ([[CountdownTimer sharedInstance] shouldShowCountDown]) {
            
            // count-down has not ended yet
            if (![[CountdownTimer sharedInstance].finalCountDownTimerValue isEqualToString:@"0:00"]) {
                strTitle = [NSString stringWithFormat:@"%@ - %@ %@", strTitle, [[[AppStrings sharedInstance] getString:TIME_REMAINING] uppercaseString], [CountdownTimer sharedInstance].finalCountDownTimerValue];
            }
            else {
                [self clearCart];
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
    [self updateUI];
}

#pragma mark Refresh State

- (void)refreshStateOnLaunch {
    
//    NSDictionary *savedOrderAheadMenuIdAndName = [[NSUserDefaults standardUserDefaults] rm_customObjectForKey:@"savedOrderAheadMenu"];
//    
//    if (savedOrderAheadMenuIdAndName != nil) {
//        
//        // if mode was on demand
//        if ([[[NSUserDefaults standardUserDefaults] rm_customObjectForKey:@"savedOrderMode0Or1"] isEqualToString:@"0"]) {
//            
//            [self enableOnDemand];
//        }
//        else {
//            if ([[BentoShop sharedInstance] isThereOrderAhead]) {
//                
//                [self setUpPickerData];
//                BOOL exists = NO;
//                
//                for (OrderAheadMenu *orderAheadMenu in [[BentoShop sharedInstance] getOrderAheadMenus]) {
//                        
//                    // does menu_id still exist?
//                    if (savedOrderAheadMenuIdAndName[@"menuId"] == orderAheadMenu.menuId) {
//                        
//                        // yes menuId exists, set UI to the selection of the saved menu
//                        exists = YES;
//                        
//                        for (int i = 0; i < menuNames.count; i++) {
//                            // match saved menu with the list of available order ahead menus
//                            if ([menuNames[i] isEqualToString:savedOrderAheadMenuIdAndName[@"name"]]) {
//                                [self enableOrderAhead];
//                                selectedOrderAheadIndex = i;
//                                [self.orderAheadPickerView selectRow:i inComponent:0 animated:YES];
//                                [self updatePickerButtonTitle];
//                            }
//                        }
//                    }
//                }
//                
//                if (exists == NO) {
//                    [self clearCart];
//                    NSNumber *isSelectedNum = (NSNumber *)self.widget[@"selected"];
//                    if ([isSelectedNum boolValue]) {
//                        [self enableOnDemand];
//                    }
//                    else {
//                        [self enableOrderAhead];
//                    }
//                    
//                    selectedOrderAheadIndex = 0;
//                }
//                
//                self.selectedOrderAheadTimeRangeIndex = 0;
//            }
//        }
//    }
//    else {
//        if ([[BentoShop sharedInstance] isThereOrderAhead]) {
//            selectedOrderAheadIndex = 0;
//            self.selectedOrderAheadTimeRangeIndex = 0;
//        }
//    }
    
    if ([[BentoShop sharedInstance] isThereOrderAhead]) {
        self.selectedOrderAheadIndex = 0;
        self.selectedOrderAheadTimeRangeIndex = 0;
    }
    
    if ([[BentoShop sharedInstance] isThereOnDemand] && [[BentoShop sharedInstance] isThereOrderAhead]) {
        [self installOnDemand];
        [self installOrderAhead];
        [self updateWidget];
        [self defaultToOnDemandOrOrderAhead];
    }
    else if ([[BentoShop sharedInstance] isThereOnDemand]) {
        [self removeOrderAhead];
        [self installOnDemand];
        [self updateWidget];
        [self enableOnDemand];
    }
    else if ([[BentoShop sharedInstance] isThereOrderAhead]) {
        [self removeOnDemand];
        [self installOrderAhead];
        [self enableOrderAhead];
    }
    
    [self updateUI];
}

- (void)viewDidLayoutSubviews {
    [self.view layoutIfNeeded];
}

- (void)defaultToOnDemandOrOrderAhead {
    NSNumber *isSelectedNum = (NSNumber *)self.widget[@"selected"];
    if ([isSelectedNum boolValue] == YES) {
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
    
    self.orderAheadPickerContainerViewHeightConstraint.constant = 0;
    self.orderAheadViewHeightConstraint.constant = 0;
    self.orderAheadPickerView.hidden = YES;
}

- (void)installOrderAhead {
    if (self.orderAheadView.hidden == YES) {
        self.orderAheadView.hidden = NO;
        self.orderAheadView.hidden = NO;
        
        self.orderAheadPickerContainerViewHeightConstraint.constant = 150;
        self.orderAheadViewHeightConstraint.constant = 59;
        self.orderAheadPickerView.hidden = NO;
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
        } completion:^(BOOL finished) {
            if (self.isFirstSelection) {
                self.isFirstSelection = NO;
                self.cancelButton.hidden = NO;
                self.doneButtonWidthConstraint.constant -= SCREEN_WIDTH;
            }
        }];
    }
}

- (void)toggleOn {
    self.isToggledOn = YES;
    
    self.fadedViewButton.alpha = 0.6;
    
    self.dropDownViewTopConstraint.constant = 64;
    
    [self.view layoutIfNeeded];
}

- (void)toggleOff {
    self.isToggledOn = NO;
    
    self.fadedViewButton.alpha = 0;
    
    self.dropDownViewTopConstraint.constant = 64 - self.dropDownView.frame.size.height - 1;
    
    [self.view layoutIfNeeded];
}

#pragma mark Update Menu
- (void)updateMenu {
    if (orderMode == OrderAhead) {
        for (OrderAheadMenu *oaMenu in [[BentoShop sharedInstance] getOrderAheadMenus]) {
            if ([menuOrderAhead isEqualToString:oaMenu.name]) {
                orderAheadMenu = oaMenu;
                
//                [[NSUserDefaults standardUserDefaults] rm_setCustomObject:@{
//                                                                            @"menuId": self.orderAheadMenu.menuId,
//                                                                            @"name": self.orderAheadMenu.name,
//                                                                            }
//                                                                   forKey:@"savedOrderAheadMenu"];
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
        
        [self installOnDemand];
        
        if (orderMode == OnDemand) {
            [self showOrHidePreview];
        }
    }
    else {
        [self removeOnDemand];
    }
}

- (void)updateOrderAheadWidget {
    if ([[BentoShop sharedInstance] isThereOrderAhead]) {
        [self installOrderAhead];
    }
    else {
        [self removeOrderAhead];
    }
}

- (void)showOrHidePreview {
    if (orderMode == OnDemand) {
        if ([self.widget[@"state"] isEqualToString:@"open"]) {
            [self hidePreview];
        }
        else if (orderMode == OnDemand) {
            [self showPreview];
        }
    }
    else {
        [self hidePreview];
    }
    
//    if ([self.widget[@"state"] isEqualToString:@"open"]) {
//        self.enabledOnDemandButton.alpha = 0; // transparent
//    }
//    else {
//        self.enabledOnDemandButton.alpha = 0.2; // gray
//    }
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
        if ([self isToggledOn]) {
            [self toggleOff];
        }
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
    orderAheadMenu.deliveryPrice = orderAheadMenu.rawTimeRangesArray[self.selectedOrderAheadTimeRangeIndex][@"delivery_price"];
    orderAheadMenu.scheduledWindowStartTime = orderAheadMenu.rawTimeRangesArray[self.selectedOrderAheadTimeRangeIndex][@"start"];
    orderAheadMenu.scheduledWindowEndTime = orderAheadMenu.rawTimeRangesArray[self.selectedOrderAheadTimeRangeIndex][@"end"];
    
    NSDictionary *menuInfo;
    
    if (orderMode == OnDemand) {
        menuInfo = @{
                     @"orderMode": [NSString stringWithFormat:@"%ld", (long)orderMode],
                     };
    }
    else if (orderMode == OrderAhead) {
        menuInfo = @{
                     @"orderAheadMenu": orderAheadMenu,
                     @"orderMode": [NSString stringWithFormat:@"%ld", (long)orderMode],
                     @"selectedOrderAheadIndex": [NSString stringWithFormat:@"%ld", (long)self.selectedOrderAheadIndex],
                     @"menuName": [NSString stringWithFormat:@"%@", menuOrderAhead],
                     @"menuTime": [NSString stringWithFormat:@"%@", timeOrderAhead]
                     };
    }
    
    [[NSUserDefaults standardUserDefaults] rm_setCustomObject:menuInfo forKey:@"menuInfo"];
    
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
    
    orderMode = OnDemand;
    
    self.orderAheadCheckMarkImageView.hidden = YES;
    self.onDemandCheckMarkImageView.hidden = NO;
    self.orderAheadPickerContainerViewHeightConstraint.constant = 0;
    self.orderAheadPickerView.hidden = YES;
    
    [self setOnDemandTitle];
    
    [self showOrHideETA];
    
    [self updateUI];
    
    [self showOrHidePreview];
    
    [self.view layoutIfNeeded];
}

- (void)enableOrderAhead {
    [self.view layoutIfNeeded];
    
    orderMode = OrderAhead;
    
    self.selectedOrderAheadIndex = [self.orderAheadPickerView selectedRowInComponent:0];
    self.selectedOrderAheadTimeRangeIndex = [self.orderAheadPickerView selectedRowInComponent:1];
    
    tempOrderMode = orderMode;
    tempSelectedOrderAheadIndex = self.selectedOrderAheadIndex;
    tempSelectedOrderAheadTimeRangeIndex = self.selectedOrderAheadTimeRangeIndex;

    self.onDemandCheckMarkImageView.hidden = YES;
    self.orderAheadCheckMarkImageView.hidden = NO;
    self.orderAheadPickerContainerViewHeightConstraint.constant = 150;
    self.orderAheadPickerView.hidden = NO;
    
    [self updatePickerButtonTitle];
    
    [self showOrHideETA];
    
    [self updateUI];
    
    [self hidePreview];
    
    [self.view layoutIfNeeded];
}

- (void)tempSelectedOnDemand {

}

- (void)tempSelectedOrderAhead {

}

- (void)showOrHideETA {
    if (orderMode == OnDemand) {
        self.etaLabel.hidden = NO;
        self.etaBannerDivider.hidden = NO;
        
        [self.view removeConstraint:self.xCenterConstraintForStartingPriceLabel];
    }
    else if (orderMode == OrderAhead) {
        self.etaLabel.hidden = YES;
        self.etaBannerDivider.hidden = YES;
        
        [self.view addConstraint:self.xCenterConstraintForStartingPriceLabel];
    }
    
    [self.view layoutIfNeeded];
}

- (void)setOnDemandTitle {
    menuOnDemand = self.asapMenuLabel.text;
    [self updatePickerButtonTitle];
}

- (void)onFinalize {
    if ([self isInMiddleOfBuildingBento]) {
        [self showConfirmMsg];
    }
    else {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"didAutoShowAddons"] != YES) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"didAutoShowAddons"];
            [self presentAddOns];
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
    if ((menuNames.count - 1) < self.selectedOrderAheadIndex) {
        self.selectedOrderAheadIndex = menuNames.count - 1;
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
        return [menuTimes[tempSelectedOrderAheadIndex] count];
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
        return menuTimes[tempSelectedOrderAheadIndex][row];
    }
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    
    UILabel *pickerLabel = [[UILabel alloc] init];
    
    if (component == 0) {
        pickerLabel.text = menuNames[row];
    }
    else {
        pickerLabel.text = menuTimes[tempSelectedOrderAheadIndex][row];
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
    pickerLabel.font = [UIFont fontWithName:@"OpenSans-Regular" size:14];
    
    [self updatePickerButtonTitle];
    
    return pickerLabel;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {

    if (component == 0) {
        menuOrderAhead = menuNames[row];
        tempSelectedOrderAheadIndex = row;
        [pickerView reloadComponent:1];
        [pickerView selectRow:0 inComponent:1 animated:YES];
    }
    else {
        // if time range is sold-out and is last on the list, push back instead of forward so array wont go out of bounds
        NSInteger lastRow = [menuTimes[self.selectedOrderAheadIndex] count] - 1;

        if ([menuTimes[self.selectedOrderAheadIndex][row] containsString:@"sold-out"] && row == lastRow) {
            [pickerView selectRow:row - 1 inComponent:component animated:YES];
            timeOrderAhead = menuTimes[self.selectedOrderAheadIndex][row - 1];
            tempSelectedOrderAheadTimeRangeIndex = row - 1;
        }
        // if time range is sold-out and not the last on the list, then push forward
        else if ([menuTimes[self.selectedOrderAheadIndex][row] containsString:@"sold-out"]) {
            [pickerView selectRow:row + 1 inComponent:component animated:YES];
            timeOrderAhead = menuTimes[self.selectedOrderAheadIndex][row + 1];
            tempSelectedOrderAheadTimeRangeIndex = row + 1;
        }
        else {
            timeOrderAhead = menuTimes[self.selectedOrderAheadIndex][row];
            tempSelectedOrderAheadTimeRangeIndex = row;
        }
    }
}

- (void)updatePickerButtonTitle {
    menuOrderAhead = [self pickerView:self.orderAheadPickerView titleForRow:[self.orderAheadPickerView selectedRowInComponent:0] forComponent:0];
    timeOrderAhead = [self pickerView:self.orderAheadPickerView titleForRow:[self.orderAheadPickerView selectedRowInComponent:1] forComponent:1];
    
    if (tempOrderMode == OnDemand) {
        if (menuOnDemand != nil) {
            [self.pickerButton setTitle:[NSString stringWithFormat:@"%@ ▾", menuOnDemand] forState:UIControlStateNormal];
        }
    }
    else if (tempOrderMode == OrderAhead) {
        if (menuOrderAhead != nil && timeOrderAhead != nil) {
            [self.pickerButton setTitle:[NSString stringWithFormat:@"%@, %@ ▾", menuOrderAhead, timeOrderAhead] forState:UIControlStateNormal];
        }
    }
    
//    [self updateMenu];
}


@end
