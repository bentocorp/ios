//
//  OrderConfirmViewController.m
//  Bento
//
//  Created by hanjinghe on 1/8/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "OrderConfirmViewController.h"

#import "MyBentoViewController.h"

@interface OrderConfirmViewController ()

@end

@implementation OrderConfirmViewController

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

- (IBAction)onHelp:(id)sender
{
    [self performSegueWithIdentifier:@"Faq" sender:nil];
}

- (IBAction)onAnothorBento:(id)sender
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

@end
