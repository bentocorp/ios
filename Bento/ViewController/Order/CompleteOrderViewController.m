//
//  CompleteOrderViewController.m
//  Bento
//
//  Created by hanjinghe on 1/8/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "CompleteOrderViewController.h"

#import "MyBentoViewController.h"

#import "BentoTableViewCell.h"

#import "PromoCodeView.h"

@interface CompleteOrderViewController ()
{
    BOOL _isEditingBentos;
}

@property (nonatomic, assign) IBOutlet UITextField *txtAddress;

@property (nonatomic, assign) IBOutlet UILabel *lblPromoDiscount;
@property (nonatomic, assign) IBOutlet UILabel *lblTax;
@property (nonatomic, assign) IBOutlet UILabel *lblDeliveryTip;
@property (nonatomic, assign) IBOutlet UILabel *lblTotal;

@property (nonatomic, assign) IBOutlet UITableView *tvBentos;

@property (nonatomic, assign) IBOutlet UIButton *btnEdit;
@property (nonatomic, assign) IBOutlet UIButton *btnGetItNow;


@end

@implementation CompleteOrderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _isEditingBentos = NO;
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

- (void) gotoCreditScreen
{
    [self performSegueWithIdentifier:@"CreditCard" sender:nil];
}

- (void) gotoConfirmOrderScreen
{
    [self performSegueWithIdentifier:@"ConfirmOrder" sender:nil];
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

- (IBAction)onChangePayment:(id)sender
{
    [self gotoCreditScreen];
}

- (IBAction)onAddAnotherBento:(id)sender
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

- (IBAction)onEditBentos:(id)sender
{
    _isEditingBentos = !_isEditingBentos;
    
    [self.tvBentos setEditing:_isEditingBentos animated:YES];
    
    [self.btnEdit setTitle:(_isEditingBentos ? @"DONE" : @"EDIT") forState:UIControlStateNormal];
}

- (IBAction)onAddPromo:(id)sender
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"PromoCodeView" owner:nil options:nil];
    PromoCodeView *promoCodeView = [nib objectAtIndex:0];
    
    promoCodeView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame));
    promoCodeView.alpha = 0.0f;
    
    [self.view addSubview:promoCodeView];
    
    [self.view bringSubviewToFront:promoCodeView];
    
    [UIView animateWithDuration:0.3f animations:^{
        
        promoCodeView.alpha = 1.0f;
        
    } completion:^(BOOL finished) {
        
    }];
    
}

- (IBAction)onGetItNow:(id)sender
{
    [self gotoConfirmOrderScreen];
}

- (IBAction)onMinuteTip:(id)sender
{
    
}

- (IBAction)onPlusTip:(id)sender
{
    
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
    BentoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(BentoTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.lblBentoName.text = @"Bento";
    cell.lblBentoPrice.text = @"$14";
    cell.lblBentoPrice.center = CGPointMake(CGRectGetWidth(self.tvBentos.frame) - cell.lblBentoPrice.frame.size.width / 2 - 15 , cell.lblBentoPrice.center.y);
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

}


@end
