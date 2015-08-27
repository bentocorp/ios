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
#import "Mixpanel.h"
#import "DataManager.h"
#import "UIColor+CustomColors.h"

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

@interface PreviewViewController () <UIScrollViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDelegate>

@end

@implementation PreviewViewController
{
    NSUserDefaults *defaults;
    
    NSArray *aryMainDishesLeft;
    NSArray *arySideDishesLeft;
    NSArray *aryMainDishesRight;
    NSArray *arySideDishesRight;
    
    NSArray *todayLunchMainDishesArray;
    NSArray *todayLunchSideDishesArray;
    NSArray *todayDinnerMainDishesArray;
    NSArray *todayDinnerSideDishesArray;
    NSArray *nextLunchMainDishesArray;
    NSArray *nextLunchSideDishesArray;
    NSArray *nextDinnerMainDishesArray;
    NSArray *nextDinnerSideDishesArray;
    
    NSString *todayAllDayLunchMenuString;
    NSString *todayAllDayDinnerMenuString;
    NSString *todayLunchMenuString;
    NSString *todayDinnerMenuString;
    NSString *nextAllDayLunchMenuString;
    NSString *nextAllDayDinnerMenuString;
    NSString *nextLunchMenuString;
    NSString *nextDinnerMenuString;
    
    UIScrollView *scrollView;
    
    UIView *navigationBarView;
    
    BWTitlePagerView *pagingTitleView;
    
    UILabel *lblTitle;
    
    UICollectionView *cvDishesLeft;
    UICollectionView *cvDishesRight;
    
    NSInteger _selectedPathMainLeft;
    NSInteger _selectedPathSideLeft;
    NSInteger _selectedPathMainRight;
    NSInteger _selectedPathSideRight;
    
    float currentTime;
    float lunchTime;
    float dinnerTime;
    float bufferTime;
    
    BOOL isThereConnection;
    
    BOOL isSoldOut;
    BOOL isClosed;
    
    BOOL isAllDay;
    BOOL nextIsAllDay;
    
    BOOL isThereLunchMenu;
    BOOL isThereDinnerMenu;
    BOOL isThereLunchNextMenu;
    BOOL isThereDinnerNextMenu;
    
    JGProgressHUD *loadingHUD;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    /* Track Previewed Today's Menu */
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Previewed Today's Menu" properties:nil];
    
    /*---Initialize to YES---*/
    
    isThereConnection = YES;
    
    /*---Times---*/
    currentTime = [[[BentoShop sharedInstance] getCurrentTime] floatValue];
    lunchTime = [[[BentoShop sharedInstance] getLunchTime] floatValue];
    dinnerTime = [[[BentoShop sharedInstance] getDinnerTime] floatValue];
    bufferTime = [[[BentoShop sharedInstance] getBufferTime] floatValue];
    
    /*---Scroll View---*/
    
    scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 45, SCREEN_WIDTH, SCREEN_HEIGHT)];
    scrollView.pagingEnabled = YES;
    scrollView.backgroundColor = [UIColor colorWithRed:0.910f green:0.925f blue:0.925f alpha:1.0f];
    scrollView.bounces = NO;
    [self.view addSubview:scrollView];
    
    /*---Navigation View---*/
    
    navigationBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 65)];
    navigationBarView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:navigationBarView];
    
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
    
    // For selection
    _selectedPathMainLeft = -1;
    _selectedPathSideLeft = -1;
    
    _selectedPathMainRight = -1;
    _selectedPathSideRight = -1;
    
    // titles and dishes
    [self setTitlesMainAndSideDishes];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)setTitlesMainAndSideDishes
{
    [self setTimes];
    [self setArrays];
    [self setBool];
    [self setStrings];
    
    NSString *titleLeft;
    NSString *titleRight;
    
    BOOL shouldShowOneMenu = NO;
    
    /*----------------------------------*/
    
    /* SOLD OUT - IS ALL DAY */
    
    if (isSoldOut && isAllDay)
    {
        // LEFT SIDE
        if(isThereLunchMenu)
        {
            titleLeft = todayAllDayLunchMenuString;
            [self setTodayLunchArrays:@"Left"];
        }
        else if (isThereDinnerMenu)
        {
            titleLeft = todayAllDayDinnerMenuString;
            [self setTodayDinnerArrays:@"Left"];
        }
        
        // RIGHT SIDE
        if (isThereLunchNextMenu)
            [self setNextLunchArrays:@"Right"];
        else if (isThereDinnerNextMenu)
            [self setNextDinnerArrays:@"Right"];
        else
            shouldShowOneMenu = YES;
        
        // set right menu title
        if (nextIsAllDay)
        {
            if (isThereLunchNextMenu)
                titleRight = nextAllDayLunchMenuString;
            else if (isThereDinnerNextMenu)
                titleRight = nextAllDayDinnerMenuString;
        }
        else if (nextIsAllDay == NO)
        {
            if (isThereLunchNextMenu)
                titleRight = nextLunchMenuString;
            else if (isThereDinnerNextMenu)
                titleRight = nextDinnerMenuString;
        }
    }
    
    /* SOLD OUT - IS NOT ALL DAY */
    else
    {
        // 00:00 - 16:29
        if (currentTime >= 0 && currentTime < dinnerTime)
        {
            // LEFT SIDE
            if (isThereLunchMenu)
            {
                titleLeft = todayLunchMenuString;
                [self setTodayLunchArrays:@"Left"];
            }
            
            // RIGHT SIDE
            if (isThereDinnerMenu)
            {
                titleRight = todayDinnerMenuString;
                [self setTodayDinnerArrays:@"Right"];
            }
            else if (nextIsAllDay)
            {
                if (isThereLunchNextMenu)
                {
                    titleRight = nextAllDayLunchMenuString;
                    [self setNextLunchArrays:@"Right"];
                }
                else if (isThereDinnerNextMenu)
                {
                    titleRight = nextAllDayDinnerMenuString;
                    [self setNextDinnerArrays:@"Right"];
                }
            }
            else
            {
                if (isThereLunchNextMenu)
                {
                    titleRight = nextLunchMenuString;
                    [self setNextLunchArrays:@"Right"];
                }
                else if (isThereDinnerNextMenu)
                {
                    titleRight = nextDinnerMenuString;
                    [self setNextDinnerArrays:@"Right"];
                }
                else
                    shouldShowOneMenu = YES;
            }
        }
        // 16:30 - 23:59
        else if (currentTime >= dinnerTime && currentTime < 24)
        {
            // LEFT SIDE
            if (isThereDinnerMenu)
            {
                titleLeft = todayDinnerMenuString;
                [self setTodayDinnerArrays:@"Left"];
            }
            
            // Right Side
            if (nextIsAllDay == YES)
            {
                if (isThereLunchNextMenu)
                {
                    titleRight = nextAllDayLunchMenuString;
                    [self setNextLunchArrays:@"Right"];
                }
                else if (isThereDinnerNextMenu)
                {
                    titleRight = nextAllDayDinnerMenuString;
                    [self setNextDinnerArrays:@"Right"];
                }
            }
            else
            {
                if (isThereLunchNextMenu)
                {
                    titleRight = nextLunchMenuString;
                    [self setNextLunchArrays:@"Right"];
                }
                else if (isThereDinnerNextMenu)
                {
                    titleRight = nextDinnerMenuString;
                    [self setNextDinnerArrays:@"Right"];
                }
                else
                    shouldShowOneMenu = YES;
            }
        }
    }
    
    /*-----------------------------------------------*/
    
    /* CLOSED - IS ALL DAY */
    
    if (isClosed && isAllDay)
    {
        // 00:00 - 17:29
        if (currentTime >= 0 && currentTime < (dinnerTime + bufferTime))
        {
            // LEFT SIDE
            if (isThereLunchMenu)
            {
                titleLeft = todayAllDayLunchMenuString;
                [self setTodayLunchArrays:@"Left"];
            }
            else if (isThereDinnerMenu)
            {
                titleLeft = todayAllDayDinnerMenuString;
                [self setTodayDinnerArrays:@"Left"];
            }
            else if (nextIsAllDay) // use all-day title
            {
                if (isThereLunchNextMenu)
                {
                    titleLeft = nextAllDayLunchMenuString;
                    [self setNextLunchArrays:@"Left"];
                }
                else if (isThereDinnerNextMenu)
                {
                    titleLeft = nextAllDayDinnerMenuString;
                    [self setNextDinnerArrays:@"Left"];
                }
                
                shouldShowOneMenu = YES;
            }
            else if (nextIsAllDay == NO) // use regular title
            {
                if (isThereLunchNextMenu)
                {
                    titleLeft = nextLunchMenuString;
                    [self setNextLunchArrays:@"Left"];
                }
                else if (isThereDinnerNextMenu)
                {
                    titleLeft = nextDinnerMenuString;
                    [self setNextDinnerArrays:@"Left"];
                    
                    shouldShowOneMenu = YES;
                }
            }
            
            // RIGHT SIDE
            if (nextIsAllDay) // use all-day title
            {
                if (isThereLunchNextMenu)
                {
                    titleRight = nextAllDayLunchMenuString;
                    [self setNextLunchArrays:@"Right"];
                }
                else if (isThereDinnerNextMenu)
                {
                    titleRight = nextAllDayDinnerMenuString;
                    [self setNextDinnerArrays:@"Right"];
                }
                else
                    shouldShowOneMenu = YES;
            }
            else if (nextIsAllDay == NO) // use regular title
            {
                if (isThereLunchNextMenu)
                {
                    titleRight = nextLunchMenuString;
                    [self setNextLunchArrays:@"Right"];
                }
                else if (isThereDinnerNextMenu)
                {
                    titleRight = nextDinnerMenuString;
                    [self setNextDinnerArrays:@"Right"];
                }
                else
                    shouldShowOneMenu = YES;
            }
        }
        
        // 17:30 - 23:59
        else if (currentTime >= (dinnerTime + bufferTime) && currentTime < 24)
        {
            // LEFT SIDE
            if (nextIsAllDay) // All-day title, shouldShowOneMenu
            {
                if (isThereLunchNextMenu)
                {
                    titleLeft = nextAllDayLunchMenuString;
                    [self setNextLunchArrays:@"Left"];
                }
                else if (isThereDinnerNextMenu)
                {
                    titleLeft = nextAllDayDinnerMenuString;
                    [self setNextDinnerArrays:@"Left"];
                }
                
                shouldShowOneMenu = YES;
            }
            else if (nextIsAllDay == NO) // Regular title
            {
                if (isThereLunchNextMenu)
                {
                    titleLeft = nextLunchMenuString;
                    [self setNextLunchArrays:@"Left"];
                    
                    if (isThereDinnerNextMenu)
                    {
                        // RIGHT SIDE
                        titleLeft = nextDinnerMenuString;
                        [self setNextDinnerArrays:@"Left"];
                    }
                    else
                        shouldShowOneMenu = YES;
                }
                else if (isThereDinnerNextMenu)
                {
                    titleLeft = nextDinnerMenuString;
                    [self setNextDinnerArrays:@"Left"];
                    
                    shouldShowOneMenu = YES;
                }
            }
        }
    }
    
    /* CLOSED - NOT ALL DAY */
    
    else if (isClosed && isAllDay == NO)
    {
        // 00:00 - 12.29
        if (currentTime >= 0 && currentTime < (lunchTime + bufferTime))
        {
            // LEFT SIDE
            if (isThereLunchMenu)
            {
                titleLeft = todayLunchMenuString;
                [self setTodayLunchArrays:@"Left"];
                
                // RIGHT SIDE
                if (isThereDinnerMenu)
                {
                    titleRight = todayDinnerMenuString;
                    [self setTodayDinnerArrays:@"Right"];
                }
                else if (isThereLunchNextMenu)
                {
                    if (nextIsAllDay == YES)
                        titleRight = nextAllDayLunchMenuString;
                    else
                        titleRight = nextLunchMenuString;
                    
                    [self setNextLunchArrays:@"Right"];
                }
                else if (isThereDinnerNextMenu)
                {
                    if (nextIsAllDay == YES)
                        titleRight = nextAllDayDinnerMenuString;
                    else
                        titleRight = nextDinnerMenuString;
                    
                    [self setNextDinnerArrays:@"Right"];
                }
                else
                    shouldShowOneMenu = YES;
            }
            else if (isThereDinnerMenu)
            {
                titleLeft = todayDinnerMenuString;
                [self setTodayDinnerArrays:@"Left"];
                
                // RIGHT SIDE
                if (isThereLunchNextMenu)
                {
                    if (nextIsAllDay == YES)
                        titleRight = nextAllDayLunchMenuString;
                    else
                        titleRight = nextLunchMenuString;
                    
                    [self setNextLunchArrays:@"Right"];
                }
                else if (isThereDinnerNextMenu)
                {
                    if (nextIsAllDay == YES)
                        titleRight = nextAllDayDinnerMenuString;
                    else
                        titleRight = nextDinnerMenuString;
                    
                    [self setNextDinnerArrays:@"Right"];
                }
                else
                    shouldShowOneMenu = YES;
            }
            else if (isThereLunchNextMenu)
            {
                if (nextIsAllDay)
                {
                    titleLeft = nextLunchMenuString;
                    [self setNextLunchArrays:@"Left"];
                    
                    shouldShowOneMenu = YES;
                }
                else if (nextIsAllDay == NO)
                {
                    titleLeft = nextLunchMenuString;
                    [self setNextLunchArrays:@"Left"];
                    
                    // RIGHT SIDE
                    if (isThereDinnerNextMenu)
                    {
                        titleRight = nextDinnerMenuString;
                        [self setNextDinnerArrays:@"Right"];
                    }
                    else
                        shouldShowOneMenu = YES;
                }
            }
            else if (isThereDinnerNextMenu)
            {
                titleLeft = nextDinnerMenuString;
                [self setNextDinnerArrays:@"Left"];
                
                shouldShowOneMenu = YES;
            }
        }
        
        // 12:30 - 17:29
        else if (currentTime >= (lunchTime + bufferTime) && currentTime < (dinnerTime + bufferTime))
        {
            // LEFT SIDE
            if (isThereDinnerMenu)
            {
                titleLeft = todayDinnerMenuString;
                [self setTodayDinnerArrays:@"Left"];
                
                // RIGHT SIDE
                if (isThereLunchNextMenu)
                {
                    if (nextIsAllDay == YES)
                        titleRight = nextAllDayLunchMenuString;
                    else
                        titleRight = nextLunchMenuString;
                    
                    [self setNextLunchArrays:@"Right"];
                }
                else if (isThereDinnerNextMenu)
                {
                    if (nextIsAllDay == YES)
                        titleRight = nextAllDayDinnerMenuString;
                    else
                        titleRight = nextDinnerMenuString;
                    
                    [self setNextDinnerArrays:@"Right"];
                }
                else
                    shouldShowOneMenu = YES;
            }
            else if (isThereLunchNextMenu)
            {
                if (nextIsAllDay == YES)
                {
                    titleLeft = nextLunchMenuString;
                    [self setNextLunchArrays:@"Left"];
                    
                    shouldShowOneMenu = YES;
                }
                else if (nextIsAllDay == NO)
                {
                    titleLeft = nextLunchMenuString;
                    [self setNextLunchArrays:@"Left"];
                    
                    // RIGHT SIDE
                    if (isThereDinnerNextMenu)
                    {
                        titleRight = nextDinnerMenuString;
                        [self setNextDinnerArrays:@"Right"];
                    }
                    else
                        shouldShowOneMenu = YES;
                }
            }
            else if (isThereDinnerNextMenu)
            {
                titleLeft = nextDinnerMenuString;
                [self setNextDinnerArrays:@"Left"];
                
                shouldShowOneMenu = YES;
            }
        }
        
        // 17:30 - 23:59, note: after 5:30 should show tomorrow's menu meaning next, no more today
        else if (currentTime >= (dinnerTime+bufferTime) && currentTime < 24)
        {
            /* NEXT IS ALL-DAY */
            if (nextIsAllDay == YES)
            {
                // LEFT SIDE
                if (isThereLunchNextMenu)
                {
                    titleLeft = nextAllDayLunchMenuString;
                    [self setNextLunchArrays:@"Left"];
                }
                else if (isThereDinnerNextMenu)
                {
                    titleLeft = nextAllDayDinnerMenuString;
                    [self setNextDinnerArrays:@"Left"];
                }
                
                shouldShowOneMenu = YES;
            }
            
            /* NEXT IS NO ALL-DAY */
            else
            {
                // LEFT SIDE
                if (isThereLunchNextMenu)
                {
                    titleLeft = nextLunchMenuString;
                    [self setNextLunchArrays:@"Left"];
                    
                    // RIGHT SIDE
                    if (isThereDinnerNextMenu)
                    {
                        titleRight = nextDinnerMenuString;
                        [self setNextDinnerArrays:@"Right"];
                    }
                    else
                        shouldShowOneMenu = YES;
                }
                else if (isThereDinnerNextMenu)
                {
                    titleLeft = nextDinnerMenuString;
                    [self setNextDinnerArrays:@"Left"];
                    
                    shouldShowOneMenu = YES;
                }
            }
        }
    }
    
    // Just a safety measure in case there's no available menu, if so this page shouldn't even have been displayed
    if (titleLeft == nil)
        titleLeft = @"No Available Menu";
    
    if (titleRight == nil)
        titleRight = @"No Available Menu";
    
    [self setPageAndScrollView:shouldShowOneMenu left:titleLeft right:titleRight];
}

- (void)setTimes
{
    currentTime = [[[BentoShop sharedInstance] getCurrentTime] floatValue];
    lunchTime = [[[BentoShop sharedInstance] getLunchTime] floatValue];
    dinnerTime = [[[BentoShop sharedInstance] getDinnerTime] floatValue];
    bufferTime = [[[BentoShop sharedInstance] getBufferTime] floatValue];
}

- (void)setArrays
{
    todayLunchMainDishesArray = [[BentoShop sharedInstance] getMainDishes:@"todayLunch"];
    todayLunchSideDishesArray = [[BentoShop sharedInstance] getSideDishes:@"todayLunch"];
    
    todayDinnerMainDishesArray = [[BentoShop sharedInstance] getMainDishes:@"todayDinner"];
    todayDinnerSideDishesArray = [[BentoShop sharedInstance] getSideDishes:@"todayDinner"];
    
    nextLunchMainDishesArray = [[BentoShop sharedInstance] getNextMainDishes:@"nextLunchPreview"];
    nextLunchSideDishesArray = [[BentoShop sharedInstance] getNextSideDishes:@"nextLunchPreview"];
    
    nextDinnerMainDishesArray = [[BentoShop sharedInstance] getNextMainDishes:@"nextDinnerPreview"];
    nextDinnerSideDishesArray = [[BentoShop sharedInstance] getNextSideDishes:@"nextDinnerPreview"];
}

- (void)setBool
{
    isSoldOut = [[BentoShop sharedInstance] isSoldOut];
    isClosed = [[BentoShop sharedInstance] isClosed];
    
    isAllDay = [[BentoShop sharedInstance] isAllDay];
    nextIsAllDay = [[BentoShop sharedInstance] nextIsAllDay];
    
    isThereLunchMenu = [[BentoShop sharedInstance] isThereLunchMenu];
    isThereDinnerMenu = [[BentoShop sharedInstance] isThereDinnerMenu];
    
    isThereLunchNextMenu = [[BentoShop sharedInstance] isThereLunchNextMenu];
    isThereDinnerNextMenu = [[BentoShop sharedInstance] isThereDinnerNextMenu];
}

- (void)setStrings
{
    todayAllDayLunchMenuString = @"Today's All-day Lunch Menu";
    todayAllDayDinnerMenuString = @"Today's All-day Dinner Menu";
    
    todayLunchMenuString = @"Today's Lunch Menu";
    todayDinnerMenuString = @"Tonight's Dinner Menu";
    
    NSString *nextMenuWeekdayString;
    
    if ([[BentoShop sharedInstance] getNextMenuWeekdayString] != nil)
        nextMenuWeekdayString = [[BentoShop sharedInstance] getNextMenuWeekdayString];
    
    nextAllDayLunchMenuString = [NSString stringWithFormat:@"%@'s All-day Lunch Menu", nextMenuWeekdayString];
    nextAllDayDinnerMenuString = [NSString stringWithFormat:@"%@'s All-day Dinner Menu", nextMenuWeekdayString];
    
    nextLunchMenuString = [NSString stringWithFormat:@"%@'s Lunch Menu", nextMenuWeekdayString];
    nextDinnerMenuString = [NSString stringWithFormat:@"%@'s Dinner Menu", nextMenuWeekdayString];
}

- (void)setPageAndScrollView:(BOOL)shouldShowOneMenu left:(NSString *)titleLeft right:(NSString *)titleRight
{
    pagingTitleView = [[BWTitlePagerView alloc] init];
    pagingTitleView.frame = CGRectMake(SCREEN_WIDTH / 2 - 100, 32.5 - 10, 200, 40);
    pagingTitleView.font = [UIFont fontWithName:@"OpenSans-Bold" size:16.0f];
    pagingTitleView.currentTintColor = [UIColor bentoTitleGray];
    [pagingTitleView observeScrollView:scrollView];
    
    if (shouldShowOneMenu)
    {
        scrollView.contentSize = CGSizeMake(SCREEN_WIDTH, SCREEN_HEIGHT-65);
        [pagingTitleView addObjects:@[titleLeft]];
    }
    else
    {
        scrollView.contentSize = CGSizeMake(SCREEN_WIDTH * 2, SCREEN_HEIGHT-65);
        [pagingTitleView addObjects:@[titleLeft, titleRight]];
    }
    
    [navigationBarView addSubview:pagingTitleView];
}

- (void)setTodayLunchArrays:(NSString *)leftOrRight
{
    if ([leftOrRight isEqualToString:@"Left"])
    {
        aryMainDishesLeft = todayLunchMainDishesArray;
        arySideDishesLeft = todayLunchSideDishesArray;
    }
    else if ([leftOrRight isEqualToString:@"Right"])
    {
        aryMainDishesRight = todayLunchMainDishesArray;
        arySideDishesRight = todayLunchSideDishesArray;
    }
}

- (void)setTodayDinnerArrays:(NSString *)leftOrRight
{
    if ([leftOrRight isEqualToString:@"Left"])
    {
        aryMainDishesLeft = todayDinnerMainDishesArray;
        arySideDishesLeft = todayDinnerSideDishesArray;
    }
    else if ([leftOrRight isEqualToString:@"Right"])
    {
        aryMainDishesRight = todayDinnerMainDishesArray;
        arySideDishesRight = todayDinnerSideDishesArray;
    }
}

- (void)setNextLunchArrays:(NSString *)leftOrRight
{
    if ([leftOrRight isEqualToString:@"Left"])
    {
        aryMainDishesLeft = nextLunchMainDishesArray;
        arySideDishesLeft = nextLunchSideDishesArray;
    }
    else if ([leftOrRight isEqualToString:@"Right"])
    {
        aryMainDishesRight = nextLunchMainDishesArray;
        arySideDishesRight = nextLunchSideDishesArray;
    }
}

- (void)setNextDinnerArrays:(NSString *)leftOrRight
{
    if ([leftOrRight isEqualToString:@"Left"])
    {
        aryMainDishesLeft = nextDinnerMainDishesArray;
        arySideDishesLeft = nextDinnerSideDishesArray;
    }
    else if ([leftOrRight isEqualToString:@"Right"])
    {
        aryMainDishesRight = nextDinnerMainDishesArray;
        arySideDishesRight = nextDinnerSideDishesArray;
    }
}

#pragma mark - Notifications

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus) name:USER_NOTIFICATION_UPDATED_STATUS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noConnection) name:@"networkError" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yesConnection) name:@"networkConnected" object:nil];
}

- (void)onUpdatedStatus
{
    if (isThereConnection) {
        if ([[BentoShop sharedInstance] isClosed] == NO && [[BentoShop sharedInstance] isSoldOut] == NO)
            [self performSelectorOnMainThread:@selector(onBack) withObject:nil waitUntilDone:NO];
    }
}

- (void)onBack
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    //
    @try {
        [scrollView removeObserver:pagingTitleView.self forKeyPath:@"contentOffset" context:nil];
    }@catch(id anException){
        //do nothing, obviously it wasn't attached because an exception was thrown
    }
    
    [super viewWillDisappear:animated];
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

#pragma mark - Navigation

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
    NSArray *aryMain;
    NSArray *arySide;
    
    if (collectionView == cvDishesLeft) // left side
    {
        aryMain = aryMainDishesLeft;
        arySide = arySideDishesLeft;
    }
    else // right side
    {
        aryMain = aryMainDishesRight;
        arySide = arySideDishesRight;
    }
    
    if (section == 0) // Main Dishes
    {
        if (aryMain == nil)
            return 0;
        
        return aryMain.count;
    }
    else if (section == 1) // Side Dishes
    {
        if (arySide == nil)
            return 0;
        
        return arySide.count;
    }
    
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PreviewCollectionViewCell *cell = (PreviewCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"PreviewCollectionViewCell" forIndexPath:indexPath];
    
    [cell initView];
    
    if (indexPath.section == 1)
        [cell setSmallDishCell];
    
    // Anything less than iOS 8.0
    if ([[UIDevice currentDevice].systemVersion intValue] < 8)
    {
        NSArray *aryMain;
        NSArray *arySide;
        
        if (collectionView == cvDishesLeft) // left side
        {
            aryMain = aryMainDishesLeft;
            arySide = arySideDishesLeft;
        }
        else // right side
        {
            aryMain = aryMainDishesRight;
            arySide = arySideDishesRight;
        }
        
        PreviewCollectionViewCell *myCell = (PreviewCollectionViewCell *)cell;
        
        if (indexPath.section == 0) // Main Dish
        {
            NSDictionary *dishInfo = [aryMain objectAtIndex:indexPath.row];
            [myCell setDishInfo:dishInfo];
            
            if (collectionView == cvDishesLeft)
            {
                if (_selectedPathMainLeft == indexPath.row)
                    [myCell setCellState:YES];
                else
                    [myCell setCellState:NO];
            }
            else
            {
                if (_selectedPathMainRight == indexPath.row)
                    [myCell setCellState:YES];
                else
                    [myCell setCellState:NO];
            }
        }
        else if (indexPath.section == 1) // Side Dish
        {
            NSDictionary *dishInfo = [arySide objectAtIndex:indexPath.row];
            [myCell setDishInfo:dishInfo];
            
            if (collectionView == cvDishesLeft)
            {
                if (_selectedPathSideLeft == indexPath.row)
                    [myCell setCellState:YES];
                else
                    [myCell setCellState:NO];
            }
            else
            {
                if (_selectedPathSideRight == indexPath.row)
                    [myCell setCellState:YES];
                else
                    [myCell setCellState:NO];
            }
        }
    }
    
    return cell;
}

// iOS 7 does not call willDisplayCell
- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *aryMain;
    NSArray *arySide;
    
    if (collectionView == cvDishesLeft) // left side
    {
        aryMain = aryMainDishesLeft;
        arySide = arySideDishesLeft;
    }
    else // right side
    {
        aryMain = aryMainDishesRight;
        arySide = arySideDishesRight;
    }
    
    PreviewCollectionViewCell *myCell = (PreviewCollectionViewCell *)cell;
    
    if (indexPath.section == 0) // Main Dish
    {
        NSDictionary *dishInfo = [aryMain objectAtIndex:indexPath.row];
        [myCell setDishInfo:dishInfo];
        
        if (collectionView == cvDishesLeft)
        {
            if (_selectedPathMainLeft == indexPath.row)
                [myCell setCellState:YES];
            else
                [myCell setCellState:NO];
        }
        else
        {
            if (_selectedPathMainRight == indexPath.row)
                [myCell setCellState:YES];
            else
                [myCell setCellState:NO];
        }
    }
    else if (indexPath.section == 1) // Side Dish
    {
        NSDictionary *dishInfo = [arySide objectAtIndex:indexPath.row];
        [myCell setDishInfo:dishInfo];
        
        if (collectionView == cvDishesLeft)
        {
            if (_selectedPathSideLeft == indexPath.row)
                [myCell setCellState:YES];
            else
                [myCell setCellState:NO];
        }
        else
        {
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
                _selectedPathSideLeft = -1;
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
                _selectedPathSideRight = -1;
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
    // left side
    if (collectionView == cvDishesLeft)
        return UIEdgeInsetsMake(0, 0, 0, 0);
    
    // right side
    else
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
