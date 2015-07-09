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

#import "FixedBentoViewController.h"
#import "FixedBentoCell.h"

#import "BWTitlePagerView.h"

#import "SignedInSettingsViewController.h"
#import "SignedOutSettingsViewController.h"

#import "DeliveryLocationViewController.h"
#import "CompleteOrderViewController.h"

#import "PreviewCollectionViewCell.h"
#import "FixedBentoPreviewViewController.h"

#import "MyAlertView.h"

#import "AppStrings.h"
#import "DataManager.h"
#import "BentoShop.h"

#import "AppDelegate.h"

#import "NSUserDefaults+RMSaveCustomObject.h"

#import "Canvas.h"

#import "SVPlacemark.h"

#import "JGProgressHUD.h"

#import "Mixpanel.h"

#import "Reachability.h"
#import <SystemConfiguration/SystemConfiguration.h>


@interface FixedBentoViewController () <UITableViewDataSource, UITableViewDelegate, MyAlertViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, retain) NSMutableArray *aryDishes;

@end

@implementation FixedBentoViewController
{
    NSArray *aryMainDishes;
    NSArray *arySideDishes;
    
    NSTimer *connectionTimer;
    
    UIView *navigationBarView;
    
    UIScrollView *scrollView;
    UITableView *myTableView;
    
    UILabel *lblBadge;
    UILabel *lblBanner;
    
    UIButton *btnCart;
    
    UIButton *btnState;
    
    // Right
    UILabel *lblTitle;
    UICollectionView *cvDishes;
    
    NSIndexPath *_selectedPath;
    NSInteger hour;
    int weekday;
    
    BWTitlePagerView *pagingTitleView;
    
    FixedBentoCell *servingLunchCell;
    
    CSAnimationView *animationView;
    
    JGProgressHUD *loadingHUD;
    
    NSMutableArray *savedArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
/*---Scroll View---*/
    
    scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 45, SCREEN_WIDTH, SCREEN_HEIGHT)];
    scrollView.pagingEnabled = YES;
    scrollView.backgroundColor = [UIColor colorWithRed:0.910f green:0.925f blue:0.925f alpha:1.0f];
    scrollView.bounces = NO;
    [self.view addSubview:scrollView];
    
/*---My Table View---*/
    
    myTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT-65 - 45)];
    myTableView.backgroundColor = [UIColor colorWithRed:0.910f green:0.925f blue:0.925f alpha:1.0f];
    myTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    myTableView.separatorInset = UIEdgeInsetsMake(0, SCREEN_WIDTH / 2.5, 0, SCREEN_WIDTH/ 2.5);
    myTableView.allowsSelection = NO;
    myTableView.dataSource = self;
    myTableView.delegate = self;
    [scrollView addSubview:myTableView];
    
/*---Navigation View---*/
    
    navigationBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 65)];
    navigationBarView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:navigationBarView];
    
/*---BW Title Pager View---*/
    
    [self setPageAndScrollView];
    
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
    
    animationView = [[CSAnimationView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 43.5, 23, 14, 14)];
    animationView.duration = 0.5;
    animationView.delay = 0;
    animationView.type = CSAnimationTypeZoomOut;
    [navigationBarView addSubview:animationView];
    
    lblBadge = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 17, 17)];
    lblBadge.textAlignment = NSTextAlignmentCenter;
    lblBadge.font = [UIFont fontWithName:@"OpenSans-Semibold" size:10];
    lblBadge.backgroundColor = [UIColor colorWithRed:0.890f green:0.247f blue:0.373f alpha:1.0f];
    lblBadge.textColor = [UIColor whiteColor];
    lblBadge.layer.cornerRadius = lblBadge.frame.size.width / 2;
    lblBadge.clipsToBounds = YES;
    [animationView addSubview:lblBadge];
    
/*---Banner---*/
    
    lblBanner = [[UILabel alloc] initWithFrame:CGRectMake(0, 65, SCREEN_WIDTH, 28)];
    lblBanner.textAlignment = NSTextAlignmentCenter;
    lblBanner.textColor = [UIColor whiteColor];
    lblBanner.backgroundColor = [UIColor colorWithRed:0.882f green:0.361f blue:0.035f alpha:0.8f];
    lblBanner.hidden = YES;
    lblBanner.center = CGPointMake(self.view.frame.size.width * 5 / 6 + 10, self.view.frame.size.width / 8 + 10);
    lblBanner.transform = CGAffineTransformMakeRotation(M_PI / 4);
    lblBanner.font = [UIFont fontWithName:@"OpenSans-Bold" size:16.0f];
    [scrollView addSubview:lblBanner];
    
/*---Button State---*/
    
    btnState = [[UIButton alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT-45-65, SCREEN_WIDTH, 45)];
    [btnState setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btnState.titleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:13.0f];
    [btnState addTarget:self action:@selector(onContinue) forControlEvents:UIControlEventTouchUpInside];
    
    NSMutableString *strTitle = [[[AppStrings sharedInstance] getString:BUILD_COMPLETE_BUTTON] mutableCopy];
    if (strTitle == nil)
    {
        strTitle = [@"FINALIZE ORDER" mutableCopy];
    }
    
    [btnState setTitle:strTitle forState:UIControlStateNormal];
    NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:strTitle];
    float spacing = 1.0f;
    [attributedTitle addAttribute:NSKernAttributeName
                            value:@(spacing)
                            range:NSMakeRange(0, [strTitle length])];
    
    btnState.titleLabel.attributedText = attributedTitle;
    attributedTitle = nil;

    
    [scrollView addSubview:btnState];
    
    /*-----*/
    
    // if self.aryBentos is empty, create a new bento
    if ([[BentoShop sharedInstance] getTotalBentoCount] == 0)
        [[BentoShop sharedInstance] addNewBento];
    
    // Show these items
    lblBadge.hidden = NO;
    btnCart.hidden = NO;
    btnState.hidden = NO;
    
    //
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    CLLocationCoordinate2D location = [delegate getCurrentLocation];
    BentoShop *globalShop = [BentoShop sharedInstance];
    if (![globalShop checkLocation:location] && [[DataManager shareDataManager] getUserInfo] == nil)
    {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"nextToBuild"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        DeliveryLocationViewController *deliveryLocationViewController = [storyboard instantiateViewControllerWithIdentifier:@"DeliveryLocationViewController"];
        [self.navigationController pushViewController:deliveryLocationViewController animated:NO];
    }
    
    /*-------------------------------------Next Menu---------------------------------------*/
    
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
    
    // Sunday = 1, Saturday = 7
    weekday = (int)[[calendar components:NSCalendarUnitWeekday fromDate:currentDate] weekday];
    NSLog(@"today is - %ld", (long)weekday);
    
    _selectedPath = nil;
}

#pragma mark Set PageView and ScrollView

- (void)setPageAndScrollView
{
    NSString *currentMenuTitle;
    NSString *nextMenuTitle;
    
    BOOL shouldShowOneMenu = NO;
    
    /* IS All-DAY */
    if ([[BentoShop sharedInstance] isAllDay])
    {
        // Left Side
        if([[BentoShop sharedInstance] isThereLunchMenu])
            currentMenuTitle = @"Serving All-day Lunch";
        else if ([[BentoShop sharedInstance] isThereDinnerMenu])
            currentMenuTitle = @"Serving All-day Dinner";
        
        // Right Side
        
        // No Next Available Menu
        if ([[BentoShop sharedInstance] isThereLunchNextMenu] == NO && [[BentoShop sharedInstance] isThereDinnerNextMenu] == NO)
            shouldShowOneMenu = YES;
        
        // Next Menu Available
        else
        {
            if ([[BentoShop sharedInstance] nextIsAllDay])
            {
                if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                    nextMenuTitle = [NSString stringWithFormat:@"%@'s All-day Lunch Menu", [[BentoShop sharedInstance] getNextMenuWeekdayString]];
                else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                    nextMenuTitle = [NSString stringWithFormat:@"%@'s All-day Dinner Menu", [[BentoShop sharedInstance] getNextMenuWeekdayString]];
            }
            else if ([[BentoShop sharedInstance] nextIsAllDay] == NO)
            {
                if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                    nextMenuTitle = [NSString stringWithFormat:@"%@'s Lunch Menu", [[BentoShop sharedInstance] getNextMenuWeekdayString]];
                else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                    nextMenuTitle = [NSString stringWithFormat:@"%@'s Dinner Menu", [[BentoShop sharedInstance] getNextMenuWeekdayString]];
            }
        }
    }
    
    /* IS NOT ALL-DAY */
    else
    {
        // 00:00 - 16:29 Lunch
        if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Lunch"])
        {
            // Left Side
            if ([[BentoShop sharedInstance] isThereLunchMenu])
                currentMenuTitle = @"Now Serving Lunch";
            
            // Right Side
            if ([[BentoShop sharedInstance] isThereDinnerMenu])
                nextMenuTitle = @"Tonight's Dinner Menu";
            else if ([[BentoShop sharedInstance] nextIsAllDay])
            {
                if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                    nextMenuTitle = [NSString stringWithFormat:@"%@'s All-Day Lunch Menu", [[BentoShop sharedInstance] getNextMenuWeekdayString]];
                else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                    nextMenuTitle = [NSString stringWithFormat:@"%@'s All-Day Dinner Menu", [[BentoShop sharedInstance] getNextMenuWeekdayString]];
            }
            else
            {
                if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                    nextMenuTitle = [NSString stringWithFormat:@"%@'s Lunch Menu", [[BentoShop sharedInstance] getNextMenuWeekdayString]];
                else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                    nextMenuTitle = [NSString stringWithFormat:@"%@'s Dinner Menu", [[BentoShop sharedInstance] getNextMenuWeekdayString]];
                else
                    shouldShowOneMenu = YES;
            }
        }
        
        // 16:30 - 23:59 Dinner
        else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Dinner"])
        {
            // Left Side
            if ([[BentoShop sharedInstance] isThereDinnerMenu])
                currentMenuTitle = @"Now Serving Dinner";
            
            // Right Side
            if ([[BentoShop sharedInstance] nextIsAllDay])
            {
                if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                    nextMenuTitle = [NSString stringWithFormat:@"%@'s All-day Lunch Menu", [[BentoShop sharedInstance] getNextMenuWeekdayString]];
                else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                    nextMenuTitle = [NSString stringWithFormat:@"%@'s All-day Dinner Menu", [[BentoShop sharedInstance] getNextMenuWeekdayString]];
            }
            else if ([[BentoShop sharedInstance] nextIsAllDay] == NO)
            {
                if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                    nextMenuTitle = [NSString stringWithFormat:@"%@'s Lunch Menu", [[BentoShop sharedInstance] getNextMenuWeekdayString]];
                else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                    nextMenuTitle = [NSString stringWithFormat:@"%@'s Dinner Menu", [[BentoShop sharedInstance] getNextMenuWeekdayString]];
                else
                    shouldShowOneMenu = YES;
            }
        }
    }
    
    // No Available Menu
    if (currentMenuTitle == nil)
        currentMenuTitle = @"No Available Menu";
    if (nextMenuTitle == nil)
        nextMenuTitle = @"No Available Menu";
    
    pagingTitleView = [[BWTitlePagerView alloc] init];
    pagingTitleView.frame = CGRectMake(SCREEN_WIDTH/2-100, 32.5 - 10, 200, 40);
    pagingTitleView.font = [UIFont fontWithName:@"OpenSans-Bold" size:16.0f];
    pagingTitleView.currentTintColor = [UIColor colorWithRed:0.341f green:0.376f blue:0.439f alpha:1.0f];
    [pagingTitleView observeScrollView:scrollView];
    
    if (shouldShowOneMenu) // shorten scrollview's width
    {
        scrollView.contentSize = CGSizeMake(SCREEN_WIDTH, SCREEN_HEIGHT-65);
        [pagingTitleView addObjects:@[currentMenuTitle]];
    }
    else
    {
        scrollView.contentSize = CGSizeMake(SCREEN_WIDTH*2, SCREEN_HEIGHT-65);
        [pagingTitleView addObjects:@[currentMenuTitle, nextMenuTitle]];
    }
    
    [navigationBarView addSubview:pagingTitleView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // set aryDishes array
    self.aryDishes = [[NSMutableArray alloc] init];
    
    for (NSDictionary *dishInfo in [[BentoShop sharedInstance] getMainDishes:@"todayDinner"])
    {
        NSInteger dishID = [[dishInfo objectForKey:@"itemId"] integerValue];
        
        if ([[BentoShop sharedInstance] canAddDish:dishID])
            [self.aryDishes addObject:dishInfo];
    }
    
    [self updateUI];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus:) name:USER_NOTIFICATION_UPDATED_MENU object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus:) name:USER_NOTIFICATION_UPDATED_STATUS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedMenu:) name:USER_NOTIFICATION_UPDATED_NEXTMENU object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noConnection) name:@"networkError" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yesConnection) name:@"networkConnected" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkCurrentMode) name:@"enteredForeground" object:nil];
}

- (BOOL)connected
{
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [reachability currentReachabilityStatus];
    return networkStatus != NotReachable;
}

- (void)noConnection
{
    // if no internet connection and timer has been paused
    if (![self connected] && [BentoShop sharedInstance]._isPaused)
    {
        if (loadingHUD == nil)
        {
            loadingHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
            loadingHUD.textLabel.text = @"Waiting for internet connectivity...";
            [loadingHUD showInView:self.view];
        }
    }
}

- (void)yesConnection
{
    if ([self connected] && ![BentoShop sharedInstance]._isPaused)
        [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(callUpdate) userInfo:nil repeats:NO];
}

- (void)callUpdate
{
    if ([self connected] && ![BentoShop sharedInstance]._isPaused)
    {
        [loadingHUD dismiss];
        loadingHUD = nil;
    
        [self viewWillAppear:YES];
    }
}

- (void)checkCurrentMode
{
    if ([[BentoShop sharedInstance] didModeOrDateChange])
    {
        [(UINavigationController *)self.presentingViewController popToRootViewControllerAnimated:NO];
        [self dismissViewControllerAnimated:YES completion:nil];
        
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewWillDisappear:animated];
}

- (void)dealloc
{
    @try
    {
        [scrollView removeObserver:pagingTitleView.self forKeyPath:@"contentOffset" context:nil];
    }
    @catch(id anException)
    {
        //do nothing, obviously it wasn't attached because an exception was thrown
    }
}

#pragma mark Tableview Datasource

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return SCREEN_HEIGHT/2 + 20;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    /* IS ALL-DAY */
    if ([[BentoShop sharedInstance] isAllDay])
    {
        if ([[BentoShop sharedInstance] isThereLunchMenu])
            return [[[BentoShop sharedInstance] getMainDishes:@"todayLunch"] count];
        else if ([[BentoShop sharedInstance] isThereDinnerMenu])
            return [[[BentoShop sharedInstance] getMainDishes:@"todayDinner"] count];
    }
    
    /* IS NOT ALL-DAY */
    else
    {
        // 00:00 - 16:29
        if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Lunch"])
            return [[[BentoShop sharedInstance] getMainDishes:@"todayLunch"] count];
        
        // 16:30 - 23:59
        else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Dinner"])
            return [[[BentoShop sharedInstance] getMainDishes:@"todayDinner"] count];
    }
    
    return 0;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    servingLunchCell = (FixedBentoCell *)[tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (servingLunchCell == nil) {
        servingLunchCell = [[FixedBentoCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    
    NSArray *aryMainDishesLeft;
    
    if ([[BentoShop sharedInstance] isAllDay])
    {
        if ([[BentoShop sharedInstance] isThereLunchMenu])
            aryMainDishesLeft = [[BentoShop sharedInstance] getMainDishes:@"todayLunch"];
        else if ([[BentoShop sharedInstance] isThereDinnerMenu])
            aryMainDishesLeft = [[BentoShop sharedInstance] getMainDishes:@"todayDinner"];
    }
    else
    {
        if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Lunch"])
            aryMainDishesLeft = [[BentoShop sharedInstance] getMainDishes:@"todayLunch"];
        else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Dinner"])
            aryMainDishesLeft = [[BentoShop sharedInstance] getMainDishes:@"todayDinner"];
    }
    
    NSDictionary *dishInfo = [aryMainDishesLeft objectAtIndex:indexPath.row];
    [servingLunchCell setDishInfo:dishInfo];
    
    servingLunchCell.btnMainDish.tag = indexPath.row; // set button tag
    [servingLunchCell.btnMainDish addTarget:self action:@selector(onDish:) forControlEvents:UIControlEventTouchUpInside];
    
    // Check Sold out item, set add to cart button state
    NSInteger mainDishId = [[dishInfo objectForKey:@"itemId"] integerValue];
    if ([[BentoShop sharedInstance] isDishSoldOut:mainDishId])
    {
        servingLunchCell.ivBannerMainDish.hidden = NO;
        servingLunchCell.addButton.enabled = NO;
        [servingLunchCell.addButton setBackgroundColor:[UIColor colorWithRed:122.0f / 255.0f green:133.0f / 255.0f blue:146.0f / 255.0f alpha:1.0f]];
    }
    else
    {
        servingLunchCell.ivBannerMainDish.hidden = YES;
        servingLunchCell.addButton.enabled = YES;
        [servingLunchCell.addButton setBackgroundColor:[UIColor colorWithRed:135.0f / 255.0f green:178.0f / 255.0f blue:96.0f / 255.0f alpha:1.0f]];
    }
    
    // add bento button
    servingLunchCell.addButton.tag = indexPath.row;
    [servingLunchCell.addButton addTarget:self action:@selector(onAddBentoHighlight:) forControlEvents:UIControlEventTouchDown];
    [servingLunchCell.addButton addTarget:self action:@selector(onAddBento:) forControlEvents:UIControlEventTouchUpInside];
    
    [servingLunchCell.addButton setTitle:@"ADD BENTO TO CART" forState:UIControlStateNormal];
    
//    // Prices
//    NSInteger salePrice = [[AppStrings sharedInstance] getInteger:SALE_PRICE];
//    NSInteger unitPrice = [[AppStrings sharedInstance] getInteger:ABOUT_PRICE];
//    if (salePrice != 0 && salePrice < unitPrice)
//    {
//        // Normal Price
//        [servingLunchCell.addButton setTitle:[NSString stringWithFormat:@"ADD BENTO TO CART - $%ld", salePrice] forState:UIControlStateNormal];
//    }
//    else
//    {
//        // On Sale
//        [servingLunchCell.addButton setTitle:[NSString stringWithFormat:@"ADD BENTO TO CART - $%ld", unitPrice] forState:UIControlStateNormal];
//    }
    
    return servingLunchCell;
}

/*---------------------------------------------------------------------------------------------*/

- (void)updateUI
{
    NSInteger salePrice = [[AppStrings sharedInstance] getInteger:SALE_PRICE];
    NSInteger unitPrice = [[AppStrings sharedInstance] getInteger:ABOUT_PRICE];
    
    if (salePrice != 0 && salePrice < unitPrice)
    {
        lblBanner.hidden = NO;
        lblBanner.text = [NSString stringWithFormat:@"NOW ONLY $%ld", (long)salePrice];
    } else {
        lblBanner.hidden = YES;
    }
    
    // Get rid of any empty bentos and update persistent data
    savedArray  = [[[NSUserDefaults standardUserDefaults] rm_customObjectForKey:@"bento_array"] mutableCopy];
    NSLog(@"SAVED ARRAY: %@", savedArray);
    
    // loop through bento array
    for (int i = 0; i < savedArray.count; i++)
    {
        // if bento in current index is empty
        Bento *bento = savedArray[i];
        if (bento.indexMainDish == 0 &&
            bento.indexSideDish1 == 0 &&
            bento.indexSideDish2 == 0 &&
            bento.indexSideDish3 == 0 &&
            bento.indexSideDish4 == 0)
        {
            // remove bento from bentos array
            [savedArray removeObjectAtIndex:i];
            
            // get today's date string
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyyMMdd"];
            NSString *strDate = [formatter stringFromDate:[NSDate date]];
            
            // update bentos array and strToday to persistent data
            [[NSUserDefaults standardUserDefaults] rm_setCustomObject:savedArray forKey:@"bento_array"];
            [[NSUserDefaults standardUserDefaults] setObject:strDate forKey:@"bento_date"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
    
    // if current bento is completed, add new empty bento
    if ([[[BentoShop sharedInstance] getLastBento] isCompleted])
    {
        [[BentoShop sharedInstance] addNewBento];
    }
    
    // Cart and Finalize button state
    if ([[BentoShop sharedInstance] getCompletedBentoCount] > 0)
    {
        btnCart.enabled = YES;
        btnCart.selected = YES;
        [btnCart setImage:[UIImage imageNamed:@"mybento_nav_cart_act"] forState:UIControlStateNormal];
        
        [btnState setBackgroundColor:[UIColor colorWithRed:135.0f / 255.0f green:178.0f / 255.0f blue:96.0f / 255.0f alpha:1.0f]];
        btnState.enabled = YES;
    }
    else
    {
        btnCart.enabled = NO;
        btnCart.selected = NO;
        
        [btnState setBackgroundColor:[UIColor colorWithRed:122.0f / 255.0f green:133.0f / 255.0f blue:146.0f / 255.0f alpha:1.0f]];
        btnState.enabled = NO;
    }
    
    // Badge count label state
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
    
    if ([self connected] && ![BentoShop sharedInstance]._isPaused)
        connectionTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(reloadDishes) userInfo:nil repeats:NO];
}

- (void)reloadDishes
{
    if ([self connected] && ![BentoShop sharedInstance]._isPaused)
    {
        [cvDishes reloadData];
        [myTableView reloadData];
    }
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
    
    FixedBentoPreviewViewController *fixedBentoPreviewViewController = [[FixedBentoPreviewViewController alloc] init];
    fixedBentoPreviewViewController.fromWhichVC = selectedButton.tag;
    
    NSArray *aryMainDishesLeft;
    
    if ([[BentoShop sharedInstance] isAllDay])
    {
        if ([[BentoShop sharedInstance] isThereLunchMenu])
            aryMainDishesLeft = [[BentoShop sharedInstance] getMainDishes:@"todayLunch"];
        else if ([[BentoShop sharedInstance] isThereDinnerMenu])
            aryMainDishesLeft = [[BentoShop sharedInstance] getMainDishes:@"todayDinner"];
    }
    else
    {
        if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Lunch"])
            aryMainDishesLeft = [[BentoShop sharedInstance] getMainDishes:@"todayLunch"];
        else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Dinner"])
            aryMainDishesLeft = [[BentoShop sharedInstance] getMainDishes:@"todayDinner"];
    }
    
    NSDictionary *dishInfo = [aryMainDishes objectAtIndex:selectedButton.tag];
    fixedBentoPreviewViewController.titleText = [NSString stringWithFormat:@"%@ Bento", [dishInfo objectForKey:@"name"]];
    
    [self.navigationController pushViewController:fixedBentoPreviewViewController animated:YES];
}

- (void)onAddBentoHighlight:(id)sender
{
    UIButton *selectedButton = (UIButton *)sender;
    selectedButton.backgroundColor = [UIColor colorWithRed:135.0f / 255.0f green:178.0f / 255.0f blue:96.0f / 255.0f alpha:0.7f];
}

- (void)onAddBento:(id)sender
{
    // Track began add a bento
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Began Registration" properties:nil];
    NSLog(@"BEGAN BUILDING A BENTO");
    
    // animate badge
    [animationView startCanvasAnimation];
    
    /*---Add items to empty bento---*/
    UIButton *selectedButton = (UIButton *)sender;
    
    NSArray *aryMainDishesLeft;
    NSArray *arySideDishesLeft;
    
    // use all day logic
    if ([[BentoShop sharedInstance] isAllDay])
    {
        if ([[BentoShop sharedInstance] isThereLunchMenu])
        {
            aryMainDishesLeft = [[BentoShop sharedInstance] getMainDishes:@"todayLunch"];
            arySideDishesLeft = [[BentoShop sharedInstance] getSideDishes:@"todayLunch"];
        }
        else if ([[BentoShop sharedInstance] isThereDinnerMenu])
        {
            aryMainDishesLeft = [[BentoShop sharedInstance] getMainDishes:@"todayDinner"];
            arySideDishesLeft = [[BentoShop sharedInstance] getSideDishes:@"todayDinner"];
        }
    }
    else // use regular logic
    {
        if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Lunch"])
        {
            aryMainDishesLeft = [[BentoShop sharedInstance] getMainDishes:@"todayLunch"];
            arySideDishesLeft = [[BentoShop sharedInstance] getSideDishes:@"todayLunch"];
        }
        else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Dinner"])
        {
            aryMainDishesLeft = [[BentoShop sharedInstance] getMainDishes:@"todayDinner"];
            arySideDishesLeft = [[BentoShop sharedInstance] getSideDishes:@"todayDinner"];
        }
    }
    
    // Add main to Bento
    NSDictionary *mainDishInfo = [aryMainDishesLeft objectAtIndex:selectedButton.tag];
    [[[BentoShop sharedInstance] getCurrentBento] setMainDish:[[mainDishInfo objectForKey:@"itemId"] integerValue]];
    
    // Add all sides to Bento
    for (int i = 0; i < arySideDishesLeft.count; i++) {
        
        switch (i) {
            case 0:
                [[[BentoShop sharedInstance] getCurrentBento] setSideDish1:[[arySideDishesLeft[i] objectForKey:@"itemId"] integerValue]];
                break;
            case 1:
                [[[BentoShop sharedInstance] getCurrentBento] setSideDish2:[[arySideDishesLeft[i] objectForKey:@"itemId"] integerValue]];
                break;
            case 2:
                [[[BentoShop sharedInstance] getCurrentBento] setSideDish3:[[arySideDishesLeft[i] objectForKey:@"itemId"] integerValue]];
                break;
            case 3:
                [[[BentoShop sharedInstance] getCurrentBento] setSideDish4:[[arySideDishesLeft[i] objectForKey:@"itemId"] integerValue]];
                break;
            default:
                break;
        }
    }
    
    //[[BentoShop sharedInstance] setCurrentBento:nil];
    
    Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];
    if (currentBento != nil && ![currentBento isCompleted])
    {
        if ([[BentoShop sharedInstance] isAllDay])
        {
            if ([[BentoShop sharedInstance] isThereLunchMenu])
                [currentBento completeBento:@"todayLunch"];
            else if ([[BentoShop sharedInstance] isThereDinnerMenu])
                [currentBento completeBento:@"todayDinner"];
        }
        else
        {
            if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Lunch"])
                [currentBento completeBento:@"todayLunch"];
            else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Dinner"])
                [currentBento completeBento:@"todayDinner"];
        }
    }
    
    [[BentoShop sharedInstance] addNewBento];
    
    [self reloadDishes];
    [self updateUI];
}

- (void)onCart
{
    Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];
    if (currentBento != nil && ![currentBento isEmpty] && ![currentBento isCompleted])
        [self showConfirmMsg];
    else
        [self gotoOrderScreen];
}

- (void)gotoOrderScreen
{
    NSDictionary *currentUserInfo = [[DataManager shareDataManager] getUserInfo];
    SVPlacemark *placeInfo = [[NSUserDefaults standardUserDefaults] rm_customObjectForKey:@"delivery_location"];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    CompleteOrderViewController *completeOrderViewController = [storyboard instantiateViewControllerWithIdentifier:@"CompleteOrderViewController"];
    DeliveryLocationViewController *deliveryLocationViewController = [storyboard instantiateViewControllerWithIdentifier:@"DeliveryLocationViewController"];
    
    if (currentUserInfo == nil)
    {
        if (placeInfo == nil)
        {
            [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"isFromHomepage"];
            [[NSUserDefaults standardUserDefaults] synchronize];

            [self openAccountViewController:[DeliveryLocationViewController class]];
        }

        else // if user already has saved address
        {
            // check if saved address is within CURRENT service area
            CLLocationCoordinate2D location = placeInfo.location.coordinate;
            
            // not within service area
            if (![[BentoShop sharedInstance] checkLocation:location])
                [self openAccountViewController:[DeliveryLocationViewController class]];
            
            // within service area
            else
                [self openAccountViewController:[CompleteOrderViewController class]];
        }
    }
    else
    {
        if (placeInfo == nil)
            [self.navigationController pushViewController:deliveryLocationViewController animated:YES];
        else
        {
            // check if saved address is within CURRENT service area
            CLLocationCoordinate2D location = placeInfo.location.coordinate;
            
            // not within service area
            if (![[BentoShop sharedInstance] checkLocation:location])
                [self.navigationController pushViewController:deliveryLocationViewController animated:YES];
            
            // within service area
            else
                [self.navigationController pushViewController:completeOrderViewController animated:YES];
        }
    }
}

- (void)onUpdatedStatus:(NSNotification *)notification
{
    // is connected and timer is not paused
    if ([self connected] && ![BentoShop sharedInstance]._isPaused)
    {
        if ([[BentoShop sharedInstance] isClosed] && ![[DataManager shareDataManager] isAdminUser])
        {
            [self showSoldoutScreen:[NSNumber numberWithInt:0]];
        }
        else if ([[BentoShop sharedInstance] isSoldOut] && ![[DataManager shareDataManager] isAdminUser])
        {
            [self showSoldoutScreen:[NSNumber numberWithInt:1]];
        }
        else
        {
            [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(updateUIOnMainThread) userInfo:nil repeats:NO];
        }
    }
}

- (void)updateUIOnMainThread
{
    if ([self connected] && ![BentoShop sharedInstance]._isPaused)
        [self performSelectorOnMainThread:@selector(updateUI) withObject:nil waitUntilDone:NO];
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
        {
            if ([[BentoShop sharedInstance] isAllDay])
            {
                if ([[BentoShop sharedInstance] isThereLunchMenu])
                    [currentBento completeBento:@"todayLunch"];
                else if ([[BentoShop sharedInstance] isThereDinnerMenu])
                    [currentBento completeBento:@"todayDinner"];
            }
            else
            {
                if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Lunch"])
                    [currentBento completeBento:@"todayLunch"];
                else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Dinner"])
                    [currentBento completeBento:@"todayDinner"];
            }
        }
        
        [self gotoOrderScreen];
    }
}

/*------------------------------------------Next Menu Preview---------------------------------------------*/

- (void)onUpdatedMenu:(NSNotification *)notification
{
    // is connected and timer is not paused
    if ([self connected] && ![BentoShop sharedInstance]._isPaused)
        [self updateUI];
}

#pragma mark - COLLECTION VIEW

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 2;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    [self setDishesBySection0MainOrSection1Side:section];
    
    // MAINS
    if (section == 0)
    {
        if (aryMainDishes == nil)
            return 0;
        
        return aryMainDishes.count;
    }
    
    // SIDES
    else if (section == 1)
    {
        if (arySideDishes == nil)
            return 0;
        
        return arySideDishes.count;
    }
    
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PreviewCollectionViewCell *cell = (PreviewCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"PreviewCollectionViewCell"
                                                                                                             forIndexPath:indexPath];
    [cell initView];
    
    if (indexPath.section == 1)
        [cell setSmallDishCell];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    PreviewCollectionViewCell *myCell = (PreviewCollectionViewCell *)cell;
    
    [self setDishesBySection0MainOrSection1Side:indexPath.section];
    
    // MAINS
    if (indexPath.section == 0)
    {
        NSDictionary *dishInfo = [aryMainDishes objectAtIndex:indexPath.row];
        [myCell setDishInfo:dishInfo];
    }
    
    // SIDES
    else if (indexPath.section == 1)
    {
        NSDictionary *dishInfo = [arySideDishes objectAtIndex:indexPath.row];
        [myCell setDishInfo:dishInfo];
    }
    
    if (_selectedPath != nil && _selectedPath == indexPath)
        [myCell setCellState:YES];
    else
        [myCell setCellState:NO];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) // Main Dish
        return CGSizeMake(cvDishes.frame.size.width, cvDishes.frame.size.width * 3 / 5);
    else if (indexPath.section == 1) // Side Dish
        return CGSizeMake(cvDishes.frame.size.width / 2, cvDishes.frame.size.width / 2);
    
    return CGSizeMake(0, 0);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (_selectedPath == indexPath)
        _selectedPath = nil;
    else
        _selectedPath = indexPath;
    
    [collectionView reloadData];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

// header
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    if (section == 0 || section == 1)
        return CGSizeMake(cvDishes.frame.size.width, 44);
    
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

#pragma mark Set Arrays

// No need to create method for today dishes array because we're only using todayDinner twice

- (void)setNextMainDishesArray:(NSString *)lunchOrDinner
{
    if ([lunchOrDinner isEqualToString:@"Lunch"])
        aryMainDishes = [[BentoShop sharedInstance] getNextMainDishes:@"nextLunchPreview"];
    
    else if ([lunchOrDinner isEqualToString:@"Dinner"])
        aryMainDishes = [[BentoShop sharedInstance] getNextMainDishes:@"nextDinnerPreview"];
}

- (void)setNextSideDishesArray:(NSString *)lunchOrDinner
{
    if ([lunchOrDinner isEqualToString:@"Lunch"])
        arySideDishes = [[BentoShop sharedInstance] getNextSideDishes:@"nextLunchPreview"];
    
    else if ([lunchOrDinner isEqualToString:@"Dinner"])
        arySideDishes = [[BentoShop sharedInstance] getNextSideDishes:@"nextDinnerPreview"];
}

- (void)setDishesBySection0MainOrSection1Side:(NSInteger)section
{
    // MAIN DISHES
    if (section == 0)
    {
        /* IS ALL-DAY */
        if ([[BentoShop sharedInstance] isAllDay])
        {
            if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                [self setNextMainDishesArray:@"Lunch"];
            else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                [self setNextMainDishesArray:@"Dinner"];
        }
        
        /* IS NOT ALL-DAY */
        else
        {
            // 00:00 - 16:29
            if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Lunch"])
            {
                if ([[BentoShop sharedInstance] isThereDinnerMenu])
                    aryMainDishes = [[BentoShop sharedInstance] getMainDishes:@"todayDinner"];
                else if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                    [self setNextMainDishesArray:@"Lunch"];
                else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                    [self setNextMainDishesArray:@"Dinner"];
            }
            
            // 16:30 - 23:59
            else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Dinner"])
            {
                if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                    [self setNextMainDishesArray:@"Lunch"];
                else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                    [self setNextMainDishesArray:@"Dinner"];
            }
        }
    }
    
    // SIDE DISHES
    else
    {
        /* IS ALL-DAY */
        if ([[BentoShop sharedInstance] isAllDay])
        {
            if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                [self setNextSideDishesArray:@"Lunch"];
            else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                [self setNextSideDishesArray:@"Dinner"];
        }
        
        /* IS NOT ALL-DAY */
        else
        {
            // 00:00 - 16:29
            if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Lunch"])
            {
                if ([[BentoShop sharedInstance] isThereDinnerMenu])
                    arySideDishes = [[BentoShop sharedInstance] getSideDishes:@"todayDinner"];
                else if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                    [self setNextSideDishesArray:@"Lunch"];
                else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                    [self setNextSideDishesArray:@"Dinner"];
            }
            
            // 16:30 - 23:59
            else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Dinner"])
            {
                if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                    [self setNextSideDishesArray:@"Lunch"];
                else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                    [self setNextSideDishesArray:@"Dinner"];
            }
        }
    }
}

@end
