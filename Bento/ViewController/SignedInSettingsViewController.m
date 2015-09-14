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

#import "MyAlertView.h"
#import "JGProgressHUD.h"
#import "WebManager.h"
#import "DataManager.h"
#import <Social/Social.h>
#import "AppStrings.h"

#import "BentoShop.h"

#import "Mixpanel.h"

#import "UIColor+CustomColors.h"

//#import <FBSDKShareKit/FBSDKShareKit.h>

@interface SignedInSettingsViewController () <UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate>

@end

@implementation SignedInSettingsViewController
{
    NSDictionary *currentUserInfo;
    UIScrollView *scrollView;
    NSString *sharePrecomposedMessageNew;
    JGProgressHUD *loadingHUD;
    
    NSString *couponCodeString;
}

- (void)viewDidLoad {
    [super viewDidLoad];

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
        scrollViewContentSizeHeight = SCREEN_HEIGHT + 41;
        NSLog(@"This is an iPhone 4.");
    } else {
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
    
    // line separator under nav bar
    UIView *longLineSepartor1 = [[UIView alloc] initWithFrame:CGRectMake(0, 65, SCREEN_WIDTH, 1)];
    longLineSepartor1.backgroundColor = [UIColor colorWithRed:0.827f green:0.835f blue:0.835f alpha:1.0f];
    [self.view addSubview:longLineSepartor1];
    
/*-----------------------------------------------------------*/
    
    // name label
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 80, 290, 24)];
    nameLabel.textColor = [UIColor colorWithRed:0.427f green:0.459f blue:0.514f alpha:1.0f];
    [nameLabel setFont:[UIFont fontWithName:@"OpenSans-Semibold" size:14]];
    nameLabel.text = [NSString stringWithFormat:@"%@ %@", currentUserInfo[@"firstname"], currentUserInfo[@"lastname"]];
    [scrollView addSubview:nameLabel];
    
    // phone label
    UILabel *phoneNumberLabel = [[UILabel alloc] initWithFrame:CGRectMake(25, 100, 250, 24)];
    phoneNumberLabel.textColor = [UIColor colorWithRed:0.427f green:0.459f blue:0.514f alpha:1.0f];
    phoneNumberLabel.font = [UIFont fontWithName:@"OpenSans" size:12];
    phoneNumberLabel.text = currentUserInfo[@"phone"];
    [scrollView addSubview:phoneNumberLabel];
    
    // email label
    UILabel *emailLabel = [[UILabel alloc] initWithFrame:CGRectMake(25, 120, 250, 24)];
    emailLabel.textColor = [UIColor colorWithRed:0.427f green:0.459f blue:0.514f alpha:1.0f];
    emailLabel.font = [UIFont fontWithName:@"OpenSans" size:12];
    emailLabel.text = currentUserInfo[@"email"];
    [scrollView addSubview:emailLabel];
    
    // logout button
    UIButton *logoutButton = [[UIButton alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 80, 117, 60, 30)];
    [logoutButton setTitleColor:[UIColor colorWithRed:0.459f green:0.639f blue:0.302f alpha:1.0f] forState:UIControlStateNormal];
    [logoutButton.titleLabel setFont:[UIFont fontWithName:@"OpenSans-Bold" size:14]];
    [logoutButton setTitle:@"Log out" forState:UIControlStateNormal];
    [logoutButton addTarget:self action:@selector(onLogout) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:logoutButton];

/*-----------------------------------------------------------*/
    
    // table view
//    UITableView *settingsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 160, SCREEN_WIDTH, 180)];
    UITableView *settingsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 160, SCREEN_WIDTH, 135)];
    settingsTableView.alwaysBounceVertical = NO;
    [settingsTableView setSeparatorInset:UIEdgeInsetsMake(0, 60, 0, 0)];
    settingsTableView.delegate = self;
    settingsTableView.dataSource = self;
    [scrollView addSubview:settingsTableView];
    
    // line separator at bottom of table view
//    UIView *longLineSepartor2 = [[UIView alloc] initWithFrame:CGRectMake(0, 339, SCREEN_WIDTH, 2)];
    UIView *longLineSepartor2 = [[UIView alloc] initWithFrame:CGRectMake(0, 294, SCREEN_WIDTH, 2)];
    longLineSepartor2.backgroundColor = [UIColor colorWithRed:0.827f green:0.835f blue:0.835f alpha:1.0f];
    [scrollView addSubview:longLineSepartor2];
    
/*-----------------------------------------------------------*/
    
    // promo gray background view
    UIView *promoGrayBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, scrollView.contentSize.height - 180, SCREEN_WIDTH, 80)];
    promoGrayBackgroundView.backgroundColor = [UIColor colorWithRed:0.271f green:0.302f blue:0.365f alpha:1.0f];
    [scrollView addSubview:promoGrayBackgroundView];
    
    // promo message label
    UILabel *promoMessageLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 12.5, SCREEN_WIDTH - 20, 21)];
    promoMessageLabel.textColor = [UIColor whiteColor];
    promoMessageLabel.font = [UIFont fontWithName:@"OpenSans" size:12];
    promoMessageLabel.textAlignment = NSTextAlignmentCenter;
    promoMessageLabel.text = [[AppStrings sharedInstance] getString:SHARE_PROMO_MESSAGE];
    [promoGrayBackgroundView addSubview:promoMessageLabel];
    
    // promo code button
    UIButton *promoCodeButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 42.5, SCREEN_WIDTH - 20, 21)];
    [promoCodeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
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
}

- (void)viewWillAppear:(BOOL)animated
{
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkCurrentMode) name:@"enteredForeground" object:nil];
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

- (void)checkCurrentMode
{
    if ([[BentoShop sharedInstance] didModeOrDateChange])
    {
        [(UINavigationController *)self.presentingViewController popToRootViewControllerAnimated:NO];
        [self dismissViewControllerAnimated:YES completion:nil];
        
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 45;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SettingsTableViewCell *settingsTableViewCell = (SettingsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (settingsTableViewCell == nil) {
        settingsTableViewCell = [[SettingsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    
//    settingsTableViewCell.iconImageView.backgroundColor = [UIColor colorWithRed:0.694f green:0.702f blue:0.729f alpha:1.0f];
    
    switch (indexPath.row) {
//        case 0:
//            settingsTableViewCell.settingsLabel.text = @"Credit Card";
//            settingsTableViewCell.iconImageView.image = [UIImage imageNamed:@"icon-square-creditcard"];
//            break;
        case 0:
            settingsTableViewCell.settingsLabel.text = @"FAQ";
            settingsTableViewCell.iconImageView.image = [UIImage imageNamed:@"icon-square-help"];
            break;
        case 1:
            settingsTableViewCell.settingsLabel.text = @"Email Support";
            settingsTableViewCell.iconImageView.image = [UIImage imageNamed:@"icon-square-email"];
            break;
        case 2:
            settingsTableViewCell.settingsLabel.text = @"Phone Support";
            settingsTableViewCell.iconImageView.image = [UIImage imageNamed:@"icon-square-phone"];
            break;
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
    
//    CreditCardInfoViewController *creditCardInfoViewController = [[CreditCardInfoViewController alloc] init];
    
    NSArray *toEmailRecipentsArray;
    MFMailComposeViewController *mailComposeViewController;
    
    switch (indexPath.row) {
//        case 0:
//            
//            // go to credit card
//            [self.navigationController pushViewController:creditCardInfoViewController animated:YES];
//            
//            break;
//            
        case 0:
        {
            // go to faq
            destVC = [storyboard instantiateViewControllerWithIdentifier:@"FAQID"];
            [self.navigationController pushViewController:destVC animated:YES];
            
            break;
        }
        case 1:
            
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
        
        case 2:
            
            // show call alert
            callAlertView.tag = 2;
            [callAlertView showInView:self.view];
            callAlertView = nil;
            
            break;
    }
}

- (void)onCloseButton
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

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
        if (strMessage == nil)
            strMessage = error.localizedDescription;
        
        MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"Error" message:strMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitle:nil];
        [alertView showInView:self.view];
        alertView = nil;
        
    } isJSON:NO];
}

- (void)alertView:(MyAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 1)
    {
        if (buttonIndex == 1) {
            
            [[Mixpanel sharedInstance] track:@"Logged Out"];
            
            [self processLogout];
        }
    }
    else if (alertView.tag == 2)
    {
        if (buttonIndex == 1) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"tel:1-415-300-1332"]];
        }
    }
}

- (void)postToTwitter
{
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
        
        // this is against FB's new policy now - does not work
//        [faceSheet setInitialText:sharePrecomposedMessageNew];
        
//        FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
//        content.contentURL = [NSURL URLWithString:@"https://developers.facebook.com"];
        
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
    
    [messageController setBody:[NSString stringWithFormat:@"Use my Bento promo code, %@, and get $5 off your first delicious Bento meal. Install the app here: http://apple.co/1FPEbWY", couponCodeString]];
    
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

@end
