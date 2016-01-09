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

@interface HomeViewController ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CustomViewController *customVC = [[CustomViewController alloc] init];
    [self addChildViewController:customVC];
    [self.scrollView addSubview:customVC.view];
    [customVC didMoveToParentViewController:self];
    
    FixedViewController *fixedVC = [[FixedViewController alloc] init];
    CGRect frame = fixedVC.view.frame;
    frame.origin.x = SCREEN_WIDTH;
    fixedVC.view.frame = frame;
    
    [self addChildViewController:fixedVC];
    [self.scrollView addSubview:fixedVC.view];
    [fixedVC didMoveToParentViewController:self];
    
    self.scrollView.contentSize = CGSizeMake(SCREEN_WIDTH * 2, SCREEN_HEIGHT);
    self.scrollView.pagingEnabled = NO;
    self.scrollView.bounces = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
