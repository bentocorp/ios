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
#import "FixedViewController.h"
#import "PreviewViewController.h"
#import "BentoShop.h"

@interface HomeViewController ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (nonatomic) CustomViewController *customVC;
@property (nonatomic) FixedViewController *fixedVC;

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *menuType = [[BentoShop sharedInstance] getMenuType];
    
    if ([menuType isEqualToString:@"custom"]) {
        self.customVC = [[CustomViewController alloc] init];
        [self addChildViewController:self.customVC];
        [self.scrollView addSubview:self.customVC.view];
        [self.customVC didMoveToParentViewController:self];
    }
    else {
        self.fixedVC = [[FixedViewController alloc] init];
        [self addChildViewController:self.fixedVC];
        [self.scrollView addSubview:self.fixedVC.view];
        [self.fixedVC didMoveToParentViewController:self];
    }
    
    PreviewViewController *previewVC = [[PreviewViewController alloc] init];
    CGRect frame = previewVC.view.frame;
    frame.origin.x = SCREEN_WIDTH;
    previewVC.view.frame = frame;
    
    [self addChildViewController:previewVC];
    [self.scrollView addSubview:previewVC.view];
    [previewVC didMoveToParentViewController:self];
    
    self.scrollView.contentSize = CGSizeMake(SCREEN_WIDTH * 2, SCREEN_HEIGHT);
    self.scrollView.pagingEnabled = NO;
    self.scrollView.bounces = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
