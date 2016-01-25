//
//  OrdersTableViewCell.h
//  Bento
//
//  Created by Joseph Lau on 1/23/16.
//  Copyright © 2016 bentonow. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OrdersTableViewCell : UITableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;

@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UILabel *priceLabel;

@end
