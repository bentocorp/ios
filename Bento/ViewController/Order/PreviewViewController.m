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

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

@interface PreviewViewController () <UIScrollViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDelegate>

@end

@implementation PreviewViewController
{
    UIScrollView *scrollView;
    BWTitlePagerView *pagingTitleView;
    
    UILabel *lblTitle;
    UICollectionView *cvDishes;
    
    NSIndexPath *_selectedPath;
    
    NSInteger hour;
    int weekday;
    
    NSUserDefaults *defaults;
    float currentTime;
    float lunchTime;
    float dinnerTime;
    float bufferTime;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    /*---Times---*/
    defaults = [NSUserDefaults standardUserDefaults];
    currentTime = [[defaults objectForKey:@"currentTimeNumber"] floatValue];
    lunchTime = [[defaults objectForKey:@"lunchTimeNumber"] floatValue];
    dinnerTime = [[defaults objectForKey:@"dinnerTimeNumber"] floatValue];
    bufferTime = [[defaults objectForKey:@"bufferTimeNumber"] floatValue];
    
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
    
    NSString *titleLeft;
    NSString *titleRight;
    
    // CLOSED: 00:00 - 12.30
    if ([[BentoShop sharedInstance] isClosed] && currentTime >= 0 && currentTime < (lunchTime + bufferTime))
    {
        titleLeft = @"Today's Lunch";
        titleRight = @"Tonight's Dinner";
    }
    
    // CLOSED: 17.30 - 23:59
    if ([[BentoShop sharedInstance] isClosed] && currentTime >= (dinnerTime+bufferTime) && currentTime < 24)
    {
        titleLeft = @"Next Lunch";
        titleRight = @"Next Dinner";
    }
    
    // SOLD-OUT: 11:30 - 16:30
    if ([[BentoShop sharedInstance] isSoldOut] && currentTime >= lunchTime && currentTime < dinnerTime)
    {
        titleLeft = @"Today's Lunch";
        titleRight = @"Tonight's Dinner";
    }
    
    // SOLD-OUT: 16:30 - 23:59
    if ([[BentoShop sharedInstance] isSoldOut] && currentTime >= dinnerTime && currentTime < 24)
    {
        titleLeft = @"Today's Dinner";
        titleRight = @"Next Lunch";
    }
    
    pagingTitleView = [[BWTitlePagerView alloc] init];
    pagingTitleView.frame = CGRectMake(SCREEN_WIDTH/2-100, 32.5 - 10, 200, 40);
    pagingTitleView.font = [UIFont fontWithName:@"OpenSans-Bold" size:16.0f];
    pagingTitleView.currentTintColor = [UIColor colorWithRed:0.341f green:0.376f blue:0.439f alpha:1.0f];
    [pagingTitleView observeScrollView:scrollView];
    [pagingTitleView addObjects:@[titleLeft, titleRight]];
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
    
    // this sets the layout of the cells
    UICollectionViewFlowLayout *collectionViewFlowLayout = [[UICollectionViewFlowLayout alloc] init];
    [collectionViewFlowLayout setMinimumLineSpacing:0];
    [collectionViewFlowLayout setMinimumInteritemSpacing:0];
    
    UICollectionViewFlowLayout *collectionViewFlowLayout2 = [[UICollectionViewFlowLayout alloc] init];
    [collectionViewFlowLayout2 setMinimumLineSpacing:0];
    [collectionViewFlowLayout2 setMinimumInteritemSpacing:0];
    
    // fix this later
    for (int i = 0; i < 2; i++) {
        
        if (i == 0) {
            [cvDishes setCollectionViewLayout:collectionViewFlowLayout];
            cvDishes = [[UICollectionView alloc] initWithFrame:CGRectMake(i * SCREEN_WIDTH, 0, SCREEN_WIDTH, SCREEN_HEIGHT-65) collectionViewLayout:collectionViewFlowLayout];
        } else {
            [cvDishes setCollectionViewLayout:collectionViewFlowLayout2];
            cvDishes = [[UICollectionView alloc] initWithFrame:CGRectMake(i * SCREEN_WIDTH, 0, SCREEN_WIDTH, SCREEN_HEIGHT-65) collectionViewLayout:collectionViewFlowLayout2];
        }
        
        cvDishes.backgroundColor = [UIColor colorWithRed:0.910f green:0.925f blue:0.925f alpha:1.0f];
        cvDishes.dataSource = self;
        cvDishes.delegate = self;
        cvDishes.tag = i;
        
        UINib *cellNib = [UINib nibWithNibName:@"PreviewCollectionViewCell" bundle:nil];
        [cvDishes registerNib:cellNib forCellWithReuseIdentifier:@"PreviewCollectionViewCell"];
        [cvDishes registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView"];
        
        [scrollView addSubview:cvDishes];
    }
    
    // Sunday = 1, Saturday = 7
    weekday = (int)[[[NSCalendar currentCalendar] components:NSCalendarUnitWeekday fromDate:[NSDate date]] weekday];
    NSLog(@"today is - %ld", (long)weekday);
    
    _selectedPath = nil;

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedMenu:) name:USER_NOTIFICATION_UPDATED_NEXTMENU object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus:) name:USER_NOTIFICATION_UPDATED_STATUS object:nil];
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
    [cvDishes reloadData];
}

- (void)onUpdatedStatus:(NSNotification *)notification
{
    if (self.type == 0 && ![[BentoShop sharedInstance] isClosed]) // Closed
        [self performSelectorOnMainThread:@selector(onCloseButton) withObject:nil waitUntilDone:NO];
    else if (self.type == 1 && ![[BentoShop sharedInstance] isSoldOut]) // Sold Out
        [self performSelectorOnMainThread:@selector(onCloseButton) withObject:nil waitUntilDone:NO];
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
    if (collectionView.tag == 0) // left side
    {
        // CLOSED: 00:00 - 12.30
        if ([[BentoShop sharedInstance] isClosed] && currentTime >= 0 && currentTime < (lunchTime + bufferTime))
        {
            aryMainDishes = [[BentoShop sharedInstance] getMainDishes:@"todayLunch"];
            arySideDishes = [[BentoShop sharedInstance] getSideDishes:@"todayLunch"];
        }
        
        // CLOSED: 17.30 - 23:59
        if ([[BentoShop sharedInstance] isClosed] && currentTime >= (dinnerTime+bufferTime) && currentTime < 24)
        {
            aryMainDishes = [[BentoShop sharedInstance] getNextMainDishes:@"nextLunchPreview"];
            arySideDishes = [[BentoShop sharedInstance] getNextSideDishes:@"nextLunchPreview"];
        }
        
        // SOLD-OUT: 11:30 - 16:30
        if ([[BentoShop sharedInstance] isSoldOut] && currentTime >= lunchTime && currentTime < dinnerTime)
        {
            aryMainDishes = [[BentoShop sharedInstance] getMainDishes:@"todayLunch"];
            arySideDishes = [[BentoShop sharedInstance] getSideDishes:@"todayLunch"];
        }
        
        // SOLD-OUT: 16:30 - 23:59
        if ([[BentoShop sharedInstance] isSoldOut] && currentTime >= dinnerTime && currentTime < 24)
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
        // CLOSED: 00:00 - 12.30
        if ([[BentoShop sharedInstance] isClosed] && currentTime >= 0 && currentTime < (lunchTime + bufferTime))
        {
            aryMainDishes = [[BentoShop sharedInstance] getMainDishes:@"todayDinner"];
            arySideDishes = [[BentoShop sharedInstance] getSideDishes:@"todayDinner"];
        }
        
        // CLOSED: 17.30 - 23:59
        if ([[BentoShop sharedInstance] isClosed] && currentTime >= (dinnerTime+bufferTime) && currentTime < 24)
        {
            aryMainDishes = [[BentoShop sharedInstance] getNextMainDishes:@"nextDinnerPreview"];
            arySideDishes = [[BentoShop sharedInstance] getNextSideDishes:@"nextDinnerPreview"];
        }
        
        // SOLD-OUT: 11:30 - 16:30
        if ([[BentoShop sharedInstance] isSoldOut] && currentTime >= lunchTime && currentTime < dinnerTime)
        {
            aryMainDishes = [[BentoShop sharedInstance] getMainDishes:@"todayDinner"];
            arySideDishes = [[BentoShop sharedInstance] getSideDishes:@"todayDinner"];
        }
        
        // SOLD-OUT: 16:30 - 23:59
        if ([[BentoShop sharedInstance] isSoldOut] && currentTime >= dinnerTime && currentTime < 24)
        {
            aryMainDishes = [[BentoShop sharedInstance] getMainDishes:@"nextLunchPreview"];
            arySideDishes = [[BentoShop sharedInstance] getSideDishes:@"nextLunchPreview"];
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
    PreviewCollectionViewCell *cell = (PreviewCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"PreviewCollectionViewCell" forIndexPath:indexPath];
    
    [cell initView];
    
    if (indexPath.section == 1)
        [cell setSmallDishCell];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *aryMainDishes;
    NSArray *arySideDishes;
    
    if (collectionView.tag == 0) // left side
    {
        // CLOSED: 00:00 - 12.30
        if ([[BentoShop sharedInstance] isClosed] && currentTime >= 0 && currentTime < (lunchTime + bufferTime))
        {
            aryMainDishes = [[BentoShop sharedInstance] getMainDishes:@"todayLunch"];
            arySideDishes = [[BentoShop sharedInstance] getSideDishes:@"todayLunch"];
        }
        
        // CLOSED: 17.30 - 23:59
        if ([[BentoShop sharedInstance] isClosed] && currentTime >= (dinnerTime+bufferTime) && currentTime < 24)
        {
            aryMainDishes = [[BentoShop sharedInstance] getNextMainDishes:@"nextLunchPreview"];
            arySideDishes = [[BentoShop sharedInstance] getNextSideDishes:@"nextLunchPreview"];
        }
        
        // SOLD-OUT: 11:30 - 16:30
        if ([[BentoShop sharedInstance] isSoldOut] && currentTime >= lunchTime && currentTime < dinnerTime)
        {
            aryMainDishes = [[BentoShop sharedInstance] getMainDishes:@"todayLunch"];
            arySideDishes = [[BentoShop sharedInstance] getSideDishes:@"todayLunch"];
        }
        
        // SOLD-OUT: 16:30 - 23:59
        if ([[BentoShop sharedInstance] isSoldOut] && currentTime >= dinnerTime && currentTime < 24)
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
        }
        else if (indexPath.section == 1) // Side Dish
        {
            
            
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
    else // right side
    {
        // CLOSED: 00:00 - 12.30
        if ([[BentoShop sharedInstance] isClosed] && currentTime >= 0 && currentTime < (lunchTime + bufferTime))
        {
            aryMainDishes = [[BentoShop sharedInstance] getMainDishes:@"todayDinner"];
            arySideDishes = [[BentoShop sharedInstance] getSideDishes:@"todayDinner"];
        }
        
        // CLOSED: 17.30 - 23:59
        if ([[BentoShop sharedInstance] isClosed] && currentTime >= (dinnerTime+bufferTime) && currentTime < 24)
        {
            aryMainDishes = [[BentoShop sharedInstance] getNextMainDishes:@"nextDinnerPreview"];
            arySideDishes = [[BentoShop sharedInstance] getNextSideDishes:@"nextDinnerPreview"];
        }
        
        // SOLD-OUT: 11:30 - 16:30
        if ([[BentoShop sharedInstance] isSoldOut] && currentTime >= lunchTime && currentTime < dinnerTime)
        {
            aryMainDishes = [[BentoShop sharedInstance] getMainDishes:@"todayDinner"];
            arySideDishes = [[BentoShop sharedInstance] getSideDishes:@"todayDinner"];
        }
        
        // SOLD-OUT: 16:30 - 23:59
        if ([[BentoShop sharedInstance] isSoldOut] && currentTime >= dinnerTime && currentTime < 24)
        {
            aryMainDishes = [[BentoShop sharedInstance] getMainDishes:@"nextLunchPreview"];
            arySideDishes = [[BentoShop sharedInstance] getSideDishes:@"nextLunchPreview"];
        }
        
        /*---------------*/

        
        PreviewCollectionViewCell *myCell = (PreviewCollectionViewCell *)cell;
        
        if (indexPath.section == 0) // Main Dish
        {
            NSDictionary *dishInfo = [aryMainDishes objectAtIndex:indexPath.row];
            [myCell setDishInfo:dishInfo];
        }
        else if (indexPath.section == 1) // Side Dish
        {
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
