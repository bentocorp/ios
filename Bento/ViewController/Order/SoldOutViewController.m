//
//  SoldOutViewController.m
//  Bento
//
//  Created by hanjinghe on 1/8/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "SoldOutViewController.h"

#import "FaqViewController.h"

#import "PreviewViewController.h"

#import "SignedInSettingsViewController.h"
#import "SignedOutSettingsViewController.h"

#import "MyAlertView.h"

#import "UIImageView+WebCache.h"

#import "JGProgressHUD.h"

#import "BentoShop.h"
#import "AppStrings.h"
#import "WebManager.h"
#import "DataManager.h"
#import "Mixpanel.h"
#import "UIColor+CustomColors.h"
#import "Bento-Swift.h"

@interface SoldOutViewController ()

@property (nonatomic, weak) IBOutlet UIView *viewMain;

@property (nonatomic, weak) IBOutlet UIImageView *ivBackground;

@property (nonatomic, weak) IBOutlet UIImageView *ivTitle;

@property (nonatomic, weak) IBOutlet UILabel *lblMessageTitle;
@property (nonatomic, weak) IBOutlet UILabel *lblMessageContent;

@property (nonatomic, weak) IBOutlet UITextField *txtEmail;

@property (nonatomic, weak) IBOutlet UIButton *btnSend;
@property (nonatomic, weak) IBOutlet UIButton *btnPreview;

@property (nonatomic, weak) IBOutlet UIButton *btnPolicy;
@property (nonatomic, weak) IBOutlet UIButton *btnTerms;

@property (nonatomic, weak) IBOutlet UILabel *openingHoursLabel;
@property (nonatomic, weak) IBOutlet UILabel *lunchAndDinnerHoursLabel;


@end

@implementation SoldOutViewController
{
    float currentTime;
    float lunchTime;
    float dinnerTime;
    float bufferTime;
    
    JGProgressHUD *loadingHUD;
    BOOL isThereConnection;
    
    BOOL areThereAnyMenus;
}

- (NSString *)getClosedText
{
    currentTime = [[[BentoShop sharedInstance] getCurrentTime] floatValue];
    lunchTime = [[[BentoShop sharedInstance] getLunchTime] floatValue];
    dinnerTime = [[[BentoShop sharedInstance] getDinnerTime] floatValue];
    bufferTime = [[[BentoShop sharedInstance] getBufferTime] floatValue];
    
    // 17:30 - 23:59, Closed for the night, see you tomorrow!
    if (currentTime >= (dinnerTime + bufferTime) && currentTime < 24) {
        return [[AppStrings sharedInstance] getString:CLOSED_TEXT_LATENIGHT];
    }

    // Closed for now, see you when we open!
    return [[AppStrings sharedInstance] getString:CLOSED_TEXT_CONTENT];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    SocketIOClient* socket = [[SocketIOClient alloc] initWithSocketURL:@"https://54.191.141.101:8081" opts:nil];

    [socket on:@"connect" callback:^(NSArray* data, SocketAckEmitter* ack) {
        NSLog(@"socket connected");
    }];

    [socket connect];
    
    isThereConnection = YES;
    
    UIButton *settingsButton = [[UIButton alloc] initWithFrame:CGRectMake(12, 30, 25, 25)];
    [settingsButton addTarget:self action:@selector(onSettings) forControlEvents:UIControlEventTouchUpInside];
    [settingsButton setImage:[UIImage imageNamed:@"icon-user"] forState:UIControlStateNormal];
    [self.view addSubview:settingsButton];
    
    self.openingHoursLabel.adjustsFontSizeToFitWidth = YES;
    self.openingHoursLabel.text = [[AppStrings sharedInstance] getString:OPEN_LINE_1];
    self.lunchAndDinnerHoursLabel.adjustsFontSizeToFitWidth = YES;
    self.lunchAndDinnerHoursLabel.text = [[AppStrings sharedInstance] getString:OPEN_LINE_2];
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.ivBackground.bounds;
    
    UIColor *color1 = [UIColor bentoGradient1];
    UIColor *color2 = [UIColor bentoGradient2];
    gradient.colors = [NSArray arrayWithObjects:(id)[color1 CGColor], (id)[color2 CGColor], nil];
    [self.ivBackground.layer insertSublayer:gradient atIndex:0];
    
    NSURL *urlBack = [[BentoShop sharedInstance] getMenuImageURL];
    [self.ivBackground sd_setImageWithURL:urlBack placeholderImage:[UIImage imageNamed:@"first_background"]];
    
    NSURL *urlLogo = [[AppStrings sharedInstance] getURL:APP_LOGO];
    [self.ivTitle sd_setImageWithURL:urlLogo placeholderImage:[UIImage imageNamed:@"logo_title"]];
    
    self.lblMessageContent.adjustsFontSizeToFitWidth = YES;
    self.lblMessageTitle.adjustsFontSizeToFitWidth = YES;
    
    self.btnPreview.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.btnPreview.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    self.btnPreview.layer.cornerRadius = 8;
    self.btnPreview.layer.borderWidth = 1;
    self.btnPreview.layer.borderColor = [[UIColor whiteColor] CGColor];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.type == 0) // Closed
    {
        self.lblMessageTitle.text = [[AppStrings sharedInstance] getString:CLOSED_TEXT_TITLE];
        self.lblMessageContent.text = [self getClosedText];
        
        self.txtEmail.placeholder = [[AppStrings sharedInstance] getString:CLOSED_PLACEHOLDER_EMAIL];
        [self.btnSend setTitle:[[AppStrings sharedInstance] getString:CLOSED_BUTTON_RECEIVE_COUPON] forState:UIControlStateNormal];
        [self.btnPolicy setTitle:[[AppStrings sharedInstance] getString:CLOSED_LINK_POLICY] forState:UIControlStateNormal];
        [self.btnTerms setTitle:[[AppStrings sharedInstance] getString:CLOSED_LINK_TERMS] forState:UIControlStateNormal];
    }
    else if (self.type == 1) // Sold Out
    {
        self.lblMessageTitle.text = [[AppStrings sharedInstance] getString:SOLDOUT_TEXT_TITLE];
        self.lblMessageContent.text = [[AppStrings sharedInstance] getString:SOLDOUT_TEXT_CONTENT];
        
        self.txtEmail.placeholder = [[AppStrings sharedInstance] getString:SOLDOUT_PLACEHOLDER_EMAIL];
        [self.btnSend setTitle:[[AppStrings sharedInstance] getString:SOLDOUT_BUTTON_RECEIVE_COUPON] forState:UIControlStateNormal];
        [self.btnPolicy setTitle:[[AppStrings sharedInstance] getString:SOLDOUT_LINK_POLICY] forState:UIControlStateNormal];
        [self.btnTerms setTitle:[[AppStrings sharedInstance] getString:SOLDOUT_LINK_TERMS] forState:UIControlStateNormal];
    }
    
    [self setPreviewButtonText];
    
    [self onUpdatedStatus];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus) name:USER_NOTIFICATION_UPDATED_STATUS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willChangeKeyboardFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noConnection) name:@"networkError" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yesConnection) name:@"networkConnected" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setPreviewButtonText) name:@"enteredForeground" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startTimerOnViewedScreen) name:@"enteredForeground" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endTimerOnViewedScreen) name:@"enteringBackground" object:nil];
    
    [self startTimerOnViewedScreen];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self endTimerOnViewedScreen];
}

#pragma mark Duration on screen
- (void)startTimerOnViewedScreen
{
    if (self.type == 0) {
        [[Mixpanel sharedInstance] timeEvent:@"Viewed Closed Screen"];
    }
    else {
        [[Mixpanel sharedInstance] timeEvent:@"Viewed Sold-out Screen"];
    }
}

- (void)endTimerOnViewedScreen
{
    if (self.type == 0) {
        [[Mixpanel sharedInstance] track:@"Viewed Closed Screen"];
    }
    else {
        [[Mixpanel sharedInstance] track:@"Viewed Sold-out Screen"];
    }
}

- (void)noConnection
{
    isThereConnection = NO;
    
    if (loadingHUD == nil)
    {
        loadingHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
        loadingHUD.textLabel.text = @"Waiting for internet connectivity...";
        [loadingHUD showInView:self.view];
    }
}

- (void)yesConnection
{
    [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(callUpdate) userInfo:nil repeats:NO];
}

- (void)callUpdate
{
    isThereConnection = YES;
    
    [loadingHUD dismiss];
    loadingHUD = nil;
    [self viewWillAppear:YES];
}

- (void)setPreviewButtonText
{
    areThereAnyMenus = YES;
    
    // SOLDOUT or CLOSED
    if ([[BentoShop sharedInstance] isClosed])
        self.type = 0;
    else if ([[BentoShop sharedInstance] isSoldOut])
        self.type = 1;
    
    NSString *todayMenuString = @"See Today's Menu";
    NSString *nextMenuString = [NSString stringWithFormat:@"See %@'s Menu", [[BentoShop sharedInstance] getNextMenuWeekdayString]];
    NSString *noAvailableMenuString = @"No Available Menu";
    
    NSString *strTitle;
    
    // CLOSED && 00:00 - 17:29
    if (self.type == 0 && currentTime >= 0 && currentTime < (dinnerTime + bufferTime))
    {
        if ([[BentoShop sharedInstance] isThereLunchMenu] || [[BentoShop sharedInstance] isThereDinnerMenu])
            strTitle = todayMenuString;
        else if ([[BentoShop sharedInstance] isThereLunchNextMenu] || [[BentoShop sharedInstance] isThereDinnerNextMenu])
            strTitle = nextMenuString;
        else
        {
            strTitle = noAvailableMenuString;
            
            areThereAnyMenus = NO;
        }
    }
    
    // CLOSED && 17:30 - 23:59
    else if (self.type == 0 && currentTime >= (dinnerTime + bufferTime) && currentTime < 24)
    {
        if ([[BentoShop sharedInstance] isThereLunchNextMenu] || [[BentoShop sharedInstance] isThereDinnerNextMenu])
            strTitle = nextMenuString;
        else
        {
            strTitle = noAvailableMenuString;
            
            areThereAnyMenus = NO;
        }
    }
    
    // SOLDOUT
    else if (self.type == 1)
    {
        if ([[BentoShop sharedInstance] isThereLunchMenu] || [[BentoShop sharedInstance] isThereDinnerMenu])
            strTitle = todayMenuString;
        else
        {
            strTitle = noAvailableMenuString;
            
            areThereAnyMenus = NO;
        }
    }
    
    [self.btnPreview setTitle:[strTitle uppercaseString] forState:UIControlStateNormal];
}

- (void)onUpdatedStatus
{
    if (isThereConnection)
    {
        if (self.type == 0) // Closed
        {
            if (![[BentoShop sharedInstance] isClosed])
                [self performSelectorOnMainThread:@selector(onBack) withObject:nil waitUntilDone:NO];
        }
        else if (self.type == 1) // Sold Out
        {
            if (![[BentoShop sharedInstance] isSoldOut])
                [self performSelectorOnMainThread:@selector(onBack) withObject:nil waitUntilDone:NO];
        }
    }
}

- (void)willShowKeyboard:(NSNotification*)notification
{
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    
    [self moveToShowablePosition:keyboardFrameBeginRect.size.height];
}

- (void)willChangeKeyboardFrame:(NSNotification *)notification
{
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    
    [self moveToShowablePosition:keyboardFrameBeginRect.size.height];
}

- (void)willHideKeyboard:(NSNotification *)notification
{
    [UIView animateWithDuration:0.3f animations:^{
        self.viewMain.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
    }];
}

- (void)moveToShowablePosition:(float)keyboardHeight
{
    if(self.viewMain.center.y > (self.view.frame.size.height - keyboardHeight))
    {
        [UIView animateWithDuration:0.3f animations:^{
            self.viewMain.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height - keyboardHeight - 15);
        }];
    }
}

- (void)onBack
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)onPrivacyPolicy:(id)sender
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    FaqViewController *destVC = [storyboard instantiateViewControllerWithIdentifier:@"FAQID"];
    destVC.contentType = CONTENT_PRIVACY;
    [self.navigationController pushViewController:destVC animated:YES];
}

- (IBAction)onTermsAndConditions:(id)sender
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    FaqViewController *destVC = [storyboard instantiateViewControllerWithIdentifier:@"FAQID"];
    destVC.contentType = CONTENT_TERMS;
    [self.navigationController pushViewController:destVC animated:YES];
}

- (IBAction)onHelp:(id)sender
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    FaqViewController *destVC = [storyboard instantiateViewControllerWithIdentifier:@"FAQID"];
    destVC.contentType = CONTENT_FAQ;
    [self.navigationController pushViewController:destVC animated:YES];
}

- (void)showConfirmMessage
{
    NSString *strMessage = @"";
    NSString *strConfirmButton = @"";
    
    if (self.type == 0) // Closed
    {
        strMessage = [[AppStrings sharedInstance] getString:ALERT_CC_TEXT];
        strConfirmButton = [[AppStrings sharedInstance] getString:ALERT_CC_BUTTON_OK];
    }
    else if (self.type == 1) // Sold Out
    {
        strMessage = [[AppStrings sharedInstance] getString:ALERT_SOC_TEXT];
        strConfirmButton = [[AppStrings sharedInstance] getString:ALERT_SOC_BUTTON_OK];
    }
    
    MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"" message:strMessage delegate:nil cancelButtonTitle:strConfirmButton otherButtonTitle:nil];
    [alertView showInView:self.view];
    
    alertView = nil;
}

- (void)doSubmit
{
    [self.txtEmail resignFirstResponder];
    
    NSString *strEmail = self.txtEmail.text;
    if (![DataManager isValidMailAddress:strEmail])
    {
        MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"" message:@"Please input a valid email address." delegate:nil cancelButtonTitle:@"OK" otherButtonTitle:nil];
        
        [alertView showInView:self.view];
        alertView = nil;
        return;
    }
    
    NSString *strReason = @"";
    if (self.type == 0)
        strReason = @"closed";
    else if (self.type == 1)
        strReason = @"sold out";
    
    NSString *strToken = [[DataManager shareDataManager] getAPIToken];
    NSDictionary* postInfo = nil;
    if (strToken != nil && strToken.length > 0) {
        postInfo = @{
                     @"email" : strEmail,
                     @"reason" : strReason,
                     @"api_token" : strToken,
                     };
    }
    else {
        postInfo = @{
                     @"email" : strEmail,
                     @"reason" : strReason,
                     };
    }
    
    NSDictionary *dicRequest = @{@"data" : [postInfo jsonEncodedKeyValueString]};
    WebManager *webManager = [[WebManager alloc] init];
    
    loadingHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
    loadingHUD.textLabel.text = @"Sending...";
    [loadingHUD showInView:self.view];
    
    
    NSString *strRequest = [NSString stringWithFormat:@"%@/coupon/request", SERVER_URL];
    if ([[DataManager shareDataManager] getUserInfo] != nil)
        strRequest = [NSString stringWithFormat:@"%@?api_token=%@", strRequest, [[DataManager shareDataManager] getAPIToken]];
    
    [webManager AsyncProcess:strRequest method:POST parameters:dicRequest success:^(MKNetworkOperation *networkOperation) {
        [loadingHUD dismiss];
        
        [self showConfirmMessage];
        
    } failure:^(MKNetworkOperation *errorOp, NSError *error) {
        [loadingHUD dismiss];
        
        NSString *strMessage = [[DataManager shareDataManager] getErrorMessage:errorOp.responseJSON];
        if (strMessage == nil)
            strMessage = error.localizedDescription;
        
        MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"" message:strMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitle:nil];
        
        [alertView showInView:self.view];
        alertView = nil;
        
    } isJSON:NO];
}

- (IBAction)onSendBentoCoupon:(id)sender
{
    [self doSubmit];
}

- (IBAction)onGotoMenu:(id)sender
{
    if (areThereAnyMenus) {
        PreviewViewController *previewViewController = [[PreviewViewController alloc] init];
        [self.navigationController pushViewController:previewViewController animated:YES];
    }
}

- (void)onSettings
{
    // get current user info
    NSDictionary *currentUserInfo = [[DataManager shareDataManager] getUserInfo];
    
    SignedInSettingsViewController *signedInSettingsViewController = [[SignedInSettingsViewController alloc] init];
    SignedOutSettingsViewController *signedOutSettingsViewController = [[SignedOutSettingsViewController alloc] init];
    
    UINavigationController *navC;
    
    // signed in or not?
    if (currentUserInfo == nil) {
        // navigate to signed out settings vc
        navC = [[UINavigationController alloc] initWithRootViewController:signedOutSettingsViewController];
        navC.navigationBar.hidden = YES;
        [self.navigationController presentViewController:navC animated:YES completion:nil];
    }
    else {
        // navigate to signed in settings vc
        navC = [[UINavigationController alloc] initWithRootViewController:signedInSettingsViewController];
        navC.navigationBar.hidden = YES;
        [self.navigationController presentViewController:navC animated:YES completion:nil];
    }
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.txtEmail resignFirstResponder];
    
    return YES;
}

@end
