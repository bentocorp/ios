//
//  DeliveryLocationViewController.m
//  Bento
//
//  Created by hanjinghe on 1/8/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "DeliveryLocationViewController.h"

#import "MyBentoViewController.h"

#import "MyAlertView.h"

#import <MapKit/MapKit.h>

@interface DeliveryLocationViewController ()<MyAlertViewDelegate>
{
    BOOL _showedLocationTableView;
}

@property (nonatomic, assign) IBOutlet UILabel *lblBadge;
@property (nonatomic, assign) IBOutlet UIButton *btnDelivery;

@property (nonatomic, assign) IBOutlet UIView *viewSearchLocation;

@property (nonatomic, assign) IBOutlet UITextField *txtAddress;
@property (nonatomic, assign) IBOutlet UITableView *tvLocations;

@property (nonatomic, assign) IBOutlet MKMapView *mapView;

@property (nonatomic, assign) IBOutlet UIButton *btnMeetMyDrive;

@property (nonatomic, assign) IBOutlet UIButton *btnBottomButton;

@end

@implementation DeliveryLocationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[self.txtAddress valueForKey:@"textInputTraits"] setValue:[UIColor colorWithRed:138.0f / 255.0f green:187.0f / 255.0f blue:90.0f / 255.0f alpha:1.0f] forKey:@"insertionPointColor"];
    
    self.lblBadge.layer.cornerRadius = self.lblBadge.frame.size.width / 2;
    self.lblBadge.clipsToBounds = YES;
    
    _showedLocationTableView = NO;
    
    float tableViewPos = self.viewSearchLocation.frame.origin.y + CGRectGetHeight(self.viewSearchLocation.frame);
    self.tvLocations.frame = CGRectMake(0, tableViewPos, CGRectGetWidth(self.view.frame), 0);
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
    [self gotoAddAnotherBentoScreen];
}

- (void) gotoAddAnotherBentoScreen
{
    NSArray *viewControllers = self.navigationController.viewControllers;
    
    for (UIViewController *vc in viewControllers) {
        
        if([vc isKindOfClass:[MyBentoViewController class]])
        {
            [self.navigationController popToViewController:vc animated:YES];
            
            return;
        }
    }
    
    [self performSegueWithIdentifier:@"AddAnotherBento" sender:nil];
}

- (IBAction)onDelivery:(id)sender
{
    [self gotoCompleteOrderScreen];
}

- (IBAction)onNavigation:(id)sender
{
    [self stopSearch];
}

- (IBAction)onSearchLocation:(id)sender
{
    if(_showedLocationTableView)
        [self stopSearch];
    else
        [self startSearch];
}

- (IBAction)onMeetMyDriver:(id)sender
{
    if(self.btnMeetMyDrive.selected)
    {
        self.btnMeetMyDrive.selected = NO;
        
        return ;
    }
    
    MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"" message:@"To keep deliveries fast, our driver will meet you at the curb." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitle:@"I agree"];
    alertView.tag = 0;
    
    [alertView showInView:self.view];
    alertView = nil;
}

- (IBAction)onChangeAddress:(id)sender
{
    [self updateUI];
}

- (IBAction)onBottomButton:(id)sender
{
    if(self.txtAddress.text.length > 0)
    {
        [self gotoCompleteOrderScreen];
    }
}

- (void) gotoNoneDeliveryAreaScreen
{
    [self performSegueWithIdentifier:@"OutOfDelivery" sender:nil];
}

- (void) gotoCompleteOrderScreen
{
    [self performSegueWithIdentifier:@"CompleteOrder" sender:nil];
}

- (void) startSearch
{
    [self showLocationTableView];
}

- (void) stopSearch
{
    [self hideLocationTableView];
}

- (void) showLocationTableView
{
    if(_showedLocationTableView) return;
    
    _showedLocationTableView = YES;
    
    float keyboardHeight = 216;
    float tableViewPos = self.viewSearchLocation.frame.origin.y + CGRectGetHeight(self.viewSearchLocation.frame);
    
    self.tvLocations.frame = CGRectMake(0, tableViewPos, CGRectGetWidth(self.view.frame), 0);
    
    [UIView animateWithDuration:0.3f animations:^{
        
        self.tvLocations.frame = CGRectMake(0, tableViewPos, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) - (tableViewPos + keyboardHeight));
        
    } completion:^(BOOL finished) {
        
    }];
}

- (void) hideLocationTableView
{
    if(!_showedLocationTableView) return;
    
    _showedLocationTableView = NO;
    
    [UIView animateWithDuration:0.3f animations:^{
        
        float tableViewPos = self.viewSearchLocation.frame.origin.y + CGRectGetHeight(self.viewSearchLocation.frame);
        self.tvLocations.frame = CGRectMake(0, tableViewPos, CGRectGetWidth(self.view.frame), 0);
        
    } completion:^(BOOL finished) {
        
    }];
}

- (void) updateUI
{
    if(self.txtAddress.text.length > 0)
    {
        [self.btnBottomButton setTitle:@"CONFIRM ADDRESS" forState:UIControlStateNormal];
        self.btnBottomButton.backgroundColor = [UIColor colorWithRed:135.0f / 255.0f green:176.0f / 255.0f blue:95.0f / 255.0f alpha:1.0f];
    }
    else
    {
        [self.btnBottomButton setTitle:@"CONFIRM ADDRESS" forState:UIControlStateNormal];
        self.btnBottomButton.backgroundColor = [UIColor colorWithRed:122.0f / 255.0f green:133.0f / 255.0f blue:145.0f / 255.0f alpha:1.0f];
    }
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    [self startSearch];
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self stopSearch];
    
    return YES;
}

#pragma mark MyAlertViewDelegate

- (void)alertView:(MyAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == 0)
    {
        if(buttonIndex == 1)
        {
            self.btnMeetMyDrive.selected = YES;
        }
    }
}

#pragma mark UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    if(cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.textLabel.text = @"199 New Montgomery St.";
    cell.textLabel.font = [UIFont fontWithName:@"Open Sans" size:14.0f];
    
    cell.detailTextLabel.text = @"San Francisco. CA";
    cell.detailTextLabel.font = [UIFont fontWithName:@"Open Sans" size:12.0f];
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self gotoNoneDeliveryAreaScreen];
}

@end
