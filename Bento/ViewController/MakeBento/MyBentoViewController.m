//
//  MyBentoViewController.m
//  Bento
//
//  Created by hanjinghe on 1/6/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "MyBentoViewController.h"

#import "ChooseSideDishViewController.h"

#import "MyAlertView.h"

#import "CAGradientLayer+SJSGradients.h"

@interface MyBentoViewController ()<MyAlertViewDelegate>

@property (nonatomic, assign) IBOutlet UILabel *lblBadge;

@property (nonatomic, assign) IBOutlet UIButton *btnCart;

@property (nonatomic, assign) IBOutlet UIView *viewDishs;

@property (nonatomic, assign) IBOutlet UIView *viewMainEntree;

@property (nonatomic, assign) IBOutlet UIView *viewSide1;
@property (nonatomic, assign) IBOutlet UIView *viewSide2;
@property (nonatomic, assign) IBOutlet UIView *viewSide3;
@property (nonatomic, assign) IBOutlet UIView *viewSide4;

@property (nonatomic, assign) IBOutlet UIImageView *ivMainDish;

@property (nonatomic, assign) IBOutlet UIImageView *ivSideDish1;
@property (nonatomic, assign) IBOutlet UIImageView *ivSideDish2;
@property (nonatomic, assign) IBOutlet UIImageView *ivSideDish3;
@property (nonatomic, assign) IBOutlet UIImageView *ivSideDish4;

@property (nonatomic, assign) IBOutlet UILabel *lblMainDish;

@property (nonatomic, assign) IBOutlet UILabel *lblSideDish1;
@property (nonatomic, assign) IBOutlet UILabel *lblSideDish2;
@property (nonatomic, assign) IBOutlet UILabel *lblSideDish3;
@property (nonatomic, assign) IBOutlet UILabel *lblSideDish4;

@property (nonatomic, assign) IBOutlet UIButton *btnAddAnotherBento;

@property (nonatomic, assign) IBOutlet UIButton *btnState;

@end

@implementation MyBentoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.lblBadge.layer.cornerRadius = self.lblBadge.frame.size.width / 2;
    self.lblBadge.clipsToBounds = YES;
    
    self.viewDishs.layer.cornerRadius = 3;
    self.viewDishs.clipsToBounds = YES;
    self.viewDishs.layer.borderColor = [UIColor colorWithRed:223.0f / 255.0f green:226.0f / 255.0f blue:226.0f / 255.0f alpha:1.0f].CGColor;
    self.viewDishs.layer.borderWidth = 1.0f;
    
    int everyDishHeight = self.viewDishs.frame.size.height / 3;
    
    self.viewMainEntree.frame = CGRectMake(-1, -1, self.viewDishs.frame.size.width + 2, everyDishHeight + 2);
    
    self.viewSide1.frame = CGRectMake(-1, everyDishHeight, self.viewDishs.frame.size.width / 2 + 2, everyDishHeight + 1);
    self.viewSide1.layer.borderWidth = 1.0f;
    self.viewSide1.layer.borderColor = [UIColor colorWithRed:223.0f / 255.0f green:226.0f / 255.0f blue:226.0f / 255.0f alpha:1.0f].CGColor;
    
    self.viewSide2.frame = CGRectMake(self.viewDishs.frame.size.width / 2, everyDishHeight, self.viewDishs.frame.size.width / 2 + 1, everyDishHeight + 1);
    self.viewSide2.layer.borderWidth = 1.0f;
    self.viewSide2.layer.borderColor = [UIColor colorWithRed:223.0f / 255.0f green:226.0f / 255.0f blue:226.0f / 255.0f alpha:1.0f].CGColor;
    
    self.viewSide3.frame = CGRectMake(-1, everyDishHeight * 2, self.viewDishs.frame.size.width / 2 + 2, everyDishHeight + 2);
    self.viewSide3.layer.borderWidth = 1.0f;
    self.viewSide3.layer.borderColor = [UIColor colorWithRed:223.0f / 255.0f green:226.0f / 255.0f blue:226.0f / 255.0f alpha:1.0f].CGColor;
    
    self.viewSide4.frame = CGRectMake(self.viewDishs.frame.size.width / 2, everyDishHeight * 2, self.viewDishs.frame.size.width / 2 + 1, everyDishHeight + 2);
    self.viewSide4.layer.borderWidth = 1.0f;
    self.viewSide4.layer.borderColor = [UIColor colorWithRed:223.0f / 255.0f green:226.0f / 255.0f blue:226.0f / 255.0f alpha:1.0f].CGColor;
    
    CAGradientLayer *backgroundLayer = [CAGradientLayer blackGradientLayer];
    backgroundLayer.frame = self.ivMainDish.frame;
    backgroundLayer.opacity = 0.8f;
    [self.ivMainDish.layer insertSublayer:backgroundLayer atIndex:0];
    
    backgroundLayer = [CAGradientLayer blackGradientLayer];
    backgroundLayer.frame = self.ivSideDish1.frame;
    backgroundLayer.opacity = 0.8f;
    [self.ivSideDish1.layer insertSublayer:backgroundLayer atIndex:0];
    
    backgroundLayer = [CAGradientLayer blackGradientLayer];
    backgroundLayer.frame = self.ivSideDish2.frame;
    backgroundLayer.opacity = 0.8f;
    [self.ivSideDish2.layer insertSublayer:backgroundLayer atIndex:0];
    
    backgroundLayer = [CAGradientLayer blackGradientLayer];
    backgroundLayer.frame = self.ivSideDish3.frame;
    backgroundLayer.opacity = 0.8f;
    [self.ivSideDish3.layer insertSublayer:backgroundLayer atIndex:0];
    
    backgroundLayer = [CAGradientLayer blackGradientLayer];
    backgroundLayer.frame = self.ivSideDish4.frame;
    backgroundLayer.opacity = 0.8f;
    [self.ivSideDish4.layer insertSublayer:backgroundLayer atIndex:0];
    
    self.btnAddAnotherBento.layer.borderColor = [UIColor colorWithRed:223.0f / 255.0f green:226.0f / 255.0f blue:226.0f / 255.0f alpha:1.0f].CGColor;
    self.btnAddAnotherBento.layer.borderWidth = 1.0f;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if([segue.identifier isEqualToString:@"SideDish"])
    {
        ChooseSideDishViewController *vc = segue.destinationViewController;
        vc.sideDishIndex = [sender integerValue];
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateUI];
}

- (void) loadSelectedDishes
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    NSInteger mainDishIndex = [[prefs objectForKey:@"MainDish"] integerValue];
    
    if(mainDishIndex != -1)
    {
        self.ivMainDish.image = [UIImage imageNamed:@"sample"];
        self.ivMainDish.hidden = NO;
        self.lblMainDish.hidden = NO;
    }
    else
    {
        self.ivMainDish.image = nil;
        self.ivMainDish.hidden = YES;
        self.lblMainDish.hidden = YES;
    }
    
    NSInteger sideDishIndex = [[prefs objectForKey:@"SideDish1"] integerValue];
    
    if(sideDishIndex != -1)
    {
        self.ivSideDish1.image = [UIImage imageNamed:@"sample"];
        self.ivSideDish1.hidden = NO;
        self.lblSideDish1.hidden = NO;
    }
    else
    {
        self.ivSideDish1.image = nil;
        self.ivSideDish1.hidden = YES;
        self.lblSideDish1.hidden = YES;
    }
    
    sideDishIndex = [[prefs objectForKey:@"SideDish2"] integerValue];
    
    if(sideDishIndex != -1)
    {
        self.ivSideDish2.image = [UIImage imageNamed:@"sample"];
        self.ivSideDish2.hidden = NO;
        self.lblSideDish2.hidden = NO;
    }
    else
    {
        self.ivSideDish2.image = nil;
        self.ivSideDish2.hidden = YES;
        self.lblSideDish2.hidden = YES;
    }
    
    sideDishIndex = [[prefs objectForKey:@"SideDish3"] integerValue];
    
    if(sideDishIndex != -1)
    {
        self.ivSideDish3.image = [UIImage imageNamed:@"sample"];
        self.ivSideDish3.hidden = NO;
        self.lblSideDish3.hidden = NO;
    }
    else
    {
        self.ivSideDish3.image = nil;
        self.ivSideDish3.hidden = YES;
        self.lblSideDish3.hidden = YES;
    }
    
    sideDishIndex = [[prefs objectForKey:@"SideDish4"] integerValue];
    
    if(sideDishIndex != -1)
    {
        self.ivSideDish4.image = [UIImage imageNamed:@"sample"];
        self.ivSideDish4.hidden = NO;
        self.lblSideDish4.hidden = NO;
    }
    else
    {
        self.ivSideDish4.image = nil;
        self.ivSideDish4.hidden = YES;
        self.lblSideDish4.hidden = YES;
    }
}

- (IBAction)onFaq:(id)sender
{
    [self performSegueWithIdentifier:@"Faq" sender:nil];
}

- (IBAction)onCart:(id)sender
{
    if([self isCompletedToMakeMyBento])
    {
        [self gotoOrderScreen];
    }
    else
    {
        [self showConfirmMsg];
    }
}

- (void) showConfirmMsg
{
    MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"" message:@"You didn't finish your Bento. \nWant us to finish it for you?" delegate:self cancelButtonTitle:@"No" otherButtonTitle:@"Yes"];
    
    [alertView showInView:self.view];
    alertView = nil;
}

- (void) gotoOrderScreen
{
    if(YES) [self gotoRegisterScreen];
}

- (void) gotoRegisterScreen
{
    [self performSegueWithIdentifier:@"Register" sender:nil];
}

- (void) gotoDeliveryLocationScreen
{
    [self performSegueWithIdentifier:@"DeliveryLocation" sender:nil];
}

- (IBAction)onAddMainEntree:(id)sender
{
    [self performSegueWithIdentifier:@"MainDish" sender:nil];
}

- (IBAction)onAddSideDish:(id)sender
{
    NSInteger tag = ((UIButton *)sender).tag;
    
    [self performSegueWithIdentifier:@"SideDish" sender:[NSNumber numberWithInteger:tag]];
}

- (IBAction)onAddAnotherBento:(id)sender
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    [prefs setValue:[NSNumber numberWithInteger:-1] forKey:@"MainDish"];
    
    [prefs setValue:[NSNumber numberWithInteger:-1] forKey:@"SideDish1"];
    [prefs setValue:[NSNumber numberWithInteger:-1] forKey:@"SideDish2"];
    [prefs setValue:[NSNumber numberWithInteger:-1] forKey:@"SideDish3"];
    [prefs setValue:[NSNumber numberWithInteger:-1] forKey:@"SideDish4"];
    
    [prefs synchronize];
    
    [self updateUI];
}

- (void) updateUI
{
    [self loadSelectedDishes];
    
    self.btnCart.selected = [self isCompletedToMakeMyBento];
    
    if([self isCompletedToMakeMyBento])
    {
        [self.btnState setBackgroundImage:[UIImage imageNamed:@"mybento_image_bottom"] forState:UIControlStateNormal];
        [self.btnState setBackgroundColor:[UIColor clearColor]];
        
        [self.btnState setTitle:@"FINALIZE ORDER" forState:UIControlStateNormal];
    }
    else
    {
        [self.btnState setBackgroundImage:[UIImage alloc] forState:UIControlStateNormal];
        [self.btnState setBackgroundColor:[UIColor colorWithRed:122.0f / 255.0f green:133.0f / 255.0f blue:146.0f / 255.0f alpha:1.0f]];
        
        [self.btnState setTitle:@"CONTINUE" forState:UIControlStateNormal];
    }
}

- (BOOL) isCompletedToMakeMyBento
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    NSInteger mainDishIndex = [[prefs objectForKey:@"MainDish"] integerValue];
    
    if(mainDishIndex == -1)
    {
        return NO;
    }
    
    NSInteger sideDishIndex = [[prefs objectForKey:@"SideDish1"] integerValue];
    
    if(sideDishIndex == -1)
    {
        return NO;
    }
    
    sideDishIndex = [[prefs objectForKey:@"SideDish2"] integerValue];
    
    if(sideDishIndex == -1)
    {
        return NO;
    }
    
    sideDishIndex = [[prefs objectForKey:@"SideDish3"] integerValue];
    
    if(sideDishIndex == -1)
    {
        return NO;
    }
    
    sideDishIndex = [[prefs objectForKey:@"SideDish4"] integerValue];
    
    if(sideDishIndex == -1)
    {
        return NO;
    }
    
    return YES;
}

#pragma mark MyAlertViewDelegate

- (void)alertView:(MyAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 1)
    {
        [self gotoOrderScreen];
    }
}

@end
