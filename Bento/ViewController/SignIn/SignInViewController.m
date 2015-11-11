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
#import "BentoShop.h"

#import "SVGeocoder.h"
#import "Mixpanel.h"

#import "SignedOutSettingsViewController.h"

#import "UIColor+CustomColors.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

//@interface SignInViewController () <FBManagerDelegate, MyAlertViewDelegate, CLLocationManagerDelegate>
@interface SignInViewController () <MyAlertViewDelegate, CLLocationManagerDelegate>

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
//    [[FacebookManager sharedInstance] setDelegate:self];
    
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkCurrentMode) name:@"checkModeOrDateChange" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkCurrentMode) name:@"enteredForeground" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startTimerOnViewedScreen) name:@"enteredForeground" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endTimerOnViewedScreen) name:@"enteringBackground" object:nil];
    
    // For test only
#ifdef DEBUG
//    self.txtEmail.text = @"ridev@bentonow.com";
//    self.txtPassword.text = @"12345678";
    self.txtEmail.text = @"joseph@bentonow.com";
    self.txtPassword.text = @"123456";
#endif//DEBUG
    
    [self updateUI];
    
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
    [[Mixpanel sharedInstance] timeEvent:@"Viewed Sign In Screen"];
}

- (void)endTimerOnViewedScreen
{
    [[Mixpanel sharedInstance] track:@"Viewed Sign In Screen"];
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
    
    UIColor *errorColor = [UIColor bentoErrorTextOrange];
    UIColor *correctColor = [UIColor bentoCorrectTextGray];
    
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
        
        NSLog(@"Email login response - %@", response);
        
        NSUserDefaults *pref = [NSUserDefaults standardUserDefaults];
        [pref setObject:strRequest forKey:@"apiName"];
        [pref setObject:dicRequest forKey:@"loginRequest"];
        [pref setObject:nil forKey:@"new_phone_number"];
        [pref synchronize];
        
        [[BentoShop sharedInstance] setSignInStatus:YES];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self trackLogin:strEmail responseJSON:response];
            [self showErrorMessage:nil code:ERROR_NONE];
            [self gotoDeliveryLocationScreen];
            
            [self.navigationController dismissViewControllerAnimated:YES completion:nil]; // try 1st
            [self.navigationController popViewControllerAnimated:YES]; // if not, this will run
        });
        
    } failure:^(MKNetworkOperation *errorOp, NSError *error) {
        [loadingHUD dismiss];

        NSString *strMessage = [[DataManager shareDataManager] getErrorMessage:errorOp.responseJSON];
        if (strMessage == nil) {
            strMessage = error.localizedDescription;
        }
        
        if (error.code == 403) {
            [self showErrorMessage:strMessage code:ERROR_PASSWORD];
        }
        else if (error.code == 404) {
            [self showErrorMessage:strMessage code:ERROR_EMAIL];
        }
        else {
            [self showErrorMessage:strMessage code:ERROR_UNKNOWN];
        }
    
    } isJSON:NO];
}

- (void)trackLogin:(NSString *)strEmail responseJSON:(NSDictionary *)response
{
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    // identify user for current session
    [mixpanel identify:strEmail];
    
    // reregister deviceToken to server
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"deviceToken"] != nil) {
        
        NSData *deviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"deviceToken"];
        [mixpanel.people addPushDeviceToken:deviceToken];
        
        NSLog(@"Device Token - %@", deviceToken);
    }
    
    // install source
    NSString *source;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"SourceOfInstall"] != nil) {
        source = [[NSUserDefaults standardUserDefaults] objectForKey:@"SourceOfInstall"];
    }
    
    NSString *sourceFinal;
    if (source != nil) {
        sourceFinal = source;
    }
    else {
        sourceFinal = @"N/A";
    }
    
    NSString *currentAddressFinal;
    
    if (currentAddress != nil) {
        currentAddressFinal = currentAddress;
    }
    else {
        currentAddressFinal = @"N/A";
    }
    
    // set properties
    [mixpanel.people set:@{
                           @"$name": [NSString stringWithFormat:@"%@ %@", response[@"firstname"], response[@"lastname"]],
                           @"$email": response[@"email"],
                           @"$phone": response[@"phone"],
                           @"Coupon Code": response[@"coupon_code"],
                           @"Installed Source":sourceFinal,
                           @"Last Login Address": currentAddressFinal
                           }];
    
    [mixpanel track:@"Logged In"];
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

- (void)reqFacebookUserInfo
{
    loadingHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
    loadingHUD.textLabel.text = @"Logging in...";
    [loadingHUD showInView:self.view];
    
    /*commented out saved token check, because what if user wants to log in with a different fb account?*/
    
    // Token is already available, not retrying && email has been granted already
//    if ([FBSDKAccessToken currentAccessToken] && [[FBSDKAccessToken currentAccessToken].declinedPermissions containsObject:@"email"] == NO) {
//        
//        // request user info using graph api
//        [self reqGraphAPI:[[FBSDKAccessToken currentAccessToken] tokenString]];
//    }
    // Token not saved, or saved, but didn't provide email, so retrying -> show webview again
//    else {
    
        // REQUEST PERMISSIONS/AUTHORIZATION FROM FB...
        // displays a webview,
        // first time - user needs to login with email/password
        // then they can choose which permissions to grant (public profile is mandatory, but email is optional)
        // if they chose to not provide email (strEmail == nil), app will prompt an error alert and allow them to retry because
        // once they authorized public profile before, FB login won't ask for it again when choosing permissions to grant
        // not providing email this time would disable the OK button in the FB webview - can't continue further
        // if all info have been authorized before, "You have already authorize Bento" would be shown in webview
        // if 'done' or 'cancel' (both sets result.isCancelled to yes), dismiss loadingHUD, and cancel out login
        // but what if user wants to log into another account? they can manually log out from safari
        
        FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
    
        // if there was a token saved from earlier, logout before trying to login another user
        // remove this line of code if checking for token above
        [login logOut];
    
        [login logInWithReadPermissions:@[@"public_profile", @"email"] fromViewController:self handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
            
            if (error == nil) {

                if ([result.declinedPermissions containsObject:@"email"])
                {
                    NSLog(@"declined permissions");
                }
                if (result.isCancelled) {
                    [loadingHUD dismiss];
                    NSLog(@"Cancelled");
                }
                else {
                    NSLog(@"Logged in");
                    
                    [self reqGraphAPI:[[FBSDKAccessToken currentAccessToken] tokenString]];
                }
            }
            // error != nil
            else {
                NSLog(@"Process error");
                
                [loadingHUD dismiss];

                MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"Error"
                                                                    message:error.debugDescription
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                           otherButtonTitle:nil];
                [alertView showInView:self.view];
                alertView = nil;
                
                return;
            }
        }];
//    }
}

- (void)reqGraphAPI:(NSString *)strAccessToken
{
    /*------------------------------------------------CALL TO GRAPH API TO GET USER INFO-----------------------------------------*/
    
    // call graph api once logged in
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    [parameters setValue:@"first_name, last_name, email, id, picture, gender, age_range" forKey:@"fields"];
    
    [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:parameters]
     startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
         
         NSDictionary *graphAPIResults = result;
         NSLog(@"result - %@", graphAPIResults);
         
         NSString *strFirstName = graphAPIResults[@"first_name"];
         NSString *strLastName = graphAPIResults[@"last_name"];
         NSString *strEmail = graphAPIResults[@"email"];
         NSString *strId = graphAPIResults[@"id"];
         NSString *strPhotoURL = graphAPIResults[@"picture"][@"data"][@"url"]; // might want to test no URL
         NSString *strGender = graphAPIResults[@"gender"];
         NSDictionary *dictAgeRange = graphAPIResults[@"age_range"];
         
         // if user declined email
         if (strEmail == nil || strEmail.length == 0) {
             [loadingHUD dismiss];
             
             MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@""
                                                                 message:@"Error! We need your email to submit your order. We promise, no spam! Do you want to try again?"
                                                                delegate:self
                                                       cancelButtonTitle:@"No"
                                                        otherButtonTitle:@"Yes"];
             [alertView showInView:self.view];
             alertView = nil;
             
             return;
         }
         
         // used to pass into phoneNumberVC is necessary
         NSDictionary *dictUserInfo = @{
                                        @"firstname" : strFirstName,
                                        @"lastname" : strLastName,
                                        @"email" : strEmail,
                                        @"fb_id" : strId,
                                        @"fb_profile_pic" : strPhotoURL,
                                        @"fb_gender" : strGender,
                                        @"fb_age_range" : dictAgeRange,
                                        @"fb_token" : strAccessToken,
                                        };
         
         NSDictionary *loginInfo = @{
                                     @"email":strEmail,
                                     @"fb_token":strAccessToken
                                     };
         
         NSDictionary *dictRequest = @{
                                      @"data":[loginInfo jsonEncodedKeyValueString]
                                      };
         
         [self fbLoginAPICallToBackend:dictUserInfo dictRequest:dictRequest];
     }];
}

- (void)fbLoginAPICallToBackend:(NSDictionary *)dictUserInfo dictRequest:(NSDictionary *)dictRequest
{
    /*----------------------------------------------------API CALL TO BACKEND------------------------------------------------*/
    
    WebManager *webManager = [[WebManager alloc] init];
    
    NSString *strRequest = [NSString stringWithFormat:@"%@/user/fblogin", SERVER_URL];
    [webManager AsyncProcess:strRequest method:POST parameters:dictRequest success:^(MKNetworkOperation *networkOperation) {
        [loadingHUD dismiss];
        
        NSDictionary *response = networkOperation.responseJSON;
        [[DataManager shareDataManager] setUserInfo:response];
        
        NSLog(@"/user/fblogin response - %@", response);
        
        NSUserDefaults *pref = [NSUserDefaults standardUserDefaults];
        [pref setObject:strRequest forKey:@"apiName"];
        [pref setObject:dictRequest forKey:@"loginRequest"];
        [pref setObject:nil forKey:@"new_phone_number"];
        [pref synchronize];
        
        [self trackLogin:dictUserInfo[@"email"] responseJSON:response];
        [self showErrorMessage:nil code:ERROR_NONE];
        [self gotoDeliveryLocationScreen];
        
    } failure:^(MKNetworkOperation *errorOp, NSError *error) {
        
        [loadingHUD dismiss];
        
        // if bad fb_token token (according to docs)
        if (error.code == 403) {
            [[BentoShop sharedInstance] setSignInStatus:NO];
            
            MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"" message:@"An error occured while trying to connect to Facebook." delegate:nil cancelButtonTitle:@"OK" otherButtonTitle:nil];
            [alertView showInView:self.view];
            alertView = nil;
            return;
        }
        // if email not found (according to docs)...i think this means not found in DB
        // NOT REGISTERED BENTO USER, GO TO PHONE NUMBER SCREEN TO REGISTER USING FB INFO AND ENTERED PHONE NUMBER FROM NEXT SCREEN
        else if (error.code == 404) {
            [[BentoShop sharedInstance] setSignInStatus:NO];
            
            // this really isn't used, since i'm only checking for Register
            [[NSUserDefaults standardUserDefaults] setObject:@"SignIn" forKey:@"RegisterOrSignIn"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [self gotoPhoneNumberScreen:dictUserInfo];
            return;
        }
        // other error
        else {
            NSString *strMessage = [[DataManager shareDataManager] getErrorMessage:errorOp.responseJSON];
            if (strMessage == nil) {
                strMessage = error.localizedDescription;
            }
            
            MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@""
                                                                message:strMessage
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                       otherButtonTitle:nil];
            [alertView showInView:self.view];
            alertView = nil;
            return;
        }
        
    } isJSON:NO];
}

- (void)doSignInWithFacebook
{
    [self hideKeyboard];
    
    [[BentoShop sharedInstance] setSignInStatus:YES];
    
    [self reqFacebookUserInfo];
}

- (IBAction)onSignInWithFacebook:(id)sender
{
    // if user taps on the register button, set retry to NO
    [self doSignInWithFacebook];
}

- (void)gotoPhoneNumberScreen:(NSDictionary *)userInfo
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
    
    if (isValid) {
        [self.btnSignIn setBackgroundColor:[UIColor bentoBrandGreen]];
    }
    else {
        [self.btnSignIn setBackgroundColor:[UIColor bentoButtonGray]];
    }
    
    /*------------------------------------------------------------*/
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([[defaults objectForKey:@"cameFromWhichVC"] isEqualToString:@"cameFromRegister"]) {
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
    if (textField == self.txtEmail) {
        [self.txtPassword becomeFirstResponder];
    }
    else {
        [self doSignin];
    }
    
    return YES;
}

- (void)willShowKeyboard:(NSNotification*)notification
{
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    
    [self collapseScrollView:keyboardFrameBeginRect.size.height];
}

- (void)willChangeKeyboardFrame:(NSNotification *)notification
{
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    
    [self collapseScrollView:keyboardFrameBeginRect.size.height];
}

- (void)willHideKeyboard:(NSNotification *)notification
{
    [self expandScrollView];
}

- (void)collapseScrollView:(float)keyboardHeight
{
    self.svMain.frame = CGRectMake(self.svMain.frame.origin.x, self.svMain.frame.origin.y, self.svMain.frame.size.width, self.view.frame.size.height - self.svMain.frame.origin.y - keyboardHeight);
}

- (void)expandScrollView
{
    self.svMain.frame = CGRectMake(self.svMain.frame.origin.x, self.svMain.frame.origin.y, self.svMain.frame.size.width, self.view.frame.size.height - self.svMain.frame.origin.y);
}

- (void)hideKeyboard
{
    [self.txtEmail resignFirstResponder];
    [self.txtPassword resignFirstResponder];
}

-(void)dismissKeyboard
{
    [self.txtEmail endEditing:YES];
    [self.txtPassword endEditing:YES];
}

#pragma mark MyAlertViewDelegate

- (void)alertView:(MyAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [self performSelector:@selector(doSignInWithFacebook) withObject:nil];
    }
}

#pragma mark Navigation

- (IBAction)onSignUpButton:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"cameFromSignIn" forKey:@"cameFromWhichVC"];
    [defaults synchronize];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *destVC = [storyboard instantiateViewControllerWithIdentifier:@"RegisterID"];
    [self.navigationController pushViewController:destVC animated:YES];
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

- (IBAction)onForgot:(id)sender
{
    NSURL *urlReset = [[AppStrings sharedInstance] getURL:SIGNIN_LINK_RESET];
    if (urlReset != nil && [[UIApplication sharedApplication] canOpenURL:urlReset]) {
        [[UIApplication sharedApplication] openURL:urlReset];
    }
    
    [[Mixpanel sharedInstance] track:@"Tapped On Forgot Password"];
}


@end
