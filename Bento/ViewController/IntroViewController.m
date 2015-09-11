//
//  IntroViewController.m
//  Bento
//
//  Created by hanjinghe on 1/6/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "IntroViewController.h"

#import "UIImageView+WebCache.h"

#import "BentoShop.h"
#import "AppStrings.h"
#import "DataManager.h"
#import "JGProgressHUD.h"
#import "Mixpanel.h"
#import "FirstViewController.h"
#import "UIColor+CustomColors.h"
#import "MyAlertView.h"
#import <FDKeychain/FDKeychain.h>

#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

@interface IntroViewController() <MyAlertViewDelegate>

@property (nonatomic, weak) IBOutlet UIImageView *ivBackground;
@property (nonatomic, weak) IBOutlet UIImageView *ivLogo;

@property (weak, nonatomic) IBOutlet UIView *lblPlatform;

@property (nonatomic, weak) IBOutlet UILabel *lblComment;

@property (nonatomic, weak) IBOutlet UILabel *lblNumber1;
@property (nonatomic, weak) IBOutlet UILabel *lblNumber2;
@property (nonatomic, weak) IBOutlet UILabel *lblNumber3;

@property (nonatomic, weak) IBOutlet UILabel *lblItem0;
@property (nonatomic, weak) IBOutlet UILabel *lblItem1;
@property (nonatomic, weak) IBOutlet UILabel *lblItem2;
@property (nonatomic, weak) IBOutlet UILabel *lblItem3;

@property (nonatomic, weak) IBOutlet UIButton *btnGetStarted;
@property (weak, nonatomic) IBOutlet UIButton *btnNoThanks;
@property (weak, nonatomic) IBOutlet UIButton *btnAllow;

@property (weak, nonatomic) IBOutlet UIView *arrowPlatform;
@property (weak, nonatomic) IBOutlet UILabel *lblTapAllow;

@end

@implementation IntroViewController
{
    JGProgressHUD *loadingHUD;

    UILabel *lblLocationRequest;
    
    UILabel *lblPushRequest;
    UILabel *lblPushComment;
    
    NSString *exitOnWhichScreen;
    
    CLLocationManager *locationManager;
    CLLocationCoordinate2D coordinate;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Gradient
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.ivBackground.bounds;
    
    // Get colors for gradient
    UIColor *color1 = [UIColor bentoGradient1];
    UIColor *color2 = [UIColor bentoGradient2];
    
    // Set gradient (light to darker green)
    gradient.colors = @[(id)[color1 CGColor], (id)[color2 CGColor]];
    [self.ivBackground.layer insertSublayer:gradient atIndex:0];
    
    // Download background image URL, then set it, use placeholder if unavailable
    NSURL *urlBack = [[BentoShop sharedInstance] getMenuImageURL];
    [self.ivBackground sd_setImageWithURL:urlBack placeholderImage:[UIImage imageNamed:@"first_background"]];
    
    // Round out corners for number labels
    self.lblNumber1.layer.cornerRadius = self.lblNumber1.frame.size.width / 2;
    self.lblNumber1.clipsToBounds = YES;
    self.lblNumber1.alpha = 0;

    self.lblNumber2.layer.cornerRadius = self.lblNumber2.frame.size.width / 2;
    self.lblNumber2.clipsToBounds = YES;
    self.lblNumber2.alpha = 0;
    
    self.lblNumber3.layer.cornerRadius = self.lblNumber3.frame.size.width / 2;
    self.lblNumber3.clipsToBounds = YES;
    self.lblNumber3.alpha = 0;
    
    self.btnGetStarted.layer.cornerRadius = 3;
    self.btnNoThanks.layer.cornerRadius = 3;
    self.btnAllow.layer.cornerRadius = 3;
    
    self.btnGetStarted.enabled = NO;
    self.btnNoThanks.enabled = NO;
    self.btnAllow.enabled = NO;
    
    self.btnGetStarted.alpha = 0;
    self.btnNoThanks.alpha = 0;
    self.btnAllow.alpha = 0;
    
    self.btnNoThanks.center = CGPointMake(self.btnNoThanks.center.x, self.btnNoThanks.center.y);
    self.btnAllow.center = CGPointMake(self.btnAllow.center.x, self.btnAllow.center.y);
    
    // Download bento logo, then set it, use placeholder if unavailable
    NSURL *urlLogo = [[AppStrings sharedInstance] getURL:APP_LOGO];
    [self.ivLogo sd_setImageWithURL:urlLogo placeholderImage:[UIImage imageNamed:@"logo"]];
    
    // Get prices
    NSInteger salePrice = [[AppStrings sharedInstance] getInteger:SALE_PRICE];
    NSInteger unitPrice = [[AppStrings sharedInstance] getInteger:ABOUT_PRICE];
    
    // Set price string
    NSString *strPrice = @"";

    // Sale price is not 0 and less than unit price
    if (salePrice != 0 && salePrice < unitPrice)
        strPrice = [NSString stringWithFormat:@"$%ld!", (long)salePrice]; // set price string as sale price
    else
        strPrice = [NSString stringWithFormat:@"$%ld!", (long)unitPrice]; //  set price string as unit price
    
    // Set up string for about text
    NSString *strItem0 = [[AppStrings sharedInstance] getString:ABOUT_ITEM_0]; // "Build your Bento for only $X" ?
    strItem0 = [strItem0 stringByReplacingOccurrencesOfString:@"$X!" withString:strPrice]; // replace $X with actualy price string
    self.lblItem0. text = strItem0; // set the about label text
    
    // Get instructional text and set as item label text
    self.lblItem1.text = [[AppStrings sharedInstance] getString:ABOUT_ITEM_1];
    self.lblItem2.text = [[AppStrings sharedInstance] getString:ABOUT_ITEM_2];
    self.lblItem3.text = [[AppStrings sharedInstance] getString:ABOUT_ITEM_3];
    
    self.lblItem0.alpha = 0;
    self.lblItem1.alpha = 0;
    self.lblItem2.alpha = 0;
    self.lblItem3.alpha = 0;
    
    // Get button title text and set it to button
    [self.btnGetStarted setTitle:[[AppStrings sharedInstance] getString:ABOUT_BUTTON_TITLE] forState:UIControlStateNormal];
    
    self.arrowPlatform.alpha = 0;
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"Shown Location Request"] == nil)
    {
        self.arrowPlatform.alpha = 1;
        
        // Location Request
        
        CGSize result = [[UIScreen mainScreen] bounds].size;
        if(result.height == 480)
        {
            // iphone 4
            self.arrowPlatform.center = CGPointMake(225, 375);
            lblLocationRequest = [[UILabel alloc] initWithFrame:CGRectMake(40, self.ivLogo.frame.origin.y + 65, self.view.bounds.size.width - 80, 44)];
        }
        
        else if(result.height == 568)
        {
            // iphone 5
            self.arrowPlatform.center = CGPointMake(225, 415);
            lblLocationRequest = [[UILabel alloc] initWithFrame:CGRectMake(40, self.ivLogo.frame.origin.y + 85, self.view.bounds.size.width - 80, 44)];
        }
        
        else if(result.height == 667)
        {
            // iphone 6
            self.arrowPlatform.center = CGPointMake(250, 465);
            lblLocationRequest = [[UILabel alloc] initWithFrame:CGRectMake(40, self.ivLogo.frame.origin.y + 77 + 30, self.view.bounds.size.width - 80, 44)];
        }
        
        else if(result.height == 736)
        {
            // iphone 6+
            self.arrowPlatform.center = CGPointMake(275, 500);
            lblLocationRequest = [[UILabel alloc] initWithFrame:CGRectMake(40, self.ivLogo.frame.origin.y + 110, self.view.bounds.size.width - 80, 44)];
        }
        
        lblLocationRequest.textAlignment = NSTextAlignmentCenter;
        if (self.view.bounds.size.width == 320)
        {
            lblLocationRequest.font = [UIFont fontWithName:@"OpenSans-Bold" size:17];
            self.lblTapAllow.font = [UIFont fontWithName:@"OpenSans-Bold" size:17];
        }
        else if (self.view.bounds.size.width == 375)
        {
            lblLocationRequest.font = [UIFont fontWithName:@"OpenSans-Bold" size:20];
            self.lblTapAllow.font = [UIFont fontWithName:@"OpenSans-Bold" size:20];
        }
        else
        {
            lblLocationRequest.font = [UIFont fontWithName:@"OpenSans-Bold" size:24];
            self.lblTapAllow.font = [UIFont fontWithName:@"OpenSans-Bold" size:24];
        }
        lblLocationRequest.textColor = [UIColor whiteColor];
        lblLocationRequest.text = @"Want speedier delivery?";
        [self.view addSubview:lblLocationRequest];
    }
    
    // Push Notifications Request
    lblPushRequest = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width - 80, 44)];
    lblPushRequest.center = self.lblComment.center;
    lblPushRequest.textAlignment = NSTextAlignmentCenter;
    if (self.view.bounds.size.width == 320)
        lblPushRequest.font = [UIFont fontWithName:@"OpenSans-Bold" size:17];
    else if (self.view.bounds.size.width == 375)
        lblPushRequest.font = [UIFont fontWithName:@"OpenSans-Bold" size:20];
    else
        lblPushRequest.font = [UIFont fontWithName:@"OpenSans-Bold" size:24];
    lblPushRequest.textColor = [UIColor whiteColor];
    lblPushRequest.text = @"Don't miss your order!";
    lblPushRequest.alpha = 0;
    [self.lblPlatform addSubview:lblPushRequest];
    
    lblPushComment = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width - 80, 88)];
    lblPushComment.center = CGPointMake(self.lblComment.center.x, self.lblComment.center.y + 100);
    lblPushComment.adjustsFontSizeToFitWidth = YES;
    if (self.view.bounds.size.width == 320)
        lblPushComment.font = [UIFont fontWithName:@"OpenSans-Semibold" size:17];
    else if (self.view.bounds.size.width == 375)
        lblPushComment.font = [UIFont fontWithName:@"OpenSans-Semibold" size:20];
    else
        lblPushComment.font = [UIFont fontWithName:@"OpenSans-Semibold" size:24];
    lblPushComment.numberOfLines = 0;
    lblPushComment.textAlignment = NSTextAlignmentCenter;
    lblPushComment.textColor = [UIColor whiteColor];
    lblPushComment.text = @"Allow push notifications to get timely updates!";
    lblPushComment.alpha = 0;
    [self.lblPlatform addSubview:lblPushComment];
    
    [self requestForLocationServices];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark Network Connectivity

- (void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noConnection) name:@"networkError" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yesConnection) name:@"networkConnected" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startTimerOnViewedScreen) name:@"enteredForeground" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endTimerOnViewedScreen) name:@"enteringBackground" object:nil];
    
    [self startTimerOnViewedScreen];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewWillDisappear:animated];
    
    [self endTimerOnViewedScreen];
}

#pragma mark Duration on screen
- (void)startTimerOnViewedScreen
{
    [[Mixpanel sharedInstance] timeEvent:@"Viewed Intro Screen"];
}

- (void)endTimerOnViewedScreen
{
    [[Mixpanel sharedInstance] track:@"Viewed Intro Screen"];
}

- (void)noConnection
{
    if (loadingHUD == nil)
    {
        loadingHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
        loadingHUD.textLabel.text = @"Waiting for internet connectivity...";
        [loadingHUD showInView:self.view];
    }
}

- (void)yesConnection
{
    [loadingHUD dismiss];
    loadingHUD = nil;
}

#pragma mark Location Services

- (void)requestForLocationServices
{
    // Initialize location manager.
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    locationManager.distanceFilter = 500; // only update if moved 500 meters
    
#ifdef __IPHONE_8_0
    if (IS_OS_8_OR_LATER)
        // Use one or the other, not both. Depending on what you put in info.plist
        [locationManager requestWhenInUseAuthorization];
#endif
    
    [locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    [[Mixpanel sharedInstance] track:@"Don't Allow Location Services"];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"Pressed Get Started"] == nil) {
        [self showTutorial];
    }
    else {
        if ([self isPushEnabled]) {
            [self exitIntroScreen];
        }
        else {
            [self showPushTutorialV2];
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"Shown Location Request"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    // ran once
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"LocationServices"]) {
        [[NSUserDefaults standardUserDefaults] setObject:@"Enabled" forKey:@"LocationServices"];
        [[Mixpanel sharedInstance] track:@"Allow Location Services"];
    }
    
    CLLocation *location = locations[0];
    coordinate = location.coordinate;
    
    NSLog(@"lat: %f, long: %f", coordinate.latitude, coordinate.longitude);
    
    [manager stopUpdatingLocation];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"Pressed Get Started"] == nil) {
        [self showTutorial];
    }
    else {
        if ([self isPushEnabled]) {
            [self exitIntroScreen];
        }
        else {
            [self showPushTutorialV2];
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"Shown Location Request"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (CLLocationCoordinate2D )getCurrentLocation
{
#if (TARGET_IPHONE_SIMULATOR)
    CLLocation *location = [[CLLocation alloc] initWithLatitude:33.571895f longitude:-117.7379837036132f];
    return location.coordinate;
#endif
    
    return coordinate;
}


#pragma mark Intro Tutorial

- (void)showTutorial
{
    [UIView animateWithDuration:1 animations:^{
        lblLocationRequest.alpha = 0;
        self.arrowPlatform.alpha = 0;
    }];
    
    [UIView animateWithDuration:2 delay:0.5 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.lblItem0.alpha = 1;
    } completion:^(BOOL finished) {

    }];

    [UIView animateWithDuration:2 delay:1.0 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.lblNumber1.alpha = 1;
        self.lblItem1.alpha = 1;
    } completion:^(BOOL finished) {

    }];

    [UIView animateWithDuration:2 delay:1.5 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.lblNumber2.alpha = 1;
        self.lblItem2.alpha = 1;
    } completion:^(BOOL finished) {

    }];

    [UIView animateWithDuration:2 delay:2.0 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.lblNumber3.alpha = 1;
        self.lblItem3.alpha = 1;
    } completion:^(BOOL finished) {

    }];

    [UIView animateWithDuration:2 delay:2.5 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.btnGetStarted.alpha = 1;
    } completion:^(BOOL finished) {
        self.btnGetStarted.enabled = YES;
    }];
}

- (IBAction)onGetStarted:(id)sender
{
    if ([self isPushEnabled]) {
        exitOnWhichScreen = @"Intro";
        [self exitIntroScreen];
    }
    else {
        [self showPushTutorial];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"Pressed Get Started"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark Push Notifications

- (BOOL)isPushEnabled
{
    BOOL enabled;
    
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(currentUserNotificationSettings)]) {
        
        UIUserNotificationSettings *notificationSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
        
        if (!notificationSettings || (notificationSettings.types == UIUserNotificationTypeNone)) {
            enabled = NO;
        }
        else {
            enabled = YES;
        }
    }
    else {
        UIRemoteNotificationType types = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
        
        if (types & UIRemoteNotificationTypeAlert) {
            enabled = YES;
        }
        else {
            enabled = NO;
        }
    }
    
    return enabled;
}

- (void)showPushTutorial
{
    [UIView animateWithDuration:1 delay:0.0 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.lblItem0.alpha = 0;
    } completion:^(BOOL finished) {

    }];

    [UIView animateWithDuration:1 delay:0.1 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.lblNumber1.alpha = 0;
        self.lblItem1.alpha = 0;
    } completion:^(BOOL finished) {

    }];

    [UIView animateWithDuration:1 delay:0.2 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.lblNumber2.alpha = 0;
        self.lblItem2.alpha = 0;
    } completion:^(BOOL finished) {

    }];

    [UIView animateWithDuration:1 delay:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.lblNumber3.alpha = 0;
        self.lblItem3.alpha = 0;
    } completion:^(BOOL finished) {

    }];

    [UIView animateWithDuration:1 delay:0.4 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.btnGetStarted.enabled = NO;
        self.btnGetStarted.alpha = 0;
    } completion:^(BOOL finished) {
        
    }];
    
    [UIView animateWithDuration:2 delay:0.5 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        lblPushRequest.alpha = 1;
    } completion:^(BOOL finished) {
        
    }];
    
    [UIView animateWithDuration:2 delay:1.0 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        lblPushComment.alpha = 1;
    } completion:^(BOOL finished) {
        
    }];
    
    [UIView animateWithDuration:2 delay:1.5 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.btnNoThanks.alpha = 1;
        self.btnAllow.alpha = 1;
    } completion:^(BOOL finished) {
        self.btnNoThanks.enabled = YES;
        self.btnAllow.enabled = YES;
    }];
}

// call this if user had pressed get started before, but closed the app before finishing the entire onboarding process
- (void)showPushTutorialV2
{
    [UIView animateWithDuration:2 delay:0.0 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        lblPushRequest.alpha = 1;
    } completion:^(BOOL finished) {
        
    }];
    
    [UIView animateWithDuration:2 delay:0.5 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        lblPushComment.alpha = 1;
    } completion:^(BOOL finished) {
        
    }];
    
    [UIView animateWithDuration:2 delay:1.0 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.btnNoThanks.alpha = 1;
        self.btnAllow.alpha = 1;
    } completion:^(BOOL finished) {
        self.btnNoThanks.enabled = YES;
        self.btnAllow.enabled = YES;
    }];
}

- (IBAction)onNoThanks:(id)sender
{
    exitOnWhichScreen = @"Push";
    [self exitIntroScreen];
}

- (IBAction)onOK:(id)sender
{
    NSError *error = nil;
    NSString *has_shown_push_alert = [FDKeychain itemForKey: @"has_shown_push_alert"
                                     forService: @"Bento"
                                          error: &error];
    
    // if system alert has been shown before
    if ([has_shown_push_alert isEqualToString:@"YES"]) {
        [self showRouteToDeviceSettingsAlert];
    }
    // if system alert has not been shown before
    else {
        [self requestPush];
        
        exitOnWhichScreen = @"Push";
        [self exitIntroScreen];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"Push Requested"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // save a flag to keychain
    [FDKeychain saveItem:@"YES"
                  forKey:@"has_shown_push_alert"
              forService:@"Bento"
                   error:&error];
}

- (void)requestPush
{
    // iOS 8 and up
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
    // iOS 7 and below
    else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes: (UIRemoteNotificationTypeNewsstandContentAvailability| UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    }
}

- (void)showRouteToDeviceSettingsAlert
{
    // go to Bento settings if ios 8+
    if ([[UIDevice currentDevice].systemVersion intValue] >= 8) {
        
        MyAlertView *alertView1 = [[MyAlertView alloc] initWithTitle:@"" message:@"Turn on notifications by going into Settings, scrolling to Bento Now and choosing Allow Notifications." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitle:@"Turn On"];
        alertView1.tag = 911;
        [alertView1 showInView:self.view];
    }
    // if ios 7, just show alert with explanation
    else {
        MyAlertView *alertView2 = [[MyAlertView alloc] initWithTitle:@"" message:@"Turn on notifications by going into Settings, scrolling to Bento Now and choosing Allow Notifications." delegate:self cancelButtonTitle:@"OK" otherButtonTitle:nil];
        [alertView2 showInView:self.view];
    }
}

#pragma mark MyAlertViewDelegate

- (void)alertView:(MyAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    exitOnWhichScreen = @"Push";
    [self exitIntroScreen];
    
    if (alertView.tag == 911) {
        if (buttonIndex == 1) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        }
    }
}

#pragma mark Exit Screen

- (void)exitIntroScreen
{
    // fade locations labels
    if ([exitOnWhichScreen isEqualToString:@"Intro"])
    {
        [UIView animateWithDuration:1 delay:0.0 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            self.lblItem0.alpha = 0;
        } completion:^(BOOL finished) {
            
        }];
        
        [UIView animateWithDuration:1 delay:0.1 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            self.lblNumber1.alpha = 0;
            self.lblItem1.alpha = 0;
        } completion:^(BOOL finished) {
            
        }];
        
        [UIView animateWithDuration:1 delay:0.2 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            self.lblNumber2.alpha = 0;
            self.lblItem2.alpha = 0;
        } completion:^(BOOL finished) {
            
        }];
        
        [UIView animateWithDuration:1 delay:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            self.lblNumber3.alpha = 0;
            self.lblItem3.alpha = 0;
        } completion:^(BOOL finished) {
            
        }];

        [UIView animateWithDuration:1 delay:0.4 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            self.btnGetStarted.enabled = NO;
            self.btnGetStarted.alpha = 0;
        } completion:^(BOOL finished) {
            [self fadeOutOnExit];
        }];
    }
    
    // fade push labels
    else if ([exitOnWhichScreen isEqualToString:@"Push"])
    {
        [UIView animateWithDuration:1 delay:0.0 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            self.ivLogo.alpha = 0;
        } completion:^(BOOL finished) {
            
        }];
        
        [UIView animateWithDuration:1 delay:0.1 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            lblPushRequest.alpha = 0;
        } completion:^(BOOL finished) {
            
        }];
        
        [UIView animateWithDuration:1 delay:0.2 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            lblPushComment.alpha = 0;
        } completion:^(BOOL finished) {
            
        }];
        
        [UIView animateWithDuration:1 delay:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            self.btnNoThanks.enabled = NO;
            self.btnAllow.enabled = NO;
            self.btnNoThanks.alpha = 0;
            self.btnAllow.alpha = 0;
        } completion:^(BOOL finished) {
            [self fadeOutOnExit];
        }];
    }
    
    // Intro has been processed, so don't show Intro screen again
    [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"IntroProcessed"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)fadeOutOnExit
{
    CATransition *transition = [CATransition animation];
    transition.duration = 0.5;
    transition.type = kCATransitionFade;
    
    [self.navigationController.view.layer addAnimation:transition forKey:kCATransition];
    [self.navigationController popViewControllerAnimated:NO];
}

@end
