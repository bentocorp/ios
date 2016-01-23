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

@interface OrdersViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) UITableView *myTableView;
@property (nonatomic) NSDictionary *dicOrderHistory;

@end

@implementation OrdersViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.myTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, SCREEN_WIDTH, SCREEN_HEIGHT-64) style:UITableViewStylePlain];
    self.myTableView.dataSource = self;
    self.myTableView.delegate = self;
    [self.view addSubview:self.myTableView];
    
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
    [closeButton setImage:[UIImage imageNamed:@"nav_btn_close"] forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(closeButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeButton];

    // line separator under nav bar
    UIView *longLineSepartor1 = [[UIView alloc] initWithFrame:CGRectMake(0, 65, SCREEN_WIDTH, 1)];
    longLineSepartor1.backgroundColor = [UIColor colorWithRed:0.827f green:0.835f blue:0.835f alpha:1.0f];
    [self.view addSubview:longLineSepartor1];
}

- (void)viewWillAppear:(BOOL)animated {
    NSString *strRequest = [NSString stringWithFormat:@"/user/orderhistory?api_token=%@", [[DataManager shareDataManager] getAPIToken]];
    [[BentoShop sharedInstance] sendRequest:strRequest completion:^(id responseDic, NSError *error) {
        if (error == nil) {
            self.dicOrderHistory = (NSDictionary *)responseDic;
        }
    }];
}

- (void)closeButtonPressed {
    [self.navigationController popViewControllerAnimated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 45;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellId = @"cell";
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellId];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    }
    
    cell.textLabel.text = @"hello im joseph";
    
    return cell;
}

@end
