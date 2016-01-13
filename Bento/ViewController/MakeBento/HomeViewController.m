//
//  HomeViewController.m
//  Bento
//
//  Created by Joseph Lau on 1/8/16.
//  Copyright © 2016 bentonow. All rights reserved.
//

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

#import "HomeViewController.h"
#import "CustomViewController.h"
#import "MenuPreviewViewController.h"

#import "BWTitlePagerView.h"

#import "AppDelegate.h"

#import "ChooseMainDishViewController.h"
#import "ChooseSideDishViewController.h"

#import "CompleteOrderViewController.h"
#import "DeliveryLocationViewController.h"

#import "SignedInSettingsViewController.h"
#import "SignedOutSettingsViewController.h"

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

#import "AddonsViewController.h"
#import "AddonList.h"

@interface HomeViewController () <CustomViewControllerDelegate, MyAlertViewDelegate>

@property (nonatomic) CustomViewController *customVC;
@property (nonatomic) MenuPreviewViewController *menuPreviewVC;

@end

@implementation HomeViewController
{
    AddonsViewController *addonsVC;
    JGProgressHUD *loadingHUD;
    
    UILabel *dinnerTitleLabel;
    
    BOOL isThereConnection;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // initialize to yes
    isThereConnection = YES;
    
    // Custom
    self.customVC = [[CustomViewController alloc] initWithNibName:@"CustomViewController" bundle:nil];
    [self addChildViewController:self.customVC];
    [self.scrollView addSubview:self.customVC.view];
    [self.customVC didMoveToParentViewController:self];
    
    // Menu Preview
    self.menuPreviewVC = [[MenuPreviewViewController alloc] init];
    CGRect frame = self.menuPreviewVC.view.frame;
    frame.origin.x = SCREEN_WIDTH;
    self.menuPreviewVC.view.frame = frame;
    
    [self addChildViewController:self.menuPreviewVC];
    [self.scrollView addSubview:self.menuPreviewVC.view];
    [self.menuPreviewVC didMoveToParentViewController:self];
    
    // Scroll View
    self.scrollView.contentSize = CGSizeMake(SCREEN_WIDTH * 2, SCREEN_HEIGHT - 20);
    
    /*---Count Badge---*/
    self.countBadgeLabel.layer.cornerRadius = self.countBadgeLabel.frame.size.width / 2;
    self.countBadgeLabel.clipsToBounds = YES;
    
    /*---Dish Images---*/
    [self.customVC.mainDishImageView setClipsToBounds:YES];
    [self.customVC.sideDish1ImageView setClipsToBounds:YES];
    [self.customVC.sideDish2Imageview setClipsToBounds:YES];
    [self.customVC.sideDish3ImageView setClipsToBounds:YES];
    
    /*---Gradient Layer---*/
    CAGradientLayer *backgroundLayer = [CAGradientLayer blackGradientLayer];
    backgroundLayer.frame = self.customVC.mainDishImageView.frame;
    backgroundLayer.opacity = 0.8f;
    [self.customVC.mainDishImageView.layer insertSublayer:backgroundLayer atIndex:0];
    
    backgroundLayer = [CAGradientLayer blackGradientLayer];
    backgroundLayer.frame = self.customVC.sideDish1ImageView.frame;
    backgroundLayer.opacity = 0.8f;
    [self.customVC.sideDish1ImageView.layer insertSublayer:backgroundLayer atIndex:0];
    
    backgroundLayer = [CAGradientLayer blackGradientLayer];
    backgroundLayer.frame = self.customVC.sideDish2Imageview.frame;
    backgroundLayer.opacity = 0.8f;
    [self.customVC.sideDish2Imageview.layer insertSublayer:backgroundLayer atIndex:0];
    
    backgroundLayer = [CAGradientLayer blackGradientLayer];
    backgroundLayer.frame = self.customVC.sideDish3ImageView.frame;
    backgroundLayer.opacity = 0.8f;
    [self.customVC.sideDish3ImageView.layer insertSublayer:backgroundLayer atIndex:0];
    
    
    //    if ([[BentoShop sharedInstance] is4PodMode]) {
    //        addonsButton = [[UIButton alloc] initWithFrame:CGRectMake(btnAddAnotherBentoShortVersionWidth + 25, SCREEN_HEIGHT - 45 -65 - 65, SCREEN_WIDTH/2-10, 45)];
    //    }
    //    else {
    //        addonsButton = [[UIButton alloc] initWithFrame:CGRectMake(btnAddAnotherBentoShortVersionWidth + 25, viewDishs.frame.size.height + 45 + 7.5, SCREEN_WIDTH/2-10, 45)];
    //    }
    //    addonsButton.layer.borderColor = BORDER_COLOR.CGColor;
    //    addonsButton.layer.borderWidth = 1.0f;
    //    [addonsButton setBackgroundColor:[UIColor colorWithRed:238.0f / 255.0f green:241.0f / 255.0f blue:241.0f / 255.0f alpha:1.0f]];
    //    [addonsButton setTitleColor:[UIColor bentoBrandGreen] forState:UIControlStateNormal];
    //    addonsButton.hidden = YES;
    //    addonsButton.titleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:12.0f];
    //
    //
    //    NSString *addonsText = @"VIEW ADD-ONS";
    //    [addonsButton setTitle:addonsText forState:UIControlStateNormal];
    //    NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:addonsText];
    //    float spacing = 1.0f;
    //    [attributedTitle addAttribute:NSKernAttributeName
    //                            value:@(spacing)
    //                            range:NSMakeRange(0, [addonsText length])];
    //    // Anything less than iOS 8.0
    //    if ([[UIDevice currentDevice].systemVersion intValue] < 8) {
    //        addonsButton.titleLabel.text = addonsText;
    //    }
    //    else {
    //        addonsButton.titleLabel.attributedText = attributedTitle;
    //    }
    //
    //    [addonsButton addTarget:self action:@selector(onViewAddons) forControlEvents:UIControlEventTouchUpInside];
    //    [scrollView addSubview:addonsButton];
    
    /*---Build Button---*/
    NSString *strTitle = [[AppStrings sharedInstance] getString:BUILD_ADD_BUTTON];
    if (strTitle != nil) {
        
        // Add Another Bento Button
        [self.customVC.buildButton setTitle:strTitle forState:UIControlStateNormal];
        NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:strTitle];
        float spacing = 1.0f;
        [attributedTitle addAttribute:NSKernAttributeName
                                value:@(spacing)
                                range:NSMakeRange(0, [strTitle length])];
        // Anything less than iOS 8.0
        if ([[UIDevice currentDevice].systemVersion intValue] < 8) {
            self.customVC.buildButton.titleLabel.text = strTitle;
        }
        else {
            self.customVC.buildButton.titleLabel.attributedText = attributedTitle;
        }
        
        // Continue Button
        strTitle = [[AppStrings sharedInstance] getString:BUILD_COMPLETE_BUTTON];
        [self.customVC.buildButton setTitle:strTitle forState:UIControlStateNormal];
        if (strTitle != nil) {
            attributedTitle = [[NSMutableAttributedString alloc] initWithString:strTitle];
        }
        spacing = 1.0f;
        [attributedTitle addAttribute:NSKernAttributeName
                                value:@(spacing)
                                range:NSMakeRange(0, [strTitle length])];
        // Anything less than iOS 8.0
        if ([[UIDevice currentDevice].systemVersion intValue] < 8) {
            self.customVC.buildButton.titleLabel.text = strTitle;
        }
        else {
            self.customVC.buildButton.titleLabel.attributedText = attributedTitle;
        }
        attributedTitle = nil;
    }
    
    // an empty is created the FIRST time app is launched - there will always be at least one empty bento in defaults
    if ([[BentoShop sharedInstance] getTotalBentoCount] == 0) {
        [[BentoShop sharedInstance] addNewBento];
    }
    
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
}

- (IBAction)settingsButtonPressed:(id)sender {
    [self onSettings];
}

- (IBAction)cartButtonPressed:(id)sender {
    [self onCart];
}

- (IBAction)pickerButtonPressed:(id)sender {
    
}

- (IBAction)bottomButtonPressed:(id)sender {
    [self onFinalize];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
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
    
    if ([[BentoShop sharedInstance] is4PodMode]) {
        if ([[[BentoShop sharedInstance] getCurrentBento] getMainDish] == 0 &&
            [[[BentoShop sharedInstance] getCurrentBento] getSideDish1] == 0 &&
            [[[BentoShop sharedInstance] getCurrentBento] getSideDish2] == 0 &&
            [[[BentoShop sharedInstance] getCurrentBento] getSideDish3] == 0) {
            
            [[[BentoShop sharedInstance] getCurrentBento] setSideDish4:0];
        }
        else {
            [[[BentoShop sharedInstance] getCurrentBento] setSideDish4:-1];
        }
    }
    
    addonsVC = [[AddonsViewController alloc] init];
    addonsVC.delegate = self;
    
    [self updateUI];
    
    [self startTimerOnViewedScreen];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewWillDisappear:animated];
    
    [self endTimerOnViewedScreen];
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

#pragma mark

- (void)checkCurrentMode {
    if ([[BentoShop sharedInstance] didModeOrDateChange]) {
        [(UINavigationController *)self.presentingViewController popToRootViewControllerAnimated:NO];
        [self dismissViewControllerAnimated:YES completion:nil];
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

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

- (void)loadSelectedDishes {
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
        
        self.customVC.mainDishImageView.hidden = NO;
        self.customVC.mainDishLabel.hidden = NO;
        
        NSDictionary *dishInfo = [[BentoShop sharedInstance] getMainDish:mainDishIndex];
        if (dishInfo != nil) {
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
    }
    else {
        self.customVC.mainDishImageView.image = nil;
        self.customVC.mainDishImageView.hidden = YES;
        self.customVC.mainDishLabel.hidden = YES;
        self.customVC.mainDishBannerImageView.hidden = YES;
    }
    
    /*-Side 1-*/
    if (side1DishIndex > 0) {
        
        self.customVC.sideDish1ImageView.hidden = NO;
        self.customVC.sideDish1Label.hidden = NO;
        
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

- (void)onSettings {
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

// addons delegate method
- (void)addonsViewControllerDidTapOnFinalize:(BOOL)didTapOnFinalize {
    if (didTapOnFinalize == YES) {
        [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(onFinalize) userInfo:nil repeats:NO];
    }
}

- (void)onViewAddons {
    // TODO: track on mixpanel
    NSLog(@"Tapped on View Another Bento");
    
    [[Mixpanel sharedInstance] track:@"Tapped on View Another Bento"];
    
    [self.navigationController presentViewController:addonsVC animated:YES completion:nil];
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
            //            lblBanner.text = [NSString stringWithFormat:@"STARTING AT $%.0f", [sortedMainPrices[0] floatValue]];
            startingPriceLabel.text = [NSString stringWithFormat:@"STARTING AT $%.0f", [sortedMainPrices[0] floatValue]];
        }
        // if no cents, just show whole number
        else {
            //            lblBanner.text = [NSString stringWithFormat:@"STARTING AT $%@", sortedMainPrices[0]];
            startingPriceLabel.text = [NSString stringWithFormat:@"STARTING AT $%@", sortedMainPrices[0]];
        }
        
        lblBanner.hidden = NO;
        lblBanner.backgroundColor = [UIColor colorWithRed:0.533f green:0.686f blue:0.376f alpha:1.0f];
        lblBanner.font = [UIFont fontWithName:@"OpenSans-Bold" size:14];
    }
    /*----------------------*/
    
    ETALabel.text = [NSString stringWithFormat:@"ETA: %ld-%ld MIN.", (long)[[BentoShop sharedInstance] getETAMin], (long)[[BentoShop sharedInstance] getETAMax]];
    
    /*----------------------*/
    
    // 1 or more bentos in cart
    if ([[BentoShop sharedInstance] getCompletedBentoCount] > 0) {
        
        // show "OR" label and "View Add-ons" button
        orLabel.hidden = NO;
        addonsButton.hidden = NO;
        //        btnAddAnotherBento.frame = CGRectMake(-1, viewDishs.frame.size.height + 45, SCREEN_WIDTH/2-15, 45); // short version
        
        
        if ([[BentoShop sharedInstance] is4PodMode]) {
            btnAddAnotherBento.frame = CGRectMake(-1, SCREEN_HEIGHT - 45 - 65 - 65, SCREEN_WIDTH/2-10, 45);
        }
        else {
            btnAddAnotherBento.frame = CGRectMake(-1, viewDishs.frame.size.height + 45 + 7.5, SCREEN_WIDTH/2-10, 45);
        }
    }
    // 0 bentos in cart
    else {
        
        orLabel.hidden = YES;
        addonsButton.hidden = YES;
        
        if ([[BentoShop sharedInstance] is4PodMode]) {
            btnAddAnotherBento.frame = CGRectMake(-1, SCREEN_HEIGHT - 45 - 65 - 65, SCREEN_WIDTH + 2, 45); // long version
        }
        else {
            btnAddAnotherBento.frame = CGRectMake(SCREEN_WIDTH / 2 - ((SCREEN_WIDTH - 60) / 2), viewDishs.frame.size.height + 45 + 7.5, SCREEN_WIDTH - 60, 45); // long version
        }
    }
    
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
        [btnAddAnotherBento setAttributedTitle:attributedTitle forState:UIControlStateNormal];
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
        btnCart.enabled = YES;
        btnCart.selected = YES;
        [btnCart setImage:[UIImage imageNamed:@"mybento_nav_cart_act"] forState:UIControlStateNormal];
    }
    else {
        btnCart.enabled = NO;
        btnCart.selected = NO;
    }
    
    /*---Finalize Button---*/
    if ([[BentoShop sharedInstance] getCompletedBentoCount] > 0) {
        [btnState setBackgroundColor:[UIColor bentoBrandGreen]];
        btnState.enabled = YES;
    }
    else {
        [btnState setBackgroundColor:[UIColor bentoButtonGray]];
        btnState.enabled = NO;
    }
    
    /*---Cart Badge---*/
    if ([[BentoShop sharedInstance] getCompletedBentoCount] > 0) {
        lblBadge.text = [NSString stringWithFormat:@"%ld", (long)[[BentoShop sharedInstance] getCompletedBentoCount] + (long)[[AddonList sharedInstance] getTotalCount]];
        lblBadge.hidden = NO;
    }
    else {
        lblBadge.text = @"";
        lblBadge.hidden = YES;
    }
}

- (void)onUpdatedMenu:(NSNotification *)notification {
    if (isThereConnection) {
        [self updateUI];
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
    NSLog(@"+ main pressed");
    [self onAddMainDish];
}

- (void)customVCAddSideDish1Pressed:(id)sender {
    NSLog(@"+ side 1 pressed");
    [self onAddSideDish:sender];
}

- (void)customVCAddSideDish2Pressed:(id)sender {
    NSLog(@"+ side 2 pressed");
    [self onAddSideDish:sender];
}

- (void)customVCAddSideDish3Pressed:(id)sender {
    NSLog(@"+ side 3 pressed");
    [self onAddSideDish:sender];
}

- (void)customVCBuildButtonPressed:(id)sender {
    NSLog(@"build button pressed");
    [self onAddAnotherBento];
}

@end
