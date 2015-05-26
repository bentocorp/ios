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

// Crashlytics
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

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
    Reachability *reachability;

    MyCLController *locationController;
    CLLocationCoordinate2D  coordinate;
    
    UIAlertView *aV;
}

@end

@implementation AppDelegate

- (void)networkChanged:(NSNotification *)notification
{
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    
    UINavigationController *vcNav = (UINavigationController *)self.window.rootViewController;
    UIViewController *vcCurrent = vcNav.visibleViewController;
    
    if (networkStatus == NotReachable)
    {
        MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"Error" message:@"There is no internet connection." delegate:nil cancelButtonTitle:@"OK" otherButtonTitle:nil];
        [alertView showInView:vcCurrent.view];
        alertView = nil;
        return;
    }
    
//    [[NSNotificationCenter defaultCenter] postNotificationName:kReachabilityChangedNotification object:networkReachability];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSLog( @"### running FB sdk version: %@", [FBSettings sdkVersion] );
    
    // Crashlytics
    [Fabric with:@[CrashlyticsKit]];
    
    // MixPanel
    [Mixpanel sharedInstanceWithToken:MIXPANEL_TOKEN];
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"App Launched" properties:nil];
    
    // Reachability
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkChanged:) name:kReachabilityChangedNotification object:nil];
    reachability = [Reachability reachabilityForInternetConnection];
    [reachability startNotifier];
    
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
    
/*---------------------------FORCE UPDATE----------------------------*/
    
    
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
    
    return YES;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 007)
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/bento-asian-food-delivered/id963634117?mt=8"]];
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
    
    // Global Data Manager
    [globalShop refreshPause];
    
    // Perform check for new version of your app
    if (globalShop.iosCurrentVersion < globalShop.iosMinVersion)
        [aV show];
    
    // reload app strings
    [[AppStrings sharedInstance] getAppStrings];
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
    [reachability stopNotifier];
    
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

@end
