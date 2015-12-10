//
//  BentoTableViewCell.h
//  Bento
//
//  Created by hanjinghe on 1/9/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol BentoTableViewCellDelegate <NSObject>

- (void) onClickedMinuteButton:(UIView *)view;
- (void) onClickedMinuteButtonForAddons:(UIView *)view;
- (void) onClickedRemoveButton:(UIView *)view;

@end

@interface BentoTableViewCell : UITableViewCell

@property (nonatomic, weak) id <BentoTableViewCellDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIView *viewMain;

@property (weak, nonatomic) IBOutlet UILabel *lblBentoName;
@property (weak, nonatomic) IBOutlet UILabel *lblBentoPrice;

@property (weak, nonatomic) IBOutlet UIButton *btnMinute;
@property (weak, nonatomic) IBOutlet UIButton *btnRemove;

@property (nonatomic) NSString *type;

- (void) setNormalState;
- (void) setEditState;
- (void) setRemoveState;

@end
