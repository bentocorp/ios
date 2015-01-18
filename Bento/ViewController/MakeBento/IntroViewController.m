//
//  IntroViewController.m
//  Bento
//
//  Created by hanjinghe on 1/6/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "IntroViewController.h"

#import "DataManager.h"

@interface IntroViewController()

@property (nonatomic, assign) IBOutlet UIImageView *ivBackground;

@property (nonatomic, assign) IBOutlet UILabel *lblComment;

@property (nonatomic, assign) IBOutlet UILabel *lblNumber1;
@property (nonatomic, assign) IBOutlet UILabel *lblNumber2;
@property (nonatomic, assign) IBOutlet UILabel *lblNumber3;

@property (nonatomic, assign) IBOutlet UIButton *btnGetStarted;

@end

@implementation IntroViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.ivBackground.bounds;
    
    UIColor *color1 = [DataManager getGradientColor1];
    UIColor *color2 = [DataManager getGradientColor2];
    gradient.colors = [NSArray arrayWithObjects:(id)[color1 CGColor], (id)[color2 CGColor], nil];
    [self.ivBackground.layer insertSublayer:gradient atIndex:0];
    
    self.lblNumber1.layer.cornerRadius = self.lblNumber1.frame.size.width / 2;
    self.lblNumber1.clipsToBounds = YES;
    
    self.lblNumber2.layer.cornerRadius = self.lblNumber2.frame.size.width / 2;
    self.lblNumber2.clipsToBounds = YES;
    
    self.lblNumber3.layer.cornerRadius = self.lblNumber3.frame.size.width / 2;
    self.lblNumber3.clipsToBounds = YES;
    
    self.btnGetStarted.layer.cornerRadius = 3;
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

}

- (IBAction)onChooseMainDish:(id)sender
{
    
}

- (IBAction)onPickSideDish:(id)sender
{
    
}

- (IBAction)onEnterAddress:(id)sender
{
    
}

- (IBAction)onGetStarted:(id)sender
{
    [self performSegueWithIdentifier:@"MyBento" sender:nil];
}


@end
