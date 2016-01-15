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

@interface FiveHomeViewController () <FiveCustomViewControllerDelegate, MyAlertViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic) FiveCustomViewController *customVC;
@property (nonatomic) MenuPreviewViewController *menuPreviewVC;

@end

@implementation FiveHomeViewController
{
    AddonsViewController *addonsVC;
    JGProgressHUD *loadingHUD;
    
    UILabel *dinnerTitleLabel;
    
    BOOL isThereConnection;
    
    NSArray *myDatabase;
    
    NSString *menu;
    NSString *time;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // order ahead mock
    myDatabase = @[
                    @[@"Today, Dinner", @"Tomorrow, Lunch", @"Tomorrow, Dinner", @"Jan 16, Lunch", @"Jan 16, Dinner"],
                    @[@"11:00-11:30 AM", @"11:30-12:00 PM", @"12:00-12:30 PM", @"12:30-1:00 PM", @"1:00-1:30 PM", @"1:30-2:00 PM", @"5:00-5:30 PM", @"5:30-6:00 PM"]
                    ];
    
    // mock
    [self enableOnDemand];
    
    isThereConnection = YES;
    
    /*---Custom---*/
    self.customVC = [[FiveCustomViewController alloc] init];
    [self addChildViewController:self.customVC];
    [self.bgView addSubview:self.customVC.view];
    [self.customVC didMoveToParentViewController:self];
    
    self.customVC.delegate = self;
    
    /*---Menu Preview---*/
    self.menuPreviewVC = [[MenuPreviewViewController alloc] init];
    [self addChildViewController:self.menuPreviewVC]; // 1. notify the prent VC that a child is being added
    //    self.bgView.frame = self.menuPreviewVC.view.bounds; // 2. before adding the child's view to its view hierarchy, the parent VC sets the child's size and position
    [self.bgView addSubview:self.menuPreviewVC.view];
    [self.menuPreviewVC didMoveToParentViewController:self]; // tell the child VC of its new parent
    
    // toggle on and off accordingly
    [self.menuPreviewVC willMoveToParentViewController:nil]; // 1. let the child VC know that it will be removed
    [self.menuPreviewVC.view removeFromSuperview]; // 2. remove the child VC's view
    [self.menuPreviewVC removeFromParentViewController]; // 3. remove the child VC
    
    /*---Picker View---*/
    self.pickerButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    
    /*---ASAP---*/
    self.asapDescriptionLabel.lineBreakMode = NSLineBreakByWordWrapping; // do i really need this?
    [self.asapDescriptionLabel sizeToFit];
    self.asapViewHeightConstraint.constant = self.asapDescriptionLabel.frame.size.height + 50; //
    
    /*---Count Badge---*/
    self.countBadgeLabel.layer.cornerRadius = self.countBadgeLabel.frame.size.width / 2;
    self.countBadgeLabel.clipsToBounds = YES;
    
    /*---Finalize Button Text---*/
    NSString *strTitle = [[AppStrings sharedInstance] getString:BUILD_COMPLETE_BUTTON];
    if (strTitle != nil) {
        NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:strTitle];
        
        float spacing = 1.0f;
        
        [attributedTitle addAttribute:NSKernAttributeName
                                value:@(spacing)
                                range:NSMakeRange(0, [strTitle length])];
        
        [self.finalizeButton setAttributedTitle:attributedTitle forState:UIControlStateNormal];
        [self.finalizeButton setTintColor:[UIColor whiteColor]];
    }
    
    /*---If No Location Set---*/
    AppDelegate *delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    CLLocationCoordinate2D location = [delegate getCurrentLocation];
    BentoShop *globalShop = [BentoShop sharedInstance];
    if (![globalShop checkLocation:location] && [[DataManager shareDataManager] getUserInfo] == nil) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        DeliveryLocationViewController *deliveryLocationViewController = [storyboard instantiateViewControllerWithIdentifier:@"DeliveryLocationViewController"];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"nextToBuild"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self.navigationController pushViewController:deliveryLocationViewController animated:NO];
    }
    
    // an empty is created the FIRST time app is launched - there will always be at least one empty bento in defaults
    if ([[BentoShop sharedInstance] getTotalBentoCount] == 0) {
        [[BentoShop sharedInstance] addNewBento];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSLog(@"dropdownheight - %f", self.dropDownView.center.y);
    
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkCurrentMode) name:@"checkModeOrDateChange" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkCurrentMode) name:@"enteredForeground" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startTimerOnViewedScreen) name:@"enteredForeground" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endTimerOnViewedScreen) name:@"enteringBackground" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewWillDisappear:animated];
    
    [self endTimerOnViewedScreen];
    
    NSLog(@"dropdownheight - %f", self.dropDownView.center.y);
}

#pragma mark Load Dishes

- (void)loadSelectedDishes {
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
    
    [self setBuildButtonConstraint];
    
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
        
        [self.customVC.buildButton setAttributedTitle:attributedTitle forState:UIControlStateNormal];
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
    if ([[BentoShop sharedInstance] getCompletedBentoCount] > 0) {
        [self.finalizeButton setBackgroundColor:[UIColor bentoBrandGreen]];
        self.finalizeButton.enabled = YES;
    }
    else {
        [self.finalizeButton setBackgroundColor:[UIColor bentoButtonGray]];
        self.finalizeButton.enabled = NO;
    }
    
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

#pragma mark Build Button Width

- (void)setBuildButtonConstraint {
    
    // 1 or more bentos in cart
    if ([[BentoShop sharedInstance] getCompletedBentoCount] > 0) {
        
        self.customVC.buildButtonWidthConstraint.constant = SCREEN_WIDTH / 2 - 5;
        
        // view add-ons button
        self.customVC.viewAddonsButton.hidden = NO;
    }
    // 0 bentos in cart
    else {
        
        self.customVC.buildButtonWidthConstraint.constant = SCREEN_WIDTH + 1;
        
        // view add-ons button
        self.customVC.viewAddonsButton.hidden = YES;
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

#pragma mark Check Current Mode

- (void)checkCurrentMode {
    if ([[BentoShop sharedInstance] didModeOrDateChange]) {
        [(UINavigationController *)self.presentingViewController popToRootViewControllerAnimated:NO];
        [self dismissViewControllerAnimated:YES completion:nil];
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
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

- (IBAction)finalizeButtonPressed:(id)sender {
    [self onFinalize];
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

- (void)enableOnDemand {
    self.onDemandGreenView1.hidden = NO;
    self.onDemandGreenView2.hidden = NO;
    
    self.orderAheadGreenView1.hidden = YES;
    self.orderAheadGreenView2.hidden = YES;
    
    self.enabledOnDemandButton.hidden = YES;
    self.enabledOrderAheadButton.hidden = NO;
}

- (void)enableOrderAhead {
    self.onDemandGreenView1.hidden = YES;
    self.onDemandGreenView2.hidden = YES;
    
    self.orderAheadGreenView1.hidden = NO;
    self.orderAheadGreenView2.hidden = NO;
    
    self.enabledOnDemandButton.hidden = NO;
    self.enabledOrderAheadButton.hidden = YES;
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
    pickerLabel.textColor = [UIColor bentoTitleGray];
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
            menu = myDatabase[component][row];
            break;
            
        default:
            time = myDatabase[component][row];
            break;
    }
    
    [self.pickerButton setTitle:[NSString stringWithFormat:@"%@, %@ ▾", menu, time] forState:UIControlStateNormal];
}


@end
