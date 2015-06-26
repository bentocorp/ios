//
//  ChooseMainDishViewController.m
//  Bento
//
//  Created by hanjinghe on 1/6/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "ChooseMainDishViewController.h"

#import "SoldOutViewController.h"
#import "DishCollectionViewCell.h"

#import "BentoShop.h"
#import "AppStrings.h"
#import "DataManager.h"

#import "JGProgressHUD.h"

@interface ChooseMainDishViewController () <DishCollectionViewCellDelegate>

@property (nonatomic, assign) IBOutlet UILabel *lblTitle;
@property (nonatomic, assign) IBOutlet UICollectionView *cvMainDishes;
@property (nonatomic, retain) NSMutableArray *aryDishes;

@end

@implementation ChooseMainDishViewController
{
    NSInteger _originalDishIndex;
    NSInteger _selectedIndex;
    NSInteger _selectedItemState;
    
    JGProgressHUD *loadingHUD;
    BOOL isThereConnection;
    
    NSString *originalDateString;
    NSString *newDateString;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // initialize to YES
    isThereConnection = YES;
    
    UINib *cellNib = [UINib nibWithNibName:@"DishCollectionViewCell" bundle:nil];
    [self.cvMainDishes registerNib:cellNib forCellWithReuseIdentifier:@"cell"];
    
    [self.lblTitle setText:[[AppStrings sharedInstance] getString:MAINDISH_TITLE]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.aryDishes = [[NSMutableArray alloc] init];
    
    NSString *lunchOrDinnerString;
    
    if ([[BentoShop sharedInstance] isAllDay])
    {
        if ([[BentoShop sharedInstance] isThereLunchMenu])
            lunchOrDinnerString = @"todayLunch";
        else if ([[BentoShop sharedInstance] isThereDinnerMenu])
            lunchOrDinnerString = @"todayDinner";
    }
    else
    {
        if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Lunch"])
            lunchOrDinnerString = @"todayLunch";
        else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Dinner"])
            lunchOrDinnerString = @"todayDinner";
    }
    
    for (NSDictionary * dishInfo in [[BentoShop sharedInstance] getMainDishes:lunchOrDinnerString])
    {
        NSInteger dishID = [[dishInfo objectForKey:@"itemId"] integerValue];
        //        if ([[BentoShop sharedInstance] isDishSoldOut:dishID] || [[BentoShop sharedInstance] canAddDish:dishID])
        if ([[BentoShop sharedInstance] canAddDish:dishID])
        {
            [self.aryDishes addObject:dishInfo];
        }
    }
    
    _selectedIndex = NSNotFound;
    _selectedItemState = DISH_CELL_NORMAL;
    
    _originalDishIndex = NSNotFound;
    if ([[BentoShop sharedInstance] getCurrentBento] != nil)
    {
        NSInteger mainDishIndex = [[[BentoShop sharedInstance] getCurrentBento] getMainDish];
        
        for (NSInteger index = 0; index < self.aryDishes.count; index++)
        {
            NSDictionary *dishInfo = [self.aryDishes objectAtIndex:index];
            if ([[dishInfo objectForKey:@"itemId"] integerValue] == mainDishIndex)
            {
                _originalDishIndex = index;
                _selectedIndex = index;
                _selectedItemState = DISH_CELL_SELECTED;
            }
        }
    }
    
//    [self.cvMainDishes reloadData];
    
    [self updateUI];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus:) name:USER_NOTIFICATION_UPDATED_MENU object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus:) name:USER_NOTIFICATION_UPDATED_STATUS object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noConnection) name:@"networkError" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yesConnection) name:@"networkConnected" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkCurrentMode) name:@"enteredForeground" object:nil];
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

//- (void)preloadCheckCurrentMode
//{
//    // so date string can refresh first
//    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(checkCurrentMode) userInfo:nil repeats:NO];
//}

- (void)checkCurrentMode
{
    NSString *originalMenuType = [[NSUserDefaults standardUserDefaults] objectForKey:@"originalMenuType"];
    NSString *currentMenuType = [[BentoShop sharedInstance] getMenuType];
    
    // if menu type changed, reset the app
    if (![originalMenuType isEqualToString:currentMenuType])
    {
        // reset originalMenuType with currentMenuType
        [[NSUserDefaults standardUserDefaults] setObject:currentMenuType forKey:@"originalMenuType"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[BentoShop sharedInstance] resetBentoArray];
        
        [(UINavigationController *)self.presentingViewController popToRootViewControllerAnimated:NO];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
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
        else
            [self performSelectorOnMainThread:@selector(updateUI) withObject:nil waitUntilDone:NO];
    }
}

- (IBAction)onBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) updateUI
{
    [self.cvMainDishes reloadData];
}

- (BOOL) isCompletedToMakeMyBento
{
    if ([[BentoShop sharedInstance] getCurrentBento] == nil)
        return NO;
    
    return [[[BentoShop sharedInstance] getCurrentBento] isCompleted];
}

- (void) showSoldoutScreen:(NSNumber *)identifier
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *nav = [storyboard instantiateViewControllerWithIdentifier:@"SoldOut"];
    SoldOutViewController *vcSoldOut = (SoldOutViewController *)nav.topViewController;
    vcSoldOut.type = [identifier integerValue];
    
    [self.navigationController presentViewController:nav animated:YES completion:nil];
}

#pragma mark - UICollectionViewDataSource Methods

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
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    DishCollectionViewCell *myCell = (DishCollectionViewCell *)cell;
    
    NSDictionary *dishInfo = [self.aryDishes objectAtIndex:indexPath.row];
    NSInteger dishID = [[dishInfo objectForKey:@"itemId"] integerValue];
    [myCell setDishInfo:dishInfo isSoldOut:[[BentoShop sharedInstance] isDishSoldOut:dishID] canBeAdded:[[BentoShop sharedInstance] canAddDish:dishID]];
    
    if (_selectedIndex == indexPath.item)
    {
        [myCell setCellState:_selectedItemState index:indexPath.item];
    }
    else
    {
        [myCell setCellState:DISH_CELL_NORMAL index:indexPath.item];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(self.cvMainDishes.frame.size.width, self.cvMainDishes.frame.size.height / 3);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
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
    
    [self updateUI];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section{
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

#pragma mark DishCollectionViewCellDelegate

- (void)onActionDishCell:(NSInteger)index
{
    _selectedIndex = index;
    
    NSDictionary *dishInfo = [self.aryDishes objectAtIndex:_selectedIndex];
    
    if (dishInfo == nil)
        return;
    
    NSInteger dishIndex = [[dishInfo objectForKey:@"itemId"] integerValue];
    
    // delete from bento
    if (_selectedItemState == DISH_CELL_SELECTED)
    {
        _originalDishIndex = NSNotFound;
        _selectedItemState = DISH_CELL_FOCUS;
        
        if ([[BentoShop sharedInstance] getCurrentBento] != nil)
        {
            [[[BentoShop sharedInstance] getCurrentBento] setMainDish:0];
        }
    }
    // add to bento
    else
    {
        _selectedItemState = DISH_CELL_SELECTED;
        
        [[[BentoShop sharedInstance] getCurrentBento] setMainDish:dishIndex];
        
        _originalDishIndex = index;
    }
    
    [self.cvMainDishes reloadData];
    
    [self updateUI];

    if (_selectedItemState == DISH_CELL_SELECTED)
        [self.navigationController popViewControllerAnimated:YES];
}

@end
