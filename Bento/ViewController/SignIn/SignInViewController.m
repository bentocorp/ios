//
//  SignInViewController.m
//  Bento
//
//  Created by hanjinghe on 1/8/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "SignInViewController.h"

#import "PhoneNumberViewController.h"
#import "RegisterViewController.h"

#import "MyAlertView.h"

#import "JGProgressHUD.h"

#import "AppStrings.h"
#import "WebManager.h"
#import "DataManager.h"
#import "FacebookManager.h"
#import "BentoShop.h"

#import "SVGeocoder.h"
#import "Mixpanel.h"

#import "SignedOutSettingsViewController.h"

@interface SignInViewController () <FBManagerDelegate, MyAlertViewDelegate, CLLocationManagerDelegate>

@property (nonatomic, weak) IBOutlet UILabel *lblTitle;

@property (nonatomic, weak) IBOutlet UIScrollView *svMain;

@property (nonatomic, weak) IBOutlet UIView *viewError;
@property (nonatomic, weak) IBOutlet UILabel *lblError;

@property (nonatomic, weak) IBOutlet UIView *viewFacebook;
@property (nonatomic, weak) IBOutlet UIButton *btnSignIn;

@property (nonatomic, weak) IBOutlet UIImageView *ivEmail;
@property (nonatomic, weak) IBOutlet UIImageView *ivPassword;

@property (nonatomic, weak) IBOutlet UILabel *signUpLabel;
@property (nonatomic, weak) IBOutlet UIButton *signUpButton;
- (IBAction)onSignUpButton:(id)sender;

@end

@implementation SignInViewController
{
    JGProgressHUD *loadingHUD;
    
    CLLocationManager *locationManager;
    NSString *currentAddress;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.lblTitle.text = [[AppStrings sharedInstance] getString:SIGNIN_TITLE];
    [self.btnSignIn setTitle:[[AppStrings sharedInstance] getString:SIGNIN_BUTTON_SIGNIN] forState:UIControlStateNormal];
    
    self.svMain.contentSize = CGSizeMake(self.svMain.frame.size.width, 504);
    
    [self showErrorMessage:nil code:ERROR_NONE];
    
    // Facebook
    [[FacebookManager sharedInstance] setDelegate:self];
    
    // Tap
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    
    /*---------------------------LOCATION MANAGER--------------------------*/
    
    // Initialize location manager.
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    [locationManager startUpdatingLocation];
    
    /*---------------------------------------------------------------------*/
    
    NSLog(@"TIME AND DATE: %@", [NSString stringWithFormat:@"%@ %@", [self getCurrentTime], [self getCurrentDate]]);
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

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"PhoneNumber"])
    {
        PhoneNumberViewController *vcPhoneNumber = segue.destinationViewController;
        vcPhoneNumber.userInfo = sender;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willShowKeyboard:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willChangeKeyboardFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noConnection) name:@"networkError" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yesConnection) name:@"networkConnected" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkCurrentMode) name:@"enteredForeground" object:nil];
    
    // For test only
#ifdef DEBUG
//    self.txtEmail.text = @"ridev@bentonow.com";
//    self.txtPassword.text = @"12345678";
    self.txtEmail.text = @"joseph@bentonow.com";
    self.txtPassword.text = @"123456";
#endif//DEBUG
    
    [self updateUI];
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

- (void) viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [super viewWillDisappear:animated];
}

- (void) willShowKeyboard:(NSNotification*)notification
{
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    
    [self collapseScrollView:keyboardFrameBeginRect.size.height];
}

- (void) willChangeKeyboardFrame:(NSNotification *)notification
{
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    
    [self collapseScrollView:keyboardFrameBeginRect.size.height];
}

- (void) willHideKeyboard:(NSNotification *)notification
{
    [self expandScrollView];
}

- (void) collapseScrollView:(float)keyboardHeight
{
    self.svMain.frame = CGRectMake(self.svMain.frame.origin.x, self.svMain.frame.origin.y, self.svMain.frame.size.width, self.view.frame.size.height - self.svMain.frame.origin.y - keyboardHeight);
}

- (void) expandScrollView
{
    self.svMain.frame = CGRectMake(self.svMain.frame.origin.x, self.svMain.frame.origin.y, self.svMain.frame.size.width, self.view.frame.size.height - self.svMain.frame.origin.y);
}

- (void)hideKeyboard
{
    [self.txtEmail resignFirstResponder];
    [self.txtPassword resignFirstResponder];
}

- (void)showErrorMessage:(NSString *)errorMsg code:(int)errorCode
{
    if (errorMsg == nil || errorMsg.length == 0)
    {
        self.viewError.hidden = YES;
    }
    else
    {
        self.viewError.hidden = NO;
        self.lblError.text = errorMsg;
    }
    
    UIColor *errorColor = [UIColor colorWithRed:233.0f / 255.0f green:114.0f / 255.0f blue:2.0f / 255.0f alpha:1.0f];
    UIColor *correctColor = [UIColor colorWithRed:109.0f / 255.0f green:117.0f / 255.0f blue:131.0f / 255.0f alpha:1.0f];
    
    switch (errorCode) {
        case ERROR_NONE:
        {
            self.viewError.hidden = YES;
            
            self.txtEmail.textColor = correctColor;
            self.txtPassword.textColor = correctColor;
            
            self.ivEmail.image = [UIImage imageNamed:@"register_icon_email"];
            self.ivPassword.image = [UIImage imageNamed:@"register_icon_password"];
        }
            break;
            
        case ERROR_EMAIL:
        {
            self.viewError.hidden = NO;

            self.txtEmail.textColor = errorColor;
            self.txtPassword.textColor = correctColor;
            
            self.ivEmail.image = [UIImage imageNamed:@"register_icon_email_err"];
            self.ivPassword.image = [UIImage imageNamed:@"register_icon_password"];
        }
            break;
            
        case ERROR_PASSWORD:
        {
            self.viewError.hidden = NO;
            
            self.txtEmail.textColor = correctColor;
            self.txtPassword.textColor = errorColor;
            
            self.ivEmail.image = [UIImage imageNamed:@"register_icon_email"];
            self.ivPassword.image = [UIImage imageNamed:@"register_icon_password_err"];
        }
            break;
            
        default:
            break;
    }
}

- (IBAction)onBack:(id)sender
{
    [self hideKeyboard];
    [self.navigationController popViewControllerAnimated:YES]; // this will be checked first. back to settings page
    [self dismissViewControllerAnimated:YES completion:nil]; // back to My Bento
}

- (void)dissmodal
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil]; // try first
    [self.navigationController popViewControllerAnimated:YES]; // if ^ doesn't execute, do this
}

- (void)processSignin
{
    NSString *strEmail = self.txtEmail.text;
    NSString *strPassword = self.txtPassword.text;
    
    NSDictionary* loginInfo = @{
                                @"email" : strEmail,
                                @"password" : strPassword,
                                };
    
    NSDictionary *dicRequest = @{@"data" : [loginInfo jsonEncodedKeyValueString]};
    WebManager *webManager = [[WebManager alloc] init];
    
    loadingHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
    loadingHUD.textLabel.text = @"Logging in...";
    [loadingHUD showInView:self.view];
    
    NSString *strRequest = [NSString stringWithFormat:@"%@/user/login", SERVER_URL];
    [webManager AsyncProcess:strRequest method:POST parameters:dicRequest success:^(MKNetworkOperation *networkOperation) {
        [loadingHUD dismiss];
        
        NSDictionary *response = networkOperation.responseJSON;
        [[DataManager shareDataManager] setUserInfo:response];
        
        NSLog(@"email log in response - %@", response);
        
        NSUserDefaults *pref = [NSUserDefaults standardUserDefaults];
        [pref setObject:strRequest forKey:@"apiName"];
        [pref setObject:dicRequest forKey:@"loginRequest"];
        [pref synchronize];
        
        [[BentoShop sharedInstance] setSignInStatus:YES];
        
        [self showErrorMessage:nil code:ERROR_NONE];
        [self gotoDeliveryLocationScreen];
        
        /*-----------------------------MIXPANEL-------------------------------*/
        
        Mixpanel *mixpanel = [Mixpanel sharedInstance];

        // identify user for current session
        [mixpanel identify:strEmail];
        
        // set properties
        [mixpanel.people set:@{
                               @"$name": [NSString stringWithFormat:@"%@ %@", response[@"firstname"], response[@"lastname"]],
                               @"$email": response[@"email"],
                               @"$phone": response[@"phone"],
                               @"Last Login Address": currentAddress
                               }];
        
        NSLog(@"%@, %@, %@, %@, %@, %@, %@", mixpanel.distinctId, [NSString stringWithFormat:@"%@ %@", response[@"firstname"], response[@"lastname"]], response[@"email"], response[@"phone"], [self getCurrentTime], [self getCurrentDate], currentAddress);
        
        /*--------------------------------------------------------------------*/
        
        [self.navigationController dismissViewControllerAnimated:YES completion:nil]; // try first
        [self.navigationController popViewControllerAnimated:YES]; // if not this will run
        
    } failure:^(MKNetworkOperation *errorOp, NSError *error) {
        [loadingHUD dismiss];

        NSString *strMessage = [[DataManager shareDataManager] getErrorMessage:errorOp.responseJSON];
        if (strMessage == nil)
            strMessage = error.localizedDescription;
        
        if (error.code == 403)
        {
            [self showErrorMessage:strMessage code:ERROR_PASSWORD];
        }
        else if (error.code == 404)
        {
            [self showErrorMessage:strMessage code:ERROR_EMAIL];
        }
        else
        {
            [self showErrorMessage:strMessage code:ERROR_UNKNOWN];
        }
    
    } isJSON:NO];
}

- (void)doSignin
{
    NSString *strEmail = self.txtEmail.text;
    if (strEmail.length == 0)
    {
        [self showErrorMessage:@"Please enter a email address." code:ERROR_EMAIL];
        return;
    }
    
    if (![DataManager isValidMailAddress:strEmail])
    {
        [self showErrorMessage:@"Please enter a valid email address." code:ERROR_EMAIL];
        return;
    }
    
    if (self.txtPassword.text.length == 0)
    {
        [self showErrorMessage:@"Please enter the password." code:ERROR_PASSWORD];
        return;
    }
    
    [self showErrorMessage:nil code:ERROR_NONE];
    [self processSignin];
}

- (IBAction)onSignIn:(id)sender
{
    [self doSignin];
}

- (IBAction)onForgot:(id)sender
{
    NSURL *urlReset = [[AppStrings sharedInstance] getURL:SIGNIN_LINK_RESET];
    if (urlReset != nil && [[UIApplication sharedApplication] canOpenURL:urlReset])
        [[UIApplication sharedApplication] openURL:urlReset];
}

- (void)reqFacebookUserInfo
{
    loadingHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
    loadingHUD.textLabel.text = @"Logging in...";
    [loadingHUD showInView:self.view];
    
    [[FacebookManager sharedInstance] loadUserDetailsWithCompletionHandler:^(NSDictionary<FBGraphUser> *user, NSError *error)
     {
         if (error == nil)
         {
             NSLog(@"facebook log in response - %@", user);
             
             NSString *strMailAddr = [user valueForKey:@"email"];
             if (strMailAddr == nil || strMailAddr.length == 0)
             {
                 [loadingHUD dismiss];
                 
                 MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"" message:@"Error! We need your email to submit your order. We promise, no spam! Do you want to try again?" delegate:self cancelButtonTitle:@"No" otherButtonTitle:@"Yes"];
                 [alertView showInView:self.view];
                 alertView = nil;
                 return;
             }
             
             NSString *strFBID = [user valueForKey:@"id"];
             NSString *strAccessToken = [[[FBSession activeSession] accessTokenData] accessToken];
             
             NSDictionary* loginInfo = @{
                                         @"email" : strMailAddr,
                                         @"fb_id" : strFBID,
                                         @"fb_token" : strAccessToken,
                                         };
             
             NSDictionary *dicRequest = @{@"data" : [loginInfo jsonEncodedKeyValueString]};
             
             NSLog(@"Facebook login dictRequest - %@", dicRequest);
             
             WebManager *webManager = [[WebManager alloc] init];
             
             NSString *strRequest = [NSString stringWithFormat:@"%@/user/fblogin", SERVER_URL];
             [webManager AsyncProcess:strRequest method:POST parameters:dicRequest success:^(MKNetworkOperation *networkOperation) {
                 [loadingHUD dismiss];
                 
                 NSDictionary *response = networkOperation.responseJSON;
                 [[DataManager shareDataManager] setUserInfo:response];
                 
                 NSLog(@"/user/fblogin response - %@", response);
                 
                 NSUserDefaults *pref = [NSUserDefaults standardUserDefaults];
                 [pref setObject:strRequest forKey:@"apiName"];
                 [pref setObject:dicRequest forKey:@"loginRequest"];
                 [pref synchronize];
                 
                 [self showErrorMessage:nil code:ERROR_NONE];
                 [self gotoDeliveryLocationScreen];
                 
             } failure:^(MKNetworkOperation *errorOp, NSError *error) {
                 
                 [loadingHUD dismiss];
                 
                 if (error.code == 403 || error.code == 404)
                 {
                     
                     [[BentoShop sharedInstance] setSignInStatus:NO];
                     
                     // this really isn't used, since i'm only checking for Register
                     [[NSUserDefaults standardUserDefaults] setObject:@"SignIn" forKey:@"RegisterOrSignIn"];
                     [[NSUserDefaults standardUserDefaults] synchronize];
                     
                     [self gotoPhoneNumberScreen:user];
                     return;
                 }
                 else
                 {
                     NSString *strMessage = [[DataManager shareDataManager] getErrorMessage:errorOp.responseJSON];
                     if (strMessage == nil)
                         strMessage = error.localizedDescription;
                     
                     MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"" message:strMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitle:nil];
                     [alertView showInView:self.view];
                     alertView = nil;
                     return;
                 }
                 
             } isJSON:NO];
         }
         else
         {
             [loadingHUD dismiss];
             
             MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"Error" message:error.debugDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitle:nil];
             [alertView showInView:self.view];
             alertView = nil;
             return;
         }
     }];
}

- (void)doSignInWithFacebook:(BOOL)isRetry
{
    [self hideKeyboard];
    
    [[BentoShop sharedInstance] setSignInStatus:YES];
    
    FacebookManager *fbManager = [FacebookManager sharedInstance];
    if (isRetry)
        [fbManager login];
    else
    {
        if ([fbManager isSessionOpen])
            [self reqFacebookUserInfo];
        else
            [fbManager login];
    }
}

- (IBAction)onSignInWithFacebook:(id)sender
{
    [self doSignInWithFacebook:NO];
}

- (void) gotoPhoneNumberScreen:(NSDictionary<FBGraphUser> *)userInfo
{
    [self performSegueWithIdentifier:@"PhoneNumber" sender:userInfo];
}

- (IBAction)onTextChanged:(id)sender
{
    [self updateUI];
}

- (void)updateUI
{
    NSString *strEmail = self.txtEmail.text;
    NSString *strPassword = self.txtPassword.text;
    
    BOOL isValid = (strEmail.length > 0 && [DataManager isValidMailAddress:strEmail] && strPassword.length > 0);
    
    //    self.btnRegister.enabled = isValid;
    if (isValid)
        [self.btnSignIn setBackgroundColor:[UIColor colorWithRed:135.0f / 255.0f green:178.0f / 255.0f blue:96.0f / 255.0f alpha:1.0f]];
    else
        [self.btnSignIn setBackgroundColor:[UIColor colorWithRed:122.0f / 255.0f green:133.0f / 255.0f blue:146.0f / 255.0f alpha:1.0f]];
    
    /*------------------------------------------------------------*/
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([[defaults objectForKey:@"cameFromWhichVC"] isEqualToString:@"cameFromRegister"])
    {
        self.signUpButton.hidden = YES;
        self.signUpLabel.hidden = YES;
    }
}

- (void) gotoDeliveryLocationScreen
{
    [self dissmodal];
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.txtEmail)
        [self.txtPassword becomeFirstResponder];
    else
        [self doSignin];
    
    return YES;
}

-(void)dismissKeyboard
{
    [self.txtEmail endEditing:YES];
    [self.txtPassword endEditing:YES];
}

#pragma mark FBManagerDelegate

-(void)FBLogin:(BOOL)flag
{
    [self reqFacebookUserInfo];
}

#pragma mark MyAlertViewDelegate

- (void)doReauthorise
{
    [self doSignInWithFacebook:YES];
}

- (void)alertView:(MyAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        [self performSelector:@selector(doReauthorise) withObject:nil];
    }
}

- (IBAction)onSignUpButton:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"cameFromSignIn" forKey:@"cameFromWhichVC"];
    [defaults synchronize];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *destVC = [storyboard instantiateViewControllerWithIdentifier:@"RegisterID"];
    [self.navigationController pushViewController:destVC animated:YES];
}

@end
