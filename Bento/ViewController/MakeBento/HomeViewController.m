//
//  HomeViewController.m
//  Bento
//
//  Created by Joseph Lau on 1/8/16.
//  Copyright © 2016 bentonow. All rights reserved.
//

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

#import "HomeViewController.h"
#import "CustomViewController.h"
#import "MenuPreviewViewController.h"
#import "SignedInSettingsViewController.h"
#import "SignedOutSettingsViewController.h"
#import "AddonsViewController.h"
#import "AddonList.h"
#import "MyAlertView.h"

#import "CompleteOrderViewController.h"
#import "DeliveryLocationViewController.h"

#import "AppDelegate.h"

#import "ChooseMainDishViewController.h"
#import "ChooseSideDishViewController.h"

#import "SVPlacemark.h"
#import "NSUserDefaults+RMSaveCustomObject.h"

#import <QuartzCore/QuartzCore.h>
#import "JGProgressHUD.h"

#import "Mixpanel/MPTweakInline.h"
#import "Mixpanel.h"

#import "BentoShop.h"
#import "DataManager.h"
#import "AppStrings.h"

@interface HomeViewController ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak, nonatomic) IBOutlet UILabel *startingPriceLabel;
@property (weak, nonatomic) IBOutlet UILabel *etaLabel;

@property (weak, nonatomic) IBOutlet UIButton *pickerButton;
@property (weak, nonatomic) IBOutlet UIButton *bottomButton;

@property (nonatomic) CustomViewController *customVC;
@property (nonatomic) MenuPreviewViewController *menuPreviewVC;

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Custom
    self.customVC = [[CustomViewController alloc] initWithNibName:@"CustomViewController" bundle:nil];
    [self addChildViewController:self.customVC];
    [self.scrollView addSubview:self.customVC.view];
    [self.customVC didMoveToParentViewController:self];
    
    // Menu Preview
    self.menuPreviewVC = [[MenuPreviewViewController alloc] init];
    CGRect frame = self.menuPreviewVC.view.frame;
    frame.origin.x = SCREEN_WIDTH;
    self.menuPreviewVC.view.frame = frame;
    
    [self addChildViewController:self.menuPreviewVC];
    [self.scrollView addSubview:self.menuPreviewVC.view];
    [self.menuPreviewVC didMoveToParentViewController:self];
    
    // Scroll View
    self.scrollView.contentSize = CGSizeMake(SCREEN_WIDTH * 2, SCREEN_HEIGHT - 20);
}

- (IBAction)settingsButtonPressed:(id)sender {
    NSDictionary *currentUserInfo = [[DataManager shareDataManager] getUserInfo];
    
    SignedInSettingsViewController *signedInSettingsViewController = [[SignedInSettingsViewController alloc] init];
    SignedOutSettingsViewController *signedOutSettingsViewController = [[SignedOutSettingsViewController alloc] init];
    
    UINavigationController *navC;
    
    // signed in or not?
    if (currentUserInfo == nil) {
        navC = [[UINavigationController alloc] initWithRootViewController:signedOutSettingsViewController];
        navC.navigationBar.hidden = YES;
        [self.navigationController presentViewController:navC animated:YES completion:nil];
    }
    else {
        navC = [[UINavigationController alloc] initWithRootViewController:signedInSettingsViewController];
        navC.navigationBar.hidden = YES;
        [self.navigationController presentViewController:navC animated:YES completion:nil];
    }
}

- (IBAction)cartButtonPressed:(id)sender {
    Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];
    if (currentBento != nil && ![currentBento isEmpty] && ![currentBento isCompleted]) {
        [self showConfirmMsg];
    }
    else {
        [self gotoOrderScreen];
    }
}

- (IBAction)pickerButtonPressed:(id)sender {
    
}

- (IBAction)bottomButtonPressed:(id)sender {
    
}

- (void)showConfirmMsg {
    NSString *strText = [[AppStrings sharedInstance] getString:ALERT_BNF_TEXT];
    NSString *strCancel = [[AppStrings sharedInstance] getString:ALERT_BNF_BUTTON_CANCEL];
    NSString *strConfirm = [[AppStrings sharedInstance] getString:ALERT_BNF_BUTTON_CONFIRM];
    MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"" message:strText delegate:self cancelButtonTitle:strCancel otherButtonTitle:strConfirm];
    
    [alertView showInView:self.view];
    alertView = nil;
}

- (void)gotoOrderScreen {
    // instantiate view controllers
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    DeliveryLocationViewController *deliveryLocationViewController = [storyboard instantiateViewControllerWithIdentifier:@"DeliveryLocationViewController"];
    CompleteOrderViewController *completeOrderViewController = [storyboard instantiateViewControllerWithIdentifier:@"CompleteOrderViewController"];
    
    // user and place info
    NSDictionary *currentUserInfo = [[DataManager shareDataManager] getUserInfo];
    SVPlacemark *placeInfo = [[NSUserDefaults standardUserDefaults] rm_customObjectForKey:@"delivery_location"];
    
    // logged out
    if (currentUserInfo == nil) {
        // no saved address
        if (placeInfo == nil) {
            [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"isFromHomepage"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [self openAccountViewController:[DeliveryLocationViewController class]];
        }
        // has saved address
        else {
            // check if saved address is inside CURRENT service area
            CLLocationCoordinate2D location = placeInfo.location.coordinate;
            
            // outside service area
            if (![[BentoShop sharedInstance] checkLocation:location]) {
                [self openAccountViewController:[DeliveryLocationViewController class]];
            }
            // inside service area
            else {
                [self openAccountViewController:[CompleteOrderViewController class]];
            }
        }
    }
    // logged in
    else {
        // no saved address
        if (placeInfo == nil) {
            [self.navigationController pushViewController:deliveryLocationViewController animated:YES];
        }
        // has saved address
        else {
            // check if saved address is inside CURRENT service area
            CLLocationCoordinate2D location = placeInfo.location.coordinate;
            
            // outside service area
            if (![[BentoShop sharedInstance] checkLocation:location]) {
                [self.navigationController pushViewController:deliveryLocationViewController animated:YES];
            }
            // inisde service area
            else {
                [self.navigationController pushViewController:completeOrderViewController animated:YES];
            }
        }
    }
}

@end
