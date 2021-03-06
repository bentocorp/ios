//
//  BaseViewController.m
//  Bento
//
//  Created by RiSongIl on 2/4/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "BaseViewController.h"

#import "DataManager.h"
#import "SoldOutViewController.h"
#import "SignInViewController.h"
#import "AddonsViewController.h"
#import "CompleteOrderViewController.h"

@interface BaseViewController ()

@end

@implementation BaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.isOpenningAccountView = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.isOpenningAccountView && [[DataManager shareDataManager] getUserInfo] != nil) {
        self.isOpenningAccountView = NO;
        
        [self performSelector:@selector(gotoNextViewController) withObject:nil];
    }
}

- (void)openAccountViewController:(id)nextViewControllerClass
{
    self.isOpenningAccountView = YES;
    self.nextViewController = nextViewControllerClass;
    self.complete = nil;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"" forKey:@"cameFromWhichVC"]; // wtf?
    [defaults synchronize];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *destVC = [storyboard instantiateViewControllerWithIdentifier:@"RegisterID"];
    [self.navigationController pushViewController:destVC animated:YES];
}

- (void)openAccountViewControllerWithComplete:(void (^)())completion
{
    self.isOpenningAccountView = YES;
    
    self.complete = completion;
    self.nextViewController = nil;
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *navACcount = [storyboard instantiateViewControllerWithIdentifier:@"Account"];
    
    [self.navigationController presentViewController:navACcount animated:YES completion:nil];
}

- (void)gotoNextViewController
{
    if (self.complete) {
        self.complete();
    }
    else if (self.nextViewController) {
        NSArray *aryViewControllers = self.navigationController.viewControllers;
        
        BOOL found = NO;
        for (UIViewController *vc in aryViewControllers) {
            if ([vc isKindOfClass:self.nextViewController]) {
                found = YES;
                [self.navigationController popToViewController:vc animated:YES];
            }
        }
        
        if (!found) {
            NSString *classIdentifier = NSStringFromClass(self.nextViewController);
            
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            UIViewController *vc = [storyboard instantiateViewControllerWithIdentifier:classIdentifier];
            
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
    
    self.nextViewController = nil;
    self.complete = nil;
}

- (void)showSoldoutScreen:(NSNumber *)identifier
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *nav = [storyboard instantiateViewControllerWithIdentifier:@"SoldOut"];
    
    SoldOutViewController *vcSoldOut = (SoldOutViewController *)nav.topViewController;
    vcSoldOut.type = [identifier integerValue];
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
