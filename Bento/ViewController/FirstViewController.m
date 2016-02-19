//
//  ViewController.m
//  Bento
//
//  Created by hanjinghe on 1/6/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "FirstViewController.h"

#import "NetworkErrorViewController.h"
#import "SoldOutViewController.h"

#import "MyAlertView.h"

#import "UIImageView+WebCache.h"

#import "AppDelegate.h"

#import "BentoShop.h"
#import "AppStrings.h"
#import "WebManager.h"
#import "DataManager.h"
#import "Reachability.h"

#import "FiveHomeViewController.h"

#import "ChooseMainDishViewController.h"
#import "ChooseSideDishViewController.h"

#import "Mixpanel.h"
#import "SVGeocoder.h"

#import "IntroViewController.h"

#import "UIColor+CustomColors.h"

#import "NSUserDefaults+RMSaveCustomObject.h"

#import "CountdownTimer.h"

#import "JGProgressHUD.h"

@interface FirstViewController () <CLLocationManagerDelegate>

@property (nonatomic, weak) IBOutlet UIImageView *ivBackground;

@property (nonatomic, weak) IBOutlet UIImageView *ivLaunchLogo;

@property (nonatomic, weak) IBOutlet UILabel *lblLaunchSlogan;

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

@implementation FirstViewController
{
    BOOL _hasInit;
    NSString *isThereConnection;
    
    CLLocationManager *locationManager;
    NSString *currentAddress;
    
    UIAlertView *aV;
    
    JGProgressHUD *loadingHUD;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    _hasInit = NO;
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.ivBackground.bounds;

    UIColor *color1 = [UIColor bentoGradient1];
    UIColor *color2 = [UIColor bentoGradient2];
    gradient.colors = [NSArray arrayWithObjects:(id)[color1 CGColor], (id)[color2 CGColor], nil];
    [self.ivBackground.layer insertSublayer:gradient atIndex:0];
    [self.ivLaunchLogo setImage:[UIImage imageNamed:@"logo"]];
    
    NSString *strSlogan = [[NSUserDefaults standardUserDefaults] objectForKey:@"Slogan"];
    if (strSlogan == nil || strSlogan.length > 0) {
        strSlogan = @"Delicious Asian Food Delivered in Minutes.";
    }
    self.lblLaunchSlogan.text = strSlogan;
    
    /*---------------------------LOCATION MANAGER--------------------------*/
        
        // If IntroVC has already been completely processed once, startUpdatingLocation
        if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"IntroProcessed"] isEqualToString:@"YES"]) {
            
            // Initialize location manager.
            locationManager = [[CLLocationManager alloc] init];
            locationManager.delegate = self;
            locationManager.desiredAccuracy = kCLLocationAccuracyBest;
            locationManager.distanceFilter = 500;
            
            [locationManager startUpdatingLocation];
        }
    
    /*---------------------------------------------------------------------*/
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *location = locations[0];
    
    // get address from coordinates
    [SVGeocoder reverseGeocode:location.coordinate completion:^(NSArray *placemarks, NSHTTPURLResponse *urlResponse, NSError *error) {
        if (error == nil && placemarks.count > 0) {
            SVPlacemark *placeMark = [placemarks firstObject];
            currentAddress = placeMark.formattedAddress;
            
            NSLog(@"ADDRESS: %@", placeMark.formattedAddress);
        }
    }];
    
    [manager stopUpdatingLocation];
}

-(NSString *)getCurrentDate
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"M/d/yyyy";
    NSString *currentDate = [formatter stringFromDate:[NSDate date]];
    
    return currentDate;
}

- (NSString *)getCurrentTime
{
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    NSString *currentTime = [dateFormatter stringFromDate:today];
    
    return currentTime;
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
    
    NSURL *urlBack = [[BentoShop sharedInstance] getMenuImageURL];
    [self.ivBackground sd_setImageWithURL:urlBack placeholderImage:[UIImage imageNamed:@"first_background"]];
    
    NSURL *urlLogo = [[AppStrings sharedInstance] getURL:APP_LOGO];
    [self.ivLaunchLogo sd_setImageWithURL:urlLogo placeholderImage:[UIImage imageNamed:@"logo"]];
    
    NSString *strSlogan = [[AppStrings sharedInstance] getString:APP_SLOGAN];
    self.lblLaunchSlogan.text = strSlogan;
    [[NSUserDefaults standardUserDefaults] setObject:strSlogan forKey:@"Slogan"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    if (isThereConnection)
    {
        // If IntroVC has not already been completely processed once, gotoIntroScreen
        if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"IntroProcessed"] isEqualToString:@"YES"])
        {
            [self performSelector:@selector(gotoIntroScreen) withObject:nil afterDelay:1.0f];
            return;
        }
        else
        {
            [self performSelector:@selector(process) withObject:nil afterDelay:1.0f];
            return;
        }
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.activityIndicator.hidden = NO;
    [self.activityIndicator startAnimating];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noConnection) name:@"networkError" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yesConnection) name:@"networkConnected" object:nil];
    
    [self loadData];
}

- (void)loadData {
    __block BentoShop *globalShop = [BentoShop sharedInstance];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"IntroProcessed"] isEqualToString:@"YES"] &&
            [[NSUserDefaults standardUserDefaults] rm_customObjectForKey:@"delivery_location"] != nil) {
            
            [globalShop getInit2WithGateKeeper:^(BOOL succeeded, NSError *error) {
                if (succeeded == NO && error != nil) {
                    
                    [self.activityIndicator stopAnimating];
                    
                    if (loadingHUD == nil) {
                        loadingHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
                        loadingHUD.textLabel.text = @"Waiting for internet connectivity...";
                        [loadingHUD showInView:self.view];
                    }
                    
                    [self loadData];
                }
                else {
                    if (loadingHUD != nil) {
                        [loadingHUD dismiss];
                        loadingHUD = nil;
                    }
                    
                    [globalShop getCurrentLunchDinnerBufferTimesInNumbersAndVersionNumbers];
                    
                    [self afterViewWillAppear];
                }
            }];
        }
        else {
            [globalShop getInit2:^(BOOL succeeded, NSError *error) {
                if (succeeded == NO && error != nil) {
                    
                    [self.activityIndicator stopAnimating];
                    
                    if (loadingHUD == nil) {
                        loadingHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
                        loadingHUD.textLabel.text = @"Waiting for internet connectivity...";
                        [loadingHUD showInView:self.view];
                    }
                    
                    [self loadData];
                }
                else {
                    if (loadingHUD != nil) {
                        [loadingHUD dismiss];
                        loadingHUD = nil;
                    }
                    
                    [globalShop getCurrentLunchDinnerBufferTimesInNumbersAndVersionNumbers];
                    
                    [self afterViewWillAppear];
                }
            }];
        }
    });
}

- (void)afterViewWillAppear {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [[BentoShop sharedInstance] refreshStart];
        [[CountdownTimer sharedInstance] refreshStart];
        
        if (!_hasInit) {
            
            // current VC has init once before
            _hasInit = YES;
            
            [self performSelector:@selector(initProcedure) withObject:nil afterDelay:0.01f];
        }
        else {
            // go to which screen next?
            [self processAfterLogin];
        }
        
        // reset if closed
        if ([[BentoShop sharedInstance] isClosed]) {
            [[BentoShop sharedInstance] resetBentoArray];
        }
        
        [self.activityIndicator stopAnimating];
    });
}

- (void)processAutoLogin
{
    NSString *strAPIName = [[NSUserDefaults standardUserDefaults] objectForKey:@"apiName"];
    NSDictionary *dicRequest = [[NSUserDefaults standardUserDefaults] objectForKey:@"loginRequest"];
    
    NSLog(@"auto login dicRequest - %@", dicRequest);
    
    WebManager *webManager = [[WebManager alloc] init];
    
    [webManager AsyncProcess:strAPIName method:POST parameters:dicRequest success:^(MKNetworkOperation *networkOperation)
    {
        [self.activityIndicator stopAnimating];
        
        NSDictionary *response = networkOperation.responseJSON;
        [[DataManager shareDataManager] setUserInfo:response];
        
        NSLog(@"auto login response - %@", response);
        
        /*-----------------------------MIXPANEL-------------------------------*/
        
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        
        // identify user for current session
        [mixpanel identify:response[@"email"]];
        
        // reregister deviceToken to server
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"deviceToken"] != nil) {
            
            NSData *deviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"deviceToken"];
            [mixpanel.people addPushDeviceToken:deviceToken];
            
            NSLog(@"Device Token - %@", deviceToken);
        }
        
        NSString *currentAddressFinal;
        
        if (currentAddress != nil) {
            currentAddressFinal = currentAddress;
        }
        else {
            currentAddressFinal = @"N/A";
        }
            
        // set properties
        [mixpanel.people set:@{
                               @"$name": [NSString stringWithFormat:@"%@ %@", response[@"firstname"], response[@"lastname"]],
                               @"$email": response[@"email"],
                               @"$phone": response[@"phone"],
                               @"Coupon Code": response[@"coupon_code"],
                               @"Last Login Address": currentAddressFinal
                               }];
        
        /*--------------------------------------------------------------------*/

        [self processAfterLogin];

        [[BentoShop sharedInstance] setSignInStatus:YES];
        
    } failure:^(MKNetworkOperation *errorOp, NSError *error) {
        [self.activityIndicator stopAnimating];
        
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"apiName"];
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"loginRequest"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
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
    if ([isThereConnection isEqualToString:@"NO"])
    {
        [self showNetworkErrorScreen];
    }
    else 
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
}

- (void)process
{
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    // first time launching, reset default distinctID to custom one using newly generated UUID, then save it to persistent storage
    if ([userDefaults objectForKey:@"Launched Once"] == nil) {
        
        NSString *UUID = [[NSUUID UUID] UUIDString];
        [mixpanel identify:UUID];
        
        [userDefaults setObject:UUID forKey:@"UUID String"];
        [userDefaults setObject:@"YES" forKey:@"Launched Once"];
        [userDefaults synchronize];
        
        [self processAfterLogin];
    }
    // not first time launching, use UUID from persistent storage
    else {
        
        // no connection, show error screen
        if ([isThereConnection isEqualToString:@"NO"]) {
            [self showNetworkErrorScreen];
        }
        else {
            if ([[NSUserDefaults standardUserDefaults] objectForKey:@"apiName"] != nil
                && [[NSUserDefaults standardUserDefaults] objectForKey:@"loginRequest"] != nil) {
                
                // logged in, identify with alias
                [self processAutoLogin];
            }
            else {
                // logged out, identify with saved UUID
                NSString *UUID = [[NSUserDefaults standardUserDefaults] objectForKey:@"UUID String"];
                [mixpanel identify:UUID];
                
                [self processAfterLogin];
            }
        }
    }
}

- (void)gotoIntroScreen {
    CATransition *transition = [CATransition animation];
    
    transition.duration = 0.5;
    transition.type = kCATransitionFade;
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    IntroViewController *introVC = [storyboard instantiateViewControllerWithIdentifier:@"IntroViewController"];
    
    [[self navigationController].view.layer addAnimation:transition forKey:kCATransition];
    [[self navigationController] pushViewController:introVC animated:NO];
}

- (void)gotoClosedScreen {
    [self showSoldoutScreen:[NSNumber numberWithInt:0]];
}

- (void)gotoSoldOutScreen {
    [self showSoldoutScreen:[NSNumber numberWithInt:1]];
}

- (void)gotoMyBentoScreen {
    
    BOOL needsAnimation = YES;
    
    if (![[BentoShop sharedInstance] isInAnyZone] && [[DataManager shareDataManager] getUserInfo] == nil) {
        needsAnimation = NO;
    }
    
    NSDictionary *branchParams = [[BentoShop sharedInstance] getBranchParams];
    NSString *mainOrSide = branchParams[@"choose"];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    // prevent unbalanced call to vc error
//    double delayInSeconds = 0.1;
    double delayInSeconds = 0.3;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        
        FiveHomeViewController *fiveHomeVC = [[FiveHomeViewController alloc] init];
        
        // deep link to Choose Your Main Dish
        if ([mainOrSide isEqualToString:@"main"]) {
            ChooseMainDishViewController *chooseMainDishVC = [storyboard instantiateViewControllerWithIdentifier:@"ChooseMainDishViewController"];
            [self.navigationController pushViewController:fiveHomeVC animated:NO];
            [self.navigationController pushViewController:chooseMainDishVC animated:YES];
        }
        // deep link to Choose Your Side Dish
        else if ([mainOrSide isEqualToString:@"side"]) {
            ChooseSideDishViewController *chooseSideDishVC = [storyboard instantiateViewControllerWithIdentifier:@"ChooseSideDishViewController"];
            [self.navigationController pushViewController:fiveHomeVC animated:NO];
            [self.navigationController pushViewController:chooseSideDishVC animated:YES];
        }
        // regular opening flow of the app. changed for later use then stop
        else {
            [self.navigationController pushViewController:fiveHomeVC animated:needsAnimation];
        }
    });
}

- (void)showSoldoutScreen:(NSNumber *)identifier
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *nav = [storyboard instantiateViewControllerWithIdentifier:@"SoldOut"];
    SoldOutViewController *vcSoldOut = (SoldOutViewController *)nav.topViewController;
    vcSoldOut.type = [identifier integerValue];
    
    [self.navigationController presentViewController:nav animated:YES completion:nil];
}

- (void)noConnection
{
    isThereConnection = @"NO";
}

- (void)yesConnection
{
    isThereConnection = @"YES";
}

- (void)showNetworkErrorScreen
{
    NetworkErrorViewController *networkErrorViewController = [[NetworkErrorViewController alloc] init];
    [self.navigationController presentViewController:networkErrorViewController animated:YES completion:nil];
}

@end
