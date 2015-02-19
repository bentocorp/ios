//
//  MyBentoViewController.m
//  Bento
//
//  Created by hanjinghe on 1/6/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "MyBentoViewController.h"

#import "AppDelegate.h"

#import "ChooseMainDishViewController.h"
#import "ChooseSideDishViewController.h"

#import "CompleteOrderViewController.h"
#import "DeliveryLocationViewController.h"

#import "MyAlertView.h"

#import "CAGradientLayer+SJSGradients.h"

#import "UIImageView+WebCache.h"

#import "BentoShop.h"
#import "AppStrings.h"
#import "DataManager.h"

#import "SVPlacemark.h"
#import "NSUserDefaults+RMSaveCustomObject.h"

#define BORDER_COLOR [UIColor colorWithRed:223.0f / 255.0f green:226.0f / 255.0f blue:226.0f / 255.0f alpha:1.0f]

@interface MyBentoViewController ()<MyAlertViewDelegate>

@property (nonatomic, assign) IBOutlet UILabel *lblTitle;

@property (nonatomic, assign) IBOutlet UIButton *btnBack;

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

@property (nonatomic, assign) IBOutlet UIButton *btnMainDish;

@property (nonatomic, assign) IBOutlet UIButton *btnSideDish1;
@property (nonatomic, assign) IBOutlet UIButton *btnSideDish2;
@property (nonatomic, assign) IBOutlet UIButton *btnSideDish3;
@property (nonatomic, assign) IBOutlet UIButton *btnSideDish4;

@property (weak, nonatomic) IBOutlet UIImageView *ivBannerMainDish;
@property (weak, nonatomic) IBOutlet UIImageView *ivBannerSideDish1;
@property (weak, nonatomic) IBOutlet UIImageView *ivBannerSideDish2;
@property (weak, nonatomic) IBOutlet UIImageView *ivBannerSideDish3;
@property (weak, nonatomic) IBOutlet UIImageView *ivBannerSideDish4;


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
    self.viewDishs.layer.borderColor = BORDER_COLOR.CGColor;
    self.viewDishs.layer.borderWidth = 1.0f;
    
    int everyDishHeight = self.viewDishs.frame.size.height / 3;
    
    self.viewMainEntree.frame = CGRectMake(-1, -1, self.viewDishs.frame.size.width + 2, everyDishHeight + 2);
    self.ivBannerMainDish.frame = CGRectMake(self.viewMainEntree.frame.size.width - self.viewMainEntree.frame.size.height / 2, 0, self.viewMainEntree.frame.size.height / 2, self.viewMainEntree.frame.size.height / 2);
    
    self.viewSide1.frame = CGRectMake(-1, everyDishHeight, self.viewDishs.frame.size.width / 2 + 2, everyDishHeight + 1);
    self.viewSide1.layer.borderWidth = 1.0f;
    self.viewSide1.layer.borderColor = BORDER_COLOR.CGColor;
    self.ivBannerSideDish1.frame = CGRectMake(self.viewSide1.frame.size.width - self.viewSide1.frame.size.height / 2, 0, self.viewSide1.frame.size.height / 2, self.viewSide1.frame.size.height / 2);
    
    self.viewSide2.frame = CGRectMake(self.viewDishs.frame.size.width / 2, everyDishHeight, self.viewDishs.frame.size.width / 2 + 1, everyDishHeight + 1);
    self.viewSide2.layer.borderWidth = 1.0f;
    self.viewSide2.layer.borderColor = BORDER_COLOR.CGColor;
    self.ivBannerSideDish2.frame = CGRectMake(self.viewSide2.frame.size.width - self.viewSide2.frame.size.height / 2, 0, self.viewSide2.frame.size.height / 2, self.viewSide2.frame.size.height / 2);
    
    self.viewSide3.frame = CGRectMake(-1, everyDishHeight * 2, self.viewDishs.frame.size.width / 2 + 2, everyDishHeight + 2);
    self.viewSide3.layer.borderWidth = 1.0f;
    self.viewSide3.layer.borderColor = BORDER_COLOR.CGColor;
    self.ivBannerSideDish3.frame = CGRectMake(self.viewSide3.frame.size.width - self.viewSide3.frame.size.height / 2, 0, self.viewSide3.frame.size.height / 2, self.viewSide3.frame.size.height / 2);
    
    self.viewSide4.frame = CGRectMake(self.viewDishs.frame.size.width / 2, everyDishHeight * 2, self.viewDishs.frame.size.width / 2 + 1, everyDishHeight + 2);
    self.viewSide4.layer.borderWidth = 1.0f;
    self.viewSide4.layer.borderColor = BORDER_COLOR.CGColor;
    self.ivBannerSideDish4.frame = CGRectMake(self.viewSide4.frame.size.width - self.viewSide4.frame.size.height / 2, 0, self.viewSide4.frame.size.height / 2, self.viewSide4.frame.size.height / 2);
    
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
    
    self.btnAddAnotherBento.layer.borderColor = BORDER_COLOR.CGColor;
    self.btnAddAnotherBento.layer.borderWidth = 1.0f;
    
    [self.lblTitle setText:[[AppStrings sharedInstance] getString:BUILD_TITLE]];
    
    [self.btnMainDish setTitle:[[AppStrings sharedInstance] getString:BUILD_MAIN_BUTTON] forState:UIControlStateNormal];
    [self.btnSideDish1 setTitle:[[AppStrings sharedInstance] getString:BUILD_SIDE1_BUTTON] forState:UIControlStateNormal];
    [self.btnSideDish2 setTitle:[[AppStrings sharedInstance] getString:BUILD_SIDE2_BUTTON] forState:UIControlStateNormal];
    [self.btnSideDish3 setTitle:[[AppStrings sharedInstance] getString:BUILD_SIDE3_BUTTON] forState:UIControlStateNormal];
    [self.btnSideDish4 setTitle:[[AppStrings sharedInstance] getString:BUILD_SIDE4_BUTTON] forState:UIControlStateNormal];
    
    NSString *strTitle = [[AppStrings sharedInstance] getString:BUILD_ADD_BUTTON];
    if (strTitle != nil)
    {
        [self.btnAddAnotherBento setTitle:strTitle forState:UIControlStateNormal];
        NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:strTitle];
        float spacing = 1.0f;
        [attributedTitle addAttribute:NSKernAttributeName
                                value:@(spacing)
                                range:NSMakeRange(0, [strTitle length])];
        
        self.btnAddAnotherBento.titleLabel.attributedText = attributedTitle;
        
        strTitle = [[AppStrings sharedInstance] getString:BUILD_CONTINUE_BUTTON];
        [self.btnState setTitle:strTitle forState:UIControlStateNormal];
        attributedTitle = [[NSMutableAttributedString alloc] initWithString:strTitle];
        spacing = 1.0f;
        [attributedTitle addAttribute:NSKernAttributeName
                                value:@(spacing)
                                range:NSMakeRange(0, [strTitle length])];
        
        self.btnState.titleLabel.attributedText = attributedTitle;
        attributedTitle = nil;
    }
    
    if ([[BentoShop sharedInstance] getTotalBentoCount] == 0)
        [[BentoShop sharedInstance] addNewBento];

    [self.btnBack setImage:[UIImage imageNamed:@"mybento_nav_help"] forState:UIControlStateNormal];
    
    self.lblBadge.hidden = NO;
    self.btnCart.hidden = NO;
    self.btnAddAnotherBento.hidden = NO;
    self.btnState.hidden = NO;

    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    CLLocationCoordinate2D location = [delegate getCurrentLocation];
    BentoShop *globalShop = [BentoShop sharedInstance];
    if (![globalShop checkLocation:location] && [[DataManager shareDataManager] getUserInfo] == nil)
    {
        UIViewController *vcLocation = [self.storyboard instantiateViewControllerWithIdentifier:@"DeliveryLocationViewController"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"nextToBuild"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self.navigationController pushViewController:vcLocation animated:NO];
    }
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
    
    if ([segue.identifier isEqualToString:@"MainDish"])
    {
        ChooseMainDishViewController *vc = segue.destinationViewController;
    }
    else if ([segue.identifier isEqualToString:@"SideDish"])
    {
        ChooseSideDishViewController *vc = segue.destinationViewController;
        
        NSNumber *number = (NSNumber *)sender;
        vc.sideDishIndex = [number integerValue];
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateUI];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus:) name:USER_NOTIFICATION_UPDATED_MENU object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus:) name:USER_NOTIFICATION_UPDATED_STATUS object:nil];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) onUpdatedStatus:(NSNotification *)notification
{
    if ([[BentoShop sharedInstance] isClosed] && ![[DataManager shareDataManager] isAdminUser])
        [self showSoldoutScreen:[NSNumber numberWithInt:0]];
    else if ([[BentoShop sharedInstance] isSoldOut] && ![[DataManager shareDataManager] isAdminUser])
        [self showSoldoutScreen:[NSNumber numberWithInt:1]];
    else
        [self performSelectorOnMainThread:@selector(updateUI) withObject:nil waitUntilDone:NO];
}

- (void) loadSelectedDishes
{
    NSInteger mainDishIndex = 0;
    NSInteger side1DishIndex = 0;
    NSInteger side2DishIndex = 0;
    NSInteger side3DishIndex = 0;
    NSInteger side4DishIndex = 0;
    
    Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];
    if (currentBento != nil)
    {
        mainDishIndex = [currentBento getMainDish];
        side1DishIndex = [currentBento getSideDish1];
        side2DishIndex = [currentBento getSideDish2];
        side3DishIndex = [currentBento getSideDish3];
        side4DishIndex = [currentBento getSideDish4];
    }
    
    if (mainDishIndex > 0)
    {
        self.ivMainDish.hidden = NO;
        self.lblMainDish.hidden = NO;
        
        NSDictionary *dishInfo = [[BentoShop sharedInstance] getMainDish:mainDishIndex];
        if (dishInfo != nil)
        {
            self.lblMainDish.text = [[dishInfo objectForKey:@"name"] uppercaseString];
            
            NSString *strImageURL = [dishInfo objectForKey:@"image1"];
            [self.ivMainDish sd_setImageWithURL:[NSURL URLWithString:strImageURL] placeholderImage:[UIImage imageNamed:@"sample"]];
            
            if ([[BentoShop sharedInstance] isDishSoldOut:mainDishIndex])
                self.ivBannerMainDish.hidden = NO;
            else
                self.ivBannerMainDish.hidden = YES;
        }
    }
    else
    {
        self.ivMainDish.image = nil;
        self.ivMainDish.hidden = YES;
        self.lblMainDish.hidden = YES;
        self.ivBannerMainDish.hidden = YES;
    }
    
    if (side1DishIndex > 0)
    {
        self.ivSideDish1.hidden = NO;
        self.lblSideDish1.hidden = NO;

        NSDictionary *dishInfo = [[BentoShop sharedInstance] getSideDish:side1DishIndex];
        if (dishInfo != nil)
        {
            self.lblSideDish1.text = [[dishInfo objectForKey:@"name"] uppercaseString];
            
            NSString *strImageURL = [dishInfo objectForKey:@"image1"];
            [self.ivSideDish1 sd_setImageWithURL:[NSURL URLWithString:strImageURL] placeholderImage:[UIImage imageNamed:@"sample"]];
            
            if ([[BentoShop sharedInstance] isDishSoldOut:side1DishIndex])
                self.ivBannerSideDish1.hidden = NO;
            else
                self.ivBannerSideDish1.hidden = YES;
        }
    }
    else
    {
        self.ivSideDish1.image = nil;
        self.ivSideDish1.hidden = YES;
        self.lblSideDish1.hidden = YES;
        self.ivBannerSideDish1.hidden = YES;
    }
    
    if (side2DishIndex > 0)
    {
        self.ivSideDish2.hidden = NO;
        self.lblSideDish2.hidden = NO;

        
        NSDictionary *dishInfo = [[BentoShop sharedInstance] getSideDish:side2DishIndex];
        if (dishInfo != nil)
        {
            self.lblSideDish2.text = [[dishInfo objectForKey:@"name"] uppercaseString];
            
            NSString *strImageURL = [dishInfo objectForKey:@"image1"];
            [self.ivSideDish2 sd_setImageWithURL:[NSURL URLWithString:strImageURL] placeholderImage:[UIImage imageNamed:@"sample"]];
            
            if ([[BentoShop sharedInstance] isDishSoldOut:side2DishIndex])
                self.ivBannerSideDish2.hidden = NO;
            else
                self.ivBannerSideDish2.hidden = YES;
        }
    }
    else
    {
        self.ivSideDish2.image = nil;
        self.ivSideDish2.hidden = YES;
        self.lblSideDish2.hidden = YES;
        self.ivBannerSideDish2.hidden = YES;
    }
    
    if (side3DishIndex > 0)
    {
        self.ivSideDish3.hidden = NO;
        self.lblSideDish3.hidden = NO;

        
        NSDictionary *dishInfo = [[BentoShop sharedInstance] getSideDish:side3DishIndex];
        if (dishInfo != nil)
        {
            self.lblSideDish3.text = [[dishInfo objectForKey:@"name"] uppercaseString];
            
            NSString *strImageURL = [dishInfo objectForKey:@"image1"];
            [self.ivSideDish3 sd_setImageWithURL:[NSURL URLWithString:strImageURL] placeholderImage:[UIImage imageNamed:@"sample"]];
            
            if ([[BentoShop sharedInstance] isDishSoldOut:side3DishIndex])
                self.ivBannerSideDish3.hidden = NO;
            else
                self.ivBannerSideDish3.hidden = YES;
        }
    }
    else
    {
        self.ivSideDish3.image = nil;
        self.ivSideDish3.hidden = YES;
        self.lblSideDish3.hidden = YES;
        self.ivBannerSideDish3.hidden = YES;
    }
    
    if (side4DishIndex > 0)
    {
        self.ivSideDish4.hidden = NO;
        self.lblSideDish4.hidden = NO;

        
        NSDictionary *dishInfo = [[BentoShop sharedInstance] getSideDish:side4DishIndex];
        if (dishInfo != nil)
        {
            self.lblSideDish4.text = [[dishInfo objectForKey:@"name"] uppercaseString];
            
            NSString *strImageURL = [dishInfo objectForKey:@"image1"];
            [self.ivSideDish4 sd_setImageWithURL:[NSURL URLWithString:strImageURL] placeholderImage:[UIImage imageNamed:@"sample"]];
        }
        
        if ([[BentoShop sharedInstance] isDishSoldOut:side4DishIndex])
            self.ivBannerSideDish4.hidden = NO;
        else
            self.ivBannerSideDish4.hidden = YES;
    }
    else
    {
        self.ivSideDish4.image = nil;
        self.ivSideDish4.hidden = YES;
        self.lblSideDish4.hidden = YES;
        self.ivBannerSideDish4.hidden = YES;
    }
}

- (IBAction)onFaq:(id)sender
{
    [self performSegueWithIdentifier:@"Faq" sender:nil];
}

- (IBAction)onCart:(id)sender
{
    Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];
    if (currentBento != nil && ![currentBento isEmpty] && ![currentBento isCompleted])
        [self showConfirmMsg];
    else
        [self gotoOrderScreen];
}

- (void) showConfirmMsg
{
    NSString *strText = [[AppStrings sharedInstance] getString:ALERT_BNF_TEXT];
    NSString *strCancel = [[AppStrings sharedInstance] getString:ALERT_BNF_BUTTON_CANCEL];
    NSString *strConfirm = [[AppStrings sharedInstance] getString:ALERT_BNF_BUTTON_CONFIRM];
    MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"" message:strText delegate:self cancelButtonTitle:strCancel otherButtonTitle:strConfirm];
    
    [alertView showInView:self.view];
    alertView = nil;
}

- (void) gotoOrderScreen
{
    NSDictionary *currentUserInfo = [[DataManager shareDataManager] getUserInfo];
    SVPlacemark *placeInfo = [[NSUserDefaults standardUserDefaults] rm_customObjectForKey:@"delivery_location"];
    if (currentUserInfo == nil)
    {
        if (placeInfo == nil)
            [self openAccountViewController:[DeliveryLocationViewController class]];
        else
            [self openAccountViewController:[CompleteOrderViewController class]];
    }
    else
    {
        if (placeInfo == nil)
            [self performSegueWithIdentifier:@"DeliveryLocation" sender:nil];
        else
            [self performSegueWithIdentifier:@"CompleteOrder" sender:nil];
    }
}

- (IBAction)onAddMainDish:(id)sender
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
    Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];
    if (currentBento != nil && ![currentBento isCompleted])
        [currentBento completeBento];
    
    [[BentoShop sharedInstance] addNewBento];
    
    [self updateUI];
}

- (IBAction)onContinue:(id)sender
{
    Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];

    if (currentBento == nil || [currentBento isEmpty])
    {
        [self performSegueWithIdentifier:@"MainDish" sender:nil];
    }
    else if (![currentBento isCompleted])
    {
        if ([currentBento getMainDish] == 0)
            [self performSegueWithIdentifier:@"MainDish" sender:nil];
        else if ([currentBento getSideDish1] == 0)
            [self performSegueWithIdentifier:@"SideDish" sender:[NSNumber numberWithInteger:self.btnSideDish1.tag]];
        else if ([currentBento getSideDish2] == 0)
            [self performSegueWithIdentifier:@"SideDish" sender:[NSNumber numberWithInteger:self.btnSideDish2.tag]];
        else if ([currentBento getSideDish3] == 0)
            [self performSegueWithIdentifier:@"SideDish" sender:[NSNumber numberWithInteger:self.btnSideDish3.tag]];
        else if ([currentBento getSideDish4] == 0)
            [self performSegueWithIdentifier:@"SideDish" sender:[NSNumber numberWithInteger:self.btnSideDish4.tag]];
    }
    else // Completed Bento
    {
        [[BentoShop sharedInstance] saveBentoArray];
        [self gotoOrderScreen];
    }
}

- (void) updateUI
{
    if ([[BentoShop sharedInstance] getTotalBentoCount] == 0)
        [[BentoShop sharedInstance] addNewBento];
    else if ([[BentoShop sharedInstance] getCurrentBento] == nil)
        [[BentoShop sharedInstance] setCurrentBento:[[BentoShop sharedInstance] getLastBento]];
    
    [self loadSelectedDishes];
    
    if ([[BentoShop sharedInstance] getCompletedBentoCount] > 0)
    {
        self.btnCart.enabled = YES;
        self.btnCart.selected = YES;
    }
    else
    {
        self.btnCart.enabled = NO;
        self.btnCart.selected = NO;
    }
    
    if ([self isCompletedToMakeMyBento])
    {
        [self.btnState setBackgroundColor:[UIColor colorWithRed:135.0f / 255.0f green:178.0f / 255.0f blue:96.0f / 255.0f alpha:1.0f]];
        
        NSString *strTitle = [[AppStrings sharedInstance] getString:BUILD_COMPLETE_BUTTON];
        if (strTitle != nil)
        {
            [self.btnState setTitle:strTitle forState:UIControlStateNormal];
            NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:strTitle];
            float spacing = 1.0f;
            [attributedTitle addAttribute:NSKernAttributeName
                                    value:@(spacing)
                                    range:NSMakeRange(0, [strTitle length])];
            
            self.btnState.titleLabel.attributedText = attributedTitle;
            attributedTitle = nil;
        }
    }
    else
    {
        [self.btnState setBackgroundColor:[UIColor colorWithRed:122.0f / 255.0f green:133.0f / 255.0f blue:146.0f / 255.0f alpha:1.0f]];
        
        NSString *strTitle = [[AppStrings sharedInstance] getString:BUILD_CONTINUE_BUTTON];
        if (strTitle != nil)
        {
            [self.btnState setTitle:strTitle forState:UIControlStateNormal];
            NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:strTitle];
            float spacing = 1.0f;
            [attributedTitle addAttribute:NSKernAttributeName
                                    value:@(spacing)
                                    range:NSMakeRange(0, [strTitle length])];
            
            self.btnState.titleLabel.attributedText = attributedTitle;
            attributedTitle = nil;
        }
    }
    
//    if (self.currentBento == nil)
    {
        NSInteger bentoCount = [[BentoShop sharedInstance] getCompletedBentoCount];
        if (bentoCount > 0)
        {
            self.lblBadge.text = [NSString stringWithFormat:@"%ld", (long)bentoCount];
            self.lblBadge.hidden = NO;
        }
        else
        {
            self.lblBadge.text = @"";
            self.lblBadge.hidden = YES;
        }
    }
    
    Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];
    if (currentBento == nil || ![currentBento isCompleted])
    {
        self.btnAddAnotherBento.enabled = NO;
        [self.btnAddAnotherBento setBackgroundColor:[UIColor colorWithRed:238.0f / 255.0f green:241.0f / 255.0f blue:241.0f / 255.0f alpha:1.0f]];
    }
    else
    {
        self.btnAddAnotherBento.enabled = YES;
        [self.btnAddAnotherBento setBackgroundColor:[UIColor colorWithRed:243.0f / 255.0f green:245.0f / 255.0f blue:245.0f / 255.0f alpha:1.0f]];
    }
}

- (BOOL) isCompletedToMakeMyBento
{
    Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];
    if (currentBento == nil)
        return NO;
    
    return [currentBento isCompleted];
}

#pragma mark MyAlertViewDelegate

- (void)alertView:(MyAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];
        if (currentBento != nil && ![currentBento isCompleted])
            [currentBento completeBento];
        
        [self gotoOrderScreen];
    }
}

@end
