//
//  OrdersViewController.m
//  Bento
//
//  Created by Joseph Lau on 1/22/16.
//  Copyright © 2016 bentonow. All rights reserved.
//

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

#import "OrdersViewController.h"
#import "UIColor+CustomColors.h"
#import <AFNetworking/AFNetworking.h>
#import "BentoShop.h"
#import "DataManager.h"
#import "JGProgressHUD.h"
#import "OrderHistorySection.h"
#import "OrderHistoryItem.h"
#import "OrdersTableViewCell.h"
#import "Mixpanel.h"

@interface OrdersViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) UITableView *myTableView;
@property (nonatomic) NSMutableArray *orderHistoryArray;

@end

@implementation OrdersViewController
{
    JGProgressHUD *loadingHUD;
    UILabel *noOrdersLabel;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    loadingHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
    [loadingHUD showInView:self.view];
    
    self.orderHistoryArray = [[NSMutableArray alloc] init];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    // navigation bar color
    UIView *navigationBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 65)];
    navigationBarView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:navigationBarView];

    // title label
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_WIDTH / 2 - 110, 20, 220, 45)];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:16.0f];
    titleLabel.textColor = [UIColor bentoTitleGray];
    titleLabel.text = @"Orders";
    [self.view addSubview:titleLabel];

    // back button
    UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 20, 50, 45)];
    [closeButton setImage:[UIImage imageNamed:@"nav_btn_back"] forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(closeButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeButton];

    // line separator under nav bar
    UIView *longLineSepartor1 = [[UIView alloc] initWithFrame:CGRectMake(0, 65, SCREEN_WIDTH, 1)];
    longLineSepartor1.backgroundColor = [UIColor colorWithRed:0.827f green:0.835f blue:0.835f alpha:1.0f];
    [self.view addSubview:longLineSepartor1];
    
    // Table View
    self.myTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, SCREEN_WIDTH, SCREEN_HEIGHT-64) style:UITableViewStylePlain];
    self.myTableView.backgroundColor = [UIColor bentoBackgroundGray];
    self.myTableView.dataSource = self;
    self.myTableView.delegate = self;
    self.myTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.myTableView.allowsSelection = NO;
    [self.view addSubview:self.myTableView];
    
    // No Orders
    noOrdersLabel = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_WIDTH-100, SCREEN_HEIGHT-22.5, 200, 45)];
    noOrdersLabel.text = @"NO ORDERS";
    noOrdersLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:14];
    noOrdersLabel.textColor = [UIColor whiteColor];
    noOrdersLabel.textAlignment = NSTextAlignmentCenter;
    noOrdersLabel.hidden = YES;
    [self.view addSubview:noOrdersLabel];
    
    [self getData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getData) name:USER_NOTIFICATION_UPDATED_MENU object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getData) name:USER_NOTIFICATION_UPDATED_STATUS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getData) name:@"enteredForeground" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noConnection) name:@"networkError" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yesConnection) name:@"networkConnected" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startTimerOnViewedScreen) name:@"enteredForeground" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endTimerOnViewedScreen) name:@"enteringBackground" object:nil];
    
    [self startTimerOnViewedScreen];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewWillDisappear:animated];
    
    [self endTimerOnViewedScreen];
}

#pragma mark Duration on screen
- (void)startTimerOnViewedScreen {
    [[Mixpanel sharedInstance] timeEvent:@"Viewed Orders Screen"];
}

- (void)endTimerOnViewedScreen {
    [[Mixpanel sharedInstance] track:@"Viewed Orders Screen"];
}

- (void)noConnection {
    if (loadingHUD == nil) {
        loadingHUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
        loadingHUD.textLabel.text = @"Waiting for internet connectivity...";
        [loadingHUD showInView:self.view];
    }
}

- (void)yesConnection {
    [loadingHUD dismiss];
    loadingHUD = nil;
}

- (void)getData {
    NSString *strRequest = [NSString stringWithFormat:@"/user/orderhistory?api_token=%@", [[DataManager shareDataManager] getAPIToken]];
    [[BentoShop sharedInstance] sendRequest:strRequest completion:^(id responseDic, NSError *error) {
        if (loadingHUD != nil) {
            [loadingHUD dismiss];
            loadingHUD = nil;
        }
        
        if (error == nil) {
            [self.orderHistoryArray removeAllObjects];
            
            for (NSDictionary *json in responseDic) {
                [self.orderHistoryArray addObject:[[OrderHistorySection alloc] initWithDictionary:json]];
            }
            
            BOOL doesAnySectionContainItems = NO;
            for (OrderHistorySection *section in self.orderHistoryArray) {
                if (section.items.count > 0) {
                    doesAnySectionContainItems = YES;
                }
            }
            
            if (doesAnySectionContainItems == YES) {
                noOrdersLabel.hidden = YES;
            }
            else {
                noOrdersLabel.hidden = NO;
            }
            
            [self.myTableView reloadData];
        }
        else {
            // error
            noOrdersLabel.hidden = NO;
        }
    }];
}

- (void)closeButtonPressed {
    [self.navigationController popViewControllerAnimated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 45;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    OrderHistorySection *orderHistorySection = self.orderHistoryArray[section];

    return orderHistorySection.sectionTitle;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if ([tableView.dataSource tableView:tableView numberOfRowsInSection:section] == 0) {
        return 0;
    }
    return 45;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *bgView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, tableView.frame.size.width, 45)];
    bgView.backgroundColor = [UIColor colorWithRed:0.275f green:0.306f blue:0.361f alpha:1.0f];
    
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 44, tableView.frame.size.width, 1)];
    lineView.backgroundColor = [UIColor colorWithRed:0.804f green:0.816f blue:0.816f alpha:1.0f];
    [bgView addSubview:lineView];
    
    OrderHistorySection *orderHistorySection = self.orderHistoryArray[section];
    
    UILabel *sectionTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, SCREEN_WIDTH-40, 45)];
    sectionTitleLabel.font = [UIFont fontWithName:@"OpenSans-SemiBold" size:14];
    sectionTitleLabel.textColor = [UIColor whiteColor];
    sectionTitleLabel.textAlignment = NSTextAlignmentCenter;
    sectionTitleLabel.text = orderHistorySection.sectionTitle;
    
    [bgView addSubview:sectionTitleLabel];
    
    return bgView;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.orderHistoryArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    OrderHistorySection *orderHistorySection = self.orderHistoryArray[section];
    
    return orderHistorySection.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellId = @"Cell";
    OrdersTableViewCell *cell = (OrdersTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellId];
    
    if (cell == nil) {
        cell = [[OrdersTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    }
    
    OrderHistorySection *orderHistorySection = self.orderHistoryArray[indexPath.section];
    OrderHistoryItem *orderHistoryItem = orderHistorySection.items[indexPath.row];
    
    cell.titleLabel.text = orderHistoryItem.title;
    cell.priceLabel.text = orderHistoryItem.price;
    
    return cell;
}

@end
