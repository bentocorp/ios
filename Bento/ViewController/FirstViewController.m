//
//  ViewController.m
//  Bento
//
//  Created by hanjinghe on 1/6/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "FirstViewController.h"

#import "SoldOutViewController.h"

#import "MyAlertView.h"

#import "UIImageView+WebCache.h"

#import "AppDelegate.h"

#import "BentoShop.h"
#import "AppStrings.h"
#import "WebManager.h"
#import "DataManager.h"
#import "Reachability.h"

#import "ServingDinnerViewController.h"
#import "ServingLunchViewController.h"

@interface FirstViewController ()
{
    BOOL _hasInit;
}

@property (nonatomic, assign) IBOutlet UIImageView *ivBackground;

@property (nonatomic, assign) IBOutlet UIImageView *ivLaunchLogo;

@property (nonatomic, assign) IBOutlet UILabel *lblLaunchSlogan;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _hasInit = NO;
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.ivBackground.bounds;

    UIColor *color1 = [DataManager getGradientColor1];
    UIColor *color2 = [DataManager getGradientColor2];
    gradient.colors = [NSArray arrayWithObjects:(id)[color1 CGColor], (id)[color2 CGColor], nil];
    [self.ivBackground.layer insertSublayer:gradient atIndex:0];
    
//    [self.ivBackground setImage:[UIImage imageNamed:@"first_background"]];
    [self.ivLaunchLogo setImage:[UIImage imageNamed:@"logo"]];
    
    NSString *strSlogan = [[NSUserDefaults standardUserDefaults] objectForKey:@"Slogan"];
    if (strSlogan == nil || strSlogan.length > 0)
        strSlogan = @"Delicious Asian Food Delivered in Minutes.";
    self.lblLaunchSlogan.text = strSlogan;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"SoldOut"])
    {
        SoldOutViewController *vc = segue.destinationViewController;
        NSNumber *number = (NSNumber *)sender;
        vc.type = [number integerValue];
    }
}

- (void)initProcedure
{
    self.activityIndicator.hidden = NO;
    [self.activityIndicator startAnimating];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1f]];
    
    [[AppStrings sharedInstance] getAppStrings];
    
    NSURL *urlBack = [[BentoShop sharedInstance] getMenuImageURL];
    [self.ivBackground sd_setImageWithURL:urlBack];
//    [self.ivBackground sd_setImageWithURL:urlBack placeholderImage:[UIImage imageNamed:@"first_background"]];
    
    NSURL *urlLogo = [[AppStrings sharedInstance] getURL:APP_LOGO];
    [self.ivLaunchLogo sd_setImageWithURL:urlLogo placeholderImage:[UIImage imageNamed:@"logo"]];
    
    NSString *strSlogan = [[AppStrings sharedInstance] getString:APP_SLOGAN];
    self.lblLaunchSlogan.text = strSlogan;
    [[NSUserDefaults standardUserDefaults] setObject:strSlogan forKey:@"Slogan"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[BentoShop sharedInstance] getMenus];
    [[BentoShop sharedInstance] getStatus];
    [[BentoShop sharedInstance] getServiceArea];
    [[BentoShop sharedInstance] refreshStart];
    
    [self.activityIndicator stopAnimating];

    // Check the app is already launched
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"HasLaunchedOnce"])
    {
        // This is the first launch ever
        [self performSelector:@selector(gotoIntroScreen) withObject:nil afterDelay:1.0f];
        return;
    }
    else
    {
        [self performSelector:@selector(process) withObject:nil afterDelay:1.0f];
        return;
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!_hasInit)
    {
        _hasInit = YES;
        [self performSelector:@selector(initProcedure) withObject:nil afterDelay:0.01f];
    }
    else
    {
        [self processAfterLogin];
    }
}

- (void)processAutoLogin
{
    NSUserDefaults *pref = [NSUserDefaults standardUserDefaults];
    NSString *strAPIName = [pref objectForKey:@"apiName"];
    NSDictionary *dicRequest = [pref objectForKey:@"loginRequest"];
    
    NSLog(@"auto login dicRequest - %@", dicRequest);
    
    WebManager *webManager = [[WebManager alloc] init];
    
    self.activityIndicator.hidden = NO;
    [self.activityIndicator startAnimating];
    
    [webManager AsyncProcess:strAPIName method:POST parameters:dicRequest success:^(MKNetworkOperation *networkOperation) {
        [self.activityIndicator stopAnimating];
        
        NSDictionary *response = networkOperation.responseJSON;
        [[DataManager shareDataManager] setUserInfo:response];
        
        NSLog(@"auto login response - %@", response);

        [self processAfterLogin];
        
    } failure:^(MKNetworkOperation *errorOp, NSError *error) {
        [self.activityIndicator stopAnimating];
        
        [pref setObject:nil forKey:@"apiName"];
        [pref setObject:nil forKey:@"loginRequest"];
        [pref synchronize];
        
        NSString *strMessage = [[DataManager shareDataManager] getErrorMessage:errorOp.responseJSON];
        if (strMessage == nil)
            strMessage = error.localizedDescription;
        
        MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"" message:strMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitle:nil];
        [alertView showInView:self.view];
        alertView = nil;
        
    } isJSON:NO];
}

- (void)processAfterLogin
{
    BentoShop *globalShop = [BentoShop sharedInstance];
    if ([globalShop isClosed])
    {
        // Check if the user is an admin or not.
        if ([[DataManager shareDataManager] getUserInfo] == nil || ![[DataManager shareDataManager] isAdminUser])
        {
            [self gotoClosedScreen];
            return;
        }
    }
    
    if ([globalShop isSoldOut])
    {
        // Check if the user is an admin or not.
        if ([[DataManager shareDataManager] getUserInfo] == nil || ![[DataManager shareDataManager] isAdminUser])
        {
            [self gotoSoldOutScreen];
            return;
        }
    }

    [self gotoMyBentoScreen];
}

- (void)process
{
    NSUserDefaults *pref = [NSUserDefaults standardUserDefaults];
/*
#ifdef DEBUG
    if ([pref objectForKey:@"apiName"] == nil)
        [pref setObject:@"/user/login" forKey:@"apiName"];
    
    if ([pref objectForKey:@"loginRequest"] == nil)
    {
        NSDictionary* loginInfo = @{
                                    @"email" : @"ridev@bentonow.com",
                                    @"password" : @"12345678",
                                    };
        
        NSDictionary *dicRequest = @{@"data" : [loginInfo jsonEncodedKeyValueString]};
        [pref setObject:dicRequest forKey:@"loginRequest"];
    }
#endif
*/    
    if ([pref objectForKey:@"apiName"] != nil && [pref objectForKey:@"loginRequest"] != nil)
    {
        [self processAutoLogin];
    }
    else
    {
        [self processAfterLogin];
    }
}

- (void) gotoIntroScreen
{
    [self performSegueWithIdentifier:@"Intro" sender:nil];
}

- (void) gotoClosedScreen
{
//    [self performSegueWithIdentifier:@"SoldOut" sender:[NSNumber numberWithInt:0]];
    [self showSoldoutScreen:[NSNumber numberWithInt:0]];
}

- (void) gotoSoldOutScreen
{
//    [self performSegueWithIdentifier:@"SoldOut" sender:[NSNumber numberWithInt:1]];
    [self showSoldoutScreen:[NSNumber numberWithInt:1]];
}

- (void) gotoMyBentoScreen
{
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    CLLocationCoordinate2D location = [delegate getCurrentLocation];
    BentoShop *globalShop = [BentoShop sharedInstance];
    
    BOOL needsAnimation = YES;
    if (![globalShop checkLocation:location] && [[DataManager shareDataManager] getUserInfo] == nil)
        needsAnimation = NO;
    
/*--------------Determine whether to show Lunch or Dinner mode--------------*/
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    float currentTime = [[defaults objectForKey:@"currentTimeNumber"] floatValue];
    float dinnerTime = [[defaults objectForKey:@"dinnerTimeNumber"] floatValue];
    
    // 12:00am - dinner opening (ie. 16.5)
    if (currentTime >= 0 && currentTime < dinnerTime) {
        
        ServingLunchViewController *servingLunchViewController = [[ServingLunchViewController alloc] init];
        [self.navigationController pushViewController:servingLunchViewController animated:needsAnimation];
        
    // dinner opening - 11:59pm
    } else if (currentTime >= dinnerTime && currentTime < 24) {
        
        ServingDinnerViewController *servingDinnerViewController = [[ServingDinnerViewController alloc] init];
        [self.navigationController pushViewController:servingDinnerViewController animated:needsAnimation];
    }
}

- (void) showSoldoutScreen:(NSNumber *)identifier
{
    UINavigationController *nav = [self.storyboard instantiateViewControllerWithIdentifier:@"SoldOut"];
    SoldOutViewController *vcSoldOut = (SoldOutViewController *)nav.topViewController;
    vcSoldOut.type = [identifier integerValue];
    
    [self.navigationController presentViewController:nav animated:YES completion:nil];
}

@end
