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

// Facebook
#import "FacebookManager.h"
#import <FacebookSDK/FacebookSDK.h>

// Force Update
#import "AppStrings.h"

NSString * const StripePublishableTestKey = @"pk_test_hFtlMiWcGFn9TvcyrLDI4Y6P";
NSString * const StripePublishableLiveKey = @"pk_live_UBeYAiCH0XezHA8r7Nmu9Jxz";

@interface AppDelegate () <MyCLControllerDelegate>
{
    AppStrings *globalStrings;
    BentoShop *globalShop;

    MyCLController *locationController;
    CLLocationCoordinate2D coordinate;
    
    UIAlertView *aV;
    
    Reachability *googleReach;
}

@end

@implementation AppDelegate

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

/////////////////////////////////////////////////////////////////////////////////////
    
    NSLog( @"### running FB sdk version: %@", [FBSettings sdkVersion] );
    
    // Crashlytics
    [Fabric with:@[CrashlyticsKit]];
    
    // Twitter Conversion Tracking, MoPub
    [[MPAdConversionTracker sharedConversionTracker] reportApplicationOpenForApplicationID:@"963634117"];
    
    
    // MixPanel, for production build only
#ifndef DEV_MODE
        [Mixpanel sharedInstanceWithToken:MIXPANEL_TOKEN];
#endif
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"App Launched" properties:nil];
    
    // Mixpanel tracking Opened App Outside of Service Area
    if (![[BentoShop sharedInstance] checkLocation:[self getCurrentLocation]])
    {
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Opened App Outside of Service Area" properties:nil];
        NSLog(@"OUT OF SERVICE AREA");
    }
    else
    {
        NSLog(@"WITHIN SERVICE AREA");
    }
    
    
    // App Strings
    globalStrings = [AppStrings sharedInstance];
    
    // Bento Shop
    globalShop = [BentoShop sharedInstance];
    
    // Stripe
#ifdef DEV_MODE
    [Stripe setDefaultPublishableKey:StripePublishableTestKey];
#else
    [Stripe setDefaultPublishableKey:StripePublishableLiveKey];
#endif

    // Initialize location manager.
    locationController = [[MyCLController alloc] init];
    locationController.delegate = self;
    locationController.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationController.locationManager.distanceFilter = kCLDistanceFilterNone;
    
#ifdef __IPHONE_8_0
    if (IS_OS_8_OR_LATER)
    {
        // Use one or the other, not both. Depending on what you put in info.plist
        [locationController.locationManager requestWhenInUseAuthorization];
    }
#endif
    
    [locationController.locationManager startUpdatingLocation];
    
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

/*---------------------------------------------------------------------*/
    
    // SET ORIGINAL MODE
    float currentTime = [[[BentoShop sharedInstance] getCurrentTime] floatValue];
    float dinnerTime = [[[BentoShop sharedInstance] getDinnerTime] floatValue];;
    
    // 12:00am - dinner opening (ie. 16.5)
    if (currentTime >= 0 && currentTime < dinnerTime)
    {
        [[NSUserDefaults standardUserDefaults] setObject:@"LunchMode" forKey:@"OriginalLunchOrDinnerMode"];
    }
    // dinner opening - 11:59pm
    else if (currentTime >= dinnerTime && currentTime < 24)
    {
        [[NSUserDefaults standardUserDefaults] setObject:@"DinnerMode" forKey:@"OriginalLunchOrDinnerMode"];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"ORIGNAL LUNCH OR DINNER MODE: %@", [[NSUserDefaults standardUserDefaults] objectForKey:@"OriginalLunchOrDinnerMode"]);
    
    
    //////
    
    [[BentoShop sharedInstance] setLunchOrDinnerMode];
    
    return YES;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 007)
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/bento-asian-food-delivered/id963634117?mt=8"]];
}

#pragma mark MyAlertViewDelegate

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
    
    [globalShop getStatus];
    [globalShop getCurrentLunchDinnerBufferTimesInNumbersAndVersionNumbers];
    [globalShop setLunchOrDinnerMode];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"enteredForeground" object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:USER_NOTIFICATION_UPDATED_STATUS object:nil];
    
    // Global Data Manager
    [globalShop refreshPause];
    
    // Perform check for new version of your app
    if (globalShop.iosCurrentVersion < globalShop.iosMinVersion)
        [aV show];
    
    // reload app strings
    [[AppStrings sharedInstance] getAppStrings];
    
/*---------*/
    
    // set currentMode
    float currentTime = [[[BentoShop sharedInstance] getCurrentTime] floatValue];
    float dinnerTime = [[[BentoShop sharedInstance] getDinnerTime] floatValue];;
    
    // 12:00am - dinner opening (ie. 16.5)
    if (currentTime >= 0 && currentTime < dinnerTime)
    {
        [[NSUserDefaults standardUserDefaults] setObject:@"LunchMode" forKey:@"NewLunchOrDinnerMode"];
    }
    // dinner opening - 11:59pm
    else if (currentTime >= dinnerTime && currentTime < 24)
    {
        [[NSUserDefaults standardUserDefaults] setObject:@"DinnerMode" forKey:@"NewLunchOrDinnerMode"];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"NEW LUNCH OR DINNER MODE: %@", [[NSUserDefaults standardUserDefaults] objectForKey:@"NewLunchOrDinnerMode"]);
    
/*---------*/
    
    if (![[BentoShop sharedInstance] checkLocation:[self getCurrentLocation]])
    {
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Opened App Outside of Service Area" properties:nil];
        NSLog(@"OUT OF SERVICE AREA");
    }
    else
    {
        NSLog(@"WITHIN SERVICE AREA");
    }
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
    
    // if version is current/greater than ios min
    if (globalShop.iosCurrentVersion >= globalShop.iosMinVersion)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [globalShop setLunchOrDinnerMode];
            [globalShop getMenus];
            [globalShop getStatus];
            [globalShop getServiceArea];
        });
    }
    
    // Global Data Manager
    [globalShop refreshResume];
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
    
    // Reachability.
    [googleReach stopNotifier];
    
    // Global Data Manager.
    [globalShop refreshStop];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    // Note this handler block should be the exact same as the handler passed to any open calls.
    
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

- (CLLocationCoordinate2D )getCurrentLocation
{
#if (TARGET_IPHONE_SIMULATOR)
    CLLocation *location = [[CLLocation alloc] initWithLatitude:33.571895f longitude:-117.7379837036132f];
    return location.coordinate;
#endif
    
    return coordinate;
}

- (void) updateLocationManagerTimer
{
    
}

#pragma mark get current location
- (void)locationUpdate:(CLLocation *)location
{
    coordinate = [location coordinate];
}

- (void)locationError:(NSError *)error
{
    if (error.code == kCLErrorDenied)
    {
        
    }
}


#pragma mark TMReachability Notification Method
-(void)reachabilityChanged:(NSNotification*)note
{
    Reachability * reach = [note object];
    
    if(reach == googleReach)
    {
        if([reach isReachable])
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"networkConnected" object:nil];
            
            if (globalShop.iosCurrentVersion >= globalShop.iosMinVersion)
            {
                [globalShop getStatus];
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [globalShop getCurrentLunchDinnerBufferTimesInNumbersAndVersionNumbers];
                    [globalShop getMenus];
                    [globalShop getServiceArea];
                });
            }
        }
        else
        {
            [globalShop refreshStop]; // stop trying to call API
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"networkError" object:nil];
        }
    }
}



@end
