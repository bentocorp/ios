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

#import "UIColor+CustomColors.h"

#import "AddonList.h"
#import "Addon.h"
#import "AddonsTableViewCell.h"
#import "AddonsViewController.h"


@interface FixedBentoViewController () <UITableViewDataSource, UITableViewDelegate, MyAlertViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, CompleteOrderViewControllerDelegate>

@property (nonatomic) NSMutableArray *aryDishes;

@end

@implementation FixedBentoViewController
{
    NSArray *aryMainDishes;
    NSArray *arySideDishes;
    NSArray *aryAddons;
    
    NSTimer *connectionTimer;
    
    UIView *navigationBarView;
    
    UIScrollView *scrollView;
    UITableView *myTableView;
    
    UILabel *lblBadge;
    UILabel *lblBanner;
    
    UIButton *btnCart;
    
    UIButton *btnViewAddons;
    UIButton *btnState;
    
    // Right
    UILabel *lblTitle;
    UICollectionView *cvDishes;
    
    NSInteger hour;
    int weekday;
    
    BWTitlePagerView *pagingTitleView;
    
    FixedBentoCell *servingLunchCell;
    
    CSAnimationView *animationView;
    
    JGProgressHUD *loadingHUD;
    
    NSMutableArray *savedArray;
    
    NSInteger _selectedPathMainRight;
    NSInteger _selectedPathSideRight;
    NSInteger _selectedPathAddonsRight;
    
    // for addon
    NSInteger _selectedPath;
    AddonsViewController *addonsVC;
    
    CompleteOrderViewController *completeOrderViewController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _selectedPathMainRight = -1;
    _selectedPathSideRight = -1;
    _selectedPathAddonsRight = -1;
    
    _selectedPath = -1;
    
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
    lblBanner.center = CGPointMake(self.view.frame.size.width * 5 / 6, self.view.frame.size.width / 6);
    lblBanner.transform = CGAffineTransformMakeRotation(M_PI / 4);
    lblBanner.font = [UIFont fontWithName:@"OpenSans-Bold" size:16.0f];
    [scrollView addSubview:lblBanner];
    
/*---Button State---*/
    
    btnState = [[UIButton alloc] initWithFrame:CGRectMake(SCREEN_WIDTH/2+0.25, SCREEN_HEIGHT-45-65, SCREEN_WIDTH/2-0.25, 45)];
    [btnState setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btnState.titleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:13.0f];
    [btnState addTarget:self action:@selector(onFinalize) forControlEvents:UIControlEventTouchUpInside];
    
    NSMutableString *strTitle = [[[AppStrings sharedInstance] getString:BUILD_COMPLETE_BUTTON] mutableCopy];
    if (strTitle == nil) {
        strTitle = [@"FINALIZE ORDER" mutableCopy];
    }
    
    [btnState setTitle:strTitle forState:UIControlStateNormal];
    NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:strTitle];
    float spacing = 1.0f;
    [attributedTitle addAttribute:NSKernAttributeName
                            value:@(spacing)
                            range:NSMakeRange(0, [strTitle length])];
    
    // Anything less than iOS 8.0
    if ([[UIDevice currentDevice].systemVersion intValue] < 8) {
        btnState.titleLabel.text = strTitle;
    }
    else {
        btnState.titleLabel.attributedText = attributedTitle;
    }
    
    attributedTitle = nil;
    
    [scrollView addSubview:btnState];
    
/*-----*/
    
/*View Add-ons*/
    
    btnViewAddons = [[UIButton alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT-45-65, SCREEN_WIDTH/2-0.25, 45)];
    [btnViewAddons setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btnViewAddons.titleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:13.0f];
    [btnViewAddons addTarget:self action:@selector(onViewAddons) forControlEvents:UIControlEventTouchUpInside];
    
    NSMutableString *strTitleAddons = [@"VIEW ADD-ONS" mutableCopy];
    
    [btnViewAddons setTitle:strTitleAddons forState:UIControlStateNormal];
    NSMutableAttributedString *attributedTitleAddons = [[NSMutableAttributedString alloc] initWithString:strTitle];
    float spacingAddons = 1.0f;
    [attributedTitleAddons addAttribute:NSKernAttributeName
                            value:@(spacingAddons)
                            range:NSMakeRange(0, [strTitle length])];
    
    // Anything less than iOS 8.0
    if ([[UIDevice currentDevice].systemVersion intValue] < 8) {
        btnViewAddons.titleLabel.text = strTitle;
    }
    else {
        btnViewAddons.titleLabel.attributedText = attributedTitle;
    }
    
    attributedTitle = nil;
    
    [scrollView addSubview:btnViewAddons];
    
/*-----*/
    
    // if self.aryBentos is empty, create a new bento
    if ([[BentoShop sharedInstance] getTotalBentoCount] == 0) {
        [[BentoShop sharedInstance] addNewBento];
    }
    
    // Show these items
    lblBadge.hidden = NO;
    btnCart.hidden = NO;
    btnState.hidden = NO;
    btnViewAddons.hidden = NO;
    
    //
    AppDelegate *delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
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
}

- (void)onViewAddons {
    [self.navigationController presentViewController:addonsVC animated:YES completion:nil];
}

// addons delegate method
- (void)addonsViewControllerDidTapOnFinalize:(BOOL)didTapOnFinalize
{
    if (didTapOnFinalize == YES) {
        [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(gotoOrderScreen) userInfo:nil repeats:NO];
    }
}

- (void)autoScrollToIndex:(NSString *)bentoName {
    for (int i = 0; i < self.aryDishes.count; i++) {
        
        if ([bentoName isEqualToString:self.aryDishes[i][@"name"]]) {
            [myTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
    }
}

- (void)completeOrderViewControllerDidTapBento:(NSString *)bentoName
{
    [self autoScrollToIndex:bentoName];
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
    pagingTitleView.currentTintColor = [UIColor bentoTitleGray];
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
    
    completeOrderViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"CompleteOrderViewController"];
    completeOrderViewController.delegate = self;
    
    addonsVC = [[AddonsViewController alloc] init];
    addonsVC.delegate = self;

    self.aryDishes = [[NSMutableArray alloc] init];
    
    [self updateUI];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus:) name:USER_NOTIFICATION_UPDATED_MENU object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus:) name:USER_NOTIFICATION_UPDATED_STATUS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedMenu:) name:USER_NOTIFICATION_UPDATED_NEXTMENU object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noConnection) name:@"networkError" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yesConnection) name:@"networkConnected" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkCurrentMode) name:@"checkModeOrDateChange" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkCurrentMode) name:@"enteredForeground" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startTimerOnViewedScreen) name:@"enteredForeground" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endTimerOnViewedScreen) name:@"enteringBackground" object:nil];
    
    [self startTimerOnViewedScreen];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewWillDisappear:animated];
    
    [self endTimerOnViewedScreen];
}

#pragma mark Duration on screen
- (void)startTimerOnViewedScreen
{
    [[Mixpanel sharedInstance] timeEvent:@"Viewed Fixed Home Screen"];
}

- (void)endTimerOnViewedScreen
{
    [[Mixpanel sharedInstance] track:@"Viewed Fixed Home Screen"];
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
    if ([self connected] && ![BentoShop sharedInstance]._isPaused) {
        [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(callUpdate) userInfo:nil repeats:NO];
    }
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

- (void)dealloc
{
    @try {
        [scrollView removeObserver:pagingTitleView.self forKeyPath:@"contentOffset" context:nil];
    }@catch(id anException){
        //do nothing, obviously it wasn't attached because an exception was thrown
    }
}

#pragma mark Tableview Datasource

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return SCREEN_HEIGHT/2 + 55;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.aryDishes.count;
}

- (void)sortAryDishesLeft {
    
    [self.aryDishes removeAllObjects];
    
    NSMutableArray *aryMainDishesLeft;
    
    if ([[BentoShop sharedInstance] isAllDay]) {
        
        if ([[BentoShop sharedInstance] isThereLunchMenu]) {
            aryMainDishesLeft = [[[BentoShop sharedInstance] getMainDishes:@"todayLunch"] mutableCopy];
        }
        else if ([[BentoShop sharedInstance] isThereDinnerMenu]) {
            aryMainDishesLeft = [[[BentoShop sharedInstance] getMainDishes:@"todayDinner"] mutableCopy];
        }
    }
    else {
        if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Lunch"]) {
            aryMainDishesLeft = [[[BentoShop sharedInstance] getMainDishes:@"todayLunch"] mutableCopy];
        }
        else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Dinner"]) {
            aryMainDishesLeft = [[[BentoShop sharedInstance] getMainDishes:@"todayDinner"] mutableCopy];
        }
    }

    NSMutableArray *soldOutDishesArray = [@[] mutableCopy];
    
    for (NSDictionary * dishInfo in aryMainDishesLeft) {
        
        NSInteger dishID = [[dishInfo objectForKey:@"itemId"] integerValue];
        
        if ([[BentoShop sharedInstance] canAddDish:dishID]) {
            
            // 1) add to self.aryDishes only if it's not sold out
            if ([[BentoShop sharedInstance] isDishSoldOut:dishID] == NO) {
                
                [self.aryDishes addObject:dishInfo];
            }
            else {
                // 2) add all sold out dishes to soldOutDishesArray
                [soldOutDishesArray addObject:dishInfo];
            }
        }
    }
    
    // 3) append sold out dishes to self.aryDishes
    self.aryDishes = [[self.aryDishes arrayByAddingObjectsFromArray:soldOutDishesArray] mutableCopy];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    servingLunchCell = (FixedBentoCell *)[tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (servingLunchCell == nil) {
        servingLunchCell = [[FixedBentoCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    
    NSDictionary *dishInfo = [self.aryDishes objectAtIndex:indexPath.row];
    [servingLunchCell setDishInfo:dishInfo];
    
    servingLunchCell.btnMainDish.tag = indexPath.row; // set button tag
    [servingLunchCell.btnMainDish addTarget:self action:@selector(onDish:) forControlEvents:UIControlEventTouchUpInside];
    
    // Check Sold out item, set add to cart button state
    NSInteger mainDishId = [[dishInfo objectForKey:@"itemId"] integerValue];
    if ([[BentoShop sharedInstance] isDishSoldOut:mainDishId])
    {
        servingLunchCell.ivBannerMainDish.hidden = NO;
        servingLunchCell.addButton.enabled = NO;
        [servingLunchCell.addButton setBackgroundColor:[UIColor bentoButtonGray]];
    }
    else
    {
        servingLunchCell.ivBannerMainDish.hidden = YES;
        servingLunchCell.addButton.enabled = YES;
        [servingLunchCell.addButton setBackgroundColor:[UIColor bentoBrandGreen]];
    }
    
    // add bento button
    servingLunchCell.addButton.tag = indexPath.row;
    [servingLunchCell.addButton addTarget:self action:@selector(onAddBentoHighlight:) forControlEvents:UIControlEventTouchDown];
    [servingLunchCell.addButton addTarget:self action:@selector(onAddBento:) forControlEvents:UIControlEventTouchUpInside];
    
    if ([dishInfo[@"price"] isEqual:[NSNull null]] || dishInfo[@"price"] == nil || dishInfo[@"price"] == 0 || [dishInfo[@"price"] isEqualToString:@""])
    {
        // format to currency style
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setNumberStyle: NSNumberFormatterCurrencyStyle];
        servingLunchCell.priceLabel.text = [NSString stringWithFormat: @"%@", [numberFormatter stringFromNumber:@([[[BentoShop sharedInstance] getUnitPrice] floatValue])]]; // default settings.price
    }
    else {
        servingLunchCell.priceLabel.text = [NSString stringWithFormat: @"$%@", dishInfo[@"price"]]; // custom price
    }
    
    return servingLunchCell;
}

/*---------------------------------------------------------------------------------------------*/

- (void)updateUI
{
    [self sortAryDishesLeft];
    
    // get current main dishes
    NSMutableArray *mainDishesArray;
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Lunch"]) {
        mainDishesArray = [[[BentoShop sharedInstance] getMainDishes:@"todayLunch"] mutableCopy];
    }
    else {
        mainDishesArray = [[[BentoShop sharedInstance] getMainDishes:@"todayDinner"] mutableCopy];
    }
    
    // get main prices
    NSMutableArray *mainPrices = [@[] mutableCopy];
    for (int i = 0; i < mainDishesArray.count; i++) {
        
        NSString *price = mainDishesArray[i][@"price"];
        
        if (price == nil || [price isEqual:[NSNull null]] || [price isEqualToString:@"0"] || [price isEqualToString:@""]) {
            [mainPrices addObject:[[BentoShop sharedInstance] getUnitPrice]]; // default settings.price
        }
        else {
            [mainPrices addObject:price]; // custom price
        }
    }
    
    // sort prices, lowest first
    NSArray *sortedMainPrices = [mainPrices sortedArrayUsingDescriptors: @[[NSSortDescriptor sortDescriptorWithKey:@"doubleValue"ascending:YES]]];
    NSLog(@"main prices: %@", sortedMainPrices);
    
    // check for empty before trying to set to prevent crash in case there is no menu defined for current mode
    if (sortedMainPrices.count != 0 && sortedMainPrices != nil) {
        
        // get and then check if cents are 0
        double integral;
        double cents = modf([sortedMainPrices[0] floatValue], &integral);
        
        // if no cents, just show whole number
        if (cents == 0) {
            lblBanner.text = [NSString stringWithFormat:@"STARTING AT $%.0f", [sortedMainPrices[0] floatValue]];
        }
        // if exists, show normal
        else {
            lblBanner.text = [NSString stringWithFormat:@"STARTING AT $%@", sortedMainPrices[0]];
        }
        
        lblBanner.hidden = NO;
        lblBanner.backgroundColor = [UIColor colorWithRed:0.533f green:0.686f blue:0.376f alpha:1.0f];
        lblBanner.font = [UIFont fontWithName:@"OpenSans-Bold" size:14];
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
        
        [btnState setBackgroundColor:[UIColor bentoBrandGreen]];
        btnState.enabled = YES;
        
        [btnViewAddons setBackgroundColor:[UIColor bentoBrandGreen]];
        btnViewAddons.enabled = YES;
    }
    else
    {
        btnCart.enabled = NO;
        btnCart.selected = NO;
        
        [btnState setBackgroundColor:[UIColor bentoButtonGray]];
        btnState.enabled = NO;
        
        [btnViewAddons setBackgroundColor:[UIColor bentoButtonGray]];
        btnViewAddons.enabled = NO;
    }
    
    /*---Cart Badge---*/
    if ([[BentoShop sharedInstance] getCompletedBentoCount] > 0) {
        lblBadge.text = [NSString stringWithFormat:@"%ld", (long)[[BentoShop sharedInstance] getCompletedBentoCount] + (long)[[AddonList sharedInstance] getTotalCount]];
        lblBadge.hidden = NO;
    }
    else {
        lblBadge.text = @"";
        lblBadge.hidden = YES;
    }
    
    if ([self connected] && ![BentoShop sharedInstance]._isPaused)
        connectionTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(reloadDishes) userInfo:nil repeats:NO];
}

- (void)reloadDishes
{
    if ([self connected] && ![BentoShop sharedInstance]._isPaused) {
        
        [self sortAryDishesLeft];
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
    
    NSDictionary *dishInfo = [self.aryDishes objectAtIndex:selectedButton.tag];
    
    fixedBentoPreviewViewController.mainDishInfo = dishInfo;
    
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
    [mixpanel track:@"Added Bento To Cart" properties:nil];
    NSLog(@"Added Bento To Cart");
    
    // animate badge
    [animationView startCanvasAnimation];
    
    /*---Add items to empty bento---*/
    UIButton *selectedButton = (UIButton *)sender;
    
    NSArray *arySideDishesLeft;
    
    // use all day logic
    if ([[BentoShop sharedInstance] isAllDay]) {
        if ([[BentoShop sharedInstance] isThereLunchMenu]) {
            arySideDishesLeft = [[BentoShop sharedInstance] getSideDishes:@"todayLunch"];
        }
        else if ([[BentoShop sharedInstance] isThereDinnerMenu]) {
            arySideDishesLeft = [[BentoShop sharedInstance] getSideDishes:@"todayDinner"];
        }
    }
    else { // use regular logic
        if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Lunch"]) {
            arySideDishesLeft = [[BentoShop sharedInstance] getSideDishes:@"todayLunch"];
        }
        else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Dinner"]) {
            arySideDishesLeft = [[BentoShop sharedInstance] getSideDishes:@"todayDinner"];
        }
    }
    
    // Add main to Bento
    NSDictionary *mainDishInfo = [self.aryDishes objectAtIndex:selectedButton.tag];
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
//            [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(updateUIOnMainThread) userInfo:nil repeats:NO];
            
            if ([self connected] && ![BentoShop sharedInstance]._isPaused) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self reloadDishes];
                    [self updateUI];
                });
            }
        }
    }
}

- (void)updateUIOnMainThread
{
    if ([self connected] && ![BentoShop sharedInstance]._isPaused) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self reloadDishes];
            [self updateUI];
        });
    }
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

- (void)onFinalize
{
    Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];
    
    if (currentBento != nil || ![currentBento isEmpty])
    {
        [[BentoShop sharedInstance] saveBentoArray];
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"AutoShowAddons"] == YES) {
        
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"didAutoShowAddons"] != YES) {
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"didAutoShowAddons"];
                [self.navigationController presentViewController:addonsVC animated:YES completion:nil];
            }
            else {
                [self gotoOrderScreen];
            }
        }
        else {
            [self gotoOrderScreen];
        }
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



- (void)onUpdatedMenu:(NSNotification *)notification
{
    // is connected and timer is not paused
    if ([self connected] && ![BentoShop sharedInstance]._isPaused)
        [self updateUI];
}
/*------------------------------------------Next Menu Preview---------------------------------------------*/
#pragma mark - COLLECTION VIEW

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 3;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    [self setDishesBySection:section];
    
    // MAINS
    if (section == 0) {
        if (aryMainDishes == nil) {
            return 0;
        }
        
        return aryMainDishes.count;
    }
    // SIDES
    else if (section == 1) {
        if (arySideDishes == nil) {
            return 0;
        }
        
        return arySideDishes.count;
    }
    // ADD-ONS
    else if (section == 2) {
        if (aryAddons == nil) {
            return 0;
        }
        
        return aryAddons.count;
    }
    
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PreviewCollectionViewCell *cell = (PreviewCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"PreviewCollectionViewCell"
                                                                                                             forIndexPath:indexPath];
    [cell initView];
    
    // sides, set small
    if (indexPath.section == 1) {
        [cell setSmallDishCell];
    }
    
    /* Anything less than iOS 8.0 */
    if ([[UIDevice currentDevice].systemVersion intValue] < 8) {
        
        // MAINS
        if (indexPath.section == 0) {
            NSDictionary *dishInfo = [aryMainDishes objectAtIndex:indexPath.row];
            [cell setDishInfo:dishInfo];
            
            if (_selectedPathMainRight == indexPath.row) {
                [cell setCellState:YES];
            }
            else {
                [cell setCellState:NO];
            }
        }
        // SIDES
        else if (indexPath.section == 1) {
            NSDictionary *dishInfo = [arySideDishes objectAtIndex:indexPath.row];
            [cell setDishInfo:dishInfo];
            
            if (_selectedPathSideRight == indexPath.row) {
                [cell setCellState:YES];
            }
            else {
                [cell setCellState:NO];
            }
        }
        // ADD-ONS
        else {
            NSDictionary *dishInfo = [aryAddons objectAtIndex:indexPath.row];
            [cell setDishInfo:dishInfo];
            
            if (_selectedPathAddonsRight == indexPath.row) {
                [cell setCellState:YES];
            }
            else {
                [cell setCellState:NO];
            }
        }
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    PreviewCollectionViewCell *myCell = (PreviewCollectionViewCell *)cell;
    
    // MAINS
    if (indexPath.section == 0) {
        NSDictionary *dishInfo = [aryMainDishes objectAtIndex:indexPath.row];
        [myCell setDishInfo:dishInfo];
        
        if (_selectedPathMainRight == indexPath.row) {
            [myCell setCellState:YES];
        }
        else {
            [myCell setCellState:NO];
        }
    }
    // SIDES
    else if (indexPath.section == 1) {
        NSDictionary *dishInfo = [arySideDishes objectAtIndex:indexPath.row];
        [myCell setDishInfo:dishInfo];
        
        if (_selectedPathSideRight == indexPath.row) {
            [myCell setCellState:YES];
        }
        else {
            [myCell setCellState:NO];
        }
    }
    // ADD-ONS
    else {
        NSDictionary *dishInfo = [aryAddons objectAtIndex:indexPath.row];
        [myCell setDishInfo:dishInfo];
        
        if (_selectedPathAddonsRight == indexPath.row) {
            [myCell setCellState:YES];
        }
        else {
            [myCell setCellState:NO];
        }
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 || indexPath.section == 2) // Main Dish and Add-ons
        return CGSizeMake(cvDishes.frame.size.width, cvDishes.frame.size.width * 3 / 5);
    else if (indexPath.section == 1) // Side Dish
        return CGSizeMake(cvDishes.frame.size.width / 2, cvDishes.frame.size.width / 2);
    
    return CGSizeMake(0, 0);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        if (_selectedPathMainRight == indexPath.row)
            _selectedPathMainRight = -1;
        else
        {
            _selectedPathMainRight = indexPath.row;
            _selectedPathSideRight = -1;
            _selectedPathAddonsRight = -1;
        }
    }
    else if (indexPath.section == 1)
    {
        if (_selectedPathSideRight == indexPath.row)
            _selectedPathSideRight = -1;
        else
        {
            _selectedPathSideRight = indexPath.row;
            _selectedPathMainRight = -1;
            _selectedPathAddonsRight = -1;
        }
    }
    else
    {
        if (_selectedPathAddonsRight == indexPath.row)
            _selectedPathAddonsRight = -1;
        else
        {
            _selectedPathAddonsRight = indexPath.row;
            _selectedPathMainRight = -1;
            _selectedPathSideRight = -1;
        }
    }
    
    [collectionView reloadData];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

// header
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    return CGSizeMake(cvDishes.frame.size.width, 44);
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
        else {
            label.text = @"Add-ons";
        }
        
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

- (void)setNextAddonsArray:(NSString *)lunchOrDinner
{
    if ([lunchOrDinner isEqualToString:@"Lunch"])
        aryAddons = [[BentoShop sharedInstance] getNextAddons:@"nextLunchPreview"];
    
    else if ([lunchOrDinner isEqualToString:@"Dinner"])
        aryAddons = [[BentoShop sharedInstance] getNextAddons:@"nextDinnerPreview"];
}

- (void)setDishesBySection:(NSInteger)section
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
    else if (section == 1)
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
    
    // ADD-ONS
    else
    {
        /* IS ALL-DAY */
        if ([[BentoShop sharedInstance] isAllDay])
        {
            if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                [self setNextAddonsArray:@"Lunch"];
            else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                [self setNextAddonsArray:@"Dinner"];
        }
        
        /* IS NOT ALL-DAY */
        else
        {
            // 00:00 - 16:29
            if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Lunch"])
            {
                if ([[BentoShop sharedInstance] isThereDinnerMenu])
                    aryAddons = [[BentoShop sharedInstance] getAddons:@"todayDinner"];
                else if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                    [self setNextAddonsArray:@"Lunch"];
                else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                    [self setNextAddonsArray:@"Dinner"];
            }
            
            // 16:30 - 23:59
            else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Dinner"])
            {
                if ([[BentoShop sharedInstance] isThereLunchNextMenu])
                    [self setNextAddonsArray:@"Lunch"];
                else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
                    [self setNextAddonsArray:@"Dinner"];
            }
        }
    }
}

@end
