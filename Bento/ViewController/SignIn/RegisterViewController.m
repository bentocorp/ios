//
//  RegisterViewController.m
//  Bento
//
//  Created by hanjinghe on 1/7/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "RegisterViewController.h"

#import "FaqViewController.h"
#import "PhoneNumberViewController.h"
#import "SignInViewController.h"

#import "MyAlertView.h"

#import "JGProgressHUD.h"
#import "SHSPhoneTextField.h"

#import "AppStrings.h"
#import "WebManager.h"
#import "DataManager.h"
#import "Mixpanel.h"

#import "BentoShop.h"
#import "SVGeocoder.h"

#import "CompleteOrderViewController.h"

#import "UIColor+CustomColors.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

@interface RegisterViewController () <MyAlertViewDelegate, CLLocationManagerDelegate>

@property (nonatomic, weak) IBOutlet UILabel *lblTitle;

@property (nonatomic, weak) IBOutlet UIScrollView *svMain;

@property (nonatomic, weak) IBOutlet UIView *viewError;
@property (nonatomic, weak) IBOutlet UILabel *lblError;

@property (nonatomic, weak) IBOutlet UIView *viewRegisterWithFacebook;

@property (nonatomic, weak) IBOutlet UIButton *btnRegister;

@property (nonatomic, weak) IBOutlet UITextField *txtYourname;
@property (nonatomic, weak) IBOutlet UITextField *txtEmail;
@property (nonatomic, weak) IBOutlet SHSPhoneTextField *txtPhoneNumber;
@property (nonatomic, weak) IBOutlet UITextField *txtPassword;

@property (nonatomic, weak) IBOutlet UIImageView *ivYourname;
@property (nonatomic, weak) IBOutlet UIImageView *ivEmail;
@property (nonatomic, weak) IBOutlet UIImageView *ivPhoneNumber;
@property (nonatomic, weak) IBOutlet UIImageView *ivPassword;

@property (nonatomic, weak) IBOutlet UIButton *btnPolicy;
@property (nonatomic, weak) IBOutlet UIButton *btnTerms;

@property (nonatomic, weak) IBOutlet UILabel *signInLabel;
@property (nonatomic, weak) IBOutlet UIButton *signInButton;

@end

@implementation RegisterViewController
{
    UITextField *_activeField;
    BOOL beganRegistration;
    JGProgressHUD *loadingHUD;
    Mixpanel *mixpanel;
    
    CLLocationManager *locationManager;
    NSString *currentAddress;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    mixpanel = [Mixpanel sharedInstance];
    
    self.lblTitle.text = [[AppStrings sharedInstance] getString:SIGNUP_TITLE];
    [self.btnRegister setTitle:[[AppStrings sharedInstance] getString:SIGNUP_BUTTON_SIGNUP] forState:UIControlStateNormal];
    [self.btnPolicy setTitle:[[AppStrings sharedInstance] getString:SIGNUP_LINK_POLICY] forState:UIControlStateNormal];
    [self.btnTerms setTitle:[[AppStrings sharedInstance] getString:SIGNUP_LINK_TERMS] forState:UIControlStateNormal];
    
    self.viewRegisterWithFacebook.layer.cornerRadius = 3;
    self.viewRegisterWithFacebook.clipsToBounds = YES;
    
    self.btnRegister.layer.cornerRadius = 3;
    self.btnRegister.clipsToBounds = YES;
    
    self.svMain.contentSize = CGSizeMake(self.svMain.frame.size.width, 504);

    [self.txtPhoneNumber setTextDidChangeBlock:^(UITextField *textField) {
        
        // set the last character in attributed text to have a bolder font
        if ([textField.attributedText length] > 0) {
            NSMutableAttributedString *newString = [[NSMutableAttributedString alloc] initWithString:textField.text];
            [newString addAttribute:NSForegroundColorAttributeName value:[UIColor bentoBrandGreen] range:NSMakeRange([textField.text length]-1, 1)];
            
            textField.attributedText = newString;
        }
        
        [self updateUI];
    }];
    
    self.txtPhoneNumber.tag = 101;
    
    [self.txtPhoneNumber.formatter setDefaultOutputPattern:@"(###) ### - ####"];
//    self.txtPhoneNumber.formatter.prefix = @"+1 ";
    
    // Tap
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    
    //
    _activeField = nil;
    
    /*---------------------------LOCATION MANAGER--------------------------*/
    
    // Initialize location manager.
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    [locationManager startUpdatingLocation];
    
    /*---------------------------------------------------------------------*/
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
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
    
    [self showErrorWithString:nil code:ERROR_NONE];
    
    [self updateUI];
    
    /*----------------*/
    
    // this should run when signed in from checkout
    if ([[DataManager shareDataManager] getUserInfo] != nil) {
        [self.navigationController popViewControllerAnimated:NO];
    }
    
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
    [[Mixpanel sharedInstance] timeEvent:@"Viewed Register Screen"];
}

- (void)endTimerOnViewedScreen
{
    [[Mixpanel sharedInstance] track:@"Viewed Register Screen"];
}

#pragma mark UI

- (void)showSignUpButton
{
    if (self.svMain.frame.size.height < self.btnRegister.frame.origin.y + self.btnRegister.frame.size.height - _activeField.frame.origin.y)
        return;
    
    BOOL isShowingButton = NO;
    CGFloat bottomOfButton = self.btnRegister.frame.origin.y + self.btnRegister.frame.size.height;
    if (bottomOfButton < self.svMain.contentOffset.y + self.svMain.frame.size.height)
        isShowingButton = YES;
    
    if (isShowingButton)
        return;
    
    self.svMain.contentOffset = CGPointMake(self.svMain.contentOffset.x,
                                            bottomOfButton + 20 - self.svMain.frame.size.height);
}

- (void)updateUI
{
    NSString *strUserName = self.txtYourname.text;
    NSString *strEmail = self.txtEmail.text;
    NSString *strPhoneNumber = self.txtPhoneNumber.text;
    NSString *strPassword = self.txtPassword.text;
    
    BOOL isValid = (strUserName.length > 0 &&
                    strEmail.length > 0 &&
                    [DataManager isValidMailAddress:strEmail] &&
                    strPhoneNumber.length > 0 &&
                    [DataManager isValidPhoneNumber:strPhoneNumber] &&
                    strPassword.length > 0);
    
    //    self.btnRegister.enabled = isValid;
    if (isValid) {
        [self.btnRegister setBackgroundColor:[UIColor bentoBrandGreen]];
    }
    else {
        [self.btnRegister setBackgroundColor:[UIColor bentoButtonGray]];
    }
    
    /*------------------------------------------------------------*/
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([[defaults objectForKey:@"cameFromWhichVC"] isEqualToString:@"cameFromSignIn"]) {
        // hide
        self.signInButton.hidden = YES;
        self.signInLabel.hidden = YES;
    }
}

#pragma mark Location Manager

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

#pragma mark Get Date

-(NSString *)getCurrentDate
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"M/d/yyyy";
    NSString *currentDate = [formatter stringFromDate:[NSDate date]];
    
    NSLog(@"CURRENT DATE: %@", currentDate);
    
    return currentDate;
}

#pragma mark Connection Handler

- (void)noConnection
{
    if (loadingHUD == nil) {
        
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

#pragma mark Mode Check

- (void)checkCurrentMode
{
    if ([[BentoShop sharedInstance] didModeOrDateChange]) {
        
        [(UINavigationController *)self.presentingViewController popToRootViewControllerAnimated:NO];
        [self dismissViewControllerAnimated:YES completion:nil];
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

#pragma mark Facebook Login/Register

- (void)reqFacebookUserInfo
{
    loadingHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
    loadingHUD.textLabel.text = @"Logging in...";
    [loadingHUD showInView:self.view];
    
    //    //Token is already available
    //    if ([FBSDKAccessToken currentAccessToken] ) {
    //
    //        NSLog(@"token is already available");
    //    }
    
    //    if ([[FBSDKAccessToken currentAccessToken] hasGranted:@"publish_actions"]) {
    //        // publish content
    //
    //        NSLog(@"has granted");
    //    }
    
    /*---------------------------------------------REQUEST PERMISSIONS/AUTHORIZATION FROM FB-----------------------------------------*/
    // note: displays a webview,
    // first time - user needs to login with email/password
    // then they can choose which permissions to grant (public profile is mandatory, but email is optional)
    // if they chose to not provide email (strEmail == nil), app will prompt an error alert and allow them to retry because
    // once they authorized public profile before, FB login won't ask for it again when choosing permissions to grant
    // not providing email this time would disable the OK button in the FB webview - can't continue further
    // if all info have been authorized before, "You have already authorize Bento" would be shown in webview
    // if 'done' or 'cancel' (both sets result.isCancelled to yes), dismiss loadingHUD, and cancel out login
    
    // but what if user wants to log into another account? they can manually log out from safari
    
    FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
    [login logInWithReadPermissions:@[@"public_profile", @"email"] fromViewController:self handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
        
        NSLog(@"token - %@", result.token.tokenString);
        NSLog(@"error - %@", error);
        
        NSString *strAccessToken = result.token.tokenString;
        
        if (error == nil) {
            
            if ([result.declinedPermissions containsObject:@"publish_actions"]) {
                NSLog(@"Declined");
            }
            if (result.isCancelled) {
                [loadingHUD dismiss];
                
                NSLog(@"Cancelled");
            }
            else {
                NSLog(@"Logged in");
                
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
                     
                     NSLog(@"user info - %@", dictUserInfo);
                     
                     NSDictionary* loginInfo = @{
                                                 @"email": strEmail,
                                                 @"fb_token": strAccessToken
                                                 };
                     
                     NSDictionary *dicRequest = @{
                                                  @"data":[loginInfo jsonEncodedKeyValueString]
                                                  };
                     
                     NSLog(@"Facebook login dictRequest - %@", dicRequest);
                     
                     /*----------------------------------------------------API CALL TO BACKEND------------------------------------------------*/
                     
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
                         [pref setObject:nil forKey:@"new_phone_number"];
                         [pref synchronize];
                         
                         [self trackLogin:strEmail responseJSON:response];
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
                     
                     /*^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^API CALL TO BACKEND^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^*/
                 }];
                
                /*^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^CALL TO GRAPH API^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^*/
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
}

- (void)doRegisterWithFacebook
{
    [self closeKeyboard];
    
    [[BentoShop sharedInstance] setSignInStatus:YES];
    
    [self reqFacebookUserInfo];
}

- (IBAction)onRegisterWithFacebook:(id)sender
{
    [self doRegisterWithFacebook];
}

- (void)trackLogin:(NSString *)strEmail responseJSON:(NSDictionary *)response
{
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
                           @"Installed Source":sourceFinal,
                           @"Last Login Address": currentAddressFinal
                           }];
    
    [mixpanel track:@"Logged In"];
}

#pragma mark Email Register

- (void)processRegister
{
    NSString *strEmail = self.txtEmail.text;
    NSString *strPassword = self.txtPassword.text;
    NSString *strUserName = self.txtYourname.text;
    NSString *strPhoneNumber = self.txtPhoneNumber.text;
    
    NSDictionary* loginInfo = @{
                                @"name" : strUserName,
                                @"email" : strEmail,
                                @"phone" : strPhoneNumber,
                                @"password" : strPassword,
                                };
    
    NSString *source;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"SourceOfInstall"] != nil) {
        source = [[NSUserDefaults standardUserDefaults] objectForKey:@"SourceOfInstall"];
    }
    
    /*------------------TEST DATA LOG FOR MIXPANEL BEFORE PROCESSING*-----------------*/
    NSLog(@"%@, %@, %@, %@, %@, %@, %@", mixpanel.distinctId, source, [self getCurrentDate], currentAddress, strUserName, strEmail, strPhoneNumber);
    /*--------------------------------------------------------------------------------*/
    
    NSDictionary *dicRequest = @{@"data" : [loginInfo jsonEncodedKeyValueString]};
    WebManager *webManager = [[WebManager alloc] init];
    
    loadingHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
    loadingHUD.textLabel.text = @"Registering...";
    [loadingHUD showInView:self.view];
    
    NSString *strRequest = [NSString stringWithFormat:@"%@/user/signup", SERVER_URL];
    [webManager AsyncProcess:strRequest method:POST parameters:dicRequest success:^(MKNetworkOperation *networkOperation) {
        [loadingHUD dismiss];
        
        NSUserDefaults *pref = [NSUserDefaults standardUserDefaults];
        NSString *strRequest = [NSString stringWithFormat:@"%@/user/login", SERVER_URL];
        [pref setObject:strRequest forKey:@"apiName"];
        
        NSDictionary *loginRequest = @{
                                       @"email" : strEmail,
                                       @"password" : strPassword,
                                       };
        
        NSDictionary *saveRequest = @{@"data" : [loginRequest jsonEncodedKeyValueString]};
        [pref setObject:saveRequest forKey:@"loginRequest"];
        [pref setObject:nil forKey:@"new_phone_number"];
        [pref setObject:@"YES" forKey:@"registeredLogin"];
        [pref synchronize];
        
        [self showErrorWithString:nil code:ERROR_NONE];
        
        [self signInWithRegisteredData:dicRequest];
        
/*-----------------------------MIXPANEL-------------------------------*/
        
        // link custom alias to default distintId
        [mixpanel createAlias:strEmail forDistinctID:mixpanel.distinctId];
        
        [mixpanel identify:strEmail];
        
        // reregister deviceToken to server
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"deviceToken"] != nil) {
            
            NSData *deviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"deviceToken"];
            [mixpanel.people addPushDeviceToken:deviceToken];
            
            NSLog(@"Device Token - %@", deviceToken);
        }
        
        NSString *currentDate = [self getCurrentDate];
        NSString *sourceFinal;
        NSString *currentDateFinal;
        NSString *currentAddressFinal;
        
        if (source != nil) {
            sourceFinal = source;
        }
        else {
            sourceFinal = @"N/A";
        }
        
        if (currentDate != nil) {
            currentDateFinal = currentDate;
        }
        else {
            currentDateFinal = @"N/A";
        }
        
        if (currentAddress != nil) {
            currentAddressFinal = currentAddress;
        }
        else {
            currentAddressFinal = @"N/A";
        }
        
        // set initial properties once
        [mixpanel.people setOnce:@{
                                   @"$created": currentDateFinal,
                                   @"Sign Up Address": currentAddressFinal
                                   }];
        
        // set properties
        [mixpanel.people set:@{
                               @"$name": strUserName,
                               @"$email": strEmail,
                               @"$phone": strPhoneNumber,
                               @"Installed Source":sourceFinal
                               }];
        
        [mixpanel track:@"Completed Registration"];

/*---------------------------------------------------------------------*/
        
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        [self.navigationController popViewControllerAnimated:YES];
        
    } failure:^(MKNetworkOperation *errorOp, NSError *error) {
        
        [loadingHUD dismiss];

        NSString *strMessage = [[DataManager shareDataManager] getErrorMessage:errorOp.responseJSON];
        if (strMessage == nil)
            strMessage = error.localizedDescription;
        
        if (error.code == 400)
            [self showErrorWithString:strMessage code:ERROR_PASSWORD];
        else if (error.code == 409)
            [self showErrorWithString:strMessage code:ERROR_NO_EMAIL];
        else
            [self showErrorWithString:strMessage code:ERROR_EMAIL];
        
    } isJSON:NO];
}

-(void)signInWithRegisteredData:(NSDictionary *)registeredData
{
    WebManager *webManager = [[WebManager alloc] init];
    
    NSString *strRequest = [NSString stringWithFormat:@"%@/user/login", SERVER_URL];
    [webManager AsyncProcess:strRequest method:POST parameters:registeredData success:^(MKNetworkOperation *networkOperation) {
        
        NSDictionary *response = networkOperation.responseJSON;
        [[DataManager shareDataManager] setUserInfo:response];
        NSLog(@"new user data - %@", [[DataManager shareDataManager] getUserInfo]);
        
        NSUserDefaults *pref = [NSUserDefaults standardUserDefaults];
        [pref setObject:strRequest forKey:@"apiName"];
        [pref setObject:registeredData forKey:@"loginRequest"];
        [pref setObject:nil forKey:@"new_phone_number"];
        [pref synchronize];
        
        [[BentoShop sharedInstance] setSignInStatus:YES];
        
        [self dismissViewControllerAnimated:YES completion:nil];
        
    } failure:^(MKNetworkOperation *errorOp, NSError *error) {
        
    } isJSON:NO];
}

- (void)doRegister
{
    [self closeKeyboard];
    
    if (self.txtYourname.text.length == 0)
    {
        [self showErrorWithString:@"Please enter a valid user name." code:ERROR_USERNAME];
        return;
    }
    
    NSString *strEmail = self.txtEmail.text;
    if (strEmail.length == 0)
    {
        [self showErrorWithString:@"Please enter a email address." code:ERROR_EMAIL];
        return;
    }
    
    if (![DataManager isValidMailAddress:strEmail])
    {
        [self showErrorWithString:@"Please enter a valid email address." code:ERROR_EMAIL];
        return;
    }
    
    NSString *strPhoneNumber = self.txtPhoneNumber.text;
    if (strPhoneNumber.length == 0)
    {
        [self showErrorWithString:@"Please enter a phone number." code:ERROR_PHONENUMBER];
        return;
    }
    
    if (![DataManager isValidPhoneNumber:strPhoneNumber])
    {
        [self showErrorWithString:@"Please enter a valid phone number." code:ERROR_PHONENUMBER];
        return;
    }
    
    if (self.txtPassword.text.length < 6) // min character of 6
    {
        [self showErrorWithString:@"Please enter a minimum of 6 characters." code:ERROR_PASSWORD];
        return;
    }
    
    [self processRegister];
}

#pragma mark Text Error Handler

- (void) showErrorWithString:(NSString *)errorMsg code:(int)errorCode
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
            
            self.txtYourname.textColor = correctColor;
            self.txtEmail.textColor = correctColor;
            self.txtPhoneNumber.textColor = correctColor;
            self.txtPassword.textColor = correctColor;
            
            self.ivYourname.image = [UIImage imageNamed:@"register_icon_username"];
            self.ivEmail.image = [UIImage imageNamed:@"register_icon_email"];
            self.ivPhoneNumber.image = [UIImage imageNamed:@"register_icon_phone"];
            self.ivPassword.image = [UIImage imageNamed:@"register_icon_password"];
        }
            break;
            
        case ERROR_USERNAME:
        {
            self.viewError.hidden = NO;
            
            self.txtYourname.textColor = errorColor;
            self.txtEmail.textColor = correctColor;
            self.txtPhoneNumber.textColor = correctColor;
            self.txtPassword.textColor = correctColor;
            
            self.ivYourname.image = [UIImage imageNamed:@"register_icon_username_err"];
            self.ivEmail.image = [UIImage imageNamed:@"register_icon_email"];
            self.ivPhoneNumber.image = [UIImage imageNamed:@"register_icon_phone"];
            self.ivPassword.image = [UIImage imageNamed:@"register_icon_password"];
        }
            break;
            
        case ERROR_EMAIL:
        {
            self.viewError.hidden = NO;
            
            self.txtYourname.textColor = correctColor;
            self.txtEmail.textColor = errorColor;
            self.txtPhoneNumber.textColor = correctColor;
            self.txtPassword.textColor = correctColor;
            
            self.ivYourname.image = [UIImage imageNamed:@"register_icon_username"];
            self.ivEmail.image = [UIImage imageNamed:@"register_icon_email_err"];
            self.ivPhoneNumber.image = [UIImage imageNamed:@"register_icon_phone"];
            self.ivPassword.image = [UIImage imageNamed:@"register_icon_password"];
        }
            break;
            
        case ERROR_NO_EMAIL:
        {
            self.viewError.hidden = NO;
            
            self.txtYourname.textColor = correctColor;
            self.txtEmail.textColor = errorColor;
            self.txtPhoneNumber.textColor = correctColor;
            self.txtPassword.textColor = correctColor;
            
            self.ivYourname.image = [UIImage imageNamed:@"register_icon_username"];
            self.ivEmail.image = [UIImage imageNamed:@"register_icon_email_err"];
            self.ivPhoneNumber.image = [UIImage imageNamed:@"register_icon_phone"];
            self.ivPassword.image = [UIImage imageNamed:@"register_icon_password"];
        }
            break;
            
        case ERROR_PHONENUMBER:
        {
            self.viewError.hidden = NO;
            
            self.txtYourname.textColor = correctColor;
            self.txtEmail.textColor = correctColor;
            self.txtPhoneNumber.textColor = errorColor;
            self.txtPassword.textColor = correctColor;
            
            self.ivYourname.image = [UIImage imageNamed:@"register_icon_username"];
            self.ivEmail.image = [UIImage imageNamed:@"register_icon_email"];
            self.ivPhoneNumber.image = [UIImage imageNamed:@"register_icon_phone_err"];
            self.ivPassword.image = [UIImage imageNamed:@"register_icon_password"];
        }
            break;
            
        case ERROR_PASSWORD:
        {
            self.viewError.hidden = NO;
            
            self.txtYourname.textColor = correctColor;
            self.txtEmail.textColor = correctColor;
            self.txtPhoneNumber.textColor = correctColor;
            self.txtPassword.textColor = errorColor;
            
            self.ivYourname.image = [UIImage imageNamed:@"register_icon_username"];
            self.ivEmail.image = [UIImage imageNamed:@"register_icon_email"];
            self.ivPhoneNumber.image = [UIImage imageNamed:@"register_icon_phone"];
            self.ivPassword.image = [UIImage imageNamed:@"register_icon_password_err"];
        }
            break;
            
        default:
        case ERROR_UNKNOWN:
        {
            self.viewError.hidden = NO;
            
            self.txtYourname.textColor = correctColor;
            self.txtEmail.textColor = correctColor;
            self.txtPhoneNumber.textColor = correctColor;
            self.txtPassword.textColor = correctColor;
            
            self.ivYourname.image = [UIImage imageNamed:@"register_icon_username"];
            self.ivEmail.image = [UIImage imageNamed:@"register_icon_email"];
            self.ivPhoneNumber.image = [UIImage imageNamed:@"register_icon_phone"];
            self.ivPassword.image = [UIImage imageNamed:@"register_icon_password"];
        }
            break;
    }
}

#pragma mark UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    _activeField = textField;
    [self showSignUpButton];
    
    // Track Began Registration
    // only call once per page view
    if (beganRegistration == NO)
    {
        [mixpanel track:@"Began Registration" properties:nil];
        
        beganRegistration = YES;
        
        NSLog(@"BEGAN REGISTRATION");
    }
    
    //
    
    if (textField.tag == 101) {
        textField.font = [UIFont fontWithName:@"OpenSans-Bold" size:20];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    _activeField = nil;
    
    NSString *strEmail = self.txtEmail.text;
    NSString *strPhoneNumber = self.txtPhoneNumber.text;
    
    if (strEmail.length != 0 && ![DataManager isValidMailAddress:strEmail])
    {
        [self showErrorWithString:@"Please enter a valid email address." code:ERROR_EMAIL];
        return;
    }
    
    if (strPhoneNumber.length != 0 && ![DataManager isValidPhoneNumber:strPhoneNumber])
    {
        [self showErrorWithString:@"Please enter a valid phone number." code:ERROR_PHONENUMBER];
        return;
    }
    
    if (self.txtPassword.text.length != 0 && self.txtPassword.text.length < 6)
    {
        [self showErrorWithString:@"Password requires a minimum of 6 characters." code:ERROR_PASSWORD];
        return;
    }
    
    [self showErrorWithString:nil code:ERROR_NONE];
    
    //
    
    if (textField.tag == 101) {
        textField.font = [UIFont fontWithName:@"OpenSans" size:14];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.txtYourname)
        [self.txtEmail becomeFirstResponder];
    else if (textField == self.txtEmail)
        [self.txtPhoneNumber becomeFirstResponder];
    else if (textField == self.txtPhoneNumber)
        [self.txtPassword becomeFirstResponder];
    else
        [self doRegister];
    
    return YES;
}

- (void)closeKeyboard
{
    [self.txtYourname resignFirstResponder];
    [self.txtEmail resignFirstResponder];
    [self.txtPhoneNumber resignFirstResponder];
    [self.txtPassword resignFirstResponder];
    
    _activeField = nil;
}

-(void)dismissKeyboard
{
    [self.txtEmail endEditing:YES];
    [self.txtYourname endEditing:YES];
    [self.txtPhoneNumber endEditing:YES];
    [self.txtPassword endEditing:YES];
}

- (IBAction)onTextChanged:(id)sender
{
    [self updateUI];
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

- (void) collapseScrollView:(float)keyboardHeight
{
    self.svMain.frame = CGRectMake(self.svMain.frame.origin.x, self.svMain.frame.origin.y, self.svMain.frame.size.width, self.view.frame.size.height - self.svMain.frame.origin.y - keyboardHeight);
    
    [self showSignUpButton];
}

- (void) expandScrollView
{
    self.svMain.frame = CGRectMake(self.svMain.frame.origin.x, self.svMain.frame.origin.y, self.svMain.frame.size.width, self.view.frame.size.height - self.svMain.frame.origin.y);
}

#pragma mark MyAlertViewDelegate

- (void)alertView:(MyAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [self performSelector:@selector(doRegisterWithFacebook) withObject:nil];
    }
}

#pragma mark Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([segue.identifier isEqualToString:@"Terms"])
    {
        FaqViewController *vc = segue.destinationViewController;
        vc.contentType = [sender intValue];
    }
    else if ([segue.identifier isEqualToString:@"PhoneNumber"])
    {
        PhoneNumberViewController *vcPhoneNumber = segue.destinationViewController;
        vcPhoneNumber.userInfo = sender;
    }
    else if([segue.identifier isEqualToString:@"SignIn"])
    {
        SignInViewController *vcSignIn = segue.destinationViewController;
        
        if(sender != nil)
            vcSignIn.txtEmail.text = sender;
        else
            vcSignIn.txtEmail.text = @"";
    }
}

- (IBAction)onSignIn:(id)sender
{
    [self closeKeyboard];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"cameFromRegister" forKey:@"cameFromWhichVC"];
    [defaults synchronize];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *destVC = [storyboard instantiateViewControllerWithIdentifier:@"SignInID"];
    [self.navigationController pushViewController:destVC animated:YES];
}

- (IBAction)onBack:(id)sender
{
    [self closeKeyboard];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)gotoPhoneNumberScreen:(NSDictionary *)userInfo
{
    [self performSegueWithIdentifier:@"PhoneNumber" sender:userInfo];
}

- (IBAction)onRegister:(id)sender
{
    [self doRegister];
}

- (IBAction)onPrivacyPolicy:(id)sender
{
    [self closeKeyboard];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    FaqViewController *destVC = [storyboard instantiateViewControllerWithIdentifier:@"FAQID"];
    destVC.contentType = CONTENT_PRIVACY;
    [self.navigationController pushViewController:destVC animated:YES];
}

- (IBAction)onTermsAndConditions:(id)sender
{
    [self closeKeyboard];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    FaqViewController *destVC = [storyboard instantiateViewControllerWithIdentifier:@"FAQID"];
    destVC.contentType = CONTENT_TERMS;
    [self.navigationController pushViewController:destVC animated:YES];
}

@end
