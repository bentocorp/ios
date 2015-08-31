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

#import "Reachability.h"
#import <SystemConfiguration/SystemConfiguration.h>

// Crashlytics, and Twitter conversion tracking
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

#import "MoPub.h"

// Mixpanel
#import "Mixpanel.h"
#define MIXPANEL_TOKEN @"e0b4fc9fdf720bb40b6cbefddb9678f3"

#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

// Branch
#import "Branch.h"
#import "ChooseMainDishViewController.h"

// Facebook
#import "FacebookManager.h"
#import <FacebookSDK/FacebookSDK.h>

// Force Update
#import "AppStrings.h"

// Adjust..attribution tracking
#define ADJUST_TOKEN @"ltd8yvnhnkrw"


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
    NSLog(@"ATTRIBUTION: %@", attribution);
    
    if (attribution.trackerName != nil)
    {
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"App Installed" properties:@{@"Source": attribution.trackerName}];
        
        [[NSUserDefaults standardUserDefaults] setObject:attribution.trackerName forKey:@"SourceOfInstall"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        NSLog(@"SourceOfInstall: %@", [[NSUserDefaults standardUserDefaults] objectForKey:@"SourceOfInstall"]);
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
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
        NSLog(@"CHOOSE: %@", params[@"choose"]);
        
        if (params[@"choose"] != nil)
        {
            // if the app is already open in the background
            UINavigationController *myNavCon = (UINavigationController*)self.window.rootViewController;
            [(UINavigationController *)myNavCon.presentingViewController popToRootViewControllerAnimated:NO];
            [myNavCon dismissViewControllerAnimated:NO completion:nil];
            [myNavCon popToRootViewControllerAnimated:NO];
        }
            
        [[BentoShop sharedInstance] setBranchParams:params];
        
        NSLog(@"deep link data: %@", [params description]);
    }];

/*--------------------------------------FACEBOOK-----------------------------------------*/
    
    // Crashlytics
    [Fabric with:@[CrashlyticsKit]];
    
    NSLog( @"### running FB sdk version: %@", [FBSettings sdkVersion]);
    
/*--------------------------------------TWITTER-----------------------------------------*/
    
    // Twitter Conversion Tracking, MoPub
    [[MPAdConversionTracker sharedConversionTracker] reportApplicationOpenForApplicationID:@"963634117"];
    
/*---------------------------------------ADJUST-----------------------------------------*/
    
    // Adjust Tracking (so far, onyl tracking organic installs)
    NSString *yourAppToken = ADJUST_TOKEN;
    NSString *environment = ADJEnvironmentProduction; // or ADJEnvironmentSandbox, ADJEnvironmentProduction
    
    ADJConfig *adjustConfig = [ADJConfig configWithAppToken:yourAppToken environment:environment];
    [adjustConfig setLogLevel:ADJLogLevelVerbose]; // enable all logging
    [adjustConfig setDelegate:self];
    [Adjust appDidLaunch:adjustConfig];
    
/*--------------------------------------MIXPANEL-----------------------------------------*/
#ifndef DEV_MODE
    {
        [Mixpanel sharedInstanceWithToken:MIXPANEL_TOKEN];  // Use MixPanel for production build only
    }
#endif
    {}
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
//    NSString *UUID = [[NSUUID UUID] UUIDString];
//    [mixpanel identify:UUID];
    
//    NSLog(@"UUID - %@, Distinct ID - %@", UUID, mixpanel.distinctId);
    
    // TRACK: "App Launched"
    [mixpanel track:@"App Launched"];
    
    // Mixpanel tracking Opened App Outside of Service Area
    if (![[BentoShop sharedInstance] checkLocation:[self getCurrentLocation]]) {
        [mixpanel track:@"Opened App Outside of Service Area"];
        NSLog(@"OUT OF SERVICE AREA");
    }

/*--------------------------------------STRIPE-----------------------------------------*/
#ifdef DEV_MODE
    [Stripe setDefaultPublishableKey:StripePublishableTestKey];
#else
    [Stripe setDefaultPublishableKey:StripePublishableLiveKey];
#endif
    
    // App Strings
    globalStrings = [AppStrings sharedInstance];
    
    // Bento Shop
    globalShop = [BentoShop sharedInstance];
    
    
/*---------------------------LOCATION MANAGER--------------------------*/
    
    // If IntroVC has already been completely processed once, startUpdatingLocation
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"IntroProcessed"] isEqualToString:@"YES"])
    {
        // Initialize location manager.
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        locationManager.distanceFilter = kCLDistanceFilterNone;
        
        [locationManager startUpdatingLocation];
    }
    
/*---------------------------------------------------------------------*/
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [globalShop getCurrentLunchDinnerBufferTimesInNumbersAndVersionNumbers];
        [globalShop getMenus];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            
/*---------------------------FORCED UPDATE----------------------------*/
#ifdef DEV_MODE
            {
                aV = [[UIAlertView alloc] initWithTitle:@"Dev Build" message:[NSString stringWithFormat:@"Current_Version: %f\niOS_Min_Verson: %f", globalShop.iosCurrentVersion, globalShop.iosMinVersion] delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
                
                NSLog(@"This is dev version...run update check anyway!");
            }
#else
            {
                aV = [[UIAlertView alloc] initWithTitle:@"Update Available" message:@"Please update to the new version now." delegate:self cancelButtonTitle:nil otherButtonTitles:@"Update", nil];
                aV.tag = 007;
                NSLog(@"This is production version...run update check!");
            }
#endif
            {
                NSLog(@"ios minimum version - %f", globalShop.iosMinVersion);
                NSLog(@"current ios version - %f", globalShop.iosCurrentVersion);
                
                // Perform check for new version of your app
                if (globalShop.iosCurrentVersion < globalShop.iosMinVersion)
                    [aV show];
            }
            
/*--------------------------------------------------------------------*/
            
            // Date Change, reset
            NSLog(@"ORIGINAL DATE STRING ON LAUNCH: %@", [[BentoShop sharedInstance] getMenuDateString]);
            [[NSUserDefaults standardUserDefaults] setObject:[[BentoShop sharedInstance] getMenuDateString] forKey:@"OriginalDateString"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            /*-------*/
            
            // Lunch/Dinner Times Changed, reset
            float currentTime = [[[BentoShop sharedInstance] getCurrentTime] floatValue];
            float dinnerTime = [[[BentoShop sharedInstance] getDinnerTime] floatValue];;

            // 12:00am - dinner opening
            if (currentTime >= 0 && currentTime < dinnerTime)
            {
                // this is only set once in the lifetime of the app because subsequent changes to original will be made in didModeOrDateChange
                if (![[NSUserDefaults standardUserDefaults] objectForKey:@"OriginalLunchOrDinnerMode"])
                    [[NSUserDefaults standardUserDefaults] setObject:@"LunchMode" forKey:@"OriginalLunchOrDinnerMode"];
                
                [[NSUserDefaults standardUserDefaults] setObject:@"LunchMode" forKey:@"NewLunchOrDinnerMode"];
            }
            // dinner opening - 11:59pm
            else if (currentTime >= dinnerTime && currentTime < 24)
            {
                // this is only set once in the lifetime of the app because subsequent changes to original will be made in didModeOrDateChange
                if (![[NSUserDefaults standardUserDefaults] objectForKey:@"OriginalLunchOrDinnerMode"])
                    [[NSUserDefaults standardUserDefaults] setObject:@"DinnerMode" forKey:@"OriginalLunchOrDinnerMode"];
                
                [[NSUserDefaults standardUserDefaults] setObject:@"DinnerMode" forKey:@"NewLunchOrDinnerMode"];
            }
            
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            NSLog(@"ORIGNAL LUNCH OR DINNER MODE: %@", [[NSUserDefaults standardUserDefaults] objectForKey:@"OriginalLunchOrDinnerMode"]);
            NSLog(@"NEW LUNCH OR DINNER MODE: %@", [[NSUserDefaults standardUserDefaults] objectForKey:@"NewLunchOrDinnerMode"]);
            
            /*-------*/
            
            [globalShop didModeOrDateChange];
            
            /*-----------------------*/
            
            [[BentoShop sharedInstance] setLunchOrDinnerModeByTimes];
        });
    });
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    // Global Data Manager
    [globalShop refreshPause];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    // Global Data Manager
    [globalShop refreshPause];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    
        [globalShop getCurrentLunchDinnerBufferTimesInNumbersAndVersionNumbers];
        [globalShop getStatus];
        [globalShop setLunchOrDinnerModeByTimes];
        [globalShop getMenus];
        [[AppStrings sharedInstance] getAppStrings];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
    
            /*--------------------*/
    
            // lunch/dinner times changed, reset
            // set currentMode
            float currentTime = [[[BentoShop sharedInstance] getCurrentTime] floatValue];
            float dinnerTime = [[[BentoShop sharedInstance] getDinnerTime] floatValue];;
            
            // 12:00am - dinner opening (ie. 16.5)
            if (currentTime >= 0 && currentTime < dinnerTime)
                [[NSUserDefaults standardUserDefaults] setObject:@"LunchMode" forKey:@"NewLunchOrDinnerMode"];
            // dinner opening - 11:59pm
            else if (currentTime >= dinnerTime && currentTime < 24)
                [[NSUserDefaults standardUserDefaults] setObject:@"DinnerMode" forKey:@"NewLunchOrDinnerMode"];
            
            [[NSUserDefaults standardUserDefaults] synchronize];
    
            NSLog(@"NEW LUNCH OR DINNER MODE: %@", [[NSUserDefaults standardUserDefaults] objectForKey:@"NewLunchOrDinnerMode"]);

            /*--------------------*/
    
            // Notifications
            [[NSNotificationCenter defaultCenter] postNotificationName:@"enteredForeground" object:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:USER_NOTIFICATION_UPDATED_STATUS object:nil];
            
            // Global Data Manager
            [globalShop refreshPause];
            
            // Perform check for new version of your app
            if (globalShop.iosCurrentVersion < globalShop.iosMinVersion)
                [aV show];
            
            /*---------*/
            
            if (![[BentoShop sharedInstance] checkLocation:[self getCurrentLocation]])
            {
                Mixpanel *mixpanel = [Mixpanel sharedInstance];
                [mixpanel track:@"Opened App Outside of Service Area" properties:nil];
                NSLog(@"OUT OF SERVICE AREA");
            }
            else
                NSLog(@"WITHIN SERVICE AREA");
        });
    });
}

- (void)showLocationAlert
{
    UINavigationController *vcNav = (UINavigationController *)self.window.rootViewController;
    UIViewController *vcCurrent = vcNav.visibleViewController;
    
    MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"Warning" message:@"You're out of delivery zone now." delegate:nil cancelButtonTitle:@"OK" otherButtonTitle:nil];
    [alertView showInView:vcCurrent.view];
    alertView = nil;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    if ([self connected])
    {
        if (globalShop.iosCurrentVersion >= globalShop.iosMinVersion)
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [globalShop setLunchOrDinnerModeByTimes];
                [globalShop getMenus];
                [globalShop getStatus];
                [globalShop getServiceArea];
            });
            
            [globalShop refreshResume];
        }
    }
    
/*
    // Check User Location and Confirm
    CLLocationCoordinate2D location = [self getCurrentLocation];
    if (![globalShop checkLocation:location])
        [self showLocationAlert];
*/
  
    // Facebook event tracking
#ifndef DEV_MODE
    static NSString *facebookKey = @"791688527544905"; // prod key
#else
    static NSString *facebookKey = @"823525551027869"; // dev key
#endif
    {
        [FBSettings setDefaultAppID: facebookKey];
        [FBAppEvents activateApp];
        
        NSLog(@"facebook key - %@", facebookKey);
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    [googleReach stopNotifier];
    
    [globalShop refreshStop];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    // Note this handler block should be the exact same as the handler passed to any open calls.
    
    // Branch (make sure this is called first before any other SDK's)
    [[Branch getInstance] handleDeepLink:url];
    
    // Facebook
#ifndef DEV_MODE
    if ([[url scheme] isEqualToString:@"fb791688527544905"])
#else
    if ([[url scheme] isEqualToString:@"fb823525551027869"])
#endif
    {
        BOOL handled = [[FacebookManager sharedInstance] handleOpenURL:url sourceApplication:sourceApplication];
        NSLog(@"<%@ (%p) %@ handled:%@>\r url: %@\r sourceApplication: %@", NSStringFromClass([self class]), self, NSStringFromSelector(_cmd), handled ? @"YES" : @"NO", url.absoluteString, sourceApplication);
        
        return handled;

    }
    return YES;
}

#pragma mark MyAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 007)
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/bento-asian-food-delivered/id963634117?mt=8"]];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    // Show alert for push notifications recevied while the app is running
    NSString *message = [[userInfo objectForKey:@"aps"] objectForKey:@"alert"];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    
    [alert show];
}

#pragma mark TMReachability Notification Method
-(void)reachabilityChanged:(NSNotification*)note
{
    Reachability * reach = [note object];
    
    if(reach == googleReach)
    {
        NSLog(@"REACHABLE");
        
        if([reach isReachable])
        {
            if (ranFirstTime == NO)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"networkConnected" object:nil];
                
                ranFirstTime = YES;
            }
        }
        else
        {
            NSLog(@"UNREACHABLE");
            
            NSLog(@"PREVENT POST NETWORK CONNECTED");
            [connectionTimer invalidate]; // prevent posting "networkConnected"
            
            [globalShop refreshPause]; // stop trying to call API
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"networkError" object:nil];
        }
    }
}

- (void)yesConnection
{
    NSLog(@"POST NETWORK CONNECTED");
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [globalShop getCurrentLunchDinnerBufferTimesInNumbersAndVersionNumbers];
        [globalShop getStatus];
        [globalShop getServiceArea];
        [globalShop getMenus];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [globalShop refreshResume];
            
            if ([self connected])
                [[NSNotificationCenter defaultCenter] postNotificationName:@"networkConnected" object:nil];
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

@end
