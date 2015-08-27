//
//  ServingLunchBentoViewController.m
//  Bento
//
//  Created by Joseph Lau on 5/7/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

#import "FixedBentoPreviewViewController.h"
#import "PreviewCollectionViewCell.h"
#import "DataManager.h"
#import "BentoShop.h"
#import "JGProgressHUD.h"
#import "UIColor+CustomColors.h"

@interface FixedBentoPreviewViewController () <UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDelegate>

@end

@implementation FixedBentoPreviewViewController
{
    UILabel *lblTitle;
    UICollectionView *cvDishes;
    
    NSInteger _selectedPathMain;
    NSInteger _selectedPathSide;
    
    NSInteger hour;
    int weekday;
    JGProgressHUD *loadingHUD;
    
    BOOL isThereConnection;
}
    
- (void)viewDidLoad {
    [super viewDidLoad];
    
    isThereConnection = YES;
    
    self.view.backgroundColor = [UIColor colorWithRed:0.910f green:0.925f blue:0.925f alpha:1.0f];
    
    // navigation bar color
    UIView *navigationBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 65)];
    navigationBarView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:navigationBarView];
    
    // title label
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_WIDTH / 2 - 110, 20, 220, 45)];
    titleLabel.adjustsFontSizeToFitWidth = YES;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:16.0f];
    titleLabel.textColor = [UIColor colorWithBentoTitleGray];
    titleLabel.text = self.titleText;
    [self.view addSubview:titleLabel];
    
    // back button
    UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 20, 50, 45)];
    [closeButton setImage:[UIImage imageNamed:@"nav_btn_back"] forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(onCloseButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeButton];
    
    /*---Collection View---*/
    
    // this sets the layout of the cells
    UICollectionViewFlowLayout *collectionViewFlowLayout = [[UICollectionViewFlowLayout alloc] init];
    [collectionViewFlowLayout setMinimumLineSpacing:0];
    [collectionViewFlowLayout setMinimumInteritemSpacing:0];
    [cvDishes setCollectionViewLayout:collectionViewFlowLayout];
    
    cvDishes = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 65, SCREEN_WIDTH, SCREEN_HEIGHT-65) collectionViewLayout:collectionViewFlowLayout];
    cvDishes.backgroundColor = [UIColor colorWithRed:0.910f green:0.925f blue:0.925f alpha:1.0f];
    cvDishes.dataSource = self;
    cvDishes.delegate = self;
    
    UINib *cellNib = [UINib nibWithNibName:@"PreviewCollectionViewCell" bundle:nil];
    [cvDishes registerNib:cellNib forCellWithReuseIdentifier:@"PreviewCollectionViewCell"];
    [cvDishes registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"HeaderView"];
    
    [self.view addSubview:cvDishes];
    
    // Get current hour
    NSDate *currentDate = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitHour fromDate:currentDate];
    
    hour = [components hour];
    
    // Sunday = 1, Saturday = 7
    weekday = (int)[[calendar components:NSCalendarUnitWeekday fromDate:currentDate] weekday];
    NSLog(@"today is - %ld", (long)weekday);
    
    _selectedPathMain = -1;
    _selectedPathSide = -1;
}

- (void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus:) name:USER_NOTIFICATION_UPDATED_STATUS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus:) name:USER_NOTIFICATION_UPDATED_MENU object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noConnection) name:@"networkError" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yesConnection) name:@"networkConnected" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkCurrentMode) name:@"enteredForeground" object:nil];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewWillDisappear:animated];
}

- (void)onUpdatedStatus:(NSNotification *)notification
{
    if (isThereConnection)
    {
        if ([[BentoShop sharedInstance] isClosed] && ![[DataManager shareDataManager] isAdminUser])
            [self showSoldoutScreen:[NSNumber numberWithInt:0]];
        
        else if ([[BentoShop sharedInstance] isSoldOut] && ![[DataManager shareDataManager] isAdminUser])
            [self showSoldoutScreen:[NSNumber numberWithInt:1]];
    }
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
    isThereConnection = YES;
    
    [loadingHUD dismiss];
    loadingHUD = nil;
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)onCloseButton
{
    [self.navigationController popViewControllerAnimated:YES];
}

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
        return 1; // 1 main dish
    else
        return 4; // 4 side dishes
    
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
        // Anything less than iOS 8.0
        
        if (indexPath.section == 0) // Main Dish
        {
            NSArray *aryMainDishes;
            
            /* IS ALL DAY */
            if ([[BentoShop sharedInstance] isAllDay])
            {
                if([[BentoShop sharedInstance] isThereLunchMenu])
                    aryMainDishes = [[BentoShop sharedInstance] getMainDishes:@"todayLunch"];
                else if ([[BentoShop sharedInstance] isThereDinnerMenu])
                    aryMainDishes = [[BentoShop sharedInstance] getMainDishes:@"todayDinner"];
            }
            
            /* IS NOT ALL DAY */
            else
            {
                // 00:00 - 16:29
                if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Lunch"])
                    aryMainDishes = [[BentoShop sharedInstance] getMainDishes:@"todayLunch"];
                
                // 16:30 - 23:59
                else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Dinner"])
                    aryMainDishes = [[BentoShop sharedInstance] getMainDishes:@"todayDinner"];
            }
            
            NSDictionary *dishInfo = [aryMainDishes objectAtIndex:self.fromWhichVC];
            [cell setDishInfo:dishInfo];
            
            if (_selectedPathMain == indexPath.row)
                [cell setCellState:YES];
            else
                [cell setCellState:NO];
            
        }
        else if (indexPath.section == 1) // Side Dish
        {
            NSArray *arySideDishes;
            
            /* IS ALL DAY */
            if ([[BentoShop sharedInstance] isAllDay])
            {
                if([[BentoShop sharedInstance] isThereLunchMenu])
                    arySideDishes = [[BentoShop sharedInstance] getSideDishes:@"todayLunch"];
                else if ([[BentoShop sharedInstance] isThereDinnerMenu])
                    arySideDishes = [[BentoShop sharedInstance] getSideDishes:@"todayDinner"];
            }
            
            /* IS NOT ALL DAY */
            else
            {
                // 00:00 - 16:29
                if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Lunch"])
                    arySideDishes = [[BentoShop sharedInstance] getSideDishes:@"todayLunch"];
                
                // 16:30 - 23:59
                else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Dinner"])
                    arySideDishes = [[BentoShop sharedInstance] getSideDishes:@"todayDinner"];
            }
            
            NSDictionary *dishInfo = [arySideDishes objectAtIndex:indexPath.row];
            [cell setDishInfo:dishInfo];
            
            if (_selectedPathSide == indexPath.row)
                [cell setCellState:YES];
            else
                [cell setCellState:NO];
        }
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    PreviewCollectionViewCell *myCell = (PreviewCollectionViewCell *)cell;
    
    if (indexPath.section == 0) // Main Dish
    {
        NSArray *aryMainDishes;
        
        /* IS ALL DAY */
        if ([[BentoShop sharedInstance] isAllDay])
        {
            if([[BentoShop sharedInstance] isThereLunchMenu])
                aryMainDishes = [[BentoShop sharedInstance] getMainDishes:@"todayLunch"];
            else if ([[BentoShop sharedInstance] isThereDinnerMenu])
                aryMainDishes = [[BentoShop sharedInstance] getMainDishes:@"todayDinner"];
        }
        
        /* IS NOT ALL DAY */
        else
        {
            // 00:00 - 16:29
            if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Lunch"])
                aryMainDishes = [[BentoShop sharedInstance] getMainDishes:@"todayLunch"];
            
            // 16:30 - 23:59
            else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Dinner"])
                aryMainDishes = [[BentoShop sharedInstance] getMainDishes:@"todayDinner"];
        }
        
        NSDictionary *dishInfo = [aryMainDishes objectAtIndex:self.fromWhichVC];
        [myCell setDishInfo:dishInfo];
        
        if (_selectedPathMain == indexPath.row)
            [myCell setCellState:YES];
        else
            [myCell setCellState:NO];
        
    }
    else if (indexPath.section == 1) // Side Dish
    {
        NSArray *arySideDishes;
        
        /* IS ALL DAY */
        if ([[BentoShop sharedInstance] isAllDay])
        {
            if([[BentoShop sharedInstance] isThereLunchMenu])
                arySideDishes = [[BentoShop sharedInstance] getSideDishes:@"todayLunch"];
            else if ([[BentoShop sharedInstance] isThereDinnerMenu])
                arySideDishes = [[BentoShop sharedInstance] getSideDishes:@"todayDinner"];
        }
        
        /* IS NOT ALL DAY */
        else
        {
            // 00:00 - 16:29
            if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Lunch"])
                arySideDishes = [[BentoShop sharedInstance] getSideDishes:@"todayLunch"];
            
            // 16:30 - 23:59
            else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Dinner"])
                arySideDishes = [[BentoShop sharedInstance] getSideDishes:@"todayDinner"];
        }
        
        NSDictionary *dishInfo = [arySideDishes objectAtIndex:indexPath.row];
        [myCell setDishInfo:dishInfo];
        
        if (_selectedPathSide == indexPath.row)
            [myCell setCellState:YES];
        else
            [myCell setCellState:NO];
    }
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
    if (indexPath.section == 0)
    {
        if (_selectedPathMain == indexPath.row)
            _selectedPathMain = -1;
        else
        {
            _selectedPathMain = indexPath.row;
            _selectedPathSide = -1;
        }
    }
    else
    {
        if (_selectedPathSide == indexPath.row)
        {
            _selectedPathSide = -1;
        }
        else
        {
            _selectedPathSide = indexPath.row;
            _selectedPathMain = -1;
        }
    }
    
    [collectionView reloadData];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

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
            label.text = @"Main Dish";
        else if (indexPath.section == 1)
            label.text = @"Side Dishes";
        
        reusableview.backgroundColor = [UIColor darkGrayColor];
        
        return reusableview;
    }
    
    return nil;
}

@end
