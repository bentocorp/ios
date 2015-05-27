//
//  NetworkErrorViewController.m
//  Bento
//
//  Created by Joseph Lau on 5/26/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "NetworkErrorViewController.h"

@interface NetworkErrorViewController ()

@end

@implementation NetworkErrorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor redColor];
}

- (void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yesConnection) name:@"networkConnected" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"networkError" object:nil];
}

- (void)yesConnection
{
    [NSTimer scheduledTimerWithTimeInterval:3.0f target:self selector:@selector(timerDidEnd) userInfo:nil repeats:NO];
}

- (void)timerDidEnd
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
