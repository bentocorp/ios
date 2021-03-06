//
//  AddonsTableViewCell.h
//  Bento
//
//  Created by Joseph Lau on 11/17/15.
//  Copyright © 2015 bentonow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OrderAheadMenu.h"
#import "FiveHomeViewController.h"

@interface AddonsTableViewCell : UITableViewCell

@property (nonatomic) UIView *viewDish;

@property (nonatomic) UIImageView *ivAddon;
@property (nonatomic) UIImageView *ivBannerAddon;

@property (nonatomic) UIButton *btnAddon;
@property (nonatomic) UIButton *addButton;
@property (nonatomic) UIButton *subtractButton;

@property (nonatomic) UILabel *lblAddon;
@property (nonatomic) UILabel *priceLabel;
@property (nonatomic) UILabel *quantityLabel;
@property (nonatomic) UILabel *descriptionLabel;

@property (nonatomic) OrderMode orderMode;
@property (nonatomic) OrderAheadMenu *orderAheadMenu;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;
- (void)addDishInfo:(NSDictionary *)dishInfo isOAOnly:(BOOL)isOAOnly;
- (void)setCellState:(BOOL)isSelected;

@end
