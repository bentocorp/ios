//
//  AddonsTableViewCell.h
//  Bento
//
//  Created by Joseph Lau on 11/17/15.
//  Copyright © 2015 bentonow. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AddonsTableViewCell : UITableViewCell

@property (nonatomic) UIView *viewDish;

@property (nonatomic) UIImageView *ivMainDish;

@property (nonatomic) UILabel *lblMainDish;

@property (nonatomic) UIButton *btnMainDish;

@property (nonatomic) UIImageView *ivBannerMainDish;

@property (nonatomic) UIButton *addButton;

@property (nonatomic) UIButton *subtractButton;

@property (nonatomic) UILabel *priceLabel;

@property (nonatomic) UILabel *quantityLabel;

- (void)setDishInfo:(NSDictionary *)dishInfo; 

@end
