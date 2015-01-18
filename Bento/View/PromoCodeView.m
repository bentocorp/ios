//
//  PromoCodeView.m
//  Bento
//
//  Created by hanjinghe on 1/9/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "PromoCodeView.h"

@interface PromoCodeView()

@property (nonatomic, assign) IBOutlet UIView *viewPromoCode;

@property (nonatomic, assign) IBOutlet UITextField *txtPromoCode;

@property (nonatomic, assign) IBOutlet UIButton *btnUsePromoCode;

@end

@implementation PromoCodeView

- (void) awakeFromNib
{
    self.viewPromoCode.layer.cornerRadius = 3;
    self.viewPromoCode.clipsToBounds = YES;
    
    self.btnUsePromoCode.layer.cornerRadius = 3;
    self.btnUsePromoCode.clipsToBounds = YES;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (IBAction)onUsePromoCode:(id)sender
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Invalid Promo Code" message:@"The promo code you entered is invalid. Please try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    
    [alertView show];
    alertView = nil;
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
    [self.txtPromoCode resignFirstResponder];
    
    return YES;
}

@end
