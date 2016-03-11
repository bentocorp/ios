//
//  SettingsViewController.m
//  settings
//
//  Created by Joseph Lau on 4/22/15.
//  Copyright (c) 2015 Joseph Lau. All rights reserved.
//

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

#import "SignedInSettingsViewController.h"
#import "SettingsTableViewCell.h"
#import <MessageUI/MessageUI.h>
#import "CreditCardInfoViewController.h"

#import "OrdersViewController.h"

#import "MyAlertView.h"
#import "JGProgressHUD.h"
#import "WebManager.h"
#import "DataManager.h"
#import <Social/Social.h>
#import "AppStrings.h"

#import "BentoShop.h"

#import "Mixpanel.h"

#import "UIColor+CustomColors.h"

#import "EditPhoneNumberView.h"

#import "FiveHomeViewController.h"

#import "NotificationsCell.h"
#import "DailyNotificationsCell.h"

//#import "OrderStatusViewController.h"

//#import <FBSDKShareKit/FBSDKShareKit.h>

@interface SignedInSettingsViewController () <UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, EditPhoneNumberDelegate>

@end

@implementation SignedInSettingsViewController
{
    NSDictionary *currentUserInfo;
    UIScrollView *scrollView;
    NSString *sharePrecomposedMessageNew;
    JGProgressHUD *loadingHUD;
    
    NSString *couponCodeString;
    
    EditPhoneNumberView *editPhoneNumberView;
    
    UILabel *phoneNumberLabel;
    UIImageView *ivPencil;
    UIButton *btnPencil;
    
    UITableView *settingsTableView;
    UIView *longLineSepartor2;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // check if came from tapping view all orders in order confirmation
    if (self.didComeFromViewAllOrdersButton) {
        [self.navigationController pushViewController:[[OrdersViewController alloc] init] animated:NO];
    }
    
    // get current user info
    currentUserInfo = [[DataManager shareDataManager] getUserInfo];
    NSLog(@"current user info - %@", currentUserInfo);
    
    // Set promo code
    if (currentUserInfo[@"coupon_code"] != [NSNull null] || currentUserInfo[@"coupon_code"] != nil)
        couponCodeString = currentUserInfo[@"coupon_code"];
    else
        couponCodeString = @"--";
    
    
    self.view.backgroundColor = [UIColor bentoBackgroundGray];
    
    /*-----------------------------------------------------------*/
    
    // scroll view
    scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, -20, SCREEN_WIDTH, SCREEN_HEIGHT + 20)];
    
    int scrollViewContentSizeHeight;
    
    // check if iphone 4 screen height
    if (SCREEN_HEIGHT <= 480) {
        scrollViewContentSizeHeight = SCREEN_HEIGHT + 125;
    }
    else if (SCREEN_HEIGHT <= 568) {
        scrollViewContentSizeHeight = SCREEN_HEIGHT + 45;
    }
    else {
        scrollViewContentSizeHeight = SCREEN_HEIGHT;
    }
    
    scrollView.contentSize = CGSizeMake(SCREEN_WIDTH, scrollViewContentSizeHeight);
    [self.view addSubview:scrollView];
    
    /*-----------------------------------------------------------*/
    
    // navigation bar color
    UIView *navigationBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 65)];
    navigationBarView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:navigationBarView];
    
    // title label
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_WIDTH / 2 - 110, 20, 220, 45)];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:16.0f];
    titleLabel.textColor = [UIColor bentoTitleGray];
    titleLabel.text = @"Settings";
    [self.view addSubview:titleLabel];
    
    // back button
    UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 20, 50, 45)];
    [closeButton setImage:[UIImage imageNamed:@"nav_btn_close"] forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(onCloseButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeButton];
    
    // Tracking
//    UIButton *orderStatusButton = [[UIButton alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 45, 30, 30, 30)];
//    [orderStatusButton addTarget:self action:@selector(onOrderStatus) forControlEvents:UIControlEventTouchUpInside];
//    [orderStatusButton setImage:[UIImage imageNamed:@"in-transit-64"] forState:UIControlStateNormal];
//    [navigationBarView addSubview:orderStatusButton];
    
    // line separator under nav bar
    UIView *longLineSepartor1 = [[UIView alloc] initWithFrame:CGRectMake(0, 65, SCREEN_WIDTH, 1)];
    longLineSepartor1.backgroundColor = [UIColor colorWithRed:0.827f green:0.835f blue:0.835f alpha:1.0f];
    [self.view addSubview:longLineSepartor1];
    
    /*-----------------------------------------------------------*/
    
    // name label
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 80, SCREEN_WIDTH - 40, 24)];
    nameLabel.textColor = [UIColor colorWithRed:0.427f green:0.459f blue:0.514f alpha:1.0f];
    [nameLabel setFont:[UIFont fontWithName:@"OpenSans-Semibold" size:16]];
    nameLabel.text = [NSString stringWithFormat:@"%@ %@", currentUserInfo[@"firstname"], currentUserInfo[@"lastname"]];
    nameLabel.adjustsFontSizeToFitWidth = YES;
    [scrollView addSubview:nameLabel];
    
    // phone label
    phoneNumberLabel = [[UILabel alloc] init];
    phoneNumberLabel.textColor = [UIColor colorWithRed:0.427f green:0.459f blue:0.514f alpha:1.0f];
    phoneNumberLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    
    NSString *newPhoneNumber = [[NSUserDefaults standardUserDefaults] objectForKey:@"new_phone_number"];
    if (newPhoneNumber == nil) {
        phoneNumberLabel.text = currentUserInfo[@"phone"];
    }
    else {
        phoneNumberLabel.text = newPhoneNumber;
    }
    
    phoneNumberLabel.adjustsFontSizeToFitWidth = YES;
    
    if ([phoneNumberLabel.text rangeOfString:@"+1"].location == NSNotFound) {
        // doesn't contain +1, retract
        phoneNumberLabel.frame = CGRectMake(25, 105, 105, 24);
    }
    else {
        // contains +1, extend
        phoneNumberLabel.frame = CGRectMake(25, 105, 125, 24);
    }
    
    [scrollView addSubview:phoneNumberLabel];
    
    // email label
    UILabel *emailLabel = [[UILabel alloc] initWithFrame:CGRectMake(25, 130, 250, 24)];
    emailLabel.textColor = [UIColor colorWithRed:0.427f green:0.459f blue:0.514f alpha:1.0f];
    emailLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
    emailLabel.text = currentUserInfo[@"email"];
    emailLabel.adjustsFontSizeToFitWidth = YES;
    [scrollView addSubview:emailLabel];
    
    // edit phone number image
    ivPencil = [[UIImageView alloc] initWithFrame:CGRectMake(25 + phoneNumberLabel.frame.size.width + 5, 105, 15, 15)];
    ivPencil.image = [UIImage imageNamed:@"pencil-bento"];
    [scrollView addSubview:ivPencil];
    
    // edit phone number button
    btnPencil = [[UIButton alloc] initWithFrame:CGRectMake(25 + phoneNumberLabel.frame.size.width, 100, 25, 25)];
    [btnPencil addTarget:self action:@selector(onEditPhoneNumber) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:btnPencil];
    
    // logout button
    UIButton *logoutButton = [[UIButton alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 80, 127, 60, 30)];
    [logoutButton setTitleColor:[UIColor colorWithRed:0.459f green:0.639f blue:0.302f alpha:1.0f] forState:UIControlStateNormal];
    [logoutButton.titleLabel setFont:[UIFont fontWithName:@"OpenSans-Bold" size:14]];
    [logoutButton setTitle:@"Log out" forState:UIControlStateNormal];
    [logoutButton addTarget:self action:@selector(onLogout) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:logoutButton];
    
    /*-----------------------------------------------------------*/
    
    settingsTableView = [[UITableView alloc] init];
    longLineSepartor2 = [[UIView alloc] init];
    
    settingsTableView.alwaysBounceVertical = NO;
    [settingsTableView setSeparatorInset:UIEdgeInsetsMake(0, 60, 0, 0)];
    settingsTableView.delegate = self;
    settingsTableView.dataSource = self;
    [scrollView addSubview:settingsTableView];
    
    
    longLineSepartor2.backgroundColor = [UIColor colorWithRed:0.827f green:0.835f blue:0.835f alpha:1.0f];
    [scrollView addSubview:longLineSepartor2];
    
    /*-----------------------------------------------------------*/
    
    // promo gray background view
    UIView *promoGrayBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, scrollView.contentSize.height - 180, SCREEN_WIDTH, 80)];
    promoGrayBackgroundView.backgroundColor = [UIColor colorWithRed:0.271f green:0.302f blue:0.365f alpha:1.0f];
    [scrollView addSubview:promoGrayBackgroundView];
    
    // promo message label
    UILabel *promoMessageLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, SCREEN_WIDTH - 20, 42)];
    promoMessageLabel.textColor = [UIColor whiteColor];
    promoMessageLabel.font = [UIFont fontWithName:@"OpenSans" size:12];
    promoMessageLabel.textAlignment = NSTextAlignmentCenter;
    promoMessageLabel.text = [[AppStrings sharedInstance] getString:SHARE_PROMO_MESSAGE];
    promoMessageLabel.numberOfLines = 0;
    [promoGrayBackgroundView addSubview:promoMessageLabel];
    
    // promo code button
    UIButton *promoCodeButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 47, SCREEN_WIDTH - 20, 21)];
    [promoCodeButton setTitleColor:[UIColor bentoBrandGreen] forState:UIControlStateNormal];
    [promoCodeButton.titleLabel setFont:[UIFont fontWithName:@"OpenSans-Bold" size:17]];
    
    [promoCodeButton setTitle:couponCodeString forState:UIControlStateNormal];
    [promoCodeButton addTarget:self action:@selector(copyCode) forControlEvents:UIControlEventTouchUpInside];
    [promoGrayBackgroundView addSubview:promoCodeButton];
    
    /*-----------------------------------------------------------*/
    
    // promo white background view
    UIView *promoWhiteBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, scrollView.contentSize.height - 100, SCREEN_WIDTH, 100)];
    promoWhiteBackgroundView.backgroundColor = [UIColor whiteColor];
    [scrollView addSubview:promoWhiteBackgroundView];
    
    // social sharing
    for (int i = 0; i < 4; i++)
    {
        // create social icon buttons
        UIButton *socialIconButton = [[UIButton alloc] initWithFrame:CGRectMake(((SCREEN_WIDTH - (SCREEN_WIDTH - (SCREEN_WIDTH / 4 - 10))) / 2) + (SCREEN_WIDTH / 4 - 10) * i, 20, 40, 40)];
        
        // create social labels
        UILabel *socialLabel = [[UILabel alloc] initWithFrame:CGRectMake(((SCREEN_WIDTH - (SCREEN_WIDTH - (SCREEN_WIDTH / 4 - 20))) / 2) + (SCREEN_WIDTH / 4 - 10) * i, 65, 50, 21)];
        socialLabel.textColor = [UIColor bentoTitleGray];
        socialLabel.textAlignment = NSTextAlignmentCenter;
        socialLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:14];
        
        // set button images, events and labels
        switch (i) {
            case 0:
                [socialIconButton setImage:[UIImage imageNamed:@"icon-circle-facebook"] forState:UIControlStateNormal];
                [socialIconButton addTarget:self action:@selector(postToFacebook) forControlEvents:UIControlEventTouchUpInside];
                
                socialLabel.text = @"SHARE";
                break;
            case 1:
                [socialIconButton setImage:[UIImage imageNamed:@"icon-circle-twitter"] forState:UIControlStateNormal];
                [socialIconButton addTarget:self action:@selector(postToTwitter) forControlEvents:UIControlEventTouchUpInside];
                
                socialLabel.text = @"TWEET";
                break;
            case 2:
                [socialIconButton setImage:[UIImage imageNamed:@"icon-circle-messages"] forState:UIControlStateNormal];
                [socialIconButton addTarget:self action:@selector(showSMS) forControlEvents:UIControlEventTouchUpInside];
                
                socialLabel.text = @"TEXT";
                break;
            case 3:
                [socialIconButton setImage:[UIImage imageNamed:@"icon-circle-mail"] forState:UIControlStateNormal];
                [socialIconButton addTarget:self action:@selector(openEmailFromSharing) forControlEvents:UIControlEventTouchUpInside];
                
                socialLabel.text = @"EMAIL";
                break;
        }
        
        // add to view
        [promoWhiteBackgroundView addSubview:socialIconButton];
        [promoWhiteBackgroundView addSubview:socialLabel];
    }
    
    // edit phone number view
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"EditPhoneNumberView" owner:nil options:nil];
    editPhoneNumberView = [nib objectAtIndex:0];
    editPhoneNumberView.delegate = self;
    
    editPhoneNumberView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    editPhoneNumberView.alpha = 0.0f;
    
    [self.view addSubview:editPhoneNumberView];
    [self.view bringSubviewToFront:editPhoneNumberView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self setTableHeight];
    
    // Set promo code string
    if (currentUserInfo[@"coupon_code"] != [NSNull null] || currentUserInfo[@"coupon_code"] != nil) {
        couponCodeString = currentUserInfo[@"coupon_code"];
    }
    else {
        couponCodeString = @"--";
    }
    
    NSString *sharePrecomposedMessageOriginal;
    
    if ([[AppStrings sharedInstance] getString:SHARE_PRECOMPOSED_MESSAGE] != nil) {
        sharePrecomposedMessageOriginal = [[AppStrings sharedInstance] getString:SHARE_PRECOMPOSED_MESSAGE];
    }
    
    if (couponCodeString != nil) {
        sharePrecomposedMessageNew = [sharePrecomposedMessageOriginal stringByReplacingOccurrencesOfString:@"%@" withString:couponCodeString];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noConnection) name:@"networkError" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yesConnection) name:@"networkConnected" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetTableHeightWithAnimation) name:@"enteredForeground" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startTimerOnViewedScreen) name:@"enteredForeground" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endTimerOnViewedScreen) name:@"enteringBackground" object:nil];
    
    [self startTimerOnViewedScreen];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewWillDisappear:animated];
    
    [self endTimerOnViewedScreen];
}

- (void)setTableHeight {
    if ([self isPushEnabled]) {
        settingsTableView.frame = CGRectMake(0, 170, SCREEN_WIDTH, 180+45+45);
        longLineSepartor2.frame = CGRectMake(0, 304 + 45 + 45 + 45, SCREEN_WIDTH, 2);
    }
    else {
        settingsTableView.frame = CGRectMake(0, 170, SCREEN_WIDTH, 180+45);
        longLineSepartor2.frame = CGRectMake(0, 304 + 45 + 45, SCREEN_WIDTH, 2);
    }
    
    [settingsTableView reloadData];
}

- (void)resetTableHeightWithAnimation {
    if ([self isPushEnabled]) {
        [UIView animateWithDuration:0.5 animations:^{
            settingsTableView.frame = CGRectMake(0, 170, SCREEN_WIDTH, 180+45+45);
            longLineSepartor2.frame = CGRectMake(0, 304 + 45 + 45 + 45, SCREEN_WIDTH, 2);
        }];
    }
    else {
        [UIView animateWithDuration:0.5 animations:^{
            settingsTableView.frame = CGRectMake(0, 170, SCREEN_WIDTH, 180+45);
            longLineSepartor2.frame = CGRectMake(0, 304 + 45 + 45, SCREEN_WIDTH, 2);
        }];
    }
    
    [settingsTableView reloadData];
}

#pragma mark Duration on screen
- (void)startTimerOnViewedScreen
{
    [[Mixpanel sharedInstance] timeEvent:@"Viewed Signed In Settings Screen"];
}

- (void)endTimerOnViewedScreen
{
    [[Mixpanel sharedInstance] track:@"Viewed Signed In Settings Screen"];
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 45;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self isPushEnabled]) {
        return 6;
    }
    
    return 5;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SettingsTableViewCell *settingsTableViewCell = (SettingsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (settingsTableViewCell == nil) {
        settingsTableViewCell = [[SettingsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    
    NotificationsCell *notificationsCell = (NotificationsCell *)[tableView dequeueReusableCellWithIdentifier:@"NCell"];
    
    if (notificationsCell == nil) {
        notificationsCell = [[NotificationsCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NCell"];
    }
    
    DailyNotificationsCell *dailyNotifications = (DailyNotificationsCell *)[tableView dequeueReusableCellWithIdentifier:@"DCell"];
    
    if (dailyNotifications == nil) {
        dailyNotifications = [[DailyNotificationsCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DCell"];
    }
    
    switch (indexPath.row) {
        case 0:
            settingsTableViewCell.settingsLabel.text = [[AppStrings sharedInstance] getString:ORDER_HISTORY_TITLE];
            settingsTableViewCell.iconImageView.image = [UIImage imageNamed:@"icon-square-creditcard"];
            break;
        case 1:
            settingsTableViewCell.settingsLabel.text = @"FAQ";
            settingsTableViewCell.iconImageView.image = [UIImage imageNamed:@"icon-square-help"];
            break;
        case 2:
            settingsTableViewCell.settingsLabel.text = @"Email Support";
            settingsTableViewCell.iconImageView.image = [UIImage imageNamed:@"icon-square-email"];
            break;
        case 3:
            settingsTableViewCell.settingsLabel.text = @"Phone Support";
            settingsTableViewCell.iconImageView.image = [UIImage imageNamed:@"icon-square-phone"];
            break;
        case 4:
            notificationsCell.settingsLabel.text = @"Notifications";
            notificationsCell.iconImageView.image = [UIImage imageNamed:@"notifications-100"];
            notificationsCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            if ([self isPushEnabled]) {
                notificationsCell.onOrOffLabel.text = @"Enabled";
            }
            else {
                notificationsCell.onOrOffLabel.text = @"Disabled";
            }
            
            return notificationsCell;
        case 5:
            dailyNotifications.iconImageView.image = [UIImage imageNamed:@"daily-notifications-100"];
            [dailyNotifications.toggle addTarget:self action:@selector(changeSwitch:) forControlEvents:UIControlEventValueChanged];
            dailyNotifications.selectionStyle = UITableViewCellSelectionStyleNone; // disables user interaction, but allows toggle
            return dailyNotifications;
    }
    
    return settingsTableViewCell;
}



-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Remove table cell highlight
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    MyAlertView *callAlertView = [[MyAlertView alloc] initWithTitle:nil message:@"(415) 300-1332" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitle:@"Call"];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *destVC;
    
    OrdersViewController *ordersVC = [[OrdersViewController alloc] init];
    
    NSArray *toEmailRecipentsArray;
    MFMailComposeViewController *mailComposeViewController;
    
    MyAlertView *alertView1 = [[MyAlertView alloc] initWithTitle:@"" message:@"You will be directed to device Settings to view Notifications settings" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitle:@"OK"];
    alertView1.tag = 890;
    
    switch (indexPath.row) {
        case 0:
             // go to orders
            [self.navigationController pushViewController:ordersVC animated:YES];
            break;
        case 1:
        {
            // go to faq
            destVC = [storyboard instantiateViewControllerWithIdentifier:@"FAQID"];
            [self.navigationController pushViewController:destVC animated:YES];
            
            break;
        }
        case 2:
            // email
            if ([MFMailComposeViewController canSendMail]) {
                toEmailRecipentsArray = @[@"help@bentonow.com"];
                mailComposeViewController = [[MFMailComposeViewController alloc] init];
                mailComposeViewController.mailComposeDelegate = self;
                [mailComposeViewController setToRecipients:toEmailRecipentsArray];
                
                // Present mail view controller on screen
                [self presentViewController:mailComposeViewController animated:YES completion:NULL];
            }
            break;
            
        case 3:
            // show call alert
            callAlertView.tag = 2;
            [callAlertView showInView:self.view];
            callAlertView = nil;
            break;
        case 4 :
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"hasShownPushAlert"] == NO) {
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasShownPushAlert"];
                [self requestPush];
            }
            else {
                [alertView1 showInView:self.view];
            }
            break;
    }
}

- (void)onCloseButton
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

//- (void)onOrderStatus {
//    
//    // if more than one order, show orderlist
//    //    if () {
//    
//    //    }
//    // if only one order, just show order
//    //    else {
//    [self.navigationController pushViewController:[[OrderStatusViewController alloc] init] animated:YES];
//    //    }
//}

- (void)openEmailFromSharing
{
    NSArray *toEmailRecipentsArray = @[@""];
    MFMailComposeViewController *mailComposeViewController = [[MFMailComposeViewController alloc] init];
    
    if ([MFMailComposeViewController canSendMail]) {
        mailComposeViewController.mailComposeDelegate = self;
        //        [mailComposeViewController setSubject:@"Check out Bento"];
        [mailComposeViewController setToRecipients:toEmailRecipentsArray];
        [mailComposeViewController setMessageBody:sharePrecomposedMessageNew isHTML:NO];
        
        // Present mail view controller on screen
        [self presentViewController:mailComposeViewController animated:YES completion:NULL];
    }
}

// Email delegate method
- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail sent");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail sent failure: %@", [error localizedDescription]);
            break;
        default:
            break;
    }
    
    // Close the Mail Interface
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark MyAlertViewDelegate

- (void)onLogout
{
    MyAlertView *logoutAlertView = [[MyAlertView alloc] initWithTitle:@"Confirmation" message:@"Are you sure you want to log out?" delegate:self cancelButtonTitle:@"No" otherButtonTitle:@"Yes"];
    logoutAlertView.tag = 1;
    [logoutAlertView showInView:self.view];
    logoutAlertView = nil;
}

- (void)processLogout
{
    NSDictionary *curUserInfo = [[DataManager shareDataManager] getUserInfo];
    if (curUserInfo == nil)
        return;
    
    NSString *strAPIToken = [[DataManager shareDataManager] getAPIToken];
    if (strAPIToken == nil || strAPIToken.length == 0)
        return;
    
    WebManager *webManager = [[WebManager alloc] init];
    
    loadingHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
    loadingHUD.textLabel.text = @"Logging out...";
    [loadingHUD showInView:self.view];
    
    NSString *strRequest = [NSString stringWithFormat:@"%@/user/logout?api_token=%@", SERVER_URL, strAPIToken];
    [webManager AsyncProcess:strRequest method:GET parameters:nil success:^(MKNetworkOperation *networkOperation) {
        [loadingHUD dismiss];
        
        [[DataManager shareDataManager] setUserInfo:nil];
        [[DataManager shareDataManager] setCreditCard:nil];
        
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"apiName"];
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"loginRequest"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[BentoShop sharedInstance] setSignInStatus:NO];
        
        /*------CLEAR MIXPANEL ID AND PROPERTIES ON LOGOUT------*/
        
        NSString *UUID;
        
        // logged in by registering new account
        if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"registeredLogin"] isEqualToString:@"YES"]) {
            UUID = [[NSUUID UUID] UUIDString];
            
            [[NSUserDefaults standardUserDefaults] setObject:UUID forKey:@"UUID String"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        // looged in normally
        else {
            // reset distinctId with preexisting UUID, so mixpanel profile doesn't break
            UUID = [[NSUserDefaults standardUserDefaults] objectForKey:@"UUID String"];
        }
        
        [[Mixpanel sharedInstance] identify:UUID];
        
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"registeredLogin"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        /*------------------------------------------------------*/
        
        // dismiss view
        [self dismissViewControllerAnimated:YES completion:nil];
        
    } failure:^(MKNetworkOperation *errorOp, NSError *error) {
        [loadingHUD dismiss];
        
        NSString *strMessage = [[DataManager shareDataManager] getErrorMessage:errorOp.responseJSON];
        
        // unauthorized
        if (error.code == 401) {
            strMessage = [[AppStrings sharedInstance] getString:ERROR_LOGIN_AGAIN];
        }
        else if (strMessage == nil) {
            strMessage = error.localizedDescription;
        }
        
        MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"" message:strMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitle:nil];
        alertView.tag = 3;
        [alertView showInView:self.view];
        alertView = nil;
        
    } isJSON:NO];
}

- (void)alertView:(MyAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 1) {
        if (buttonIndex == 1) {
            [[Mixpanel sharedInstance] track:@"Logged Out"];
            
            [self processLogout];
        }
    }
    else if (alertView.tag == 2) {
        if (buttonIndex == 1) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"tel:1-415-300-1332"]];
        }
    }
    else if (alertView.tag == 3) {
        [self forceLogout];
    }
    else if (alertView.tag == 890) {
        if (buttonIndex == 1) {
            [self gotoDeviceSettings];
        }
    }
}

- (void)forceLogout {
    [[DataManager shareDataManager] setUserInfo:nil];
    [[DataManager shareDataManager] setCreditCard:nil];
    
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"apiName"];
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"loginRequest"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[BentoShop sharedInstance] setSignInStatus:NO];
    
    /*------CLEAR MIXPANEL ID AND PROPERTIES ON LOGOUT------*/
    
    NSString *UUID;
    
    // logged in by registering new account
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"registeredLogin"] isEqualToString:@"YES"]) {
        UUID = [[NSUUID UUID] UUIDString];
        
        [[NSUserDefaults standardUserDefaults] setObject:UUID forKey:@"UUID String"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    // looged in normally
    else {
        // reset distinctId with preexisting UUID, so mixpanel profile doesn't break
        UUID = [[NSUserDefaults standardUserDefaults] objectForKey:@"UUID String"];
    }
    
    [[Mixpanel sharedInstance] identify:UUID];
    
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"registeredLogin"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    /*------------------------------------------------------*/
    
    // dismiss view
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onEditPhoneNumber {
    [UIView animateWithDuration:0.3f animations:^{
        editPhoneNumberView.alpha = 1.0f;
    }];
}

- (void)postToTwitter {
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
        SLComposeViewController *tweetSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        
        [tweetSheet setInitialText:sharePrecomposedMessageNew];
        
        [self presentViewController:tweetSheet animated:YES completion:nil];
    } else { // not logged into twitter
        UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Not Logged In"
                                                               message:@"Please log into Twitter via the Twitter app or in your iPhone Settings and try again."
                                                              delegate:nil
                                                     cancelButtonTitle:@"OK"
                                                     otherButtonTitles:nil];
        [warningAlert show];
    }
}

- (void)postToFacebook
{
    if([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
        SLComposeViewController *faceSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        
        [self presentViewController:faceSheet animated:YES completion:Nil];
    } else {
        UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Not Logged In"
                                                               message:@"Please log into Facebook via the Facebook app or in your iPhone Settings and try again."
                                                              delegate:nil
                                                     cancelButtonTitle:@"OK"
                                                     otherButtonTitles:nil];
        [warningAlert show];
    }
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult) result {
    switch (result) {
        case MessageComposeResultCancelled:
            break;
        case MessageComposeResultFailed:
        {
            UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Failed to send SMS!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [warningAlert show];
            break;
        }
        case MessageComposeResultSent:
            break;
        default:
            break;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showSMS
{
    if(![MFMessageComposeViewController canSendText]) {
        
        UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                               message:@"Your device doesn't support SMS!"
                                                              delegate:nil
                                                     cancelButtonTitle:@"OK"
                                                     otherButtonTitles:nil];
        [warningAlert show];
        
        return;
    }
    
    MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
    messageController.messageComposeDelegate = self;
    
    [messageController setBody:sharePrecomposedMessageNew];
    
    // Present message view controller on screen
    [self presentViewController:messageController animated:YES completion:nil];
}

- (void)copyCode
{
    loadingHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
    loadingHUD.textLabel.text = @"Copying";
    [loadingHUD showInView:self.view];
    
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = couponCodeString;
    
    [loadingHUD dismiss];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)changePhoneNumber:(NSString *)newPhoneNumber
{
    [[NSUserDefaults standardUserDefaults] setObject:newPhoneNumber forKey:@"new_phone_number"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    phoneNumberLabel.text = newPhoneNumber;
    if ([phoneNumberLabel.text rangeOfString:@"+1"].location == NSNotFound) {
        // doesn't contain +1, retract
        phoneNumberLabel.frame = CGRectMake(25, 105, 105, 24);
    }
    else {
        // contains +1, extend
        phoneNumberLabel.frame = CGRectMake(25, 105, 125, 24);
    }
    
    ivPencil.frame = CGRectMake(25 + phoneNumberLabel.frame.size.width + 5, 105, 15, 15);
    
    btnPencil.frame = CGRectMake(25 + phoneNumberLabel.frame.size.width, 100, 25, 25);
}

#pragma Notifications

- (BOOL)isPushEnabled
{
    BOOL enabled;
    
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(currentUserNotificationSettings)]) {
        
        UIUserNotificationSettings *notificationSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
        
        if (!notificationSettings || (notificationSettings.types == UIUserNotificationTypeNone)) {
            enabled = NO;
        }
        else {
            enabled = YES;
        }
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
}

- (void)gotoDeviceSettings {
    if (UIApplicationOpenSettingsURLString != NULL) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
}

- (void)changeSwitch:(id)sender {
    if([sender isOn]) {
        NSLog(@"Switch is ON");
    }
    else {
        NSLog(@"Switch is OFF");
    }
}

@end
