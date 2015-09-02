//
//  OrderConfirmViewController.m
//  Bento
//
//  Created by hanjinghe on 1/8/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

#import "OrderConfirmViewController.h"

#import "CustomBentoViewController.h"
#import "FixedBentoViewController.h"

#import "UIImageView+WebCache.h"

#import "AppStrings.h"
#import "BentoShop.h"
#import "Mixpanel.h"

#import "JGProgressHUD.h"

#import "MyAlertView.h"

@interface OrderConfirmViewController () <MyAlertViewDelegate>

@property (nonatomic, weak) IBOutlet UIImageView *ivTitle;

@property (weak, nonatomic) IBOutlet UIView *confirmationPlatform;

@property (nonatomic, weak) IBOutlet UIImageView *ivCompleted;

@property (nonatomic, weak) IBOutlet UILabel *lblCompletedTitle;

@property (nonatomic, weak) IBOutlet UILabel *lblCompletedText;

@property (nonatomic, weak) IBOutlet UIButton *btnQuestion;

@property (nonatomic, weak) IBOutlet UIButton *btnBuild;

@property (weak, nonatomic) IBOutlet UIView *pushPlatform;

- (IBAction)onHelp:(id)sender;

@end

@implementation OrderConfirmViewController
{
    JGProgressHUD *loadingHUD;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSURL *urlLogo = [[AppStrings sharedInstance] getURL:APP_LOGO];
    [self.ivTitle sd_setImageWithURL:urlLogo placeholderImage:[UIImage imageNamed:@"logo_title"]];
    
    NSURL *urlCompleted = [[AppStrings sharedInstance] getURL:COMPLETED_IMAGE_CAR];
    [self.ivCompleted sd_setImageWithURL:urlCompleted placeholderImage:[UIImage imageNamed:@"orderconfirm_image_car"]];
    
    self.lblCompletedTitle.text = [[AppStrings sharedInstance] getString:COMPLETED_TITLE];
    self.lblCompletedText.text = [[AppStrings sharedInstance] getString:COMPLETED_TEXT];
    [self.btnQuestion setTitle:[[AppStrings sharedInstance] getString:COMPLETED_LINK_QUESTION] forState:UIControlStateNormal];
    [self.btnBuild setTitle:[[AppStrings sharedInstance] getString:COMPLETED_BUTTON_COMPLETE] forState:UIControlStateNormal];
    
    if ([self isPushEnabled]) {
        self.confirmationPlatform.center = self.view.center;
        self.pushPlatform.hidden = YES;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Navigation


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noConnection) name:@"networkError" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yesConnection) name:@"networkConnected" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkCurrentMode) name:@"enteredForeground" object:nil];
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

- (void)checkCurrentMode
{
    if ([[BentoShop sharedInstance] didModeOrDateChange])
    {
        [(UINavigationController *)self.presentingViewController popToRootViewControllerAnimated:NO];
        [self dismissViewControllerAnimated:YES completion:nil];
        
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewWillDisappear:animated];
}

- (IBAction)onAnothorBento:(id)sender
{
    [self gotoAddAnotherBentoScreen];
}

- (void)gotoAddAnotherBentoScreen
{
    NSArray *viewControllers = self.navigationController.viewControllers;
    
    for (UIViewController *vc in viewControllers) {
        
        if ([vc isKindOfClass:[CustomBentoViewController class]] || [vc isKindOfClass:[FixedBentoViewController class]]) {

            [[BentoShop sharedInstance] addNewBento];
            [self.navigationController popToViewController:vc animated:YES];
            
            return;
        }
    }
}

- (IBAction)onHelp:(id)sender
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *destVC = [storyboard instantiateViewControllerWithIdentifier:@"FAQID"];
    [self.navigationController pushViewController:destVC animated:YES];
}

#pragma mark Push Notifications

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

- (IBAction)onTurnOnPush:(id)sender
{
    // push request not prompted before
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"Push Requested"] == nil) {
        
        [self requestPush];
    
        [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"Push Requested"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else {
        // go to Bento settings if ios 8+
        if ([[UIDevice currentDevice].systemVersion intValue] >= 8) {
            
            if ([self isPushEnabled] == NO) {
                MyAlertView *alertView1 = [[MyAlertView alloc] initWithTitle:@"" message:@"Turn on notifications by going into Settings, scrolling to Bento Now and choosing Allow Notifications." delegate:self cancelButtonTitle:@"OK" otherButtonTitle:@"Turn On"];
                alertView1.tag = 911;
                [alertView1 showInView:self.view];
            }
            else {
                // this case is for when they go outside of app to turn on then come back in
                MyAlertView *pushAlreadyAlertView = [[MyAlertView alloc] initWithTitle:@"" message:@"Notifications are already enabled." delegate:nil cancelButtonTitle:@"OK" otherButtonTitle:nil];
                [pushAlreadyAlertView showInView:self.view];
            }
        }
        // if ios 7, show alert
        else {
            MyAlertView *alertView2 = [[MyAlertView alloc] initWithTitle:@"" message:@"Turn on notifications by going into Settings, scrolling to Bento Now and choosing Allow Notifications." delegate:self cancelButtonTitle:@"OK" otherButtonTitle:nil];
            [alertView2 showInView:self.view];
        }
    }
}

#pragma mark MyAlertViewDelegate

- (void)alertView:(MyAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 911) {
        if (buttonIndex == 1) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        }
    }
}

@end
