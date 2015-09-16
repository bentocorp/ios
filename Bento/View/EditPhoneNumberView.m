//
//  EditPhoneNumberView.m
//  Bento
//
//  Created by Joseph Lau on 9/4/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "EditPhoneNumberView.h"
#import "MyAlertView.h"
#import "JGProgressHUD.h"
#import "AppStrings.h"
#import "WebManager.h"
#import "DataManager.h"
#import "Mixpanel.h"
#import "UIColor+CustomColors.h"
#import "SHSPhoneTextField.h"


@interface EditPhoneNumberView() <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIView *viewEnterPhoneNumber;
@property (weak, nonatomic) IBOutlet UIView *viewConfirmPhoneNumber;

@property (weak, nonatomic) IBOutlet SHSPhoneTextField *txtEnterPhoneNumber;
@property (weak, nonatomic) IBOutlet SHSPhoneTextField *txtConfirmPhoneNumber;

@property (weak, nonatomic) IBOutlet UIButton *btnChangePhoneNumber;
@property (weak, nonatomic) IBOutlet UIButton *btnCancel;

@property (nonatomic, weak) IBOutlet UIView *viewError;
@property (nonatomic, weak) IBOutlet UILabel *lblError;

@property (nonatomic) BOOL enterPhoneIsActive;
@property (nonatomic) BOOL confirmPhoneIsActive;

@end

@implementation EditPhoneNumberView

- (void)awakeFromNib
{
    // error message
    self.viewError.hidden = YES;
    
    self.viewEnterPhoneNumber.layer.cornerRadius = 3;
    self.viewEnterPhoneNumber.clipsToBounds = YES;
    
    self.viewConfirmPhoneNumber.layer.cornerRadius = 3;
    self.viewConfirmPhoneNumber.clipsToBounds = YES;
    
    self.btnChangePhoneNumber.layer.cornerRadius = 3;
    self.btnChangePhoneNumber.clipsToBounds = YES;
    
    self.txtEnterPhoneNumber.delegate = self;
    [self.txtEnterPhoneNumber.formatter setDefaultOutputPattern:@"(###) ### - ####"];
    [self.txtEnterPhoneNumber setTextDidChangeBlock:^(UITextField *textField) {
        if ([textField.attributedText length] > 0) {
            NSMutableAttributedString *newString = [[NSMutableAttributedString alloc] initWithString:textField.text];
            [newString addAttribute:NSForegroundColorAttributeName
                              value:[UIColor bentoBrandGreen]
                              range:NSMakeRange([textField.text length]-1, 1)];
            textField.attributedText = newString;
        }
        
        [self validate];
    }];
    
    self.txtConfirmPhoneNumber.delegate = self;
    self.txtConfirmPhoneNumber.tag = 2;
    [self.txtConfirmPhoneNumber.formatter setDefaultOutputPattern:@"(###) ### - ####"];
    [self.txtConfirmPhoneNumber setTextDidChangeBlock:^(UITextField *textField) {
        if ([textField.attributedText length] > 0) {
            NSMutableAttributedString *newString = [[NSMutableAttributedString alloc] initWithString:textField.text];
            [newString addAttribute:NSForegroundColorAttributeName
                              value:[UIColor bentoBrandGreen]
                              range:NSMakeRange([textField.text length]-1, 1)];
            textField.attributedText = newString;
        }
        
        [self validate];
    }];

    [self validate];
}

- (void)process
{
    NSString *strPhoneNumber = self.txtConfirmPhoneNumber.text;
    
    if (strPhoneNumber.length == 0) {
        return;
    }
    
    NSString *strAPIToken = [[DataManager shareDataManager] getAPIToken];
    if (strAPIToken == nil || strAPIToken.length == 0) {
        return;
    }
    
    WebManager *webManager = [[WebManager alloc] init];
    
    JGProgressHUD *loadingHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
    loadingHUD.textLabel.text = @"Processing...";
    [loadingHUD showInView:self];
    
    NSString *strRequest = [NSString stringWithFormat:@"%@/coupon/apply/%@?api_token=%@", SERVER_URL, strPhoneNumber, strAPIToken];
    
    [webManager AsyncProcess:strRequest method:GET parameters:nil success:^(MKNetworkOperation *networkOperation) {
        [loadingHUD dismiss];
        
//        NSDictionary *response = networkOperation.responseJSON;
//        id amountOff = [response objectForKey:@"amountOff"];
//        if (response != nil && amountOff != nil && [amountOff isKindOfClass:[NSString class]]) {
        
//            NSInteger discount = [[response objectForKey:@"amountOff"] integerValue];
//            if (self.delegate != nil) {
//                [self.delegate setDiscound:discount strCouponCode:strPhoneNumber];
//            }
//        }
        
        // fade out animation
        [self fadeView];
        
    } failure:^(MKNetworkOperation *errorOp, NSError *error) {
        [loadingHUD dismiss];
        
        NSString *strMessage = [[DataManager shareDataManager] getErrorMessage:errorOp.responseJSON];
        if (strMessage == nil) {
            strMessage = error.localizedDescription;
        }
        
        MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"" message:strMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitle:nil];
        [alertView showInView:self];
        alertView = nil;
        return;
        
    } isJSON:NO];
}

- (void)fadeView
{
    [UIView animateWithDuration:0.3f animations:^{
        self.alpha = 0.0f;
    }];
}

- (void)showErrorWithString:(NSString *)errorMsg code:(int)errorCode
{
    if (errorMsg == nil || errorMsg.length == 0) {
        self.viewError.hidden = YES;
    }
    else {
        self.viewError.hidden = NO;
        self.lblError.text = errorMsg;
    }
    
    UIColor *errorColor = [UIColor bentoErrorTextOrange];
    UIColor *correctColor = [UIColor bentoCorrectTextGray];
    
    switch (errorCode) {
        case ERROR_NONE:
        {
            self.viewError.hidden = YES;
            self.txtEnterPhoneNumber.textColor = correctColor;
            self.txtConfirmPhoneNumber.textColor = correctColor;
            
            if (self.txtEnterPhoneNumber.enabled == YES && self.txtEnterPhoneNumber.text.length > 0 && self.enterPhoneIsActive == YES) {
                NSMutableAttributedString *newString = [[NSMutableAttributedString alloc] initWithString:self.txtEnterPhoneNumber.text];
                [newString addAttribute:NSForegroundColorAttributeName
                                  value:[UIColor bentoBrandGreen]
                                  range:NSMakeRange([self.txtEnterPhoneNumber.text length]-1, 1)];
                self.txtEnterPhoneNumber.attributedText = newString;
            }
            
            if (self.txtConfirmPhoneNumber.text.length > 0 && self.confirmPhoneIsActive == YES) {
                NSMutableAttributedString *newString = [[NSMutableAttributedString alloc] initWithString:self.txtConfirmPhoneNumber.text];
                [newString addAttribute:NSForegroundColorAttributeName
                                  value:[UIColor bentoBrandGreen]
                                  range:NSMakeRange([self.txtConfirmPhoneNumber.text length]-1, 1)];
                self.txtConfirmPhoneNumber.attributedText = newString;
            }
        }
            break;
            
        case ERROR_PHONENUMBER:
        {
            self.viewError.hidden = NO;
            self.txtEnterPhoneNumber.textColor = errorColor;
            self.txtConfirmPhoneNumber.textColor = errorColor;
        }
            break;
            
        default:
        case ERROR_UNKNOWN:
        {
            self.viewError.hidden = NO;
            self.txtEnterPhoneNumber.textColor = correctColor;
            self.txtConfirmPhoneNumber.textColor = correctColor;
        }
            break;
    }
}

- (void)validate
{
    NSString *strPhoneNumber1 = self.txtEnterPhoneNumber.text;
    NSString *strPhoneNumber2 = self.txtConfirmPhoneNumber.text;
    
    BOOL isValid = (strPhoneNumber1.length > 0 && [DataManager isValidPhoneNumber:strPhoneNumber1] &&
                    strPhoneNumber2.length > 0 && [DataManager isValidPhoneNumber:strPhoneNumber2] &&
                    [strPhoneNumber1 isEqualToString:strPhoneNumber2]);
    
    self.btnChangePhoneNumber.enabled = isValid;
    if (isValid) {
        [self.btnChangePhoneNumber setBackgroundColor:[UIColor bentoBrandGreen]];
    }
    else {
        [self.btnChangePhoneNumber setBackgroundColor:[UIColor bentoButtonGray]];
    }
    
    if (strPhoneNumber1.length > 0 && strPhoneNumber1.length < 17 && [DataManager isValidPhoneNumber:strPhoneNumber1] == YES) {
        self.txtConfirmPhoneNumber.enabled = YES;
        self.viewConfirmPhoneNumber.backgroundColor = [UIColor whiteColor];
        
        if (strPhoneNumber2.length > 0) {
            self.txtEnterPhoneNumber.enabled = NO;
            self.viewEnterPhoneNumber.backgroundColor = [UIColor colorWithRed:0.824f green:0.820f blue:0.839f alpha:1.0f];
        }
        else {
            self.txtEnterPhoneNumber.enabled = YES;
            self.viewEnterPhoneNumber.backgroundColor = [UIColor whiteColor];
        }
    }
    else {
        self.txtConfirmPhoneNumber.enabled = NO;
        self.viewConfirmPhoneNumber.backgroundColor = [UIColor colorWithRed:0.824f green:0.820f blue:0.839f alpha:1.0f];
        
        self.txtEnterPhoneNumber.enabled = YES;
        self.viewEnterPhoneNumber.backgroundColor = [UIColor whiteColor];
    }
    
    NSString *firstChars;
    
    if (strPhoneNumber1.length > 0) {
        firstChars = [strPhoneNumber1 substringToIndex:2];
    }
    
    if ([firstChars isEqualToString:@"(1"]) {
        [self showErrorWithString:@"Phone number cannot start with \"1\"." code:ERROR_PHONENUMBER];
        return;
    }
    
    if (self.txtConfirmPhoneNumber.enabled == YES) {
        NSString *strPhoneNumber1UpToSubstring = [strPhoneNumber1 substringToIndex:strPhoneNumber2.length];
        
        if (![strPhoneNumber1UpToSubstring isEqualToString:strPhoneNumber2]) {
            [self showErrorWithString:@"Phone numbers entered must match." code:ERROR_PHONENUMBER];
            return;
        }
        
        NSLog(@"%@", strPhoneNumber1UpToSubstring);
    }
    
    [self showErrorWithString:nil code:ERROR_NONE];
}

#pragma mark On Tap

- (IBAction)onChangePhoneNumber:(id)sender
{
    [self.txtEnterPhoneNumber resignFirstResponder];
    [self.txtConfirmPhoneNumber resignFirstResponder];
    
//    [self process];
    
    [self.delegate changePhoneNumber:self.txtConfirmPhoneNumber.text];
    
    [self doCancel];
}

- (IBAction)onCancel:(id)sender
{
    [self doCancel];
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self process];
    
    return YES;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.txtEnterPhoneNumber resignFirstResponder];
    [self.txtConfirmPhoneNumber resignFirstResponder];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (textField.tag == 2) {
        self.enterPhoneIsActive = NO;
        self.confirmPhoneIsActive = YES;
    }
    else {
        self.enterPhoneIsActive = YES;
        self.confirmPhoneIsActive = NO;
    }
    
    textField.font = [UIFont fontWithName:@"OpenSans-Bold" size:20];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (textField.tag == 2) {
        self.enterPhoneIsActive = YES;
        self.confirmPhoneIsActive = NO;
    }
    else {
        self.enterPhoneIsActive = NO;
        self.confirmPhoneIsActive = YES;
    }
    
    textField.font = [UIFont fontWithName:@"OpenSans" size:14];
    
    [self validate];
    
    NSString *strPhoneNumber1 = self.txtEnterPhoneNumber.text;
    
    if (strPhoneNumber1.length > 0 && ![DataManager isValidPhoneNumber:strPhoneNumber1]) {
        [self showErrorWithString:@"Please enter a valid phone number." code:ERROR_PHONENUMBER];
        return;
    }
    
    if (textField.tag == 2) {
        if ( self.txtConfirmPhoneNumber.enabled == YES && self.txtConfirmPhoneNumber.text.length > 0 &&
            ![self.txtConfirmPhoneNumber.text isEqualToString:self.txtEnterPhoneNumber.text]) {
            
            UIColor *errorColor = [UIColor bentoErrorTextOrange];
            self.viewError.hidden = NO;
            self.lblError.text = @"Phone numbers entered must match.";
            self.txtConfirmPhoneNumber.textColor = errorColor;
        }
    }
}

- (void)doCancel
{
    // dismiss keyboard
    [self.txtEnterPhoneNumber resignFirstResponder];
    [self.txtConfirmPhoneNumber resignFirstResponder];
    
    // clear textfields
    self.txtEnterPhoneNumber.text = @"";
    self.txtConfirmPhoneNumber.text = @"";
    
    // fix enable
    self.txtEnterPhoneNumber.enabled = YES;
    self.txtConfirmPhoneNumber.enabled = NO;
    self.viewEnterPhoneNumber.backgroundColor = [UIColor whiteColor];
    self.viewConfirmPhoneNumber.backgroundColor = [UIColor colorWithRed:0.824f green:0.820f blue:0.839f alpha:1.0f];
    
    // hide error message
    self.viewError.hidden = YES;
    
    [self fadeView];
}

@end
