//
//  PromoCodeView.m
//  Bento
//
//  Created by hanjinghe on 1/9/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "PromoCodeView.h"

#import "MyAlertView.h"

#import "JGProgressHUD.h"

#import "AppStrings.h"
#import "WebManager.h"
#import "DataManager.h"

@interface PromoCodeView()

@property (nonatomic, assign) IBOutlet UIView *viewPromoCode;

@property (nonatomic, assign) IBOutlet UITextField *txtPromoCode;

@property (nonatomic, assign) IBOutlet UIButton *btnUsePromoCode;

@property (nonatomic, assign) IBOutlet UIButton *btnCancel;

@end

@implementation PromoCodeView

- (void) awakeFromNib
{
    self.viewPromoCode.layer.cornerRadius = 3;
    self.viewPromoCode.clipsToBounds = YES;
    
    self.btnUsePromoCode.layer.cornerRadius = 3;
    self.btnUsePromoCode.clipsToBounds = YES;
    
    self.txtPromoCode.placeholder = [[AppStrings sharedInstance] getString:PROMOCODE_PLACEHOLDER];
    [self.btnUsePromoCode setTitle:[[AppStrings sharedInstance] getString:PROMOCODE_BUTTON_USE] forState:UIControlStateNormal];
    [self.btnCancel setTitle:[[AppStrings sharedInstance] getString:PROMOCODE_BUTTON_CANCEL] forState:UIControlStateNormal];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)process
{
    [self.txtPromoCode resignFirstResponder];
    
    NSString *strPromoCode = self.txtPromoCode.text;
    
    // Remove all whitespaces
    strPromoCode = [strPromoCode stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (strPromoCode.length == 0)
        return;
    
    NSString *strAPIToken = [[DataManager shareDataManager] getAPIToken];
    if (strAPIToken == nil || strAPIToken.length == 0)
        return;
    
    WebManager *webManager = [[WebManager alloc] init];
    
    JGProgressHUD *loadingHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
    loadingHUD.textLabel.text = @"Processing...";
    [loadingHUD showInView:self];
    
    NSString *strRequest = [NSString stringWithFormat:@"%@/coupon/apply/%@?api_token=%@", SERVER_URL, strPromoCode, strAPIToken];
    [webManager AsyncProcess:strRequest method:GET parameters:nil success:^(MKNetworkOperation *networkOperation) {
        [loadingHUD dismiss];
        
        NSDictionary *response = networkOperation.responseJSON;
        if (response != nil && [response objectForKey:@"amountOff"] != nil)
        {
            NSInteger discount = [[response objectForKey:@"amountOff"] integerValue];
            if (self.delegate != nil)
                [self.delegate setDiscound:discount];
        }
        
        [UIView animateWithDuration:0.3f animations:^{
            
            self.alpha = 0.0f;
            
        } completion:^(BOOL finished) {
            
            [self removeFromSuperview];
            
        }];
        
    } failure:^(MKNetworkOperation *errorOp, NSError *error) {
        [loadingHUD dismiss];
        
        NSString *strMessage = [[DataManager shareDataManager] getErrorMessage:errorOp.responseJSON];
        if (strMessage == nil)
            strMessage = error.localizedDescription;
        
        MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"" message:strMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitle:nil];
        [alertView showInView:self];
        alertView = nil;
        return;
        
//        if (error.code == 400)
//        {
//            NSString *strTitle = [[AppStrings sharedInstance] getString:ALERT_IPC_TITLE];
//            NSString *strText = [[AppStrings sharedInstance] getString:ALERT_IPC_TEXT];
//            NSString *strConfirm = [[AppStrings sharedInstance] getString:ALERT_IPC_BUTTON_OK];
//            
//            MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:strTitle message:strText delegate:nil cancelButtonTitle:strConfirm otherButtonTitle:nil];
//            
//            [alertView showInView:self];
//            alertView = nil;
//            return;
//        }
//        else
//        {
//            MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitle:nil];
//            [alertView showInView:self];
//            alertView = nil;
//            return;
//        }
        
    } isJSON:NO];
}

- (IBAction)onUsePromoCode:(id)sender
{
    [self process];
}

- (IBAction)onCancel:(id)sender
{
    [UIView animateWithDuration:0.3f animations:^{
        
        self.alpha = 0.0f;
        
    } completion:^(BOOL finished) {
        
        [self removeFromSuperview];
        
    }];
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self process];
    
    return YES;
}

@end
