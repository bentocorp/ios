//
//  OrdersViewController.m
//  Bento
//
//  Created by Joseph Lau on 1/15/16.
//  Copyright © 2016 bentonow. All rights reserved.
//

#import "OrdersViewController.h"
#import "OrdersTableViewCell.h"

@interface OrdersViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OrdersViewController
{
    NSArray *myDatabase;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    myDatabase = @[
                   @[@"Today, Dinner", @"Tomorrow, Lunch", @"Tomorrow, Dinner", @"Jan 16, Lunch", @"Jan 16, Dinner"],
                   @[@"11:00-11:30 AM", @"11:30-12:00 PM", @"12:00-12:30 PM", @"12:30-1:00 PM (sold-out)", @"1:00-1:30 PM", @"1:30-2:00 PM", @"5:00-5:30 PM", @"5:30-6:00 PM"]
                   ];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 45;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return myDatabase.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [myDatabase[section] count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellId = @"Cell";
    
    OrdersTableViewCell *cell = (OrdersTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellId];
    
    if (cell == nil) {
        cell = [[OrdersTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellId];
    }
    
    switch (indexPath.section) {
        case 0:
            cell.menuLabel.text = myDatabase[indexPath.section][indexPath.row];
            break;
            
        default:
            cell.timeLabel.text = myDatabase[indexPath.section][indexPath.row];
            break;
    }
    
    return cell;
}

@end
