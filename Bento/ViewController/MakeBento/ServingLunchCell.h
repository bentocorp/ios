//
//  ServingLunchCell.h
//  Bento
//
//  Created by Joseph Lau on 5/5/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ServingLunchCell : UITableViewCell

@property (nonatomic) UIView *viewDish;

@property (nonatomic) UIImageView *ivMainDish;

@property (nonatomic) UILabel *lblMainDish;

@property (nonatomic) UIButton *btnMainDish;

@property (nonatomic) UIImageView *ivBannerMainDish;

@property (nonatomic) UIButton *addButton;

- (void)setDishInfo:(NSDictionary *)dishInfo;

@end
