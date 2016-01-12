//
//  HomeViewController.m
//  Bento
//
//  Created by Joseph Lau on 1/8/16.
//  Copyright © 2016 bentonow. All rights reserved.
//

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

#import "HomeViewController.h"
#import "CustomViewController.h"
#import "MenuPreviewViewController.h"

#import "BentoShop.h"

@interface HomeViewController ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak, nonatomic) IBOutlet UILabel *startingPriceLabel;
@property (weak, nonatomic) IBOutlet UILabel *etaLabel;

@property (weak, nonatomic) IBOutlet UIButton *pickerButton;
@property (weak, nonatomic) IBOutlet UIButton *bottomButton;

@property (nonatomic) CustomViewController *customVC;
@property (nonatomic) MenuPreviewViewController *menuPreviewVC;

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Custom
    self.customVC = [[CustomViewController alloc] initWithNibName:@"CustomViewController" bundle:nil];
    [self addChildViewController:self.customVC];
    [self.scrollView addSubview:self.customVC.view];
    [self.customVC didMoveToParentViewController:self];
    
    // Menu Preview
    self.menuPreviewVC = [[MenuPreviewViewController alloc] init];
    CGRect frame = self.menuPreviewVC.view.frame;
    frame.origin.x = SCREEN_WIDTH;
    self.menuPreviewVC.view.frame = frame;
    
    [self addChildViewController:self.menuPreviewVC];
    [self.scrollView addSubview:self.menuPreviewVC.view];
    [self.menuPreviewVC didMoveToParentViewController:self];
    
    // Scroll View
    self.scrollView.contentSize = CGSizeMake(SCREEN_WIDTH * 2, SCREEN_HEIGHT - 20);
}

- (IBAction)settingsButtonPressed:(id)sender {
    
}

- (IBAction)cartButtonPressed:(id)sender {
    
}

- (IBAction)pickerButtonPressed:(id)sender {
    
}

- (IBAction)bottomButtonPressed:(id)sender {
    
}

@end