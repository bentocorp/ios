//
//  FaqViewController.m
//  Bento
//
//  Created by hanjinghe on 1/6/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "FaqViewController.h"

#import "MyBentoViewController.h"

@interface FaqViewController ()

@property (nonatomic, assign) IBOutlet UILabel *lblTitle;

@property (nonatomic, assign) IBOutlet UIButton *btnFinishing;

@end

@implementation FaqViewController

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
    
    [self initContent];
}

- (void) initContent
{
    switch (self.contentType) {
        case CONTENT_PRIVACY:
        {
            self.lblTitle.text = @"Privacy Policy";
            self.btnFinishing.hidden = YES;
        }
            break;
            
        case CONTENT_TERMS:
        {
            self.lblTitle.text = @"Terms & Conditions";
            self.btnFinishing.hidden = YES;
        }
            break;
            
        case CONTENT_FAQ:
        {
            self.lblTitle.text = @"FAQ";
            self.btnFinishing.hidden = NO;
        }
            break;
            
        default:
            break;
    }
}

- (IBAction)onBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onEmailUs:(id)sender
{
    
}

- (IBAction)onFinishBuildingMyBento:(id)sender
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
