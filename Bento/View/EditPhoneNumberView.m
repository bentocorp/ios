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


@interface EditPhoneNumberView()

@property (weak, nonatomic) IBOutlet UIView *viewEnterPhoneNumber;
@property (weak, nonatomic) IBOutlet UIView *viewConfirmPhoneNumber;

@property (weak, nonatomic) IBOutlet UITextField *txtEnterPhoneNumber;
@property (weak, nonatomic) IBOutlet UITextField *txtConfirmPhoneNumber;

@property (weak, nonatomic) IBOutlet UIButton *btnChangePhoneNumber;
@property (weak, nonatomic) IBOutlet UIButton *btnCancel;

@property (nonatomic, weak) IBOutlet UIView *viewError;
@property (nonatomic, weak) IBOutlet UILabel *lblError;

@end

@implementation EditPhoneNumberView

- (void)awakeFromNib
{
    self.viewEnterPhoneNumber.layer.cornerRadius = 3;
    self.viewEnterPhoneNumber.clipsToBounds = YES;
    
    self.viewConfirmPhoneNumber.layer.cornerRadius = 3;
    self.viewConfirmPhoneNumber.clipsToBounds = YES;
    
    self.btnChangePhoneNumber.layer.cornerRadius = 3;
    self.btnChangePhoneNumber.clipsToBounds = YES;
    
//    [self showErrorWithString:nil code:ERROR_NONE];
    
    self.viewError.alpha = 0;
}

- (IBAction)onChangePhoneNumber:(id)sender
{
    [self process];
}

- (IBAction)onCancel:(id)sender
{
    [self fadeView];
}

- (void)process
{
    [self.txtEnterPhoneNumber resignFirstResponder];
    [self.txtConfirmPhoneNumber resignFirstResponder];
    
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
    [self.txtEnterPhoneNumber resignFirstResponder];
    [self.txtConfirmPhoneNumber resignFirstResponder];
    
    [UIView animateWithDuration:0.3f animations:^{
        self.alpha = 0.0f;
    }];
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

@end
