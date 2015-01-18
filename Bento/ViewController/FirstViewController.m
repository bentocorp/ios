//
//  ViewController.m
//  Bento
//
//  Created by hanjinghe on 1/6/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "FirstViewController.h"

#import "DataManager.h"

@interface FirstViewController ()

@property (nonatomic, assign) IBOutlet UIImageView *ivBackground;

@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.ivBackground.bounds;

    UIColor *color1 = [DataManager getGradientColor1];
    UIColor *color2 = [DataManager getGradientColor2];
    gradient.colors = [NSArray arrayWithObjects:(id)[color1 CGColor], (id)[color2 CGColor], nil];
    [self.ivBackground.layer insertSublayer:gradient atIndex:0];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self performSelector:@selector(process) withObject:nil afterDelay:1.0f];
}

- (void) process
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    [prefs setValue:[NSNumber numberWithInteger:-1] forKey:@"MainDish"];
    
    [prefs setValue:[NSNumber numberWithInteger:-1] forKey:@"SideDish1"];
    [prefs setValue:[NSNumber numberWithInteger:-1] forKey:@"SideDish2"];
    [prefs setValue:[NSNumber numberWithInteger:-1] forKey:@"SideDish3"];
    [prefs setValue:[NSNumber numberWithInteger:-1] forKey:@"SideDish4"];
    
    [prefs synchronize];
    
    [self gotoIntroScreen];
}

- (void) gotoIntroScreen
{
    [self performSegueWithIdentifier:@"MakeBento" sender:nil];
}


@end
