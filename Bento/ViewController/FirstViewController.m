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

#import "CustomBentoViewController.h"
#import "FixedBentoViewController.h"
#import "ChooseMainDishViewController.h"
#import "ChooseSideDishViewController.h"

#import "Mixpanel.h"
#import "SVGeocoder.h"

#import "IntroViewController.h"

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
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _hasInit = NO;
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.ivBackground.bounds;

    UIColor *color1 = [DataManager getGradientColor1];
    UIColor *color2 = [DataManager getGradientColor2];
    gradient.colors = [NSArray arrayWithObjects:(id)[color1 CGColor], (id)[color2 CGColor], nil];
    [self.ivBackground.layer insertSublayer:gradient atIndex:0];
    [self.ivLaunchLogo setImage:[UIImage imageNamed:@"logo"]];
    
    NSString *strSlogan = [[NSUserDefaults standardUserDefaults] objectForKey:@"Slogan"];
    if (strSlogan == nil || strSlogan.length > 0)
        strSlogan = @"Delicious Asian Food Delivered in Minutes.";
    self.lblLaunchSlogan.text = strSlogan;
    
    /*---------------------------LOCATION MANAGER--------------------------*/
    
    // Initialize location manager.
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    [locationManager startUpdatingLocation];
    
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
        if (error == nil && placemarks.count > 0)
        {
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
    
    [[AppStrings sharedInstance] getAppStrings];
    
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
    
    __block BentoShop *globalShop = [BentoShop sharedInstance];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    
        if (globalShop.iosCurrentVersion >= globalShop.iosMinVersion)
        {
            [[BentoShop sharedInstance] getCurrentLunchDinnerBufferTimesInNumbersAndVersionNumbers];
            [[AppStrings sharedInstance] getAppStrings];
            [[BentoShop sharedInstance] getMenus];
            [[BentoShop sharedInstance] getStatus];
            [[BentoShop sharedInstance] getServiceArea];
        }
    
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [[BentoShop sharedInstance] refreshStart];
            
            if (!_hasInit)
            {
                _hasInit = YES;
                [self performSelector:@selector(initProcedure) withObject:nil afterDelay:0.01f];
            }
            else
            {
                [self processAfterLogin];
            }
            
            // reset if closed
            if ([globalShop isClosed])
                [globalShop resetBentoArray];
            
            [self.activityIndicator stopAnimating];
        });
    });
}

- (void)processAutoLogin
{
    NSUserDefaults *pref = [NSUserDefaults standardUserDefaults];
    NSString *strAPIName = [pref objectForKey:@"apiName"];
    NSDictionary *dicRequest = [pref objectForKey:@"loginRequest"];
    
    NSLog(@"auto login dicRequest - %@", dicRequest);
    
    WebManager *webManager = [[WebManager alloc] init];
    
//    self.activityIndicator.hidden = NO;
//    [self.activityIndicator startAnimating];
    
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
        
        NSString *currentAddressFinal;
        if (currentAddress != nil)
            currentAddressFinal = currentAddress;
        else
            currentAddressFinal = @"N/A";
            
        // set properties
        [mixpanel.people set:@{
                               @"$name": [NSString stringWithFormat:@"%@ %@", response[@"firstname"], response[@"lastname"]],
                               @"$email": response[@"email"],
                               @"$phone": response[@"phone"],
                               @"Last Login Address": currentAddressFinal
                               }];
        
        /*--------------------------------------------------------------------*/

        [self processAfterLogin];

        [[BentoShop sharedInstance] setSignInStatus:YES];
        
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
    if ([isThereConnection isEqualToString:@"NO"])
    {
        [self showNetworkErrorScreen];
    }
    else
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
}

- (void)gotoIntroScreen
{
    CATransition *transition = [CATransition animation];
    
    transition.duration = 0.5;
    transition.type = kCATransitionFade;
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    IntroViewController *introVC = [storyboard instantiateViewControllerWithIdentifier:@"IntroViewController"];
    
    [[self navigationController].view.layer addAnimation:transition forKey:kCATransition];
    [[self navigationController] pushViewController:introVC animated:NO];
    
//    [self performSegueWithIdentifier:@"Intro" sender:nil];
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

- (void)gotoMyBentoScreen
{
    AppDelegate *delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    CLLocationCoordinate2D location = [delegate getCurrentLocation];
    BentoShop *globalShop = [BentoShop sharedInstance];
    
    BOOL needsAnimation = YES;
    if (![globalShop checkLocation:location] && [[DataManager shareDataManager] getUserInfo] == nil)
        needsAnimation = NO;
    
/*--------------Determine whether to show Fixed or Custom--------------*/
    
    [globalShop setLunchOrDinnerModeByTimes]; // putting this here for when entering app without network connection, otherwise it wont be up to date
    
    // this is dynamic to times of day
    NSString *menuType = [[BentoShop sharedInstance] getMenuType];
    
    NSDictionary *branchParams = [[BentoShop sharedInstance] getBranchParams];
    NSString *mainOrSide = branchParams[@"choose"];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    // prevent unbalanced call to vc error
    double delayInSeconds = 0.1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void)
    {
        if ([menuType isEqualToString:@"fixed"])
        {
            FixedBentoViewController *fixedBentoViewController = [[FixedBentoViewController alloc] init];
            [self.navigationController pushViewController:fixedBentoViewController animated:needsAnimation];
        }
        else if ([menuType isEqualToString:@"custom"])
        {
            CustomBentoViewController *customBentoViewController = [[CustomBentoViewController alloc] init];
            
            // deep link to Choose Your Main Dish
            if ([mainOrSide isEqualToString:@"main"])
            {
                ChooseMainDishViewController *chooseMainDishVC = [storyboard instantiateViewControllerWithIdentifier:@"ChooseMainDishViewController"];
                [self.navigationController pushViewController:customBentoViewController animated:NO];
                [self.navigationController pushViewController:chooseMainDishVC animated:YES];
            }
            
            // deep link to Choose Your Side Disg
            else if ([mainOrSide isEqualToString:@"side"])
            {
                ChooseSideDishViewController *chooseSideDishVC = [storyboard instantiateViewControllerWithIdentifier:@"ChooseSideDishViewController"];
                [self.navigationController pushViewController:customBentoViewController animated:NO];
                [self.navigationController pushViewController:chooseSideDishVC animated:YES];
            }
            
            // regular opening flow of the app. changed for later use then stop
            else
            {
                [self.navigationController pushViewController:customBentoViewController animated:needsAnimation];
            }
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
