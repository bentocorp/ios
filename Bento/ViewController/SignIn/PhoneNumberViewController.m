//
//  PhoneNumberViewController.m
//  Bento
//
//  Created by hanjinghe on 1/8/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "PhoneNumberViewController.h"

#import "FaqViewController.h"

#import "MyAlertView.h"
#import "JGProgressHUD.h"
#import "SHSPhoneTextField.h"

#import "AppStrings.h"
#import "WebManager.h"
#import "DataManager.h"

#import "BentoShop.h"
#import "Mixpanel.h"

#import "AppDelegate.h"
#import "SVGeocoder.h"

#import "UIColor+CustomColors.h"

#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

@interface PhoneNumberViewController () <CLLocationManagerDelegate>

@property (nonatomic, weak) IBOutlet UILabel *lblTitle;
@property (nonatomic, weak) IBOutlet UIView *viewError;
@property (nonatomic, weak) IBOutlet UILabel *lblError;
@property (nonatomic, weak) IBOutlet UILabel *lblDescription;
@property (nonatomic, weak) IBOutlet UIImageView *ivPhoneNumber;
@property (nonatomic, weak) IBOutlet SHSPhoneTextField *txtPhoneNumber;
@property (nonatomic, weak) IBOutlet UIButton *btnDone;
@property (nonatomic, weak) IBOutlet UIView *viewPhoneNumber;

@end

@implementation PhoneNumberViewController
{
    JGProgressHUD *loadingHUD;
    CLLocationManager *locationManager;
    NSString *currentAddress;
}

- (void)onTextChanged:(UITextField *)textField
{
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.btnDone.layer.cornerRadius = 3;
    self.btnDone.clipsToBounds = YES;
    
    self.lblTitle.text = [[AppStrings sharedInstance] getString:PHNUMBER_TITLE];
    self.lblDescription.text = [[AppStrings sharedInstance] getString:PHNUMBER_DESC];
    
    [self.btnDone setTitle:[[AppStrings sharedInstance] getString:PHNUMBER_BUTTON_DONE] forState:UIControlStateNormal];

    [self showErrorMessage:nil code:ERROR_NONE];
    
    [self.txtPhoneNumber setTextDidChangeBlock:^(UITextField *textField) {
        
        if ([textField.attributedText length] > 0)
        {
            NSMutableAttributedString *newString = [[NSMutableAttributedString alloc] initWithString:textField.text];
            
            [newString addAttribute:NSForegroundColorAttributeName
                              value:[UIColor bentoBrandGreen]
                              range:NSMakeRange([textField.text length]-1, 1)];
            
            textField.attributedText = newString;
        }
        
        [self updateUI];
    }];
    
    [self.txtPhoneNumber.formatter setDefaultOutputPattern:@"(###) ### - ####"];
    
    /*---------------------------LOCATION MANAGER--------------------------*/
    
    // Initialize location manager.
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    [locationManager startUpdatingLocation];
    
    /*---------------------------------------------------------------------*/
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
    
    NSLog(@"CURRENT DATE: %@", currentDate);
    
    return currentDate;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    textField.font = [UIFont fontWithName:@"OpenSans-Bold" size:20];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Faq"]) {
        FaqViewController *vc = segue.destinationViewController;
        vc.contentType = [sender intValue];
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
    [[Mixpanel sharedInstance] timeEvent:@"Viewed Phone Number Screen"];
}

- (void)endTimerOnViewedScreen
{
    [[Mixpanel sharedInstance] track:@"Viewed Phone Number Screen"];
}

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

- (void)checkCurrentMode
{
    if ([[BentoShop sharedInstance] didModeOrDateChange]) {
        [(UINavigationController *)self.presentingViewController popToRootViewControllerAnimated:NO];
        [self dismissViewControllerAnimated:YES completion:nil];
        
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)willShowKeyboard:(NSNotification*)notification
{
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    
    [self repositionPhoneView:keyboardFrameBeginRect.size.height];
}

- (void)willChangeKeyboardFrame:(NSNotification *)notification
{
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    
    [self repositionPhoneView:keyboardFrameBeginRect.size.height];
}

- (void)willHideKeyboard:(NSNotification *)notification
{
    [UIView animateWithDuration:0.3f animations:^{
        self.viewPhoneNumber.center = CGPointMake(self.viewPhoneNumber.center.x, self.view.frame.size.height / 2);
    } completion:^(BOOL finished) {
    }];
}

- (void)repositionPhoneView:(float) keyboardHeight
{
    [UIView animateWithDuration:0.3f animations:^{
        
        float newCenterY = self.view.frame.size.height - keyboardHeight - self.viewPhoneNumber.frame.size.height / 2;
        
        if(newCenterY < self.viewPhoneNumber.center.y) {
            self.viewPhoneNumber.center = CGPointMake(self.viewPhoneNumber.center.x, newCenterY);
        }
        
    } completion:^(BOOL finished) {
        
    }];
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
            
            self.ivPhoneNumber.image = [UIImage imageNamed:@"register_icon_phone"];
            self.txtPhoneNumber.textColor = correctColor;
        }
            break;
            
        case ERROR_PHONENUMBER:
        {
            self.viewError.hidden = NO;
            
            self.ivPhoneNumber.image = [UIImage imageNamed:@"register_icon_phone_err"];
            self.txtPhoneNumber.textColor = errorColor;
        }
            break;
            
        default:
            break;
    }
}

- (IBAction)onBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)processRegister
{
    NSString *strFirstName = self.userInfo[@"first_name"];
    NSString *strLastName = self.userInfo[@"last_name"];
    NSString *strMailAddr = self.userInfo[@"email"];
    NSString *strId = self.userInfo[@"id"];
    NSString *strGender = self.userInfo[@"gender"];
    NSString *strPhotoURL = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", strId];
    NSString *strPhoneNumber = self.txtPhoneNumber.text;
    NSString *strAccessToken = self.userInfo[@"strAccessToken"];
    
    NSString *strAgeRange;
    NSDictionary *dictAgeRange = self.userInfo[@"dictAgeRange"];
    if (dictAgeRange != nil)
    {
        if ([dictAgeRange objectForKey:@"min"] != nil && [dictAgeRange objectForKey:@"max"] != nil) {
            strAgeRange = [NSString stringWithFormat:@"%@-%@", [dictAgeRange objectForKey:@"min"], [dictAgeRange objectForKey:@"max"]];
        }
        else if ([dictAgeRange objectForKey:@"min"] != nil) {
            strAgeRange = [NSString stringWithFormat:@"%@+", [dictAgeRange objectForKey:@"min"]];
        }
        else if ([dictAgeRange objectForKey:@"max"] != nil) {
            strAgeRange = [NSString stringWithFormat:@"-%@", [dictAgeRange objectForKey:@"max"]];
        }
        else {
            strAgeRange = @"";
        }
    }
    
    if (strGender == nil)
        strGender = @"";
    
    NSDictionary *request = @{
                              @"firstname" : strFirstName,
                              @"lastname" : strLastName,
                              @"email" : strMailAddr,
                              @"phone" : strPhoneNumber,
                              @"fb_id" : strId,
                              @"fb_profile_pic" : strPhotoURL,
                              @"fb_gender" : strGender,
                              @"fb_age_range" : strAgeRange,
                              @"fb_token" : strAccessToken,
                              };
    
    
    NSString *source;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"SourceOfInstall"] != nil) {
        source = [[NSUserDefaults standardUserDefaults] objectForKey:@"SourceOfInstall"];
    }
    
    NSString *registerOrSignIn = [[NSUserDefaults standardUserDefaults] objectForKey:@"RegisterOrSignIn"];
    
    /*------------------TEST DATA LOG FOR MIXPANEL BEFORE PROCESSING*-----------------*/
    NSLog(@"%@, %@, %@, %@, %@, %@, %@", registerOrSignIn, source, [self getCurrentDate], currentAddress, [NSString stringWithFormat:@"%@ %@", strFirstName, strLastName], strMailAddr, strPhoneNumber);
    /*--------------------------------------------------------------------------------*/
    
    NSDictionary *dicRequest = @{@"data" : [request jsonEncodedKeyValueString]};
    WebManager *webManager = [[WebManager alloc] init];
    
    loadingHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
    loadingHUD.textLabel.text = @"Registering...";
    [loadingHUD showInView:self.view];
    
    NSString *strRequest = [NSString stringWithFormat:@"%@/user/fbsignup", SERVER_URL];
    
    [webManager AsyncProcess:strRequest method:POST parameters:dicRequest success:^(MKNetworkOperation *networkOperation) {
        
        [loadingHUD dismiss];
        
        NSDictionary *response = networkOperation.responseJSON;
        [[DataManager shareDataManager] setUserInfo:response];
        
        NSString *strRequest = [NSString stringWithFormat:@"%@/user/fblogin", SERVER_URL];
        [[NSUserDefaults standardUserDefaults] setObject:strRequest forKey:@"apiName"];
        
        NSDictionary *fbloginRequest = @{
                                         @"email" : strMailAddr,
                                         @"fb_id" : strId,
                                         @"fb_token" : strAccessToken,
                                       };
        
        NSDictionary *saveRequest = @{@"data" : [fbloginRequest jsonEncodedKeyValueString]};
        [[NSUserDefaults standardUserDefaults] setObject:saveRequest forKey:@"loginRequest"];
        [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"registeredLogin"];
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"new_phone_number"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[BentoShop sharedInstance] setSignInStatus:YES];

/*-----------------------------MIXPANEL-------------------------------*/
        
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        
        if ([registerOrSignIn isEqualToString:@"Register"]) {
            // link custom id with default id
            [mixpanel createAlias:strMailAddr forDistinctID:mixpanel.distinctId];
        }
        
        // identify user for current session
        [mixpanel identify:strMailAddr];
        
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
                               @"$name": [NSString stringWithFormat:@"%@ %@", strFirstName, strLastName],
                               @"$email": strMailAddr,
                               @"$phone": strPhoneNumber,
                               @"Installed Source":sourceFinal,
                               }];
        
        [mixpanel track:@"Completed Registration"];
        
/*--------------------------------------------------------------------*/
        
        [self showErrorMessage:nil code:ERROR_NONE];
        
        [self processAutoLogin];
        
        [self dissmodal];
        
    } failure:^(MKNetworkOperation *errorOp, NSError *error) {
        
        [loadingHUD dismiss];
        
        NSString *strMessage = [[DataManager shareDataManager] getErrorMessage:errorOp.responseJSON];
        if (strMessage == nil)
            strMessage = error.localizedDescription;
        
        MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"" message:strMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitle:nil];
        [alertView showInView:self.view];
        alertView = nil;
        return;
        
    } isJSON:NO];
}

- (void)processAutoLogin
{
    NSString *strAPIName = [[NSUserDefaults standardUserDefaults] objectForKey:@"apiName"];
    NSDictionary *dicRequest = [[NSUserDefaults standardUserDefaults] objectForKey:@"loginRequest"];
    
    NSLog(@"auto login dicRequest - %@", dicRequest);
    
    WebManager *webManager = [[WebManager alloc] init];
    
    [webManager AsyncProcess:strAPIName method:POST parameters:dicRequest success:^(MKNetworkOperation *networkOperation)
     {
         NSDictionary *response = networkOperation.responseJSON;
         [[DataManager shareDataManager] setUserInfo:response];
         
         NSLog(@"auto login response - %@", response);
         
         /*-----------------------------MIXPANEL-------------------------------*/
         
         Mixpanel *mixpanel = [Mixpanel sharedInstance];
         
         // identify user for current session
         [mixpanel identify:response[@"email"]];
         
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
         
         // current address
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
         
         /*--------------------------------------------------------------------*/
         
         [[BentoShop sharedInstance] setSignInStatus:YES];
         
     } failure:^(MKNetworkOperation *errorOp, NSError *error) {
         
         [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"apiName"];
         [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"loginRequest"];
         [[NSUserDefaults standardUserDefaults] synchronize];
         
         NSString *strMessage = [[DataManager shareDataManager] getErrorMessage:errorOp.responseJSON];
         if (strMessage == nil)
             strMessage = error.localizedDescription;
         
         MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"" message:strMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitle:nil];
         [alertView showInView:self.view];
         alertView = nil;
         
     } isJSON:NO];
}


- (IBAction)onDone:(id)sender
{
    NSString *strPhoneNumber = self.txtPhoneNumber.text;
    if (strPhoneNumber.length == 0) {
        [self showErrorMessage:@"Please enter a phone number." code:ERROR_PHONENUMBER];
        return;
    }
    
    if (![DataManager isValidPhoneNumber:strPhoneNumber]) {
        [self showErrorMessage:@"Please enter a valid phone number." code:ERROR_PHONENUMBER];
        return;
    }
    
    [self processRegister];
}

- (void)updateUI
{
    NSString *strPhoneNumber = self.txtPhoneNumber.text;
    if (strPhoneNumber.length > 0 && [DataManager isValidPhoneNumber:strPhoneNumber])
    {
        self.btnDone.enabled = YES;
        [self.btnDone setBackgroundColor:[UIColor bentoBrandGreen]];
    }
    else
    {
//        self.btnDone.enabled = NO;
        [self.btnDone setBackgroundColor:[UIColor bentoButtonGray]];
    }
}

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
            self.txtPhoneNumber.textColor = correctColor;
            self.ivPhoneNumber.image = [UIImage imageNamed:@"register_icon_phone"];
        }
            break;
            
        case ERROR_PHONENUMBER:
        {
            self.viewError.hidden = NO;
            self.txtPhoneNumber.textColor = errorColor;
            self.ivPhoneNumber.image = [UIImage imageNamed:@"register_icon_phone_err"];
        }
            break;
            
        default:
        case ERROR_UNKNOWN:
        {
            self.viewError.hidden = NO;
            self.txtPhoneNumber.textColor = correctColor;
            self.ivPhoneNumber.image = [UIImage imageNamed:@"register_icon_phone"];
        }
            break;
    }
}

- (void)dissmodal
{
    // dismiss to home page
    [(UINavigationController *)self.presentingViewController popToRootViewControllerAnimated:NO];
    [self dismissViewControllerAnimated:YES completion:nil];
    
    // pop back to home page
    [self.navigationController popToViewController:[[self.navigationController viewControllers] objectAtIndex:1] animated:YES];
}

@end
