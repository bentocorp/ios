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

@interface BaseViewController ()

@end

@implementation BaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.isOpenningAccountView = NO;
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

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if(self.isOpenningAccountView && [[DataManager shareDataManager] getUserInfo] != nil)
    {
        self.isOpenningAccountView = NO;
        
        [self performSelector:@selector(gotoNextViewController) withObject:nil];
    }
}

- (void) openAccountViewController:(id) nextViewControllerClass
{
    self.isOpenningAccountView = YES;
    
    self.nextViewController = nextViewControllerClass;
    self.complete = nil;
    
    UINavigationController *navACcount = [self.storyboard instantiateViewControllerWithIdentifier:@"Account"];
    
    [self.navigationController presentViewController:navACcount animated:YES completion:nil];
}
- (void) openAccountViewControllerWithComplete:(void (^)())completion
{
    self.isOpenningAccountView = YES;
    
    self.complete = completion;
    self.nextViewController = nil;
    
    UINavigationController *navACcount = [self.storyboard instantiateViewControllerWithIdentifier:@"Account"];
    
    [self.navigationController presentViewController:navACcount animated:YES completion:nil];
}

- (void) gotoNextViewController
{
    if(self.complete)
    {
        self.complete();
    }
    else if(self.nextViewController)
    {
        NSArray *aryViewControllers = self.navigationController.viewControllers;
        
        BOOL found = NO;
        for (UIViewController *vc in aryViewControllers)
        {
            if([vc isKindOfClass:self.nextViewController])
            {
                found = YES;
                [self.navigationController popToViewController:vc animated:YES];
            }
        }
        
        if(!found)
        {
            NSString *classIdentifier = NSStringFromClass(self.nextViewController);
            
            UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:classIdentifier];
            
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
    
    self.nextViewController = nil;
    self.complete = nil;
}

- (void) showSoldoutScreen:(NSNumber *)identifier
{
    UINavigationController *nav = [self.storyboard instantiateViewControllerWithIdentifier:@"SoldOut"];
    SoldOutViewController *vcSoldOut = (SoldOutViewController *)nav.topViewController;
    vcSoldOut.type = [identifier integerValue];
    
    [self.navigationController presentViewController:nav animated:YES completion:nil];
}

@end