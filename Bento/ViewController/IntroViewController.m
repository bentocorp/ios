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
    
    CLLocationManager *locationManager;
    CLLocationCoordinate2D coordinate;
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

    self.lblNumber2.layer.cornerRadius = self.lblNumber2.frame.size.width / 2;
    self.lblNumber2.clipsToBounds = YES;
    
    self.lblNumber3.layer.cornerRadius = self.lblNumber3.frame.size.width / 2;
    self.lblNumber3.clipsToBounds = YES;
    
    self.btnGetStarted.layer.cornerRadius = 3;
    self.btnNoThanks.layer.cornerRadius = 3;
    self.btnAllow.layer.cornerRadius = 3;
    
    self.btnNoThanks.hidden = YES;
    self.btnAllow.hidden = YES;
    
    self.btnNoThanks.center = CGPointMake(self.btnNoThanks.center.x, self.btnNoThanks.center.y + 100);
    self.btnAllow.center = CGPointMake(self.btnAllow.center.x, self.btnAllow.center.y + 100);
    
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
    
    // Get button title text and set it to button
    [self.btnGetStarted setTitle:[[AppStrings sharedInstance] getString:ABOUT_BUTTON_TITLE] forState:UIControlStateNormal];
    
    // Location Request
    lblLocationPlatform = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 255)];
    lblLocationPlatform.center = CGPointMake(self.lblPlatform.center.x + 400, self.lblPlatform.center.y);
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
    [lblLocationPlatform addSubview:lblLocationRequest];
    
    lblLocationComment = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width - 80, 88)];
    lblLocationComment.center = CGPointMake(lblLocationRequest.center.x, lblLocationRequest.center.y + 100);
//    lblLocationComment.adjustsFontSizeToFitWidth = YES;
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
    [lblLocationPlatform addSubview:lblLocationComment];
}

- (void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noConnection) name:@"networkError" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yesConnection) name:@"networkConnected" object:nil];
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
//    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HasLaunchedOnce"];
//    [[NSUserDefaults standardUserDefaults] synchronize];
    
//    [self.navigationController popViewControllerAnimated:YES];
    
    [self firstAnimation];
}

- (IBAction)onNoThanks:(id)sender
{
    NSLog(@"No Thanks");
}

- (IBAction)onOK:(id)sender
{
    // Initialize location manager.
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    
#ifdef __IPHONE_8_0
    if (IS_OS_8_OR_LATER)
        // Use one or the other, not both. Depending on what you put in info.plist
        [locationManager requestWhenInUseAuthorization];
#endif
    
    [locationManager startUpdatingLocation];
}

- (void)firstAnimation
{
    [UIView animateWithDuration:0.5 animations:^{
        lblLocationPlatform.center  = self.lblPlatform.center;
        
        self.lblPlatform.center = CGPointMake(self.lblPlatform.center.x - 400, self.lblPlatform.center.y);
        self.btnGetStarted.center = CGPointMake(self.btnGetStarted.center.x, self.btnGetStarted.center.y + 100);
    } completion:^(BOOL finished) {
        [self secondAnimation];
    }];
}

- (void)secondAnimation
{
    [UIView animateWithDuration:0.5 animations:^{
        self.btnNoThanks.hidden = NO;
        self.btnAllow.hidden = NO;
        self.btnNoThanks.center = CGPointMake(self.btnNoThanks.center.x, self.btnNoThanks.center.y - 100);
        self.btnAllow.center = CGPointMake(self.btnAllow.center.x, self.btnAllow.center.y - 100);
    } completion:^(BOOL finished) {
        
    }];
}

#pragma mark Current Location

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    [[Mixpanel sharedInstance] track:@"Don't Allow Location Services"];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    // Location allowed, proceed to 1) push notifications request OR 2) popVC
    
    // show once
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"LocationServices"])
    {
        [[NSUserDefaults standardUserDefaults] setObject:@"Enabled" forKey:@"LocationServices"];
        [[Mixpanel sharedInstance] track:@"Allow Location Services"];
    }
    
    CLLocation *location = locations[0];
    coordinate = location.coordinate;
    
    NSLog(@"lat: %f, long: %f", coordinate.latitude, coordinate.longitude);
    
    [manager stopUpdatingLocation];
}

- (CLLocationCoordinate2D )getCurrentLocation
{
#if (TARGET_IPHONE_SIMULATOR)
    CLLocation *location = [[CLLocation alloc] initWithLatitude:33.571895f longitude:-117.7379837036132f];
    return location.coordinate;
#endif
    
    return coordinate;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
