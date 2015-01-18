//
//  SoldOutViewController.m
//  Bento
//
//  Created by hanjinghe on 1/8/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "SoldOutViewController.h"

#import "FaqViewController.h"

#import "DataManager.h"

@interface SoldOutViewController ()

@property (nonatomic, assign) IBOutlet UIView *viewMain;

@property (nonatomic, assign) IBOutlet UIImageView *ivBackground;

@property (nonatomic, assign) IBOutlet UILabel *lblMessageTitle;
@property (nonatomic, assign) IBOutlet UILabel *lblMessageContent;

@property (nonatomic, assign) IBOutlet UITextField *txtEmail;

@end

@implementation SoldOutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.ivBackground.bounds;
    
    UIColor *color1 = [DataManager getGradientColor1];
    UIColor *color2 = [DataManager getGradientColor2];
    gradient.colors = [NSArray arrayWithObjects:(id)[color1 CGColor], (id)[color2 CGColor], nil];
    [self.ivBackground.layer insertSublayer:gradient atIndex:0];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if([segue.identifier isEqualToString:@"Terms"])
    {
        FaqViewController *vc = segue.destinationViewController;
        vc.contentType = [sender intValue];
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
}

- (IBAction)onPrivacyPolicy:(id)sender
{
    [self performSegueWithIdentifier:@"Faq" sender:[NSNumber numberWithInt:CONTENT_PRIVACY]];
}

- (IBAction)onTermsAndConditions:(id)sender
{
    [self performSegueWithIdentifier:@"Faq" sender:[NSNumber numberWithInt:CONTENT_TERMS]];
}

- (IBAction)onHelp:(id)sender
{
    [self performSegueWithIdentifier:@"Faq" sender:[NSNumber numberWithInt:CONTENT_FAQ]];
}

- (IBAction)onSendBentoCoupon:(id)sender
{
    
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.txtEmail resignFirstResponder];
    
    return YES;
}

@end
