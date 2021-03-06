//
//  AppDelegate.m
//  Bento
//
//  Created by hanjinghe on 1/6/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "AppDelegate.h"

#import "MyAlertView.h"
#import "JGProgressHUD.h"

#import "Stripe.h"
#import "BentoShop.h"
#import "AppStrings.h"
#import "DataManager.h"
#import "CountdownTimer.h"

#import "AddonList.h"

#import "Reachability.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import "AFNetworkReachabilityManager.h"

#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

#import <MoPub/MoPub.h>

// Mixpanel
#import "Mixpanel/MPTweakInline.h"
#import "Mixpanel.h"
#define MIXPANEL_TOKEN @"e0b4fc9fdf720bb40b6cbefddb9678f3"

#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

// Branch
#import "Branch.h"
#import "SignedInSettingsViewController.h"
#import "OrdersViewController.h"

// Facebook
#import <FBSDKCoreKit/FBSDKCoreKit.h>

// Force Update
#import "AppStrings.h"

// Adjust..attribution tracking
#define ADJUST_TOKEN @"ltd8yvnhnkrw"

#import "NSUserDefaults+RMSaveCustomObject.h"

// Stripe API Keys
NSString * const StripePublishableTestKey = @"pk_test_hFtlMiWcGFn9TvcyrLDI4Y6P";
NSString * const StripePublishableLiveKey = @"pk_live_UBeYAiCH0XezHA8r7Nmu9Jxz";

@interface AppDelegate () <CLLocationManagerDelegate>
{
    AppStrings *globalStrings;
    BentoShop *globalShop;

    CLLocationManager *locationManager;
    CLLocationCoordinate2D coordinate;
    
    UIAlertView *aV;
    
    Reachability *googleReach;
    
    BOOL ranFirstTime;
    NSTimer *connectionTimer;
}

@end

@implementation AppDelegate

// adjust callback, Organic? Facebook? Twitter?
- (void)adjustAttributionChanged:(ADJAttribution *)attribution
{
    if (attribution.network != nil) {
        
        [[NSUserDefaults standardUserDefaults] setObject:attribution.network forKey:@"SourceOfInstall"];
        [[NSUserDefaults standardUserDefaults] synchronize];

        NSLog(@"SourceOfInstall: %@", [[NSUserDefaults standardUserDefaults] objectForKey:@"SourceOfInstall"]);
    }
    
    NSLog(@"ATTRIBUTION: %@", attribution);
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"checkedForLocationOnLaunch"];
    
    /*------------------------------------REGISTER NOTIFICATIONS-------------------------------------*/
    
    if ([[BentoShop sharedInstance] isPushEnabled]) {
        if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
            UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeAlert
                                                                                                 | UIUserNotificationTypeBadge
                                                                                                 | UIUserNotificationTypeSound) categories:nil];
            [application registerUserNotificationSettings:settings];
        }
    }

    /*-----------------------------------------------------------------------------------------*/

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    googleReach = [Reachability reachabilityWithHostname:@"www.google.com"];
    
    googleReach.reachableBlock = ^(Reachability * reachability)
    {
        NSString * temp = [NSString stringWithFormat:@"GOOGLE Block Says Reachable(%@)", reachability.currentReachabilityString];
        NSLog(@"%@", temp);
        
        // to update UI components from a block callback
        // you need to dipatch this to the main thread
        // this uses NSOperationQueue mainQueue
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            
            NSLog(@"TRYING TO POST NETWORK CONNECTED");
            
            if (globalShop.iosCurrentVersion >= globalShop.iosMinVersion)
                connectionTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(yesConnection) userInfo:nil repeats:NO];
        }];
    };
    
    googleReach.unreachableBlock = ^(Reachability * reachability)
    {
        NSString * temp = [NSString stringWithFormat:@"GOOGLE Block Says Unreachable(%@)", reachability.currentReachabilityString];
        NSLog(@"%@", temp);
        
        // to update UI components from a block callback
        // you need to dipatch this to the main thread
        // this one uses dispatch_async they do the same thing (as above)
        dispatch_async(dispatch_get_main_queue(), ^{
            
        });
    };
    
    [googleReach startNotifier];
    
/*--------------------------------------BRANCH-----------------------------------------*/

    Branch *branch = [Branch getInstance];
    
    [branch initSessionWithLaunchOptions:launchOptions andRegisterDeepLinkHandler:^(NSDictionary *params, NSError *error)
    {
        // params are the deep linked params associated with the link that the user clicked before showing up.
        NSLog(@"deep link data: %@", [params description]);
        
        if ([params[@"$marketing_title"] isEqualToString:@"Deep Link to Orders Screen"]) {
            [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(didDeepLink) userInfo:nil repeats:NO];
        }
        
        [[BentoShop sharedInstance] setBranchParams:params];
    }];

/*---------------------------------CRASHLYTICS---------------------------------------*/
    
    [Fabric with:@[[MoPub class], [Crashlytics class], [STPAPIClient class]]];
    
/*--------------------------------------TWITTER-----------------------------------------*/
    
    // Twitter Conversion Tracking, MoPub
    [[MPAdConversionTracker sharedConversionTracker] reportApplicationOpenForApplicationID:@"963634117"];
    
/*---------------------------------------ADJUST-----------------------------------------*/
    
    // Adjust Tracking (so far, only tracking organic installs)
    NSString *yourAppToken = ADJUST_TOKEN;
    NSString *environment = ADJEnvironmentProduction; // or ADJEnvironmentSandbox, ADJEnvironmentProduction
    
    ADJConfig *adjustConfig = [ADJConfig configWithAppToken:yourAppToken environment:environment];
    [adjustConfig setLogLevel:ADJLogLevelVerbose]; // enable all logging
    [adjustConfig setDelegate:self];
    [Adjust appDidLaunch:adjustConfig];
    
/*--------------------------------------MIXPANEL-----------------------------------------*/
#ifndef DEV_MODE
    // set for prod build only, won't track dev
    [Mixpanel sharedInstanceWithToken:MIXPANEL_TOKEN];
#endif
    
//    if (MPTweakValue(@"Auto show add-ons once per order", NO)) {
//        // test, auto show add-ons
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"AutoShowAddons"];
//    }
//    else {
//        // original, don't auto show add-ons
//        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"AutoShowAddons"];
//    }
    
    NSLog(@"DISTINCT ID ON LAUNCH - %@", [[Mixpanel sharedInstance] distinctId]);
    
/*--------------------------------------STRIPE-----------------------------------------*/
#ifdef DEV_MODE
    [Stripe setDefaultPublishableKey:StripePublishableTestKey];
#else
    [Stripe setDefaultPublishableKey:StripePublishableLiveKey];
#endif
/*---------------------------------------------------------------------*/
    
    globalStrings = [AppStrings sharedInstance];
    globalShop = [BentoShop sharedInstance];
    [CountdownTimer sharedInstance];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"IntroProcessed"] isEqualToString:@"YES"] &&
            [[NSUserDefaults standardUserDefaults] rm_customObjectForKey:@"delivery_location"] != nil) {
            [[BentoShop sharedInstance] getInit2WithGateKeeper:^(BOOL succeeded, NSError *error) {
                
            }];
        }
        else {
            [[BentoShop sharedInstance] getInit2:^(BOOL succeeded, NSError *error) {
                
            }];
        }
        
        [globalShop getCurrentLunchDinnerBufferTimesInNumbersAndVersionNumbers];
    });
    
    return [[FBSDKApplicationDelegate sharedInstance] application:application didFinishLaunchingWithOptions:launchOptions];
}

- (void)didDeepLink {
    if ([[DataManager shareDataManager] getUserInfo] != nil) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"didPopBackFromViewAllOrdersButton" object:nil];
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    // Global Data Manager
    [globalShop refreshPause];
    [[CountdownTimer sharedInstance] refreshPause];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"enteringBackground" object:nil];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    // Global Data Manager
    [globalShop refreshPause];
    [[CountdownTimer sharedInstance] refreshPause];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    
    if ([self connected]) {
        if (globalShop.iosCurrentVersion >= globalShop.iosMinVersion) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    // If IntroVC has already been completely processed once, startUpdatingLocation
                    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"IntroProcessed"] isEqualToString:@"YES"]) {
                        
                        // Initialize location manager.
                        locationManager = [[CLLocationManager alloc] init];
                        locationManager.delegate = self;
                        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
                        locationManager.distanceFilter = 500;
                        
                        switch ([CLLocationManager authorizationStatus]) {
                                
                            // if they reset location and privacy settings
                            case kCLAuthorizationStatusNotDetermined:
                                [locationManager requestWhenInUseAuthorization];
                                break;
                                
                            case kCLAuthorizationStatusRestricted:
                                break;
                                
                            case kCLAuthorizationStatusDenied:
                                break;
                                
                            case kCLAuthorizationStatusAuthorizedAlways:
                                break;
                                
                            case kCLAuthorizationStatusAuthorizedWhenInUse:
                                break;
                                
                            default:
                                break;
                        }
                        
                        [locationManager startUpdatingLocation];
                    }
                });
            });

            [globalShop refreshResume];
            [[CountdownTimer sharedInstance] refreshResume];
        }
    }
  
    // FACEBOOK TRACK EVENT
#ifndef DEV_MODE
    static NSString *facebookKey = @"791688527544905"; // prod key
#else
    static NSString *facebookKey = @"823525551027869"; // dev key
#endif
    {
        [FBSDKSettings setAppID:facebookKey];
        [FBSDKAppEvents activateApp];
        
        NSLog(@"facebook key - %@", facebookKey);
    }
    
    // the following transferred from didenterforeground
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"IntroProcessed"] isEqualToString:@"YES"] &&
            [[NSUserDefaults standardUserDefaults] rm_customObjectForKey:@"delivery_location"] != nil) {
            [[BentoShop sharedInstance] getInit2WithGateKeeper:^(BOOL succeeded, NSError *error) {
                
            }];
        }
        else {
            [[BentoShop sharedInstance] getInit2:^(BOOL succeeded, NSError *error) {
                
            }];
        }
        
        [globalShop getCurrentLunchDinnerBufferTimesInNumbersAndVersionNumbers];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            /*--------------------*/
            
            // lunch/dinner times changed, reset
            // set currentMode
            float currentTime = [[[BentoShop sharedInstance] getCurrentTime] floatValue];
            float dinnerTime = [[[BentoShop sharedInstance] getDinnerTime] floatValue];;
            
            // 12:00am - dinner opening (ie. 16.5)
            if (currentTime >= 0 && currentTime < dinnerTime) {
                [[NSUserDefaults standardUserDefaults] setObject:@"LunchMode" forKey:@"NewLunchOrDinnerMode"];
            }
            // dinner opening - 11:59pm
            else if (currentTime >= dinnerTime && currentTime < 24) {
                [[NSUserDefaults standardUserDefaults] setObject:@"DinnerMode" forKey:@"NewLunchOrDinnerMode"];
            }
            
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            NSLog(@"NEW LUNCH OR DINNER MODE: %@", [[NSUserDefaults standardUserDefaults] objectForKey:@"NewLunchOrDinnerMode"]);
            
            /*--------------------*/
            
            // Notifications
            [[NSNotificationCenter defaultCenter] postNotificationName:@"enteredForeground" object:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:USER_NOTIFICATION_UPDATED_STATUS object:nil];
            
            // Global Data Manager
            [globalShop refreshPause];
            [[CountdownTimer sharedInstance] refreshPause];
            
            // Perform check for new version of your app
            if (globalShop.iosCurrentVersion < globalShop.iosMinVersion) {
                [aV show];
            }
        });
    });
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    [googleReach stopNotifier];
    
    [globalShop refreshStop];
    [[CountdownTimer sharedInstance] refreshStop];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    // Note this handler block should be the exact same as the handler passed to any open calls.
    
    // Branch (make sure this is called first before any other SDK's)
    [[Branch getInstance] handleDeepLink:url];
    
    // Facebook
#ifndef DEV_MODE
    if ([[url scheme] isEqualToString:@"fb791688527544905"]) // prod
#else
    if ([[url scheme] isEqualToString:@"fb823525551027869"]) // dev
#endif
    {
        return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                              openURL:url
                                                    sourceApplication:sourceApplication
                                                           annotation:annotation];
    }
    return YES;
}

//#pragma mark MyAlertViewDelegate
//- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
//{
//    if (alertView.tag == 007) {
//        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/bento-asian-food-delivered/id963634117?mt=8"]];
//    }
//}


#pragma mark Remote Notifications
#ifdef __IPHONE_8_0
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    // register to receive notifications
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void(^)())completionHandler
{
    // handle the actions
    if ([identifier isEqualToString:@"declineAction"]) {
        
    }
    else if ([identifier isEqualToString:@"answerAction"]) {
        
    }
}
#endif

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:@"deviceToken"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSLog(@"Device Token - %@", deviceToken);
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    NSLog(@"Failed to get token, error: %@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    NSLog(@"Received remote notification");
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *))restorationHandler
{
    [[Branch getInstance] continueUserActivity:userActivity];
    
    return YES;
}

#pragma mark TMReachability Notification Method
-(void)reachabilityChanged:(NSNotification*)note
{
    Reachability * reach = [note object];
    
    if(reach == googleReach) {
        
        NSLog(@"REACHABLE");
        
        if([reach isReachable]) {
            if (ranFirstTime == NO) {
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"networkConnected" object:nil];
                
                ranFirstTime = YES;
            }
        }
        else {
            NSLog(@"UNREACHABLE");
            
            NSLog(@"PREVENT POST NETWORK CONNECTED");
            
            [connectionTimer invalidate]; // prevent posting "networkConnected"
            
            [globalShop refreshPause];
            [[CountdownTimer sharedInstance] refreshPause];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"networkError" object:nil];
        }
    }
}

- (void)yesConnection
{
    NSLog(@"POST NETWORK CONNECTED");
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"IntroProcessed"] isEqualToString:@"YES"] &&
            [[NSUserDefaults standardUserDefaults] rm_customObjectForKey:@"delivery_location"] != nil) {
            [[BentoShop sharedInstance] getInit2WithGateKeeper:^(BOOL succeeded, NSError *error) {
                
            }];
        }
        else {
            [[BentoShop sharedInstance] getInit2:^(BOOL succeeded, NSError *error) {
                
            }];
        }
        
        [globalShop getCurrentLunchDinnerBufferTimesInNumbersAndVersionNumbers];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [globalShop refreshResume];
            [[CountdownTimer sharedInstance] refreshResume];
            
            if ([self connected]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"networkConnected" object:nil];
            }
        });
    });
}

- (BOOL)connected
{
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [reachability currentReachabilityStatus];
    return networkStatus != NotReachable;
}

#pragma mark Current Location

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *location = locations[0];
    coordinate = location.coordinate;
    
    [manager stopUpdatingLocation];
    
//    [[BentoShop sharedInstance] checkIfSelectedLocationIsInAnyZone:coordinate completion:^(BOOL isSelectedLocationInZone, NSString *appState) {
//        if (isSelectedLocationInZone == NO) {
//            [[Mixpanel sharedInstance] track:@"Opened App Outside of Service Area"];
//        }
//        
//        
//    }];
    
    [self trackAppLaunch: YES];
}

- (CLLocationCoordinate2D)getGPSLocation {
    return coordinate;
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [self trackAppLaunch: NO];
}

- (void)trackAppLaunch:(BOOL)locationEnabled {
    if (locationEnabled == YES) {
        [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(trackAppLaunchWithCoordinate) userInfo:nil repeats:NO];
    }
    else {
        [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(trackAppLaunchWithoutCoordinate) userInfo:nil repeats:NO];
    }
}

- (void)trackAppLaunchWithCoordinate {
    [[Mixpanel sharedInstance] track:@"App Launched With Coordinate" properties:@{@"lat": [NSString stringWithFormat:@"%f", coordinate.latitude],
                                                                                  @"lng": [NSString stringWithFormat:@"%f", coordinate.longitude]
                                                                                  }];
}

- (void)trackAppLaunchWithoutCoordinate {
    [[Mixpanel sharedInstance] track:@"App Launched Without Coordinate"];
}

@end
