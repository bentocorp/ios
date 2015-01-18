//
//  PhoneNumberViewController.m
//  Bento
//
//  Created by hanjinghe on 1/8/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "PhoneNumberViewController.h"

#import "FaqViewController.h"

@interface PhoneNumberViewController ()

@property (nonatomic, assign) IBOutlet UIButton *btnDone;

@property (nonatomic, assign) IBOutlet UITextField *txtPhoneNumber;

@end

@implementation PhoneNumberViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.btnDone.layer.cornerRadius = 3;
    self.btnDone.clipsToBounds = YES;
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

- (IBAction)onBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onPrivacyPolicy:(id)sender
{
    [self performSegueWithIdentifier:@"Faq" sender:[NSNumber numberWithInt:CONTENT_PRIVACY]];
}

- (IBAction)onTermsAndConditions:(id)sender
{
    [self performSegueWithIdentifier:@"Faq" sender:[NSNumber numberWithInt:CONTENT_TERMS]];
}

- (IBAction)onDone:(id)sender
{
    [self gotoDeliveryLocationScreen];
}

- (void) gotoDeliveryLocationScreen
{
    [self performSegueWithIdentifier:@"DeliveryLocation" sender:nil];
}

@end
