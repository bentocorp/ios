//
//  NotificationsCell.m
//  Bento
//
//  Created by Joseph Lau on 3/11/16.
//  Copyright © 2016 bentonow. All rights reserved.
//

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

#import "NotificationsCell.h"

@implementation NotificationsCell

- (void)awakeFromNib {
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        
        self.backgroundColor = [UIColor whiteColor];
        
//        self.toggle = [[UISwitch alloc] initWithFrame:CGRectMake(SCREEN_WIDTH-60, self.frame.size.height/2-15, 0, 0)];
//        self.toggle.transform = CGAffineTransformMakeScale(0.75, 0.75);
//        [self addSubview:self.toggle];
        
        // icon view
        UIView *notificationsIconView = [[UIView alloc] initWithFrame:CGRectMake(18, 10, 23, 23)];
        notificationsIconView.layer.cornerRadius = 3;
        notificationsIconView.layer.masksToBounds = YES;
        notificationsIconView.backgroundColor = [UIColor colorWithRed:0.694f green:0.706f blue:0.733f alpha:1.0f];
        [self addSubview:notificationsIconView];
        
        self.iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(notificationsIconView.frame.size.width/2-7.5, notificationsIconView.frame.size.height/2-7.5, 15, 15)];
        [notificationsIconView addSubview:self.iconImageView];
        
        // settings label
        self.settingsLabel = [[UILabel alloc] initWithFrame:CGRectMake(60, 10.5, 200, 24)];
        self.settingsLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
        self.settingsLabel.textColor = [UIColor colorWithRed:0.427f green:0.459f blue:0.514f alpha:1.0f];
        [self addSubview:self.settingsLabel];
        
        // on or off
        self.onOrOffLabel = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 140, 10.5, 100, 24)];
        self.onOrOffLabel.font = [UIFont fontWithName:@"OpenSans" size:14];
        self.onOrOffLabel.textColor = [UIColor colorWithRed:0.694f green:0.706f blue:0.733f alpha:1.0f];
        self.onOrOffLabel.textAlignment = NSTextAlignmentRight;
        [self addSubview:self.onOrOffLabel];
    }
    
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

@end
