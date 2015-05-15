//
//  SettingsTableViewCell.m
//  settings
//
//  Created by Joseph Lau on 4/23/15.
//  Copyright (c) 2015 Joseph Lau. All rights reserved.
//

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

#import "SettingsTableViewCell.h"

@implementation SettingsTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        
        self.backgroundColor = [UIColor whiteColor];
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        // icon
        self.iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(17.5, 10, 25, 25)];
        [self addSubview:self.iconImageView];
        
        // settings label
        self.settingsLabel = [[UILabel alloc] initWithFrame:CGRectMake(60, 10.5, 200, 24)];
        self.settingsLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
        self.settingsLabel.textColor = [UIColor colorWithRed:0.427f green:0.459f blue:0.514f alpha:1.0f];
        [self addSubview:self.settingsLabel];
    }
    
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
