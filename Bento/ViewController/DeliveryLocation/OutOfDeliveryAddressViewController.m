//
//  OutOfDeliveryAddressViewController.m
//  Bento
//
//  Created by hanjinghe on 1/8/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "OutOfDeliveryAddressViewController.h"

#import "MyAlertView.h"

#import <MapKit/MapKit.h>

@interface OutOfDeliveryAddressViewController ()

@property (nonatomic, assign) IBOutlet MKMapView *mapView;

@property (nonatomic, assign) IBOutlet UITextField *txtEmail;
@property (nonatomic, assign) IBOutlet UITextField *txtAddress;

@end

@implementation OutOfDeliveryAddressViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    
}

- (IBAction)onBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onHelp:(id)sender
{
    [self performSegueWithIdentifier:@"Faq" sender:nil];
}

- (IBAction)onChangeAddress:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onSendFreeCoupon:(id)sender
{
    MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"" message:@"Thanks! We'll let you know when we're in your area." delegate:nil cancelButtonTitle:@"OK" otherButtonTitle:nil];
    
    [alertView showInView:self.view];
    alertView = nil;
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    
    [self.txtEmail resignFirstResponder];
    
    return YES;
}

@end
