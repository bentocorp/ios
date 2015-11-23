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

@interface AddonsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) NSMutableArray *aryDishes;

@end

@implementation AddonsViewController
{
    NSArray *aryMainDishes;
    
    NSTimer *connectionTimer;
    
    UITableView *myTableView;
    
    UILabel *lblBadge;
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
    
    /*---Button State---*/
    
    btnState = [[UIButton alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT-45, SCREEN_WIDTH, 45)];
    [btnState setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btnState.titleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:13.0f];
    [btnState addTarget:self action:@selector(onContinue) forControlEvents:UIControlEventTouchUpInside];
    
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
    
    // if self.aryBentos is empty, create a new bento
    if ([[BentoShop sharedInstance] getTotalBentoCount] == 0) {
        [[BentoShop sharedInstance] addNewBento];
    }
    
    // Show these items
    lblBadge.hidden = NO;
    btnCart.hidden = NO;
    btnState.hidden = NO;
    
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
    return SCREEN_HEIGHT/2 + 60;
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
    addonsCell = (AddonsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (addonsCell == nil) {
        addonsCell = [[AddonsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    
    /*---Dish Info---*/
    NSDictionary *dishInfo = [self.aryDishes objectAtIndex:indexPath.row];
    [addonsCell setDishInfo:dishInfo];
    
    /*---Set State---*/
    if (_selectedPath == indexPath.row) {
        [addonsCell setCellState:YES];
    }
    else {
        [addonsCell setCellState:NO];
    }
    
    /*---Sold Out Banner---*/
    NSInteger mainDishId = [[dishInfo objectForKey:@"itemId"] integerValue];
    if ([[BentoShop sharedInstance] isDishSoldOut:mainDishId]) {
        addonsCell.ivBannerMainDish.hidden = NO;
    }
    else {
        addonsCell.ivBannerMainDish.hidden = YES;
    }
    
    /*---Description View---*/
    addonsCell.descriptionLabel.text = dishInfo[@"description"];
    
    addonsCell.btnMainDish.tag = indexPath.row; // set button tag
    [addonsCell.btnMainDish addTarget:self action:@selector(onDish:) forControlEvents:UIControlEventTouchUpInside];
    
    /*---Add---*/
    addonsCell.addButton.tag = indexPath.row;
    [addonsCell.addButton addTarget:self action:@selector(onAdd:) forControlEvents:UIControlEventTouchUpInside];
    
    /*---Subtract---*/
    addonsCell.subtractButton.tag = indexPath.row;
    [addonsCell.subtractButton addTarget:self action:@selector(onSubtract:) forControlEvents:UIControlEventTouchUpInside];
    
    /*---Price---*/
    if ([dishInfo[@"price"] isEqual:[NSNull null]] || dishInfo[@"price"] == nil || dishInfo[@"price"] == 0 || [dishInfo[@"price"] isEqualToString:@""]) {
        
        // format to currency style
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setNumberStyle: NSNumberFormatterCurrencyStyle];
        addonsCell.priceLabel.text = [NSString stringWithFormat: @"%@", [numberFormatter stringFromNumber:@([[[BentoShop sharedInstance] getUnitPrice] floatValue])]]; // default settings.price
    }
    else {
        addonsCell.priceLabel.text = [NSString stringWithFormat: @"$%@", dishInfo[@"price"]]; // custom price
    }
    
    return addonsCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (_selectedPath == indexPath.row)
        _selectedPath = -1;
    else {
        _selectedPath = indexPath.row;
    }
    
    [myTableView reloadData];
}

/*---------------------------------------------------------------------------------------------*/

- (void)updateUI
{
    [self sortAryDishesLeft];
    
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
    }
    else
    {
        btnCart.enabled = NO;
        btnCart.selected = NO;
        
        [btnState setBackgroundColor:[UIColor bentoButtonGray]];
        btnState.enabled = NO;
    }
    
    // Badge count label state
    NSInteger bentoCount = [[BentoShop sharedInstance] getCompletedBentoCount];
    if (bentoCount > 0)
    {
        lblBadge.text = [NSString stringWithFormat:@"%ld", (long)bentoCount];
        lblBadge.hidden = NO;
    }
    else
    {
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
        [myTableView reloadData];
    }
}

- (void)onDish:(UIButton *)button {
    
    // search: How to get indexPath in a tableview from a button action in a cell?
    
    AddonsTableViewCell *cell = (AddonsTableViewCell *)button.superview.superview;
    
    NSIndexPath *indexPath = [myTableView indexPathForCell:cell];
    
    [self tableView:myTableView didSelectRowAtIndexPath:indexPath];
}

- (void)onAdd:(id)sender {

}

- (void)onSubtract:(id)sender {

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
    if (currentBento != nil && ![currentBento isEmpty] && ![currentBento isCompleted]) {
        [self showConfirmMsg];
    }
    else {
        [self gotoOrderScreen];
    }
}

- (void)gotoOrderScreen
{
    NSDictionary *currentUserInfo = [[DataManager shareDataManager] getUserInfo];
    SVPlacemark *placeInfo = [[NSUserDefaults standardUserDefaults] rm_customObjectForKey:@"delivery_location"];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    CompleteOrderViewController *completeOrderViewController = [storyboard instantiateViewControllerWithIdentifier:@"CompleteOrderViewController"];
    DeliveryLocationViewController *deliveryLocationViewController = [storyboard instantiateViewControllerWithIdentifier:@"DeliveryLocationViewController"];
    
    if (currentUserInfo == nil) {
        
        if (placeInfo == nil) {
            [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"isFromHomepage"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [self openAccountViewController:[DeliveryLocationViewController class]];
        }
        // if user already has saved address
        else {

            // check if saved address is within CURRENT service area
            CLLocationCoordinate2D location = placeInfo.location.coordinate;
            
            // not within service area
            if (![[BentoShop sharedInstance] checkLocation:location]) {
                [self openAccountViewController:[DeliveryLocationViewController class]];
            }
            // within service area
            else {
                [self openAccountViewController:[CompleteOrderViewController class]];
            }
        }
    }
    else {
        if (placeInfo == nil) {
            [self.navigationController pushViewController:deliveryLocationViewController animated:YES];
        }
        else {
            // check if saved address is within CURRENT service area
            CLLocationCoordinate2D location = placeInfo.location.coordinate;
            
            // not within service area
            if (![[BentoShop sharedInstance] checkLocation:location]) {
                [self.navigationController pushViewController:deliveryLocationViewController animated:YES];
            }
            // within service area
            else {
                [self.navigationController pushViewController:completeOrderViewController animated:YES];
            }
        }
    }
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

- (void)onContinue
{
    Bento *currentBento = [[BentoShop sharedInstance] getCurrentBento];
    
    if (currentBento != nil || ![currentBento isEmpty]) {
        [[BentoShop sharedInstance] saveBentoArray];
        [self gotoOrderScreen];
    }
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
    if ([self connected] && ![BentoShop sharedInstance]._isPaused)
        [self updateUI];
}

@end
