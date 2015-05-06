//
//  ServingLunchViewController.m
//  Bento
//
//  Created by Joseph Lau on 5/5/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
#define BORDER_COLOR [UIColor colorWithRed:223.0f / 255.0f green:226.0f / 255.0f blue:226.0f / 255.0f alpha:1.0f]

#import "ServingLunchViewController.h"
#import "ServingLunchCell.h"

#import "BWTitlePagerView.h"

#import "SignedInSettingsViewController.h"
#import "SignedOutSettingsViewController.h"

#import "DeliveryLocationViewController.h"
#import "CompleteOrderViewController.h"

#import "MyAlertView.h"

#import "AppStrings.h"
#import "DataManager.h"
#import "BentoShop.h"

#import "SVPlacemark.h"

#import "NSUserDefaults+RMSaveCustomObject.h"


@interface ServingLunchViewController () <UITableViewDataSource, UITableViewDelegate, MyAlertViewDelegate>

@end

@implementation ServingLunchViewController
{
    UIScrollView *scrollView;
    UITableView *myTableView;
    
    UILabel *lblBadge;
    UILabel *lblBanner;
    
    UIButton *btnCart;
    
    UIStoryboard *storyboard;
    DeliveryLocationViewController *deliveryLocationViewController;
    CompleteOrderViewController *completeOrderViewController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    deliveryLocationViewController = [storyboard instantiateViewControllerWithIdentifier:@"DeliveryLocationViewController"];
    completeOrderViewController = [storyboard instantiateViewControllerWithIdentifier:@"CompleteOrderViewController"];
    
/*---Scroll View---*/
    
    scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 45, SCREEN_WIDTH, SCREEN_HEIGHT)];
    scrollView.contentSize = CGSizeMake(SCREEN_WIDTH*2, SCREEN_HEIGHT-65);
    scrollView.pagingEnabled = YES;
    scrollView.backgroundColor = [UIColor colorWithRed:0.910f green:0.925f blue:0.925f alpha:1.0f];
    scrollView.bounces = NO;
    [self.view addSubview:scrollView];
    
/*---My Table View---*/
    myTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT-65)];
    myTableView.backgroundColor = [UIColor colorWithRed:0.910f green:0.925f blue:0.925f alpha:1.0f];
    myTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    myTableView.allowsSelection = NO;
    myTableView.dataSource = self;
    myTableView.delegate = self;
    [scrollView addSubview:myTableView];
    
/*---Navigation View---*/
    
    UIView *navigationBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 65)];
    navigationBarView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:navigationBarView];
    
/*---BW Title Pager View---*/
    
    BWTitlePagerView *pagingTitleView = [[BWTitlePagerView alloc] init];
    pagingTitleView.frame = CGRectMake(SCREEN_WIDTH/2-100, 32.5 - 10, 200, 40);
    pagingTitleView.font = [UIFont fontWithName:@"OpenSans-Bold" size:16.0f];
    pagingTitleView.currentTintColor = [UIColor colorWithRed:0.341f green:0.376f blue:0.439f alpha:1.0f];
    [pagingTitleView observeScrollView:scrollView];
    [pagingTitleView addObjects:@[@"Now Serving Lunch", @"Upcoming Dinner"]];
    [navigationBarView addSubview:pagingTitleView];
    
/*---Line Separator---*/
    
    UIView *longLineSepartor1 = [[UIView alloc] initWithFrame:CGRectMake(0, 65, SCREEN_WIDTH, 1)];
    longLineSepartor1.backgroundColor = [UIColor colorWithRed:0.827f green:0.835f blue:0.835f alpha:1.0f];
    [navigationBarView addSubview:longLineSepartor1];
    
/*---Back button---*/
    
    UIImageView *settingsImageView = [[UIImageView alloc] initWithFrame:CGRectMake(12, 30, 25, 25)];
    settingsImageView.image = [UIImage imageNamed:@"icon-user"];
    [navigationBarView addSubview:settingsImageView];
    
/*---Settings Button---*/
    
    UIButton *settingsButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 20, 50, 45)];
    [settingsButton addTarget:self action:@selector(onSettings) forControlEvents:UIControlEventTouchUpInside];
    [navigationBarView addSubview:settingsButton];
    
/*---Cart Button---*/
    
    btnCart = [[UIButton alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 50, 20, 50, 45)];
    [btnCart setImage:[UIImage imageNamed:@"mybento_nav_cart_inact"] forState:UIControlStateNormal];
    [btnCart addTarget:self action:@selector(onCart) forControlEvents:UIControlEventTouchUpInside];
    [navigationBarView addSubview:btnCart];
    
    btnCart.hidden = NO;
    
/*---Count Badge---*/
    
    lblBadge = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 42.5, 25, 14, 14)];
    lblBadge.textAlignment = NSTextAlignmentCenter;
    lblBadge.font = [UIFont fontWithName:@"OpenSans-Semibold" size:10];
    lblBadge.backgroundColor = [UIColor colorWithRed:0.890f green:0.247f blue:0.373f alpha:1.0f];
    lblBadge.textColor = [UIColor whiteColor];
    lblBadge.layer.cornerRadius = lblBadge.frame.size.width / 2;
    lblBadge.clipsToBounds = YES;
    [navigationBarView addSubview:lblBadge];
    
/*---Banner---*/
    
    lblBanner = [[UILabel alloc] initWithFrame:CGRectMake(0, 65, SCREEN_WIDTH, 28)];
    lblBanner.textAlignment = NSTextAlignmentCenter;
    lblBanner.textColor = [UIColor whiteColor];
    lblBanner.backgroundColor = [UIColor colorWithRed:0.882f green:0.361f blue:0.035f alpha:0.8f];
    lblBanner.hidden = YES;
    lblBanner.center = CGPointMake(self.view.frame.size.width * 5 / 6, 64 + self.view.frame.size.width / 6);
    lblBanner.transform = CGAffineTransformMakeRotation(M_PI / 4);
    lblBanner.font = [UIFont fontWithName:@"OpenSans-Bold" size:16.0f];
    [scrollView addSubview:lblBanner];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return tableView.frame.size.height/2-10;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ServingLunchCell *servingLunchCell = (ServingLunchCell *)[tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (servingLunchCell == nil) {
        servingLunchCell = [[ServingLunchCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    
    servingLunchCell.ivMainDish.image = [UIImage imageNamed:@""]; //  set main dish image
    
    servingLunchCell.lblMainDish.text = @"Test Label"; // set main dish name [ getMainLabel:indexpath.row]
    
    servingLunchCell.btnMainDish.tag = indexPath.row; // set button tag
    [servingLunchCell.btnMainDish addTarget:self action:@selector(onDish:) forControlEvents:UIControlEventTouchUpInside]; // button action
    
    servingLunchCell.ivBannerMainDish.hidden = YES; // when to show/hide?
    
    return servingLunchCell;
}

- (void)onSettings
{
    // get current user info
    NSDictionary *currentUserInfo = [[DataManager shareDataManager] getUserInfo];
    
    SignedInSettingsViewController *signedInSettingsViewController = [[SignedInSettingsViewController alloc] init];
    SignedOutSettingsViewController *signedOutSettingsViewController = [[SignedOutSettingsViewController alloc] init];
    UINavigationController *navC;
    
    // signed in or not?
    if (currentUserInfo == nil) {
        
        // navigate to signed out settings vc
        navC = [[UINavigationController alloc] initWithRootViewController:signedOutSettingsViewController];
        navC.navigationBar.hidden = YES;
        [self.navigationController presentViewController:navC animated:YES completion:nil];
        
    } else {
        
        // navigate to signed in settings vc
        navC = [[UINavigationController alloc] initWithRootViewController:signedInSettingsViewController];
        navC.navigationBar.hidden = YES;
        [self.navigationController presentViewController:navC animated:YES completion:nil];
    }
}

- (void)onDish:(id)sender
{
    UIButton *selectedButton = (UIButton *)sender;
    
    NSLog(@"Dish Selected Tag - %ld", selectedButton.tag);
}

- (void)onCart
{
    Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];
    if (currentBento != nil && ![currentBento isEmpty] && ![currentBento isCompleted])
        [self showConfirmMsg];
    else
        [self gotoOrderScreen];
}

- (void)showConfirmMsg
{
    NSString *strText = [[AppStrings sharedInstance] getString:ALERT_BNF_TEXT];
    NSString *strCancel = [[AppStrings sharedInstance] getString:ALERT_BNF_BUTTON_CANCEL];
    NSString *strConfirm = [[AppStrings sharedInstance] getString:ALERT_BNF_BUTTON_CONFIRM];
    MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"" message:strText delegate:self cancelButtonTitle:strCancel otherButtonTitle:strConfirm];
    
    [alertView showInView:self.view];
    alertView = nil;
}

- (void)gotoOrderScreen
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
            [self.navigationController pushViewController:deliveryLocationViewController animated:YES];
        else
            [self.navigationController pushViewController:completeOrderViewController animated:YES];
    }
}

//- (void)updateUI
//{
//    NSInteger salePrice = [[AppStrings sharedInstance] getInteger:SALE_PRICE];
//    NSInteger unitPrice = [[AppStrings sharedInstance] getInteger:ABOUT_PRICE];
//    
//    lblBanner.hidden = YES;
//    if (salePrice != 0 && salePrice < unitPrice)
//    {
//        lblBanner.hidden = NO;
//        lblBanner.text = [NSString stringWithFormat:@"NOW ONLY $%ld", (long)salePrice];
//    }
//    
//    if ([[BentoShop sharedInstance] getTotalBentoCount] == 0)
//        [[BentoShop sharedInstance] addNewBento];
//    else if ([[BentoShop sharedInstance] getCurrentBento] == nil)
//        [[BentoShop sharedInstance] setCurrentBento:[[BentoShop sharedInstance] getLastBento]];
//    
//    [self loadSelectedDishes];
//    
//    if ([[BentoShop sharedInstance] getCompletedBentoCount] > 0)
//    {
//        btnCart.enabled = YES;
//        btnCart.selected = YES;
//        [btnCart setImage:[UIImage imageNamed:@"mybento_nav_cart_act"] forState:UIControlStateNormal];
//    }
//    else
//    {
//        btnCart.enabled = NO;
//        btnCart.selected = NO;
//    }
//    
//    if ([self isCompletedToMakeMyBento])
//    {
//        [btnState setBackgroundColor:[UIColor colorWithRed:135.0f / 255.0f green:178.0f / 255.0f blue:96.0f / 255.0f alpha:1.0f]];
//        
//        NSString *strTitle = [[AppStrings sharedInstance] getString:BUILD_COMPLETE_BUTTON];
//        if (strTitle != nil)
//        {
//            [btnState setTitle:strTitle forState:UIControlStateNormal];
//            NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:strTitle];
//            float spacing = 1.0f;
//            [attributedTitle addAttribute:NSKernAttributeName
//                                    value:@(spacing)
//                                    range:NSMakeRange(0, [strTitle length])];
//            
//            btnState.titleLabel.attributedText = attributedTitle;
//            attributedTitle = nil;
//        }
//    }
//    else
//    {
//        [btnState setBackgroundColor:[UIColor colorWithRed:122.0f / 255.0f green:133.0f / 255.0f blue:146.0f / 255.0f alpha:1.0f]];
//        
//        NSString *strTitle = [[AppStrings sharedInstance] getString:BUILD_CONTINUE_BUTTON];
//        if (strTitle != nil)
//        {
//            [btnState setTitle:strTitle forState:UIControlStateNormal];
//            NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:strTitle];
//            float spacing = 1.0f;
//            [attributedTitle addAttribute:NSKernAttributeName
//                                    value:@(spacing)
//                                    range:NSMakeRange(0, [strTitle length])];
//            
//            btnState.titleLabel.attributedText = attributedTitle;
//            attributedTitle = nil;
//        }
//    }
//    
//    //    if (self.currentBento == nil)
//    {
//        NSInteger bentoCount = [[BentoShop sharedInstance] getCompletedBentoCount];
//        if (bentoCount > 0)
//        {
//            lblBadge.text = [NSString stringWithFormat:@"%ld", (long)bentoCount];
//            lblBadge.hidden = NO;
//        }
//        else
//        {
//            lblBadge.text = @"";
//            lblBadge.hidden = YES;
//        }
//    }
//    
//    Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];
//    if (currentBento == nil || ![currentBento isCompleted])
//    {
//        btnAddAnotherBento.enabled = NO;
//        [btnAddAnotherBento setBackgroundColor:[UIColor colorWithRed:238.0f / 255.0f green:241.0f / 255.0f blue:241.0f / 255.0f alpha:1.0f]];
//    }
//    else
//    {
//        btnAddAnotherBento.enabled = YES;
//        [btnAddAnotherBento setBackgroundColor:[UIColor colorWithRed:243.0f / 255.0f green:245.0f / 255.0f blue:245.0f / 255.0f alpha:1.0f]];
//    }
//}
//
//- (void)didReceiveMemoryWarning {
//    [super didReceiveMemoryWarning];
//}

@end
