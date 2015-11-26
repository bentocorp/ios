//
//  AddonsViewController.m
//  Bento
//
//  Created by Joseph Lau on 11/17/15.
//  Copyright © 2015 bentonow. All rights reserved.
//

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

#import "AddonsViewController.h"
#import "AddonsTableViewCell.h"
#import "UIColor+CustomColors.h"
#import "BentoShop.h"
#import "AppStrings.h"
#import "MyAlertView.h"
#import "DataManager.h"
#import "AppDelegate.h"
#import "NSUserDefaults+RMSaveCustomObject.h"
#import "Canvas.h"
#import "SVPlacemark.h"
#import "JGProgressHUD.h"
#import "Mixpanel.h"
#import "Reachability.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import "DeliveryLocationViewController.h"
#import "CompleteOrderViewController.h"

#import "Addon.h"
#import "AddonList.h"

@interface AddonsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) NSMutableArray *aryDishes;

@end

@implementation AddonsViewController
{
    NSArray *aryMainDishes;
    
    NSTimer *connectionTimer;
    
    UITableView *myTableView;
    
    UILabel *lblBadge;
    UILabel *lblBadge2;
    UILabel *lblBanner;
    
    UIButton *btnCart;
    
    UIButton *btnState;
    
    // Right
    UILabel *lblTitle;
    UICollectionView *cvDishes;
    
    NSInteger hour;
    int weekday;
    
    AddonsTableViewCell *addonsCell;
    
    CSAnimationView *animationView;
    CSAnimationView *animationView2;
    
    JGProgressHUD *loadingHUD;
    
    NSMutableArray *savedArray;
    
    NSInteger _selectedPath;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _selectedPath = -1;
    
    /*---Navigation View---*/
    
    UIView *navigationBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 65)];
    navigationBarView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:navigationBarView];
    
    /*---Title---*/
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_WIDTH / 2 - 110, 20, 220, 45)];
    titleLabel.adjustsFontSizeToFitWidth = YES;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:16.0f];
    titleLabel.textColor = [UIColor bentoTitleGray];
    titleLabel.text = @"Choose Add-ons";
    [self.view addSubview:titleLabel];
    
    /*---Close Button---*/
    
    UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 20, 50, 45)];
    [closeButton setImage:[UIImage imageNamed:@"nav_btn_close"] forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(onClose) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeButton];
    
    /*---My Table View---*/
    
    myTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 65, SCREEN_WIDTH, SCREEN_HEIGHT - 65 - 45)];
    myTableView.backgroundColor = [UIColor colorWithRed:0.910f green:0.925f blue:0.925f alpha:1.0f];
    myTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    myTableView.separatorInset = UIEdgeInsetsMake(0, SCREEN_WIDTH / 2.5, 0, SCREEN_WIDTH/ 2.5);
    myTableView.allowsSelection = NO;
    myTableView.dataSource = self;
    myTableView.delegate = self;
    [self.view addSubview:myTableView];
    
    /*---Line Separator---*/
    
    UIView *longLineSepartor1 = [[UIView alloc] initWithFrame:CGRectMake(0, 65, SCREEN_WIDTH, 1)];
    longLineSepartor1.backgroundColor = [UIColor colorWithRed:0.827f green:0.835f blue:0.835f alpha:1.0f];
    [navigationBarView addSubview:longLineSepartor1];
    
    /*---Cart Button---*/
    
    btnCart = [[UIButton alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 50, 20, 50, 45)];
    [btnCart setImage:[UIImage imageNamed:@"mybento_nav_cart_act"] forState:UIControlStateNormal];
    [btnCart addTarget:self action:@selector(onCart) forControlEvents:UIControlEventTouchUpInside];
    [navigationBarView addSubview:btnCart];
    
    /*---Count Badge---*/
    
    animationView = [[CSAnimationView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 45, 25, 14, 14)];
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
    lblBadge.text = [NSString stringWithFormat:@"%ld", [[BentoShop sharedInstance] getCompletedBentoCount]];
    [animationView addSubview:lblBadge];
    
    animationView2 = [[CSAnimationView alloc] initWithFrame:CGRectMake(animationView.frame.origin.x + 14, 20, 14, 14)];
    animationView2.duration = 0.5;
    animationView2.delay = 0;
    animationView2.type = CSAnimationTypeZoomOut;
    [navigationBarView addSubview:animationView2];
    
    lblBadge2 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 17, 17)];
    lblBadge2.textAlignment = NSTextAlignmentCenter;
    lblBadge2.font = [UIFont fontWithName:@"OpenSans-Semibold" size:10];
    lblBadge2.textColor = [UIColor whiteColor];
    lblBadge2.backgroundColor = [UIColor colorWithRed:0.349f green:0.510f blue:0.855f alpha:1.0f];
    lblBadge2.layer.cornerRadius = lblBadge2.frame.size.width / 2;
    lblBadge2.clipsToBounds = YES;
    [animationView2 addSubview:lblBadge2];
    
    [self updateBadgeCount];
    
    /*---Button State---*/
    
    btnState = [[UIButton alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT-45, SCREEN_WIDTH, 45)];
    [btnState setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btnState.titleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:13.0f];
    btnState.backgroundColor = [UIColor bentoBrandGreen];
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
    
    [self.view addSubview:btnState];
    
    /*-----*/
    
    //
    AppDelegate *delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    CLLocationCoordinate2D location = [delegate getCurrentLocation];
    BentoShop *globalShop = [BentoShop sharedInstance];
    if (![globalShop checkLocation:location] && [[DataManager shareDataManager] getUserInfo] == nil) {
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"nextToBuild"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        DeliveryLocationViewController *deliveryLocationViewController = [storyboard instantiateViewControllerWithIdentifier:@"DeliveryLocationViewController"];
        [self.navigationController pushViewController:deliveryLocationViewController animated:NO];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // set aryDishes array
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

- (void)onClose {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Duration on screen
- (void)startTimerOnViewedScreen
{
    [[Mixpanel sharedInstance] timeEvent:@"Viewed Add-ons Screen"];
}

- (void)endTimerOnViewedScreen
{
    [[Mixpanel sharedInstance] track:@"Viewed Add-ons Screen"];
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
    if (![self connected] && [BentoShop sharedInstance]._isPaused) {
        if (loadingHUD == nil) {
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
    if ([self connected] && ![BentoShop sharedInstance]._isPaused) {
        [loadingHUD dismiss];
        loadingHUD = nil;
        
        [self viewWillAppear:YES];
    }
}

- (void)checkCurrentMode
{
    if ([[BentoShop sharedInstance] didModeOrDateChange]) {
        [(UINavigationController *)self.presentingViewController popToRootViewControllerAnimated:NO];
        [self dismissViewControllerAnimated:YES completion:nil];
        
        [self.navigationController popToRootViewControllerAnimated:YES];
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
    /*---Dish Info---*/
    NSDictionary *dishInfo = [self.aryDishes objectAtIndex:indexPath.row];
    
    NSLog(@"Current Dish: %@", dishInfo);
    
    addonsCell = (AddonsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (addonsCell == nil) {
        addonsCell = [[AddonsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
        addonsCell.tag = indexPath.row;
    }
    
    /*---Set dishInfo---*/
    [addonsCell addDishInfo:dishInfo];
    
    /*---Set State---*/
    if (_selectedPath == indexPath.row) {
        [addonsCell setCellState:YES];
    }
    else {
        [addonsCell setCellState:NO];
    }
    
    /*---Description---*/
    addonsCell.btnMainDish.tag = indexPath.row;
    [addonsCell.btnMainDish addTarget:self action:@selector(onDish:) forControlEvents:UIControlEventTouchUpInside];
    
    /*---Add---*/
    addonsCell.addButton.tag = indexPath.row;
    [addonsCell.addButton addTarget:self action:@selector(onAdd:) forControlEvents:UIControlEventTouchUpInside];
    
    /*---Subtract---*/
    addonsCell.subtractButton.tag = indexPath.row;
    [addonsCell.subtractButton addTarget:self action:@selector(onSubtract:) forControlEvents:UIControlEventTouchUpInside];
    
    // quantity
    // match current cell with addonitem, check if it exists in addonlist
    
    Addon *currentAddon = [[Addon alloc] initWithDictionary: dishInfo];
    
    BOOL currentItemExistsInAddonList = NO;
    
    for (int i = 0; i < [AddonList sharedInstance].addonList.count; i++) {
        
        Addon *addOnInList = [AddonList sharedInstance].addonList[i];
        
        if (currentAddon.itemId ==  addOnInList.itemId) {
            
            addonsCell.quantityLabel.text = [NSString stringWithFormat:@"%ld", addOnInList.qty];
            
            currentItemExistsInAddonList = YES;
            
            break;
        }
    }
    
    if (currentItemExistsInAddonList == NO) {
        addonsCell.quantityLabel.text = @"0";
    }
    
    return addonsCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (_selectedPath == indexPath.row) {
        _selectedPath = -1;
    }
    else {
        _selectedPath = indexPath.row;
    }
    
    [myTableView reloadData];
}

/*---------------------------------------------------------------------------------------------*/

- (void)updateUI
{
    [self sortAryDishesLeft];
    
    if ([self connected] && ![BentoShop sharedInstance]._isPaused) {
        connectionTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(reloadDishes) userInfo:nil repeats:NO];
    }
}

- (void)updateBadgeCount
{
    if ([[BentoShop sharedInstance] getCompletedBentoCount] > 0) {
        
        lblBadge2.text = [NSString stringWithFormat:@"%ld", [[AddonList sharedInstance] getTotalCount]];
        
        [animationView2 startCanvasAnimation];
        
        if ([[AddonList sharedInstance] getTotalCount] > 0) {
            lblBadge2.hidden = NO;
        }
        else {
            lblBadge2.hidden = YES;
        }
    }
}

- (void)reloadDishes
{
    if ([self connected] && ![BentoShop sharedInstance]._isPaused) {
        [self sortAryDishesLeft];
        [myTableView reloadData];
    }
}

- (void)onDish:(UIButton *)button {
    
    // search: http://stackoverflow.com/questions/7452389/how-to-get-indexpath-in-a-tableview-from-a-button-action-in-a-cell
    
    AddonsTableViewCell *cell = (AddonsTableViewCell *)button.superview.superview;
    
    NSIndexPath *indexPath = [myTableView indexPathForCell:cell];
    
    [self tableView:myTableView didSelectRowAtIndexPath:indexPath];
}

- (void)onAdd:(UIButton *)button {
    
    /*---Dish Info---*/
    NSDictionary *dishInfo = [self.aryDishes objectAtIndex: button.tag];
    Addon *selectedAddonItem = [[Addon alloc] initWithDictionary:dishInfo];
    
    // addonlist is not empty
    if ([AddonList sharedInstance].addonList.count != 0 || [AddonList sharedInstance].addonList != nil) {
    
        BOOL selectedItemIsInList = NO;
        
        // loop through addonlist
        for (int i = 0; i < [AddonList sharedInstance].addonList.count; i++) {
            
            Addon *addonItemInList = [AddonList sharedInstance].addonList[i];
            
            // selectedAddonItem is found in addonlist
            if (selectedAddonItem.itemId == addonItemInList.itemId) {
                
                // add one count to prexisting addon
                [[AddonList sharedInstance].addonList[i] addOneCount];
                
                selectedItemIsInList = YES;
            }
        }
        
        if (selectedItemIsInList == NO) {
            // add addon to list
            [selectedAddonItem addOneCount];
            [[AddonList sharedInstance].addonList addObject: selectedAddonItem];
        }
    }
    
    NSLog(@"addonlist - %@", [AddonList sharedInstance].addonList);
    
    [myTableView reloadData];
    [self updateUI];
    [self updateBadgeCount];
}

- (void)onSubtract:(UIButton *)button {
    
    /*---Dish Info---*/
    NSDictionary *dishInfo = [self.aryDishes objectAtIndex: button.tag];
    Addon *selectedAddonItem = [[Addon alloc] initWithDictionary:dishInfo];
    
    // addonlist is not empty
    if ([AddonList sharedInstance].addonList.count != 0 || [AddonList sharedInstance].addonList != nil) {
        
        // loop through addonlist
        for (int i = 0; i < [AddonList sharedInstance].addonList.count; i++) {
            
            Addon *addonItemInList = [AddonList sharedInstance].addonList[i];
            
            // selectedAddonItem is found in addonlist
            if (selectedAddonItem.itemId == addonItemInList.itemId) {
                
                // add one count to prexisting addon
                [[AddonList sharedInstance].addonList[i] removeOneCount];
                
                [myTableView reloadData];
                [self updateUI];
                [self updateBadgeCount];
            }
        }
    }
    
    NSLog(@"addonlist - %@", [AddonList sharedInstance].addonList);
}
- (void)onCart
{
    [self gotoOrderScreen];
    
//    Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];
//    if (currentBento != nil && ![currentBento isEmpty] && ![currentBento isCompleted]) {
//        [self showConfirmMsg];
//    }
//    else {
//        [self gotoOrderScreen];
//    }
}

- (void)gotoOrderScreen
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
    
//    // user and place info
//    NSDictionary *currentUserInfo = [[DataManager shareDataManager] getUserInfo];
//    SVPlacemark *placeInfo = [[NSUserDefaults standardUserDefaults] rm_customObjectForKey:@"delivery_location"];
//    
//    // summary and delivery screens
//    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
//    CompleteOrderViewController *completeOrderViewController = [storyboard instantiateViewControllerWithIdentifier:@"CompleteOrderViewController"];
//    DeliveryLocationViewController *deliveryLocationViewController = [storyboard instantiateViewControllerWithIdentifier:@"DeliveryLocationViewController"];
//    
//    // not logged in
//    if (currentUserInfo == nil) {
//        
//        // never saved location
//        if (placeInfo == nil) {
//            [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"isFromHomepage"];
//            [[NSUserDefaults standardUserDefaults] synchronize];
//            
//            [self openAccountViewController:[DeliveryLocationViewController class]];
//        }
//        // already has saved address
//        else {
//
//            // check if saved address is within CURRENT service area
//            CLLocationCoordinate2D location = placeInfo.location.coordinate;
//            
//            // not within service area
//            if (![[BentoShop sharedInstance] checkLocation:location]) {
//                [self openAccountViewController:[DeliveryLocationViewController class]];
//            }
//            // within service area
//            else {
//                [self openAccountViewController:[CompleteOrderViewController class]];
//            }
//        }
//    }
//    else {
//        if (placeInfo == nil) {
//            [self.navigationController pushViewController:deliveryLocationViewController animated:YES];
//        }
//        else {
//            // check if saved address is within CURRENT service area
//            CLLocationCoordinate2D location = placeInfo.location.coordinate;
//            
//            // not within service area
//            if (![[BentoShop sharedInstance] checkLocation:location]) {
//                [self.navigationController pushViewController:deliveryLocationViewController animated:YES];
//            }
//            // within service area
//            else {
//                [self.navigationController pushViewController:completeOrderViewController animated:YES];
//            }
//        }
//    }
}

- (void)onUpdatedStatus:(NSNotification *)notification
{
    if ([self connected] && ![BentoShop sharedInstance]._isPaused) {
        
        if ([[BentoShop sharedInstance] isClosed] && ![[DataManager shareDataManager] isAdminUser]) {
            [self showSoldoutScreen:[NSNumber numberWithInt:0]];
        }
        else if ([[BentoShop sharedInstance] isSoldOut] && ![[DataManager shareDataManager] isAdminUser]) {
            [self showSoldoutScreen:[NSNumber numberWithInt:1]];
        }
        else {
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
    [self gotoOrderScreen];
}

- (BOOL)isCompletedToMakeMyBento
{
    Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];
    if (currentBento == nil) {
        return NO;
    }
    
    return [currentBento isCompleted];
}

- (void)alertView:(MyAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];
        if (currentBento != nil && ![currentBento isCompleted]) {
            if ([[BentoShop sharedInstance] isAllDay]) {
                if ([[BentoShop sharedInstance] isThereLunchMenu]) {
                    [currentBento completeBento:@"todayLunch"];
                }
                else if ([[BentoShop sharedInstance] isThereDinnerMenu]) {
                    [currentBento completeBento:@"todayDinner"];
                }
            }
            else {
                if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Lunch"]) {
                    [currentBento completeBento:@"todayLunch"];
                }
                else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Dinner"]) {
                    [currentBento completeBento:@"todayDinner"];
                }
            }
        }
        
        [self gotoOrderScreen];
    }
}

- (void)onUpdatedMenu:(NSNotification *)notification
{
    // is connected and timer is not paused
    if ([self connected] && ![BentoShop sharedInstance]._isPaused) {
        [self updateUI];
    }
}

@end
