//
//  OrdersTableViewCell.h
//  Bento
//
//  Created by Joseph Lau on 1/15/16.
//  Copyright © 2016 bentonow. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OrdersTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *menuLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@end
