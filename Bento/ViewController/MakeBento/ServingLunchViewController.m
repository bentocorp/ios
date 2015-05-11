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

#import "PreviewCollectionViewCell.h"
#import "ServingLunchBentoViewController.h"

#import "MyAlertView.h"

#import "AppStrings.h"
#import "DataManager.h"
#import "BentoShop.h"

#import "SVPlacemark.h"

#import "NSUserDefaults+RMSaveCustomObject.h"

#import "AppDelegate.h"


@interface ServingLunchViewController () <UITableViewDataSource, UITableViewDelegate, MyAlertViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@end

@implementation ServingLunchViewController
{
    UIScrollView *scrollView;
    UITableView *myTableView;
    
    UILabel *lblBadge;
    UILabel *lblBanner;
    
    UIButton *btnCart;
    
    UIButton *btnState;
    
    UIStoryboard *storyboard;
    DeliveryLocationViewController *deliveryLocationViewController;
    CompleteOrderViewController *completeOrderViewController;
    
    // Tonight's Dinner
    UILabel *lblTitle;
    UICollectionView *cvDishes;
    
    NSIndexPath *_selectedPath;
    NSInteger hour;
    int weekday;
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
    [pagingTitleView addObjects:@[@"Serving Lunch", @"Tonight's Dinner Preview"]];
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
    
/*---Button State---*/
    
    btnState = [[UIButton alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT-45-65, SCREEN_WIDTH, 45)];
    [btnState setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btnState setBackgroundColor:[UIColor colorWithRed:0.475f green:0.522f blue:0.569f alpha:1.0f]];
    btnState.backgroundColor = [UIColor blackColor];
    btnState.titleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:13.0f];
    [btnState addTarget:self action:@selector(onContinue) forControlEvents:UIControlEventTouchUpInside];
    [scrollView addSubview:btnState];
    
    /*------*/
    
    NSString *strTitle = [[AppStrings sharedInstance] getString:BUILD_ADD_BUTTON];
    if (strTitle != nil)
    {
        NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:strTitle];
        float spacing = 1.0f;
        [attributedTitle addAttribute:NSKernAttributeName
                                value:@(spacing)
                                range:NSMakeRange(0, [strTitle length])];
        
        strTitle = [[AppStrings sharedInstance] getString:BUILD_CONTINUE_BUTTON];
        [btnState setTitle:strTitle forState:UIControlStateNormal];
        attributedTitle = [[NSMutableAttributedString alloc] initWithString:strTitle];
        spacing = 1.0f;
        [attributedTitle addAttribute:NSKernAttributeName
                                value:@(spacing)
                                range:NSMakeRange(0, [strTitle length])];
        
        btnState.titleLabel.attributedText = attributedTitle;
        attributedTitle = nil;
    }
    
    if ([[BentoShop sharedInstance] getTotalBentoCount] == 0)
        [[BentoShop sharedInstance] addNewBento];
    
    lblBadge.hidden = NO;
    btnCart.hidden = NO;
    btnState.hidden = NO;
    
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    CLLocationCoordinate2D location = [delegate getCurrentLocation];
    BentoShop *globalShop = [BentoShop sharedInstance];
    if (![globalShop checkLocation:location] && [[DataManager shareDataManager] getUserInfo] == nil)
    {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"nextToBuild"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self.navigationController pushViewController:deliveryLocationViewController animated:NO];
    }
    
    
/*-------------------------------------Tonight's Dinner---------------------------------------*/
    
    /*---Collection View---*/
    
    // this sets the layout of the cells
    UICollectionViewFlowLayout *collectionViewFlowLayout = [[UICollectionViewFlowLayout alloc] init];
    [collectionViewFlowLayout setMinimumLineSpacing:0];
    [collectionViewFlowLayout setMinimumInteritemSpacing:0];
    [cvDishes setCollectionViewLayout:collectionViewFlowLayout];
    
    cvDishes = [[UICollectionView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH, 0, SCREEN_WIDTH, SCREEN_HEIGHT-65) collectionViewLayout:collectionViewFlowLayout];
    cvDishes.backgroundColor = [UIColor colorWithRed:0.910f green:0.925f blue:0.925f alpha:1.0f];
    cvDishes.dataSource = self;
    cvDishes.delegate = self;
    
    UINib *cellNib = [UINib nibWithNibName:@"PreviewCollectionViewCell" bundle:nil];
    [cvDishes registerNib:cellNib forCellWithReuseIdentifier:@"PreviewCollectionViewCell"];
    [cvDishes registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView"];
    
    [scrollView addSubview:cvDishes];
    
    // Get current hour
    NSDate *currentDate = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitHour fromDate:currentDate];
    
    hour = [components hour];
    NSLog(@"current hour - %ld", hour);
    
    // Sunday = 1, Saturday = 7
    weekday = (int)[[calendar components:NSCalendarUnitWeekday fromDate:currentDate] weekday];
    NSLog(@"today is - %ld", (long)weekday);
    
    // set menu title
    //    // if sold out || (closed && before 9pm && is not sunday && is not saturday)
    //    if ([[BentoShop sharedInstance] isSoldOut] ||
    //        (([[BentoShop sharedInstance] isClosed] && hour < 21) && weekday != 1 && weekday != 7)) {
    //
    //        self.lblTitle.text = [NSString stringWithFormat:@"%@'s Menu", [[BentoShop sharedInstance] getMenuWeekdayString]];
    //
    //    } else if ([[BentoShop sharedInstance] isClosed]) {
    //
    //        self.lblTitle.text = [NSString stringWithFormat:@"%@'s Menu", [[BentoShop sharedInstance] getNextMenuWeekdayString]];
    //    }
    
    _selectedPath = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return tableView.frame.size.height/2 + 40;
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
    
    servingLunchCell.lblMainDish.text = @"Pork in Black Bean Sauce"; // set main dish name [ getMainLabel:indexpath.row]
    
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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateUI];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus:) name:USER_NOTIFICATION_UPDATED_MENU object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus:) name:USER_NOTIFICATION_UPDATED_STATUS object:nil];
    
    /*---------------Tomorrow Lunch------------*/
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedMenu:) name:USER_NOTIFICATION_UPDATED_NEXTMENU object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewWillDisappear:animated];
}

- (void)onUpdatedStatus:(NSNotification *)notification
{
    if ([[BentoShop sharedInstance] isClosed] && ![[DataManager shareDataManager] isAdminUser])
        [self showSoldoutScreen:[NSNumber numberWithInt:0]];
    else if ([[BentoShop sharedInstance] isSoldOut] && ![[DataManager shareDataManager] isAdminUser])
        [self showSoldoutScreen:[NSNumber numberWithInt:1]];
    else
        [self performSelectorOnMainThread:@selector(updateUI) withObject:nil waitUntilDone:NO];
}

- (void)onDish:(id)sender
{
    UIButton *selectedButton = (UIButton *)sender;
    
    ServingLunchBentoViewController *servingLunchBentoViewController = [[ServingLunchBentoViewController alloc] init];
    [self.navigationController pushViewController:servingLunchBentoViewController animated:YES];
    
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

- (void)updateUI
{
    [cvDishes reloadData];
    
    NSInteger salePrice = [[AppStrings sharedInstance] getInteger:SALE_PRICE];
    NSInteger unitPrice = [[AppStrings sharedInstance] getInteger:ABOUT_PRICE];
    
    lblBanner.hidden = YES;
    if (salePrice != 0 && salePrice < unitPrice)
    {
        lblBanner.hidden = NO;
        lblBanner.text = [NSString stringWithFormat:@"NOW ONLY $%ld", (long)salePrice];
    }
    
    if ([[BentoShop sharedInstance] getTotalBentoCount] == 0)
        [[BentoShop sharedInstance] addNewBento];
    else if ([[BentoShop sharedInstance] getCurrentBento] == nil)
        [[BentoShop sharedInstance] setCurrentBento:[[BentoShop sharedInstance] getLastBento]];
    
    [self loadSelectedDishes];
    
    if ([[BentoShop sharedInstance] getCompletedBentoCount] > 0)
    {
        btnCart.enabled = YES;
        btnCart.selected = YES;
        [btnCart setImage:[UIImage imageNamed:@"mybento_nav_cart_act"] forState:UIControlStateNormal];
    }
    else
    {
        btnCart.enabled = NO;
        btnCart.selected = NO;
    }
    
    if ([self isCompletedToMakeMyBento])
    {
        [btnState setBackgroundColor:[UIColor colorWithRed:135.0f / 255.0f green:178.0f / 255.0f blue:96.0f / 255.0f alpha:1.0f]];
        
        NSString *strTitle = [[AppStrings sharedInstance] getString:BUILD_COMPLETE_BUTTON];
        if (strTitle != nil)
        {
            [btnState setTitle:strTitle forState:UIControlStateNormal];
            NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:strTitle];
            float spacing = 1.0f;
            [attributedTitle addAttribute:NSKernAttributeName
                                    value:@(spacing)
                                    range:NSMakeRange(0, [strTitle length])];
            
            btnState.titleLabel.attributedText = attributedTitle;
            attributedTitle = nil;
        }
    }
    else
    {
        [btnState setBackgroundColor:[UIColor colorWithRed:122.0f / 255.0f green:133.0f / 255.0f blue:146.0f / 255.0f alpha:1.0f]];
        
        NSString *strTitle = [[AppStrings sharedInstance] getString:BUILD_CONTINUE_BUTTON];
        if (strTitle != nil)
        {
            [btnState setTitle:strTitle forState:UIControlStateNormal];
            NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:strTitle];
            float spacing = 1.0f;
            [attributedTitle addAttribute:NSKernAttributeName
                                    value:@(spacing)
                                    range:NSMakeRange(0, [strTitle length])];
            
            btnState.titleLabel.attributedText = attributedTitle;
            attributedTitle = nil;
        }
    }
    
    //    if (self.currentBento == nil)
    {
        NSInteger bentoCount = [[BentoShop sharedInstance] getCompletedBentoCount];
        if (bentoCount > 0)
        {
            lblBadge.text = [NSString stringWithFormat:@"%ld", (long)bentoCount];
            lblBadge.hidden = NO;
        }
        else
        {
            lblBadge.text = @"";
            lblBadge.hidden = YES;
        }
    }
    
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
}

- (void)loadSelectedDishes
{
    NSInteger mainDishIndex = 0;
    
    Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];
    if (currentBento != nil) {
        
        mainDishIndex = [currentBento getMainDish];
    }
    
    if (mainDishIndex > 0) {
        
//        ivMainDish.hidden = NO;
//        lblMainDish.hidden = NO;
        
        NSDictionary *dishInfo = [[BentoShop sharedInstance] getMainDish:mainDishIndex];
        if (dishInfo != nil)
        {
//            lblMainDish.text = [[dishInfo objectForKey:@"name"] uppercaseString];
//            
//            NSString *strImageURL = [dishInfo objectForKey:@"image1"];
//            [ivMainDish sd_setImageWithURL:[NSURL URLWithString:strImageURL] placeholderImage:[UIImage imageNamed:@"sample"]];
            
//            if ([[BentoShop sharedInstance] isDishSoldOut:mainDishIndex])
//                serving.ivBannerMainDish.hidden = NO;
//            else
//                self.ivBannerMainDish.hidden = YES;
        }
    } else {
//        self.ivBannerMainDish.hidden = YES;
    }
}

- (void)onContinue
{
    Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];
    
    if (currentBento != nil || ![currentBento isEmpty])
    {
        [[BentoShop sharedInstance] saveBentoArray];
        [self gotoOrderScreen];
    }
}

- (BOOL)isCompletedToMakeMyBento
{
    Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];
    if (currentBento == nil)
        return NO;
    
    return [currentBento isCompleted];
}

- (void)alertView:(MyAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];
        if (currentBento != nil && ![currentBento isCompleted])
            [currentBento completeBento:@"todayLunch"];
        
        [self gotoOrderScreen];
    }
}


//- (void)showConfirmMsg
//{
//    NSString *strText = [[AppStrings sharedInstance] getString:ALERT_BNF_TEXT];
//    NSString *strCancel = [[AppStrings sharedInstance] getString:ALERT_BNF_BUTTON_CANCEL];
//    NSString *strConfirm = [[AppStrings sharedInstance] getString:ALERT_BNF_BUTTON_CONFIRM];
//    MyAlertView *alertView = [[MyAlertView alloc] initWithTitle:@"" message:strText delegate:self cancelButtonTitle:strCancel otherButtonTitle:strConfirm];
//    
//    [alertView showInView:self.view];
//    alertView = nil;
//}

/*------------------------------------------Tomorrow Lunch---------------------------------------------*/

- (void)onUpdatedMenu:(NSNotification *)notification
{
    [cvDishes reloadData];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 2;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (section == 0)
    {
        // get dinner main preview
        NSArray *aryMainDishes = aryMainDishes = [[BentoShop sharedInstance] getMainDishes:@"tonightDinnerPreview"];
        
        if (aryMainDishes == nil)
            return 0;
        
        return aryMainDishes.count;
    }
    else if (section == 1)
    {
        // get dinner side preview
        NSArray *arySideDishes = [[BentoShop sharedInstance] getSideDishes:@"tonightDinnerPreview"];
        
        if (arySideDishes == nil)
            return 0;
        
        return arySideDishes.count;
    }
    
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PreviewCollectionViewCell *cell = (PreviewCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"PreviewCollectionViewCell" forIndexPath:indexPath];
    
    [cell initView];
    
    if (indexPath.section == 1)
        [cell setSmallDishCell];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    PreviewCollectionViewCell *myCell = (PreviewCollectionViewCell *)cell;
    
    if (indexPath.section == 0) // Main Dish
    {
        NSArray *aryMainDishes = [[BentoShop sharedInstance] getMainDishes:@"tonightDinnerPreview"];
        
        NSDictionary *dishInfo = [aryMainDishes objectAtIndex:indexPath.row];
        [myCell setDishInfo:dishInfo];
    }
    else if (indexPath.section == 1) // Side Dish
    {
        NSArray *arySideDishes = [[BentoShop sharedInstance] getSideDishes:@"tonightDinnerPreview"];
        
        NSDictionary *dishInfo = [arySideDishes objectAtIndex:indexPath.row];
        [myCell setDishInfo:dishInfo];
    }
    
    if (_selectedPath != nil && _selectedPath == indexPath)
    {
        [myCell setCellState:YES];
    }
    else
    {
        [myCell setCellState:NO];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) // Main Dish
    {
        return CGSizeMake(cvDishes.frame.size.width, cvDishes.frame.size.width * 3 / 5);
    }
    else if (indexPath.section == 1) // Side Dish
    {
        return CGSizeMake(cvDishes.frame.size.width / 2, cvDishes.frame.size.width / 2);
    }
    
    return CGSizeMake(0, 0);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (_selectedPath == indexPath)
    {
        _selectedPath = nil;
    }
    else
    {
        _selectedPath = indexPath;
    }
    
    [collectionView reloadData];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

// header
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    if (section == 0 || section == 1)
    {
        return CGSizeMake(cvDishes.frame.size.width, 44);
    }
    
    return CGSizeMake(0, 0);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:UICollectionElementKindSectionHeader])
    {
        UICollectionReusableView *reusableview = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView" forIndexPath:indexPath];
        
        if (reusableview == nil)
            reusableview = [[UICollectionReusableView alloc] initWithFrame:CGRectMake(0, 0, cvDishes.frame.size.width, 44)];
        
        UILabel *label = (UILabel *)[reusableview viewWithTag:1];
        if (label == nil)
        {
            label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, reusableview.frame.size.width, reusableview.frame.size.height)];
            label.tag = 1;
            [reusableview addSubview:label];
        }
        
        label.textColor = [UIColor whiteColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont fontWithName:@"OpenSans-Semibold" size:16.0f];
        
        if (indexPath.section == 0)
            label.text = @"Main Dishes";
        else if (indexPath.section == 1)
            label.text = @"Side Dishes";
        
        reusableview.backgroundColor = [UIColor darkGrayColor];
        
        return reusableview;
    }
    
    return nil;
}

@end
