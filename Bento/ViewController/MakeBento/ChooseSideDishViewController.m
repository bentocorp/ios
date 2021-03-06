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

#import "CountdownTimer.h"
#import "AddonList.h"

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
    
    NSMutableArray *OAOnlyItemsSides;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    isThereConnection = YES;
    
    // Set Nib to Collection View
    UINib *cellNib = [UINib nibWithNibName:@"DishCollectionViewCell" bundle:nil];
    [self.cvSideDishes registerNib:cellNib forCellWithReuseIdentifier:@"cell"];
    
    // Set Dish Title Label
    [self setDishTitleLabel];
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startTimerOnViewedScreen) name:@"enteredForeground" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endTimerOnViewedScreen) name:@"enteringBackground" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkCountDown) name:@"showCountDownTimer" object:nil];
    
    if (self.orderMode == OnDemand) {
        OAOnlyItemsSides = [[BentoShop sharedInstance] getOAOnlyItemsSides];
    }
    
    self.aryDishes = [[NSMutableArray alloc] init];
    
    _originalDishIndex = NSNotFound;
    _selectedIndex = NSNotFound;
    _selectedItemState = DISH_CELL_NORMAL;

    [self updateUI];
    
    [self startTimerOnViewedScreen];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewWillDisappear:animated];
    
    [self endTimerOnViewedScreen];
}

- (void)setDishTitleLabel {
    if (self.sideDishIndex == 0) {
        [self.lblTitle setText:[[AppStrings sharedInstance] getString:SIDEDISH_1_TITLE]];
    }
    else if (self.sideDishIndex == 1) {
        [self.lblTitle setText:[[AppStrings sharedInstance] getString:SIDEDISH_2_TITLE]];
    }
    else if (self.sideDishIndex == 2) {
        [self.lblTitle setText:[[AppStrings sharedInstance] getString:SIDEDISH_3_TITLE]];
    }
    else if (self.sideDishIndex == 3) {
        [self.lblTitle setText:[[AppStrings sharedInstance] getString:SIDEDISH_4_TITLE]];
    }
}

- (void)sortAryDishes {
    
    [self.aryDishes removeAllObjects];
    
    // Get Side Dish
    NSInteger sideDishIndex = 0;
    if ([[BentoShop sharedInstance] getCurrentBento] != nil) {
        if (self.sideDishIndex == 0) {
            sideDishIndex = [[[BentoShop sharedInstance] getCurrentBento] getSideDish1];
        }
        else if (self.sideDishIndex == 1) {
            sideDishIndex = [[[BentoShop sharedInstance] getCurrentBento] getSideDish2];
        }
        else if (self.sideDishIndex == 2) {
            sideDishIndex = [[[BentoShop sharedInstance] getCurrentBento] getSideDish3];
        }
        else if (self.sideDishIndex == 3) {
            sideDishIndex = [[[BentoShop sharedInstance] getCurrentBento] getSideDish4];
        }
    }
    
    NSArray *sideDishesFromMode;
    
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
            if ([[[BentoShop sharedInstance] getOnDemandMealMode] isEqualToString:@"lunch"])
                lunchOrDinnerString = @"todayLunch";
            
            // 16:30 - 23:59
            else if ([[[BentoShop sharedInstance] getOnDemandMealMode] isEqualToString:@"dinner"])
                lunchOrDinnerString = @"todayDinner";
        }
        
        sideDishesFromMode = [[BentoShop sharedInstance] getSideDishes:lunchOrDinnerString];
    }
    else if (self.orderMode == OrderAhead) {
        sideDishesFromMode = self.orderAheadMenu.sideDishes;
    }
    
    NSMutableArray *soldOutDishesArray = [@[] mutableCopy];
    
    for (NSDictionary * dishInfo in sideDishesFromMode) {
        NSInteger dishID = [[dishInfo objectForKey:@"itemId"] integerValue];
        
        if (self.orderMode == OnDemand) {
            if ([[BentoShop sharedInstance] canAddDish:dishID] && ([[[BentoShop sharedInstance] getCurrentBento] canAddSideDish:dishID] || dishID == sideDishIndex)) {
                
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
        else if (self.orderMode == OrderAhead) {
            if ([self.orderAheadMenu canAddDish:dishID] && ([self.orderAheadMenu canAddSideDish:dishID] || dishID == sideDishIndex)) {
                
                // 1) add to self.aryDishes only if it's not sold out
                if ([self.orderAheadMenu isDishSoldOut:dishID] == NO) {
                    
                    [self.aryDishes addObject:dishInfo];
                }
                else {
                    // 2) add all sold out dishes to soldOutDishesArray
                    [soldOutDishesArray addObject:dishInfo];
                }
            }
        }
    }
    
    // ) append exclusive dishes to self.arydishes
    if (self.orderMode == OnDemand) {
        self.aryDishes = [[self.aryDishes arrayByAddingObjectsFromArray:OAOnlyItemsSides] mutableCopy];
    }
    
    // 3) append sold out dishes to self.aryDishes
    self.aryDishes = [[self.aryDishes arrayByAddingObjectsFromArray:soldOutDishesArray] mutableCopy];
    
    if (sideDishIndex != 0) {
        for (NSInteger index = 0; index < self.aryDishes.count; index++) {
            NSDictionary *dishInfo = [self.aryDishes objectAtIndex:index];
            if ([dishInfo[@"itemId"] integerValue] == sideDishIndex) {
                _originalDishIndex = index;
                _selectedIndex = index;
                _selectedItemState = DISH_CELL_SELECTED;
            }
        }
    }
}

#pragma mark Duration on screen
- (void)startTimerOnViewedScreen {
    [[Mixpanel sharedInstance] timeEvent:@"Viewed Choose Your Side Dish Screen"];
}

- (void)endTimerOnViewedScreen {
    [[Mixpanel sharedInstance] track:@"Viewed Choose Your Side Dish Screen"];
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
    
    [self.cvSideDishes reloadData];
}

- (BOOL)isCompletedToMakeMyBento {
    if ([[BentoShop sharedInstance] getCurrentBento] == nil) {
        return NO;
    }
    
    return [[[BentoShop sharedInstance] getCurrentBento] isCompleted];
}

- (void)showSoldoutScreen:(NSNumber *)identifier {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *nav = [storyboard instantiateViewControllerWithIdentifier:@"SoldOut"];
    SoldOutViewController *vcSoldOut = (SoldOutViewController *)nav.topViewController;
    vcSoldOut.type = [identifier integerValue];
    
    [self.navigationController presentViewController:nav animated:YES completion:nil];
}

#pragma mark - UICollectionViewDatasource Methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.aryDishes == nil) {
        return 0;
    }
    
    return self.aryDishes.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    DishCollectionViewCell *cell = (DishCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.delegate = self;
    
    [cell setSmallDishCell];
    
    // Anything less than iOS 8.0
    if ([[UIDevice currentDevice].systemVersion intValue] < 8) {

        NSDictionary *dishInfo = [self.aryDishes objectAtIndex:indexPath.row];
        NSInteger dishID = [[dishInfo objectForKey:@"itemId"] integerValue];
        
        BOOL canBeAdded;
        
        if (self.orderMode == OnDemand) {
            canBeAdded = [[BentoShop sharedInstance] canAddDish:dishID] && [[[BentoShop sharedInstance] getCurrentBento] canAddSideDish:dishID];
            
            // if side dish, set isMain to NO
            if ([dishInfo[@"type"] isEqualToString:@"main"] == NO) {
                [cell setDishInfo:dishInfo isOAOnlyItem:[[BentoShop sharedInstance] isDishOAOnly:dishID OAOnlyItems:OAOnlyItemsSides] isSoldOut:[[BentoShop sharedInstance] isDishSoldOut:dishID] canBeAdded:[[BentoShop sharedInstance] canAddDish:dishID] isMain:NO];
            }
        }
        else if (self.orderMode == OrderAhead) {
            canBeAdded = [self.orderAheadMenu canAddDish:dishID] && [[[BentoShop sharedInstance] getCurrentBento] canAddSideDish:dishID];
            
            // if side dish, set isMain to NO
            if ([dishInfo[@"type"] isEqualToString:@"main"] == NO) {
                [cell setDishInfo:dishInfo isOAOnlyItem:[[BentoShop sharedInstance] isDishOAOnly:dishID OAOnlyItems:OAOnlyItemsSides] isSoldOut:[self.orderAheadMenu isDishSoldOut:dishID] canBeAdded:[self.orderAheadMenu canAddDish:dishID] isMain:NO];
            }
        }
        
        [cell setSmallDishCell];
        
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
    
    BOOL canBeAdded;
    
    if (self.orderMode == OnDemand) {
        canBeAdded = [[BentoShop sharedInstance] canAddDish:dishID] && [[[BentoShop sharedInstance] getCurrentBento] canAddSideDish:dishID];
        
        // if side dish, set isMain to NO
        if ([dishInfo[@"type"] isEqualToString:@"main"] == NO) {
            [myCell setDishInfo:dishInfo isOAOnlyItem:[[BentoShop sharedInstance] isDishOAOnly:dishID OAOnlyItems:OAOnlyItemsSides] isSoldOut:[[BentoShop sharedInstance] isDishSoldOut:dishID] canBeAdded:[[BentoShop sharedInstance] canAddDish:dishID] isMain:NO];
        }
    }
    else if (self.orderMode == OrderAhead) {
        canBeAdded = [self.orderAheadMenu canAddDish:dishID] && [[[BentoShop sharedInstance] getCurrentBento] canAddSideDish:dishID];
        
        // if side dish, set isMain to NO
        if ([dishInfo[@"type"] isEqualToString:@"main"] == NO) {
            [myCell setDishInfo:dishInfo isOAOnlyItem:[[BentoShop sharedInstance] isDishOAOnly:dishID OAOnlyItems:OAOnlyItemsSides] isSoldOut:[self.orderAheadMenu isDishSoldOut:dishID] canBeAdded:[self.orderAheadMenu canAddDish:dishID] isMain:NO];
        }
    }
    
    [myCell setSmallDishCell];
    
    if (_selectedIndex == indexPath.item) {
        [myCell setCellState:_selectedItemState index:indexPath.item];
    }
    else {
        [myCell setCellState:DISH_CELL_NORMAL index:indexPath.item];
    }
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
    
    if (dishInfo == nil) {
        return;
    }
    
    NSInteger dishIndex = [[dishInfo objectForKey:@"itemId"] integerValue];
    
    if (_selectedItemState == DISH_CELL_SELECTED) {
        
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
        
        [[Mixpanel sharedInstance] track:@"Withdrew Side Dish"];
    }
    else {
        _selectedItemState = DISH_CELL_SELECTED;
        
        if (self.sideDishIndex == 0)
            [[[BentoShop sharedInstance] getCurrentBento] setSideDish1:dishIndex];
        else if (self.sideDishIndex == 1)
            [[[BentoShop sharedInstance] getCurrentBento] setSideDish2:dishIndex];
        else if (self.sideDishIndex == 2)
            [[[BentoShop sharedInstance] getCurrentBento] setSideDish3:dishIndex];
        else if (self.sideDishIndex == 3)
            [[[BentoShop sharedInstance] getCurrentBento] setSideDish4:dishIndex];
        
        if (self.orderMode == OrderAhead) {
            [[BentoShop sharedInstance] getCurrentBento].orderAheadMenu = self.orderAheadMenu;
        }
        
        _originalDishIndex = index;
    }
    
    [self updateUI];

    if (_selectedItemState == DISH_CELL_SELECTED)
        [self.navigationController popViewControllerAnimated:YES];
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

- (void)checkCountDown {
    if (self.orderMode == OrderAhead && self.selectedOrderAheadIndex == 0) {
        if ([[CountdownTimer sharedInstance] shouldShowCountDown]) {
            if ([[CountdownTimer sharedInstance].finalCountDownTimerValue isEqualToString:@"0:00"]) {
                [self clearCart];
                [self.navigationController popToRootViewControllerAnimated:YES];
            }
        }
    }
}

- (void)clearCart {
    [[BentoShop sharedInstance] resetBentoArray];
    [[AddonList sharedInstance] emptyList];
}

@end
