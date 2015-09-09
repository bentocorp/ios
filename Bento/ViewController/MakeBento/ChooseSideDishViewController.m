//
//  ChooseSideDishViewController.m
//  Bento
//
//  Created by hanjinghe on 1/6/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "ChooseSideDishViewController.h"

#import "SoldOutViewController.h"
#import "DishCollectionViewCell.h"

#import "BentoShop.h"
#import "AppStrings.h"
#import "DataManager.h"

#import "JGProgressHUD.h"

#import "Mixpanel.h"

@interface ChooseSideDishViewController ()<DishCollectionViewCellDelegate>

@property (nonatomic, weak) IBOutlet UILabel *lblTitle;
@property (nonatomic, weak) IBOutlet UICollectionView *cvSideDishes;
@property (nonatomic) NSMutableArray *aryDishes;

@end

@implementation ChooseSideDishViewController
{
    NSInteger _originalDishIndex;
    NSInteger _selectedIndex;
    NSInteger _selectedItemState;
    
    JGProgressHUD *loadingHUD;
    BOOL isThereConnection;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // initialize to YES
    isThereConnection = YES;
    
    NSLog(@"viewdidload");
    
    // Set Nib to Collection View
    UINib *cellNib = [UINib nibWithNibName:@"DishCollectionViewCell" bundle:nil];
    [self.cvSideDishes registerNib:cellNib forCellWithReuseIdentifier:@"cell"];
    
    // Set Dish Title Label
    if (self.sideDishIndex == 0)
        [self.lblTitle setText:[[AppStrings sharedInstance] getString:SIDEDISH_1_TITLE]];
    else if (self.sideDishIndex == 1)
        [self.lblTitle setText:[[AppStrings sharedInstance] getString:SIDEDISH_2_TITLE]];
    else if (self.sideDishIndex == 2)
        [self.lblTitle setText:[[AppStrings sharedInstance] getString:SIDEDISH_3_TITLE]];
    else if (self.sideDishIndex == 3)
        [self.lblTitle setText:[[AppStrings sharedInstance] getString:SIDEDISH_4_TITLE]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus:) name:USER_NOTIFICATION_UPDATED_MENU object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus:) name:USER_NOTIFICATION_UPDATED_STATUS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noConnection) name:@"networkError" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yesConnection) name:@"networkConnected" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkCurrentMode) name:@"enteredForeground" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startTimerOnViewedScreen) name:@"enteredForeground" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endTimerOnViewedScreen) name:@"enteringBackground" object:nil];
    
    // Get Side Dish
    NSInteger sideDishIndex = 0;
    if ([[BentoShop sharedInstance] getCurrentBento] != nil)
    {
        if (self.sideDishIndex == 0)
            sideDishIndex = [[[BentoShop sharedInstance] getCurrentBento] getSideDish1];
        else if (self.sideDishIndex == 1)
            sideDishIndex = [[[BentoShop sharedInstance] getCurrentBento] getSideDish2];
        else if (self.sideDishIndex == 2)
            sideDishIndex = [[[BentoShop sharedInstance] getCurrentBento] getSideDish3];
        else if (self.sideDishIndex == 3)
            sideDishIndex = [[[BentoShop sharedInstance] getCurrentBento] getSideDish4];
    }
    
    self.aryDishes = [[NSMutableArray alloc] init];
    
    NSString *lunchOrDinnerString;
    
    /* IS ALL-DAY */
    if ([[BentoShop sharedInstance] isAllDay])
    {
        if ([[BentoShop sharedInstance] isThereLunchMenu])
            lunchOrDinnerString = @"todayLunch";
        else if ([[BentoShop sharedInstance] isThereDinnerMenu])
            lunchOrDinnerString = @"todayDinner";
    }
    
    /* IS NOT ALL-DAY */
    else
    {
        // 00:00 - 16:29
        if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Lunch"])
            lunchOrDinnerString = @"todayLunch";
        
        // 16:30 - 23:59
        else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Dinner"])
            lunchOrDinnerString = @"todayDinner";
    }
    
    for (NSDictionary * dishInfo in [[BentoShop sharedInstance] getSideDishes:lunchOrDinnerString])
    {
        NSInteger dishID = [[dishInfo objectForKey:@"itemId"] integerValue];
        
        if ([[BentoShop sharedInstance] canAddDish:dishID] && ([[[BentoShop sharedInstance] getCurrentBento] canAddSideDish:dishID] || dishID == sideDishIndex))
        {
            [self.aryDishes addObject:dishInfo];
            NSLog(@"self.aryDishes - %@", self.aryDishes);
        }
    }

    _originalDishIndex = NSNotFound;
    _selectedIndex = NSNotFound;
    _selectedItemState = DISH_CELL_NORMAL;
    
    if (sideDishIndex != 0)
    {
        for (NSInteger index = 0; index < self.aryDishes.count; index++)
        {
            NSDictionary *dishInfo = [self.aryDishes objectAtIndex:index];
            if ([[dishInfo objectForKey:@"itemId"] integerValue] == sideDishIndex)
            {
                _originalDishIndex = index;
                _selectedIndex = index;
                _selectedItemState = DISH_CELL_SELECTED;
            }
        }
    }
    
    [self updateUI];
    
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
    [[Mixpanel sharedInstance] timeEvent:@"Viewed Choose Your Side Dish Screen"];
}

- (void)endTimerOnViewedScreen
{
    [[Mixpanel sharedInstance] track:@"Viewed Choose Your Side Dish Screen"];
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

- (void)checkCurrentMode
{
    if ([[BentoShop sharedInstance] didModeOrDateChange])
    {
        [(UINavigationController *)self.presentingViewController popToRootViewControllerAnimated:NO];
        [self dismissViewControllerAnimated:YES completion:nil];
        
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)onUpdatedStatus:(NSNotification *)notification
{
    if (isThereConnection)
    {
        if ([[BentoShop sharedInstance] isClosed] && ![[DataManager shareDataManager] isAdminUser])
            [self showSoldoutScreen:[NSNumber numberWithInt:0]];
        else if ([[BentoShop sharedInstance] isSoldOut] && ![[DataManager shareDataManager] isAdminUser])
            [self showSoldoutScreen:[NSNumber numberWithInt:1]];
        else
            [self performSelectorOnMainThread:@selector(updateUI) withObject:nil waitUntilDone:NO];
    }
}

- (IBAction)onBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)updateUI
{
    [self.cvSideDishes reloadData];
}

- (BOOL)isCompletedToMakeMyBento
{
    if ([[BentoShop sharedInstance] getCurrentBento] == nil)
        return NO;
    
    return [[[BentoShop sharedInstance] getCurrentBento] isCompleted];
}

- (void)showSoldoutScreen:(NSNumber *)identifier
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *nav = [storyboard instantiateViewControllerWithIdentifier:@"SoldOut"];
    SoldOutViewController *vcSoldOut = (SoldOutViewController *)nav.topViewController;
    vcSoldOut.type = [identifier integerValue];
    
    [self.navigationController presentViewController:nav animated:YES completion:nil];
}

#pragma mark - UICollectionViewDatasource Methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (self.aryDishes == nil)
        return 0;
    
    return self.aryDishes.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    DishCollectionViewCell *cell = (DishCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.delegate = self;
    
    [cell setSmallDishCell];
    
    // Anything less than iOS 8.0
    if ([[UIDevice currentDevice].systemVersion intValue] < 8)
    {
        // Anything less than iOS 8.0
        NSDictionary *dishInfo = [self.aryDishes objectAtIndex:indexPath.row];
        NSInteger dishID = [[dishInfo objectForKey:@"itemId"] integerValue];
        
        BOOL canBeAdded = [[BentoShop sharedInstance] canAddDish:dishID];
        canBeAdded = canBeAdded && [[[BentoShop sharedInstance] getCurrentBento] canAddSideDish:dishID];
        [cell setDishInfo:dishInfo isSoldOut:[[BentoShop sharedInstance] isDishSoldOut:dishID] canBeAdded:canBeAdded];
        
        [cell setSmallDishCell];
        
        if (_selectedIndex == indexPath.item)
            [cell setCellState:_selectedItemState index:indexPath.item];
        else
            [cell setCellState:DISH_CELL_NORMAL index:indexPath.item];
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    DishCollectionViewCell *myCell = (DishCollectionViewCell *)cell;
    
    NSDictionary *dishInfo = [self.aryDishes objectAtIndex:indexPath.row];
    NSInteger dishID = [[dishInfo objectForKey:@"itemId"] integerValue];
    
    BOOL canBeAdded = [[BentoShop sharedInstance] canAddDish:dishID];
    canBeAdded = canBeAdded && [[[BentoShop sharedInstance] getCurrentBento] canAddSideDish:dishID];
    [myCell setDishInfo:dishInfo isSoldOut:[[BentoShop sharedInstance] isDishSoldOut:dishID] canBeAdded:canBeAdded];
    
    [myCell setSmallDishCell];
    
    if (_selectedIndex == indexPath.item)
        [myCell setCellState:_selectedItemState index:indexPath.item];
    else
        [myCell setCellState:DISH_CELL_NORMAL index:indexPath.item];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(self.cvSideDishes.frame.size.width / 2, self.cvSideDishes.frame.size.width / 2);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{   
    if (_selectedIndex == indexPath.item)
    {
        if (_selectedItemState == DISH_CELL_NORMAL)
        {
            if (_selectedIndex == _originalDishIndex)
                _selectedItemState = DISH_CELL_SELECTED;
            else
                _selectedItemState = DISH_CELL_FOCUS;
        }
        else if (_selectedItemState == DISH_CELL_FOCUS || _selectedItemState == DISH_CELL_SELECTED)
            _selectedItemState = DISH_CELL_NORMAL;
    }
    else
    {
        _selectedIndex = indexPath.item;
        
        if (_selectedIndex == _originalDishIndex)
            _selectedItemState = DISH_CELL_SELECTED;
        else
            _selectedItemState = DISH_CELL_FOCUS;
    }
    
    [collectionView reloadData];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

#pragma mark DishCollectionViewCellDelegate

- (void)onActionDishCell:(NSInteger)index
{
    NSDictionary *dishInfo = [self.aryDishes objectAtIndex:_selectedIndex];
    
    if (dishInfo == nil)
        return;
    
    NSInteger dishIndex = [[dishInfo objectForKey:@"itemId"] integerValue];
    
    if (_selectedItemState == DISH_CELL_SELECTED)
    {
        _originalDishIndex = NSNotFound;
        _selectedItemState = DISH_CELL_FOCUS;
        
        if ([[BentoShop sharedInstance] getCurrentBento] != nil)
        {
            // removes item from Side Dish
            if (self.sideDishIndex == 0)
                [[[BentoShop sharedInstance] getCurrentBento] setSideDish1:0];
            else if (self.sideDishIndex == 1)
                [[[BentoShop sharedInstance] getCurrentBento] setSideDish2:0];
            else if (self.sideDishIndex == 2)
                [[[BentoShop sharedInstance] getCurrentBento] setSideDish3:0];
            else if (self.sideDishIndex == 3)
                [[[BentoShop sharedInstance] getCurrentBento] setSideDish4:0];
        }
    }
    else
    {
        _selectedItemState = DISH_CELL_SELECTED;
        
        if (self.sideDishIndex == 0)
            [[[BentoShop sharedInstance] getCurrentBento] setSideDish1:dishIndex];
        else if (self.sideDishIndex == 1)
            [[[BentoShop sharedInstance] getCurrentBento] setSideDish2:dishIndex];
        else if (self.sideDishIndex == 2)
            [[[BentoShop sharedInstance] getCurrentBento] setSideDish3:dishIndex];
        else if (self.sideDishIndex == 3)
            [[[BentoShop sharedInstance] getCurrentBento] setSideDish4:dishIndex];
        
        _originalDishIndex = index;
    }
    
    [self updateUI];

    if (_selectedItemState == DISH_CELL_SELECTED)
        [self.navigationController popViewControllerAnimated:YES];
}

@end
