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
#import "Mixpanel.h"

@interface PromoCodeView()

@property (nonatomic, weak) IBOutlet UIView *viewPromoCode;

@property (nonatomic, weak) IBOutlet UITextField *txtPromoCode;

@property (nonatomic, weak) IBOutlet UIButton *btnUsePromoCode;

@property (nonatomic, weak) IBOutlet UIButton *btnCancel;

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

- (void)process
{
    [self.txtPromoCode resignFirstResponder];
    
    NSString *strPromoCode = self.txtPromoCode.text;
    
    // Remove all whitespaces
    NSArray* words = [strPromoCode componentsSeparatedByCharactersInSet :[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    strPromoCode = [words componentsJoinedByString:@""];
    
    if (strPromoCode.length == 0)
        return;
    
    NSString *strAPIToken = [[DataManager shareDataManager] getAPIToken];
    if (strAPIToken == nil || strAPIToken.length == 0)
        return;
    
//#ifndef DEBUG
    WebManager *webManager = [[WebManager alloc] init];
    
    JGProgressHUD *loadingHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
    loadingHUD.textLabel.text = @"Processing...";
    [loadingHUD showInView:self];
    
    NSString *strRequest = [NSString stringWithFormat:@"%@/coupon/apply/%@?api_token=%@", SERVER_URL, strPromoCode, strAPIToken];
    
    NSLog(@"api token %@", strRequest);
    
    [webManager AsyncProcess:strRequest method:GET parameters:nil success:^(MKNetworkOperation *networkOperation) {
        [loadingHUD dismiss];
        
        NSDictionary *response = networkOperation.responseJSON;
        id amountOff = [response objectForKey:@"amountOff"];
        if (response != nil && amountOff != nil && [amountOff isKindOfClass:[NSString class]])
        {
            float discount = [[response objectForKey:@"amountOff"] floatValue];
            if (self.delegate != nil)
                [self.delegate setDiscound:discount strCouponCode:strPromoCode];
            
            /*TRACK PROMO MIXPANEL*/
            [[Mixpanel sharedInstance] track:@"Entered Promo Code" properties:@{
                                                                                @"code": strPromoCode,
                                                                                @"discount": [NSString stringWithFormat:@"%ld", (long)discount]
                                                                                }];
            
             NSLog(@"json response %@", response);
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
        
    } isJSON:NO];
//#else
//    float discount = 5.75; // promo discount - hardcoded for testing
//    if (self.delegate != nil) {
//        [self.delegate setDiscound:discount strCouponCode:@"ridev"];
//    }
//
//    [UIView animateWithDuration:0.3f animations:^{
//        self.alpha = 0.0f;
//    } completion:^(BOOL finished) {
//        [self removeFromSuperview];
//    }];
//#endif
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
