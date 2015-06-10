//
//  PreviewViewController.m
//  Bento
//
//  Created by Joseph Lau on 5/7/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "PreviewViewController.h"
#import "BWTitlePagerView.h"
#import "BentoShop.h"
#import "PreviewCollectionViewCell.h"
#import "JGProgressHUD.h"

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

@interface PreviewViewController () <UIScrollViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDelegate>

@end

@implementation PreviewViewController
{
    UIScrollView *scrollView;
    BWTitlePagerView *pagingTitleView;
    
    UILabel *lblTitle;
    UICollectionView *cvDishesLeft;
    UICollectionView *cvDishesRight;
    
    NSInteger _selectedPathMainLeft;
    NSInteger _selectedPathSideLeft;
    
    NSInteger _selectedPathMainRight;
    NSInteger _selectedPathSideRight;
    
    NSInteger hour;
    int weekday;
    
    NSUserDefaults *defaults;
    float currentTime;
    float lunchTime;
    float dinnerTime;
    float bufferTime;
    
    JGProgressHUD *loadingHUD;
    BOOL isThereConnection;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // initialize to YES
    isThereConnection = YES;
    
    /*---Times---*/
    currentTime = [[[BentoShop sharedInstance] getCurrentTime] floatValue];
    lunchTime = [[[BentoShop sharedInstance] getLunchTime] floatValue];
    dinnerTime = [[[BentoShop sharedInstance] getDinnerTime] floatValue];
    bufferTime = [[[BentoShop sharedInstance] getBufferTime] floatValue];
    
    /*---Scroll View---*/
    
    scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 45, SCREEN_WIDTH, SCREEN_HEIGHT)];
    scrollView.contentSize = CGSizeMake(SCREEN_WIDTH*2, SCREEN_HEIGHT-65);
    scrollView.pagingEnabled = YES;
    scrollView.backgroundColor = [UIColor colorWithRed:0.910f green:0.925f blue:0.925f alpha:1.0f];
    scrollView.bounces = NO;
    [self.view addSubview:scrollView];
    
    /*---Navigation View---*/
    
    UIView *navigationBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 65)];
    navigationBarView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:navigationBarView];
    
    /*---BW Title Pager View---*/
    
//    NSString *titleLeft;
//    NSString *titleRight;
//    
//    NSString *nextMenuTitleLunch = [NSString stringWithFormat:@"%@'s Lunch Menu", [[BentoShop sharedInstance] getNextMenuWeekdayString]];
//    NSString *nextMenuTitleDinner = [NSString stringWithFormat:@"%@'s Dinner Menu", [[BentoShop sharedInstance] getNextMenuWeekdayString]];
//    
//    // CLOSED: no menu today
//    if ([[BentoShop sharedInstance] isClosed] && [[BentoShop sharedInstance] getMenuDateString] == nil)
//    {
//        titleLeft = nextMenuTitleLunch;
//        titleRight = nextMenuTitleDinner;
//    }
//    
//    // CLOSED: 00:00 - 12:29
//    else if ([[BentoShop sharedInstance] isClosed] && currentTime >= 0 && currentTime < (lunchTime + bufferTime))
//    {
//        titleLeft = @"Today's Lunch Menu";
//        titleRight = @"Tonight's Dinner Menu";
//    }
//    
//    // CLOSED: 12:30 - 17:29
//    else if ([[BentoShop sharedInstance] isClosed] && currentTime >= (lunchTime + bufferTime) && currentTime < (dinnerTime+bufferTime))
//    {
//        titleLeft = @"Tonight's Dinner Menu";
//        titleRight = nextMenuTitleLunch;
//    }
//    
//    // CLOSED: 17.30 - 23:59
//    else if ([[BentoShop sharedInstance] isClosed] && currentTime >= (dinnerTime+bufferTime) && currentTime < 24)
//    {
//        titleLeft = nextMenuTitleLunch;
//        titleRight = nextMenuTitleDinner;
//    }
//
//    // SOLD-OUT: 11:30 - 16:30 (but use instead: 00:00 - 16:30)
//    else if ([[BentoShop sharedInstance] isSoldOut] && currentTime >= 0 && currentTime < dinnerTime)
//    {
//        titleLeft = @"Today's Lunch Menu";
//        titleRight = @"Tonight's Dinner Menu";
//    }
//    
//    // SOLD-OUT: 16:30 - 23:59
//    else if ([[BentoShop sharedInstance] isSoldOut] && currentTime >= dinnerTime && currentTime < 24)
//    {
//        titleLeft = @"Tonight's Dinner Menu";
//        titleRight = nextMenuTitleLunch;
//    }
//    
//    pagingTitleView = [[BWTitlePagerView alloc] init];
//    pagingTitleView.frame = CGRectMake(SCREEN_WIDTH/2-100, 32.5 - 10, 200, 40);
//    pagingTitleView.font = [UIFont fontWithName:@"OpenSans-Bold" size:16.0f];
//    pagingTitleView.currentTintColor = [UIColor colorWithRed:0.341f green:0.376f blue:0.439f alpha:1.0f];
//    [pagingTitleView observeScrollView:scrollView];
//    [pagingTitleView addObjects:@[titleLeft, titleRight]];
//    [navigationBarView addSubview:pagingTitleView];
    
    NSString *currentMenuTitle;
    NSString *nextMenuTitle;
    
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Lunch"])
        currentMenuTitle = @"Today's Lunch Menu";
    else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Dinner"])
        currentMenuTitle = @"Tonight's Dinner Menu";
    
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Lunch"])
    {
        if ([[BentoShop sharedInstance] isThereDinnerMenu])
            nextMenuTitle = @"Tonight's Dinner Menu";
        else if ([[BentoShop sharedInstance] isThereLunchNextMenu])
            nextMenuTitle = [NSString stringWithFormat:@"%@'s Lunch Menu", [[BentoShop sharedInstance] getNextMenuWeekdayString]];
        else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
            nextMenuTitle = [NSString stringWithFormat:@"%@'s Dinner Menu", [[BentoShop sharedInstance] getNextMenuWeekdayString]];
    }
    else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Dinner"])
    {
        if ([[BentoShop sharedInstance] isThereLunchNextMenu])
            nextMenuTitle = [NSString stringWithFormat:@"%@'s Lunch Menu", [[BentoShop sharedInstance] getNextMenuWeekdayString]];
        else if ([[BentoShop sharedInstance] isThereDinnerNextMenu])
            nextMenuTitle = [NSString stringWithFormat:@"%@'s Dinner Menu", [[BentoShop sharedInstance] getNextMenuWeekdayString]];
    }
    
    pagingTitleView = [[BWTitlePagerView alloc] init];
    pagingTitleView.frame = CGRectMake(SCREEN_WIDTH/2-100, 32.5 - 10, 200, 40);
    pagingTitleView.font = [UIFont fontWithName:@"OpenSans-Bold" size:16.0f];
    pagingTitleView.currentTintColor = [UIColor colorWithRed:0.341f green:0.376f blue:0.439f alpha:1.0f];
    [pagingTitleView observeScrollView:scrollView];
    [pagingTitleView addObjects:@[currentMenuTitle, nextMenuTitle]];
    [navigationBarView addSubview:pagingTitleView];
    
    /*---Line Separator---*/
    
    UIView *longLineSepartor1 = [[UIView alloc] initWithFrame:CGRectMake(0, 65, SCREEN_WIDTH, 1)];
    longLineSepartor1.backgroundColor = [UIColor colorWithRed:0.827f green:0.835f blue:0.835f alpha:1.0f];
    [navigationBarView addSubview:longLineSepartor1];
    
    /*---Back button---*/
    
    UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 20, 50, 45)];
    [closeButton setImage:[UIImage imageNamed:@"nav_btn_back"] forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(onCloseButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeButton];
    
    /*---Collection View---*/
    
// Left Side
    UICollectionViewFlowLayout *collectionViewFlowLayout = [[UICollectionViewFlowLayout alloc] init];
    [collectionViewFlowLayout setMinimumLineSpacing:0];
    [collectionViewFlowLayout setMinimumInteritemSpacing:0];
    cvDishesLeft = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT-65) collectionViewLayout:collectionViewFlowLayout];
    cvDishesLeft.backgroundColor = [UIColor colorWithRed:0.910f green:0.925f blue:0.925f alpha:1.0f];
    cvDishesLeft.dataSource = self;
    cvDishesLeft.delegate = self;
    [cvDishesLeft setCollectionViewLayout:collectionViewFlowLayout];
    UINib *cellNib = [UINib nibWithNibName:@"PreviewCollectionViewCell" bundle:nil];
    [cvDishesLeft registerNib:cellNib forCellWithReuseIdentifier:@"PreviewCollectionViewCell"];
    [cvDishesLeft registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView"];
    [scrollView addSubview:cvDishesLeft];
    
// Right Side
    UICollectionViewFlowLayout *collectionViewFlowLayout2 = [[UICollectionViewFlowLayout alloc] init];
    [collectionViewFlowLayout2 setMinimumLineSpacing:0];
    [collectionViewFlowLayout2 setMinimumInteritemSpacing:0];
    cvDishesRight = [[UICollectionView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH, 0, SCREEN_WIDTH, SCREEN_HEIGHT-65) collectionViewLayout:collectionViewFlowLayout2];
    cvDishesRight.backgroundColor = [UIColor colorWithRed:0.910f green:0.925f blue:0.925f alpha:1.0f];
    cvDishesRight.dataSource = self;
    cvDishesRight.delegate = self;
    [cvDishesRight setCollectionViewLayout:collectionViewFlowLayout2];
    UINib *cellNib2 = [UINib nibWithNibName:@"PreviewCollectionViewCell" bundle:nil];
    [cvDishesRight registerNib:cellNib2 forCellWithReuseIdentifier:@"PreviewCollectionViewCell"];
    [cvDishesRight registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView"];
    [scrollView addSubview:cvDishesRight];
    
    
    // Sunday = 1, Saturday = 7
    weekday = (int)[[[NSCalendar currentCalendar] components:NSCalendarUnitWeekday fromDate:[NSDate date]] weekday];
    NSLog(@"today is - %ld", (long)weekday);
    
    
    // For selection
    _selectedPathMainLeft = -1;
    _selectedPathSideLeft = -1;
    
    _selectedPathMainRight = -1;
    _selectedPathSideRight = -1;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedMenu:) name:USER_NOTIFICATION_UPDATED_NEXTMENU object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus:) name:USER_NOTIFICATION_UPDATED_STATUS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noConnection) name:@"networkError" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yesConnection) name:@"networkConnected" object:nil];
}

- (void)noConnection
{
    isThereConnection = NO;
    
    if (loadingHUD == nil)
    {
        loadingHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
        loadingHUD.textLabel.text = @"Waiting for internet connectivity...";
        [loadingHUD showInView:self.view];
    }
}

- (void)yesConnection
{
    [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(callUpdate) userInfo:nil repeats:NO];
}

- (void)callUpdate
{
    isThereConnection = YES;
    
    [loadingHUD dismiss];
    loadingHUD = nil;
    [self viewWillAppear:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewWillDisappear:animated];
}

- (void)dealloc
{
    [scrollView removeObserver:pagingTitleView.self forKeyPath:@"contentOffset" context:nil];
}

- (void)onUpdatedMenu:(NSNotification *)notification
{
    if (isThereConnection)
    {
        [cvDishesLeft reloadData];
        [cvDishesRight reloadData];
    }
}

- (void)onUpdatedStatus:(NSNotification *)notification
{
    if (isThereConnection)
    {
        if (self.type == 0 && ![[BentoShop sharedInstance] isClosed]) // Closed
            [self performSelectorOnMainThread:@selector(onCloseButton) withObject:nil waitUntilDone:NO];
        else if (self.type == 1 && ![[BentoShop sharedInstance] isSoldOut]) // Sold Out
            [self performSelectorOnMainThread:@selector(onCloseButton) withObject:nil waitUntilDone:NO];
    }
}

- (void)onCloseButton
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 2;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSArray *aryMainDishes;
    NSArray *arySideDishes;
    
    // Which Side
    if (collectionView == cvDishesLeft) // left side
    {
        /*GE*/
        
        // CLOSED: no menu today
        if ([[BentoShop sharedInstance] isClosed] && [[BentoShop sharedInstance] getMenuDateString] == nil)
        {
            aryMainDishes = [[BentoShop sharedInstance] getNextMainDishes:@"nextLunchPreview"];
            arySideDishes = [[BentoShop sharedInstance] getNextSideDishes:@"nextLunchPreview"];
        }
        
        // CLOSED: 00:00 - 12.29
        else if ([[BentoShop sharedInstance] isClosed] && currentTime >= 0 && currentTime < (lunchTime + bufferTime))
        {
            aryMainDishes = [[BentoShop sharedInstance] getMainDishes:@"todayLunch"];
            arySideDishes = [[BentoShop sharedInstance] getSideDishes:@"todayLunch"];
        }
        
        // CLOSED: 12:30 - 17:29
        else if ([[BentoShop sharedInstance] isClosed] && currentTime >= (lunchTime + bufferTime) && currentTime < (dinnerTime+bufferTime))
        {
            aryMainDishes = [[BentoShop sharedInstance] getMainDishes:@"todayDinner"];
            arySideDishes = [[BentoShop sharedInstance] getSideDishes:@"todayDinner"];
        }
        
        // CLOSED: 17.30 - 23:59
        else if ([[BentoShop sharedInstance] isClosed] && currentTime >= (dinnerTime+bufferTime) && currentTime < 24)
        {
            aryMainDishes = [[BentoShop sharedInstance] getNextMainDishes:@"nextLunchPreview"];
            arySideDishes = [[BentoShop sharedInstance] getNextSideDishes:@"nextLunchPreview"];
        }
        
        // SOLD-OUT: 11:30 - 16:30 (but use instead: 00:00 - 16:30)
        else if ([[BentoShop sharedInstance] isSoldOut] && currentTime >= 0 && currentTime < dinnerTime)
        {
            aryMainDishes = [[BentoShop sharedInstance] getMainDishes:@"todayLunch"];
            arySideDishes = [[BentoShop sharedInstance] getSideDishes:@"todayLunch"];
        }
        
        // SOLD-OUT: 16:30 - 23:59
        else if ([[BentoShop sharedInstance] isSoldOut] && currentTime >= dinnerTime && currentTime < 24)
        {
            aryMainDishes = [[BentoShop sharedInstance] getMainDishes:@"todayDinner"];
            arySideDishes = [[BentoShop sharedInstance] getSideDishes:@"todayDinner"];
        }
        
        NSLog(@"mains - %@", aryMainDishes);
        
        /*---------------*/
        
        if (section == 0) // Main Dishes
        {
            if (aryMainDishes == nil)
                return 0;
            
            return aryMainDishes.count;
        }
        else if (section == 1) // Side Dishes
        {
            if (arySideDishes == nil)
                return 0;
            
            return arySideDishes.count;
        }
    }
    else // right side
    {
        if ([[BentoShop sharedInstance] isClosed] && [[BentoShop sharedInstance] getMenuDateString] == nil)
        {
            aryMainDishes = [[BentoShop sharedInstance] getNextMainDishes:@"nextDinnerPreview"];
            arySideDishes = [[BentoShop sharedInstance] getNextSideDishes:@"nextDinnerPreview"];
        }
        
        // CLOSED: 00:00 - 12:29
        else if ([[BentoShop sharedInstance] isClosed] && currentTime >= 0 && currentTime < (lunchTime + bufferTime))
        {
            aryMainDishes = [[BentoShop sharedInstance] getMainDishes:@"todayDinner"];
            arySideDishes = [[BentoShop sharedInstance] getSideDishes:@"todayDinner"];
        }
        
        // CLOSED: 12:30 - 17:29
        else if ([[BentoShop sharedInstance] isClosed] && currentTime >= (lunchTime + bufferTime) && currentTime < (dinnerTime+bufferTime))
        {
            aryMainDishes = [[BentoShop sharedInstance] getNextMainDishes:@"nextLunchPreview"];
            arySideDishes = [[BentoShop sharedInstance] getNextSideDishes:@"nextLunchPreview"];
        }
        
        // CLOSED: 17.30 - 23:59
        else if ([[BentoShop sharedInstance] isClosed] && currentTime >= (dinnerTime+bufferTime) && currentTime < 24)
        {
            aryMainDishes = [[BentoShop sharedInstance] getNextMainDishes:@"nextDinnerPreview"];
            arySideDishes = [[BentoShop sharedInstance] getNextSideDishes:@"nextDinnerPreview"];
        }
        
        // SOLD-OUT: 11:30 - 16:30 (but use instead: 00:00 - 16:30)
        else if ([[BentoShop sharedInstance] isSoldOut] && currentTime >= 0 && currentTime < dinnerTime)
        {
            aryMainDishes = [[BentoShop sharedInstance] getMainDishes:@"todayDinner"];
            arySideDishes = [[BentoShop sharedInstance] getSideDishes:@"todayDinner"];
        }
        
        // SOLD-OUT: 16:30 - 23:59
        else if ([[BentoShop sharedInstance] isSoldOut] && currentTime >= dinnerTime && currentTime < 24)
        {
            aryMainDishes = [[BentoShop sharedInstance] getNextMainDishes:@"nextLunchPreview"];
            arySideDishes = [[BentoShop sharedInstance] getNextSideDishes:@"nextLunchPreview"];
        }
        
        /*---------------*/
        
        if (section == 0) // Main Dishes
        {
            if (aryMainDishes == nil)
                return 0;
            
            return aryMainDishes.count;
        }
        else if (section == 1) // Side Dishes
        {
            if (arySideDishes == nil)
                return 0;
            
            return arySideDishes.count;
        }
    }
    
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView == cvDishesLeft) // left side
    {
        PreviewCollectionViewCell *cell = (PreviewCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"PreviewCollectionViewCell" forIndexPath:indexPath];
        
        [cell initView];
        
        if (indexPath.section == 1)
            [cell setSmallDishCell];
        
        return cell;
    }
    else // right side
    {
        PreviewCollectionViewCell *cell = (PreviewCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"PreviewCollectionViewCell" forIndexPath:indexPath];
        
        [cell initView];
        
        if (indexPath.section == 1)
            [cell setSmallDishCell];
        
        return cell;
    }
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *aryMainDishes;
    NSArray *arySideDishes;
    
    if (collectionView == cvDishesLeft) // left side
    {
        // Closed: no menu today
        if ([[BentoShop sharedInstance] isClosed] && [[BentoShop sharedInstance] getMenuDateString] == nil)
        {
            aryMainDishes = [[BentoShop sharedInstance] getNextMainDishes:@"nextLunchPreview"];
            arySideDishes = [[BentoShop sharedInstance] getNextSideDishes:@"nextLunchPreview"];
        }
        
        // CLOSED: 00:00 - 12.29
        else if ([[BentoShop sharedInstance] isClosed] && currentTime >= 0 && currentTime < (lunchTime + bufferTime))
        {
            aryMainDishes = [[BentoShop sharedInstance] getMainDishes:@"todayLunch"];
            arySideDishes = [[BentoShop sharedInstance] getSideDishes:@"todayLunch"];
        }
        
        // CLOSED: 12:30 - 17:29
        else if ([[BentoShop sharedInstance] isClosed] && currentTime >= (lunchTime + bufferTime) && currentTime < (dinnerTime+bufferTime))
        {
            aryMainDishes = [[BentoShop sharedInstance] getMainDishes:@"todayDinner"];
            arySideDishes = [[BentoShop sharedInstance] getSideDishes:@"todayDinner"];
        }
        
        // CLOSED: 17.30 - 23:59
        else if ([[BentoShop sharedInstance] isClosed] && currentTime >= (dinnerTime+bufferTime) && currentTime < 24)
        {
            aryMainDishes = [[BentoShop sharedInstance] getNextMainDishes:@"nextLunchPreview"];
            arySideDishes = [[BentoShop sharedInstance] getNextSideDishes:@"nextLunchPreview"];
        }
        
        // SOLD-OUT: 11:30 - 16:30 (but use instead: 00:00 - 16:30)
        else if ([[BentoShop sharedInstance] isSoldOut] && currentTime >= 0 && currentTime < dinnerTime)
        {
            aryMainDishes = [[BentoShop sharedInstance] getMainDishes:@"todayLunch"];
            arySideDishes = [[BentoShop sharedInstance] getSideDishes:@"todayLunch"];
        }
        
        // SOLD-OUT: 16:30 - 23:59
        else if ([[BentoShop sharedInstance] isSoldOut] && currentTime >= dinnerTime && currentTime < 24)
        {
            aryMainDishes = [[BentoShop sharedInstance] getMainDishes:@"todayDinner"];
            arySideDishes = [[BentoShop sharedInstance] getSideDishes:@"todayDinner"];
        }
        
        /*---------------*/
        
        PreviewCollectionViewCell *myCell = (PreviewCollectionViewCell *)cell;
        
        if (indexPath.section == 0) // Main Dish
        {
            NSDictionary *dishInfo = [aryMainDishes objectAtIndex:indexPath.row];
            [myCell setDishInfo:dishInfo];
            
            if (_selectedPathMainLeft == indexPath.row)
                [myCell setCellState:YES];
            else
                [myCell setCellState:NO];
        }
        else if (indexPath.section == 1) // Side Dish
        {
            NSDictionary *dishInfo = [arySideDishes objectAtIndex:indexPath.row];
            [myCell setDishInfo:dishInfo];
            
            if (_selectedPathSideLeft == indexPath.row)
                [myCell setCellState:YES];
            else
                [myCell setCellState:NO];
        }
    }
    else // right side
    {
        // closed: no menu today
        if ([[BentoShop sharedInstance] isClosed] && [[BentoShop sharedInstance] getMenuDateString] == nil)
        {
            aryMainDishes = [[BentoShop sharedInstance] getNextMainDishes:@"nextDinnerPreview"];
            arySideDishes = [[BentoShop sharedInstance] getNextSideDishes:@"nextDinnerPreview"];
        }
        
        // CLOSED: 00:00 - 12:29
        else if ([[BentoShop sharedInstance] isClosed] && currentTime >= 0 && currentTime < (lunchTime + bufferTime))
        {
            aryMainDishes = [[BentoShop sharedInstance] getMainDishes:@"todayDinner"];
            arySideDishes = [[BentoShop sharedInstance] getSideDishes:@"todayDinner"];
        }
        
        // CLOSED: 12:30 - 17:29
        else if ([[BentoShop sharedInstance] isClosed] && currentTime >= (lunchTime + bufferTime) && currentTime < (dinnerTime+bufferTime))
        {
            aryMainDishes = [[BentoShop sharedInstance] getNextMainDishes:@"nextLunchPreview"];
            arySideDishes = [[BentoShop sharedInstance] getNextSideDishes:@"nextLunchPreview"];
        }
        
        // CLOSED: 17.30 - 23:59
        else if ([[BentoShop sharedInstance] isClosed] && currentTime >= (dinnerTime+bufferTime) && currentTime < 24)
        {
            aryMainDishes = [[BentoShop sharedInstance] getNextMainDishes:@"nextDinnerPreview"];
            arySideDishes = [[BentoShop sharedInstance] getNextSideDishes:@"nextDinnerPreview"];
        }
        
        // SOLD-OUT: 11:30 - 16:30 (but use instead: 00:00 - 16:30)
        else if ([[BentoShop sharedInstance] isSoldOut] && currentTime >= 0 && currentTime < dinnerTime)
        {
            aryMainDishes = [[BentoShop sharedInstance] getMainDishes:@"todayDinner"];
            arySideDishes = [[BentoShop sharedInstance] getSideDishes:@"todayDinner"];
        }
        
        // SOLD-OUT: 16:30 - 23:59
        else if ([[BentoShop sharedInstance] isSoldOut] && currentTime >= dinnerTime && currentTime < 24)
        {
            aryMainDishes = [[BentoShop sharedInstance] getNextMainDishes:@"nextLunchPreview"];
            arySideDishes = [[BentoShop sharedInstance] getNextSideDishes:@"nextLunchPreview"];
        }
        
        /*---------------*/

        
        PreviewCollectionViewCell *myCell = (PreviewCollectionViewCell *)cell;
        
        if (indexPath.section == 0) // Main Dish
        {
            NSDictionary *dishInfo = [aryMainDishes objectAtIndex:indexPath.row];
            [myCell setDishInfo:dishInfo];
            
            if (_selectedPathMainRight == indexPath.row)
                [myCell setCellState:YES];
            else
                [myCell setCellState:NO];
        }
        else if (indexPath.section == 1) // Side Dish
        {
            NSDictionary *dishInfo = [arySideDishes objectAtIndex:indexPath.row];
            [myCell setDishInfo:dishInfo];
            
            if (_selectedPathSideRight == indexPath.row)
                [myCell setCellState:YES];
            else
                [myCell setCellState:NO];
        }
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView == cvDishesLeft) // left side
    {
        if (indexPath.section == 0) // Main Dish
            return CGSizeMake(cvDishesLeft.frame.size.width, cvDishesLeft.frame.size.width * 3 / 5);
        else if (indexPath.section == 1) // Side Dish
            return CGSizeMake(cvDishesLeft.frame.size.width / 2, cvDishesLeft.frame.size.width / 2);
        
        return CGSizeMake(0, 0);
    }
    else // right side
    {
        if (indexPath.section == 0) // Main Dish
            return CGSizeMake(cvDishesRight.frame.size.width, cvDishesRight.frame.size.width * 3 / 5);
        else if (indexPath.section == 1) // Side Dish
            return CGSizeMake(cvDishesRight.frame.size.width / 2, cvDishesRight.frame.size.width / 2);
        
        return CGSizeMake(0, 0);
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView == cvDishesLeft) // left side
    {
        if (indexPath.section == 0)
        {
            if (_selectedPathMainLeft == indexPath.row)
                _selectedPathMainLeft = -1;
            else
            {
                _selectedPathMainLeft = indexPath.row;
                _selectedPathSideLeft = -1;
                
                // deselect everything on the right side
                _selectedPathMainRight = -1;
                _selectedPathSideRight = -1;
            }
        }
        else
        {
            if (_selectedPathSideLeft == indexPath.row)
            {
                _selectedPathSideLeft = -1;
            }
            else
            {
                _selectedPathSideLeft = indexPath.row;
                _selectedPathMainLeft = -1;
                
                // deselect everything on the right side
                _selectedPathMainRight = -1;
                _selectedPathSideRight = -1;
            }
        }
    }
    else // right side
    {
        if (indexPath.section == 0)
        {
            if (_selectedPathMainRight == indexPath.row)
                _selectedPathMainRight = -1;
            else
            {
                _selectedPathMainRight = indexPath.row;
                _selectedPathSideRight = -1;
                
                // deselect everything on the left side
                _selectedPathMainLeft = -1;
                _selectedPathSideLeft = -1;
            }
        }
        else
        {
            if (_selectedPathSideRight == indexPath.row)
            {
                _selectedPathSideRight = -1;
            }
            else
            {
                _selectedPathSideRight = indexPath.row;
                _selectedPathMainRight = -1;
                
                // deselect everything on the left side
                _selectedPathMainLeft = -1;
                _selectedPathSideLeft = -1;
            }
        }
    }
    
    [cvDishesLeft reloadData];
    [cvDishesRight reloadData];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    if (collectionView == cvDishesLeft) // left side
        return UIEdgeInsetsMake(0, 0, 0, 0);
    else // right side
        return UIEdgeInsetsMake(0, 0, 0, 0);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    if (collectionView == cvDishesLeft) // left side
    {
        if (section == 0 || section == 1)
            return CGSizeMake(cvDishesLeft.frame.size.width, 44);
    
        return CGSizeMake(0, 0);
    }
    else // right side
    {
        if (section == 0 || section == 1)
            return CGSizeMake(cvDishesRight.frame.size.width, 44);
    
        return CGSizeMake(0, 0);
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView == cvDishesLeft) // left side
    {
        if ([kind isEqualToString:UICollectionElementKindSectionHeader])
        {
            UICollectionReusableView *reusableview = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView" forIndexPath:indexPath];
            
            if (reusableview == nil)
                reusableview = [[UICollectionReusableView alloc] initWithFrame:CGRectMake(0, 0, cvDishesLeft.frame.size.width, 44)];
            
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
    else // right side
    {
        if ([kind isEqualToString:UICollectionElementKindSectionHeader])
        {
            UICollectionReusableView *reusableview = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView" forIndexPath:indexPath];
            
            if (reusableview == nil)
                reusableview = [[UICollectionReusableView alloc] initWithFrame:CGRectMake(0, 0, cvDishesRight.frame.size.width, 44)];
            
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
}

@end
