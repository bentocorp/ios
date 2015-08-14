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

#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

@interface IntroViewController()

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

@end

@implementation IntroViewController
{
    JGProgressHUD *loadingHUD;
    
    UIView *lblLocationPlatform;
    UILabel *lblLocationRequest;
    UILabel *lblLocationComment;
    
    UILabel *lblPushRequest;
    UILabel *lblPushComment;
    
    CLLocationManager *locationManager;
    CLLocationCoordinate2D coordinate;
    
    BOOL passedLocationNoThanks;
    BOOL passedLocationAllow;
    
    NSString *exitOnWhichScreen;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Gradient
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.ivBackground.bounds;
    
    // Get colors for gradient
    UIColor *color1 = [DataManager getGradientColor1];
    UIColor *color2 = [DataManager getGradientColor2];
    
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
    
    self.btnNoThanks.alpha = 0;
    self.btnAllow.alpha = 0;
    
    self.btnNoThanks.center = CGPointMake(self.btnNoThanks.center.x, self.btnNoThanks.center.y);
    self.btnAllow.center = CGPointMake(self.btnAllow.center.x, self.btnAllow.center.y);
    
    self.ivLogo.alpha = 0;
    self.btnGetStarted.alpha = 0;
    
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
    
    // Location Request
    lblLocationPlatform = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 255)];
    lblLocationPlatform.center = CGPointMake(self.lblPlatform.center.x, self.lblPlatform.center.y);
    [self.view addSubview:lblLocationPlatform];
    
    lblLocationRequest = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width - 80, 44)];
    lblLocationRequest.center = self.lblComment.center;
    lblLocationRequest.textAlignment = NSTextAlignmentCenter;
    if (self.view.bounds.size.width == 320)
        lblLocationRequest.font = [UIFont fontWithName:@"OpenSans-Bold" size:17];
    else if (self.view.bounds.size.width == 375)
        lblLocationRequest.font = [UIFont fontWithName:@"OpenSans-Bold" size:20];
    else
        lblLocationRequest.font = [UIFont fontWithName:@"OpenSans-Bold" size:24];
    lblLocationRequest.textColor = [UIColor whiteColor];
    lblLocationRequest.text = @"Want speedier delivery?";
    lblLocationRequest.alpha = 0;
    [lblLocationPlatform addSubview:lblLocationRequest];
    
    lblLocationComment = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width - 80, 88)];
    lblLocationComment.center = CGPointMake(lblLocationRequest.center.x, lblLocationRequest.center.y + 100);
    lblLocationComment.adjustsFontSizeToFitWidth = YES;
    if (self.view.bounds.size.width == 320)
        lblLocationComment.font = [UIFont fontWithName:@"OpenSans-Semibold" size:17];
    else if (self.view.bounds.size.width == 375)
        lblLocationComment.font = [UIFont fontWithName:@"OpenSans-Semibold" size:20];
    else
        lblLocationComment.font = [UIFont fontWithName:@"OpenSans-Semibold" size:24];
    lblLocationComment.numberOfLines = 0;
    lblLocationComment.textAlignment = NSTextAlignmentCenter;
    lblLocationComment.textColor = [UIColor whiteColor];
    lblLocationComment.text = @"Bento needs your zipcode to check your delivery area.";
    lblLocationComment.alpha = 0;
    [lblLocationPlatform addSubview:lblLocationComment];
    
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
    [lblLocationPlatform addSubview:lblPushRequest];
    
    lblPushComment = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width - 80, 88)];
    lblPushComment.center = CGPointMake(lblLocationRequest.center.x, lblLocationRequest.center.y + 100);
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
    lblPushComment.text = @"Allow push notifications to get timely updates & information about your order status!";
    lblPushComment.alpha = 0;
    [lblLocationPlatform addSubview:lblPushComment];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noConnection) name:@"networkError" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yesConnection) name:@"networkConnected" object:nil];
}

- (void)viewDidLayoutSubviews
{
    [UIView animateWithDuration:2 delay:0.0 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.ivLogo.alpha = 1;
    } completion:^(BOOL finished) {

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
        
    }];
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

- (IBAction)onGetStarted:(id)sender
{
    [self firstAnimation];
}

- (IBAction)onNoThanks:(id)sender
{
    // NO THANKS pressed in locations walk-through
    if (passedLocationNoThanks == NO)
    {
        passedLocationNoThanks = YES;
        
        // if push is already asked, exit introVC
        if ([self isPushEnabled])
        {
            exitOnWhichScreen = @"Location";
            [self exitIntroScreen];
        }
        
        // if push hasn't been asked, then show push tutorial
        else
            [self showPushTutorial];
    }
    
    // NO THANKS pressed in push walk-through
    else
    {
        exitOnWhichScreen = @"Push";
        [self exitIntroScreen];
    }
}

- (IBAction)onOK:(id)sender
{
    /*----------------LOCATIONS----------------*/
    if (passedLocationAllow == NO)
    {
        // Initialize location manager.
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        locationManager.distanceFilter = kCLDistanceFilterNone;
        locationManager.distanceFilter = 50; // only update if moved 50 meters
        
    #ifdef __IPHONE_8_0
        if (IS_OS_8_OR_LATER)
            // Use one or the other, not both. Depending on what you put in info.plist
            [locationManager requestWhenInUseAuthorization];
    #endif
        
        [locationManager startUpdatingLocation];
    }
    
    /*------------PUSH NOTIFICATIONS----------*/
    else
    {
#ifndef DEV_MODE
        // Tell iOS you want your app to receive push notifications
        
        // This code will work in iOS 8.0 xcode 6.0 or later:
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
        {
            [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
            [[UIApplication sharedApplication] registerForRemoteNotifications];
        }
        // This code will work in iOS 7.0 and below:
        else
        {
            [[UIApplication sharedApplication] registerForRemoteNotificationTypes: (UIRemoteNotificationTypeNewsstandContentAvailability| UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
        }
        
        exitOnWhichScreen = @"Push";
        [self exitIntroScreen];
#endif
    }
}

- (void)firstAnimation
{
    [UIView animateWithDuration:1 delay:0.0 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.lblItem0.alpha = 0;
    } completion:^(BOOL finished) {
        
    }];
    
    [UIView animateWithDuration:1 delay:0.2 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.lblNumber1.alpha = 0;
        self.lblItem1.alpha = 0;
    } completion:^(BOOL finished) {
        
    }];
    
    [UIView animateWithDuration:1 delay:0.4 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.lblNumber2.alpha = 0;
        self.lblItem2.alpha = 0;
    } completion:^(BOOL finished) {
        
    }];
    
    [UIView animateWithDuration:1 delay:0.6 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.lblNumber3.alpha = 0;
        self.lblItem3.alpha = 0;
    } completion:^(BOOL finished) {
        
    }];
    
    [UIView animateWithDuration:1 delay:0.8 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.btnGetStarted.alpha = 0;
    } completion:^(BOOL finished) {
        
    }];
    
    [UIView animateWithDuration:2 delay:0.8 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        lblLocationRequest.alpha = 1;
    } completion:^(BOOL finished) {
        
    }];
    
    [UIView animateWithDuration:2 delay:1.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        lblLocationComment.alpha = 1;
    } completion:^(BOOL finished) {
        
    }];
    
    [UIView animateWithDuration:2 delay:1.8 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.btnNoThanks.alpha = 1;
        self.btnAllow.alpha = 1;
    } completion:^(BOOL finished) {
        
    }];
}

#pragma mark Current Location

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    [[Mixpanel sharedInstance] track:@"Don't Allow Location Services"];
    
    // Tapped OK, but then tapped Don't Allow
    passedLocationAllow = YES;
    
    // if push is already asked, exit introVC
    if ([self isPushEnabled])
    {
        exitOnWhichScreen = @"Location";
        [self exitIntroScreen];
    }
    
    // if push hasn't been asked, then show push tutorial
    else
        [self showPushTutorial];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    // ran once
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"LocationServices"])
    {
        [[NSUserDefaults standardUserDefaults] setObject:@"Enabled" forKey:@"LocationServices"];
        [[Mixpanel sharedInstance] track:@"Allow Location Services"];
    }
    
    passedLocationAllow = YES;
    
    CLLocation *location = locations[0];
    coordinate = location.coordinate;
    
    NSLog(@"lat: %f, long: %f", coordinate.latitude, coordinate.longitude);
    
    [manager stopUpdatingLocation];
    
    // if push is already asked, pop
    if ([self isPushEnabled])
        [self exitIntroScreen];
    // if push hasn't been asked, then ask for push
    else
        [self showPushTutorial];
}

- (CLLocationCoordinate2D )getCurrentLocation
{
#if (TARGET_IPHONE_SIMULATOR)
    CLLocation *location = [[CLLocation alloc] initWithLatitude:33.571895f longitude:-117.7379837036132f];
    return location.coordinate;
#endif
    
    return coordinate;
}

- (void)exitIntroScreen
{
    // fade locations labels
    if ([exitOnWhichScreen isEqualToString:@"Location"])
    {
        [UIView animateWithDuration:1 delay:0.0 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            self.ivLogo.alpha = 0;
        } completion:^(BOOL finished) {
            
        }];
        
        [UIView animateWithDuration:1 delay:0.2 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            lblLocationRequest.alpha = 0;
        } completion:^(BOOL finished) {
            
        }];
        
        [UIView animateWithDuration:1 delay:0.4 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            lblLocationComment.alpha = 0;
        } completion:^(BOOL finished) {
            
        }];
        
        [UIView animateWithDuration:1 delay:0.6 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            self.btnNoThanks.alpha = 0;
            self.btnAllow.alpha = 0;
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
        
        [UIView animateWithDuration:1 delay:0.2 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            lblPushRequest.alpha = 0;
        } completion:^(BOOL finished) {
            
        }];
        
        [UIView animateWithDuration:1 delay:0.4 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            lblPushComment.alpha = 0;
        } completion:^(BOOL finished) {
            
        }];
        
        [UIView animateWithDuration:1 delay:0.6 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
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

- (BOOL)isPushEnabled
{
    BOOL enabled;
    
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(currentUserNotificationSettings)])
    {
        UIUserNotificationSettings *notificationSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
        
        if (!notificationSettings || (notificationSettings.types == UIUserNotificationTypeNone))
            enabled = NO;
        else
            enabled = YES;
    }
    else
    {
        UIRemoteNotificationType types = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
        
        if (types & UIRemoteNotificationTypeAlert)
            enabled = YES;
        else
            enabled = NO;
    }
    
    return enabled;
}
         
- (void)showPushTutorial
{
    [UIView animateWithDuration:1 delay:0.0 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        lblLocationRequest.alpha = 0;
    } completion:^(BOOL finished) {
        
    }];
    
    [UIView animateWithDuration:1 delay:0.2 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        lblLocationComment.alpha = 0;
    } completion:^(BOOL finished) {
        
    }];
    
    [UIView animateWithDuration:2 delay:0.2 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        lblPushRequest.alpha = 1;
    } completion:^(BOOL finished) {
        
    }];
    
    [UIView animateWithDuration:2 delay:0.7 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        lblPushComment.alpha = 1;
    } completion:^(BOOL finished) {
        
    }];
}

#pragma mark Push Notifications

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel.people addPushDeviceToken:deviceToken];
    
    NSLog(@"%@", deviceToken);
}


@end
