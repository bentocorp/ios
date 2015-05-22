//
//  OrderConfirmViewController.m
//  Bento
//
//  Created by hanjinghe on 1/8/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "OrderConfirmViewController.h"

#import "ServingDinnerViewController.h"
#import "ServingLunchViewController.h"

#import "UIImageView+WebCache.h"

#import "AppStrings.h"
#import "BentoShop.h"

@interface OrderConfirmViewController ()

@property (nonatomic, assign) IBOutlet UIImageView *ivTitle;

@property (nonatomic, assign) IBOutlet UIImageView *ivCompleted;

@property (nonatomic, assign) IBOutlet UILabel *lblCompletedTitle;

@property (nonatomic, assign) IBOutlet UILabel *lblCompletedText;

@property (nonatomic, assign) IBOutlet UIButton *btnQuestion;

@property (nonatomic, assign) IBOutlet UIButton *btnBuild;

- (IBAction)onHelp:(id)sender;

@end

@implementation OrderConfirmViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSURL *urlLogo = [[AppStrings sharedInstance] getURL:APP_LOGO];
    [self.ivTitle sd_setImageWithURL:urlLogo placeholderImage:[UIImage imageNamed:@"logo_title"]];
    
    NSURL *urlCompleted = [[AppStrings sharedInstance] getURL:COMPLETED_IMAGE_CAR];
    [self.ivCompleted sd_setImageWithURL:urlCompleted placeholderImage:[UIImage imageNamed:@"orderconfirm_image_car"]];
    
    self.lblCompletedTitle.text = [[AppStrings sharedInstance] getString:COMPLETED_TITLE];
    self.lblCompletedText.text = [[AppStrings sharedInstance] getString:COMPLETED_TEXT];
    [self.btnQuestion setTitle:[[AppStrings sharedInstance] getString:COMPLETED_LINK_QUESTION] forState:UIControlStateNormal];
    [self.btnBuild setTitle:[[AppStrings sharedInstance] getString:COMPLETED_BUTTON_COMPLETE] forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation


- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (IBAction)onAnothorBento:(id)sender
{
    [self gotoAddAnotherBentoScreen];
}

- (void)gotoAddAnotherBentoScreen
{
    NSArray *viewControllers = self.navigationController.viewControllers;
    
    for (UIViewController *vc in viewControllers) {
        
        if ([vc isKindOfClass:[ServingDinnerViewController class]] || [vc isKindOfClass:[ServingLunchViewController class]])
        {
            [[BentoShop sharedInstance] addNewBento];
            [self.navigationController popToViewController:vc animated:YES];
            
            return;
        }
    }
}

- (IBAction)onHelp:(id)sender
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *destVC = [storyboard instantiateViewControllerWithIdentifier:@"FAQID"];
    [self.navigationController pushViewController:destVC animated:YES];
}

@end
