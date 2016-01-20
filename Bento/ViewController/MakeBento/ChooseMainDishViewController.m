//
//  ChooseMainDishViewController.m
//  Bento
//
//  Created by hanjinghe on 1/6/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "ChooseMainDishViewController.h"

#import "BentoShop.h"
#import "AppStrings.h"
#import "DataManager.h"

#import "JGProgressHUD.h"

#import "SoldOutViewController.h"
#import "DishCollectionViewCell.h"

#import "Mixpanel.h"

#import "OrderAheadMenu.h"

@interface ChooseMainDishViewController () <DishCollectionViewCellDelegate>

@property (nonatomic, weak) IBOutlet UILabel *lblTitle;
@property (nonatomic, weak) IBOutlet UICollectionView *cvMainDishes;
@property (nonatomic) NSMutableArray *aryDishes;

@end

@implementation ChooseMainDishViewController
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
    
    UINib *cellNib = [UINib nibWithNibName:@"DishCollectionViewCell" bundle:nil];
    [self.cvMainDishes registerNib:cellNib forCellWithReuseIdentifier:@"cell"];
    
    [self.lblTitle setText:[[AppStrings sharedInstance] getString:MAINDISH_TITLE]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self startTimerOnViewedScreen];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus:) name:USER_NOTIFICATION_UPDATED_MENU object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUpdatedStatus:) name:USER_NOTIFICATION_UPDATED_STATUS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noConnection) name:@"networkError" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yesConnection) name:@"networkConnected" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startTimerOnViewedScreen) name:@"enteredForeground" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endTimerOnViewedScreen) name:@"enteringBackground" object:nil];
    
    self.aryDishes = [[NSMutableArray alloc] init];
    
    [self sortAryDishes];
    
    _originalDishIndex = NSNotFound;
    _selectedIndex = NSNotFound;
    _selectedItemState = DISH_CELL_NORMAL;
    
    if ([[BentoShop sharedInstance] getCurrentBento] != nil) {
        
        NSInteger mainDishIndex = [[[BentoShop sharedInstance] getCurrentBento] getMainDish];
        
        for (NSInteger index = 0; index < self.aryDishes.count; index++) {
            
            NSDictionary *dishInfo = [self.aryDishes objectAtIndex:index];
            
            if ([[dishInfo objectForKey:@"itemId"] integerValue] == mainDishIndex) {
                _originalDishIndex = index;
                _selectedIndex = index;
                _selectedItemState = DISH_CELL_SELECTED;
            }
        }
    }
    
    [self updateUI];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewWillDisappear:animated];
    
    [self endTimerOnViewedScreen];
}

- (void)sortAryDishes {
    
    // clear items first
    [self.aryDishes removeAllObjects];
    
    NSArray *mainDishesFromMode;
    
    if (self.orderMode == OnDemand) {
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
        
        mainDishesFromMode = [[BentoShop sharedInstance] getMainDishes:lunchOrDinnerString];
    }
    else if (self.orderMode == OrderAhead) {
        mainDishesFromMode = self.orderAheadMenu.mainDishes;
    }
    
    NSMutableArray *soldOutDishesArray = [@[] mutableCopy];
    
    for (NSDictionary * dishInfo in mainDishesFromMode)
    {
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

#pragma mark Duration on screen
- (void)startTimerOnViewedScreen {
    [[Mixpanel sharedInstance] timeEvent:@"Viewed Choose Your Main Dish Screen"];
}

- (void)endTimerOnViewedScreen {
    [[Mixpanel sharedInstance] track:@"Viewed Choose Your Main Dish Screen"];
}

- (void)noConnection {
    isThereConnection = NO;
    
    if (loadingHUD == nil) {
        loadingHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
        loadingHUD.textLabel.text = @"Waiting for internet connectivity...";
        [loadingHUD showInView:self.view];
    }
}

- (void)yesConnection {
    [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(callUpdate) userInfo:nil repeats:NO];
}

- (void)callUpdate {
    isThereConnection = YES;
    
    [loadingHUD dismiss];
    loadingHUD = nil;
    [self viewWillAppear:YES];
}

- (void)onUpdatedStatus:(NSNotification *)notification {
    if (isThereConnection) {
        if ([[BentoShop sharedInstance] isClosed] && ![[DataManager shareDataManager] isAdminUser]) {
            [self showSoldoutScreen:[NSNumber numberWithInt:0]];
        }
        else if ([[BentoShop sharedInstance] isSoldOut] && ![[DataManager shareDataManager] isAdminUser]) {
            [self showSoldoutScreen:[NSNumber numberWithInt:1]];
        }
        else {
            [self performSelectorOnMainThread:@selector(updateUI) withObject:nil waitUntilDone:NO];
        }
    }
}

- (IBAction)onBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)updateUI {
    [self updateOrderAheadMenu];
    
    [self sortAryDishes];
    
    [self.cvMainDishes reloadData];
}

- (BOOL)isCompletedToMakeMyBento
{
    if ([[BentoShop sharedInstance] getCurrentBento] == nil)
        return NO;
    
    return [[[BentoShop sharedInstance] getCurrentBento] isCompleted];
}

- (void)showSoldoutScreen:(NSNumber *)identifier {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *nav = [storyboard instantiateViewControllerWithIdentifier:@"SoldOut"];
    SoldOutViewController *vcSoldOut = (SoldOutViewController *)nav.topViewController;
    vcSoldOut.type = [identifier integerValue];
    
    [self.navigationController presentViewController:nav animated:YES completion:nil];
}

#pragma mark - UICollectionViewDataSource Methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (self.aryDishes == nil) {
        return 0;
    }
    
    return self.aryDishes.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    DishCollectionViewCell *cell = (DishCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.delegate = self;
    
    // Anything less than iOS 8.0
    if ([[UIDevice currentDevice].systemVersion intValue] < 8)
    {
        NSDictionary *dishInfo = self.aryDishes[indexPath.row];
        NSInteger dishID = [dishInfo[@"itemId"] integerValue];
        
        if (self.orderMode == OnDemand) {
            // if main dish, set isMain to true
            if ([dishInfo[@"type"] isEqualToString:@"main"]) {
                [cell setDishInfo:dishInfo isSoldOut:[[BentoShop sharedInstance] isDishSoldOut:dishID] canBeAdded:[[BentoShop sharedInstance] canAddDish:dishID] isMain:YES];
            }
        }
        else if (self.orderMode == OrderAhead) {
            // if main dish, set isMain to true
            if ([dishInfo[@"type"] isEqualToString:@"main"]) {
                [cell setDishInfo:dishInfo isSoldOut:[self.orderAheadMenu isDishSoldOut:dishID] canBeAdded:[self.orderAheadMenu canAddDish:dishID] isMain:YES];
            }
        }
        
        if (_selectedIndex == indexPath.item) {
            [cell setCellState:_selectedItemState index:indexPath.item];
        }
        else {
            [cell setCellState:DISH_CELL_NORMAL index:indexPath.item];
        }
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    DishCollectionViewCell *myCell = (DishCollectionViewCell *)cell;
    
    NSDictionary *dishInfo = [self.aryDishes objectAtIndex:indexPath.row];
    NSInteger dishID = [[dishInfo objectForKey:@"itemId"] integerValue];
    
    // if main dish, set isMain to true
    if ([dishInfo[@"type"] isEqualToString:@"main"]) {
        
        if (self.orderMode == OnDemand) {
            [myCell setDishInfo:dishInfo isSoldOut:[[BentoShop sharedInstance] isDishSoldOut:dishID] canBeAdded:[[BentoShop sharedInstance] canAddDish:dishID] isMain:YES];
        }
        else if (self.orderMode == OrderAhead) {
            [myCell setDishInfo:dishInfo isSoldOut:[self.orderAheadMenu isDishSoldOut:dishID] canBeAdded:[self.orderAheadMenu canAddDish:dishID] isMain:YES];
        }
    }
    
    if (_selectedIndex == indexPath.item) {
        [myCell setCellState:_selectedItemState index:indexPath.item];
    }
    else {
        [myCell setCellState:DISH_CELL_NORMAL index:indexPath.item];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(self.cvMainDishes.frame.size.width, self.cvMainDishes.frame.size.height / 3 - 10);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (_selectedIndex == indexPath.item) {
        if (_selectedItemState == DISH_CELL_NORMAL) {
            if (_selectedIndex == _originalDishIndex) {
                _selectedItemState = DISH_CELL_SELECTED;
            }
            else {
                _selectedItemState = DISH_CELL_FOCUS;
            }
        }
        else if (_selectedItemState == DISH_CELL_FOCUS || _selectedItemState == DISH_CELL_SELECTED) {
            _selectedItemState = DISH_CELL_NORMAL;
        }
    }
    else {
        _selectedIndex = indexPath.item;
        if (_selectedIndex == _originalDishIndex) {
            _selectedItemState = DISH_CELL_SELECTED;
        }
        else {
            _selectedItemState = DISH_CELL_FOCUS;
        }
    }
    
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
    
    if (dishInfo == nil) {
        return;
    }
    
    NSInteger dishIndex = [[dishInfo objectForKey:@"itemId"] integerValue];
    
    // delete from bento
    if (_selectedItemState == DISH_CELL_SELECTED) {
        
        _originalDishIndex = NSNotFound;
        _selectedItemState = DISH_CELL_FOCUS;
        
        if ([[BentoShop sharedInstance] getCurrentBento] != nil) {
            [[[BentoShop sharedInstance] getCurrentBento] setMainDish:0];
        }
        
        [[Mixpanel sharedInstance] track:@"Withdrew Main Dish"];
    }
    // add to bento
    else {
        _selectedItemState = DISH_CELL_SELECTED;
        
        [[[BentoShop sharedInstance] getCurrentBento] setMainDish:dishIndex];
        
        if (self.orderMode == OrderAhead) {
            [[BentoShop sharedInstance] getCurrentBento].orderAheadMenu = self.orderAheadMenu;
        }
        
        _originalDishIndex = index;
    }
    
    [self updateUI];

    if (_selectedItemState == DISH_CELL_SELECTED) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark OrderAhead Update Menu
- (void)updateOrderAheadMenu {
    if (self.orderMode == OrderAhead) {
        for (OrderAheadMenu *orderAheadMenu in [[BentoShop sharedInstance] getOrderAheadMenus]) {
            if ([self.orderAheadMenu.name isEqualToString:orderAheadMenu.name]) {
                self.orderAheadMenu = orderAheadMenu;
            }
        }
    }
}

@end
