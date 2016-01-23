//
//  OrdersTableViewCell.m
//  Bento
//
//  Created by Joseph Lau on 1/23/16.
//  Copyright © 2016 bentonow. All rights reserved.
//

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

#import "OrdersTableViewCell.h"
#import "UIColor+CustomColors.h"

@implementation OrdersTableViewCell

- (void)awakeFromNib {
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 12, 200, 21)];
        self.titleLabel.textColor = [UIColor bentoBrandGreen];
        self.titleLabel.font = [UIFont fontWithName:@"OpenSans-SemiBold" size:14];
        [self addSubview:self.titleLabel];
        
        self.priceLabel = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 100, 12, 80, 21)];
        self.priceLabel.textColor = [UIColor bentoCorrectTextGray];
        self.priceLabel.font = [UIFont fontWithName:@"OpenSans-SemiBold" size:14];
        self.priceLabel.textAlignment = NSTextAlignmentRight;
        [self addSubview:self.priceLabel];
    }
    
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end
