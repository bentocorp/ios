//
//  BentoTableViewCell.m
//  Bento
//
//  Created by hanjinghe on 1/9/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import "BentoTableViewCell.h"

@implementation BentoTableViewCell

- (void)awakeFromNib {
    // Initialization code
    
    [self setNormalState];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)onMinute:(id)sender
{
    NSRange first = [self.lblBentoName.text rangeOfComposedCharacterSequenceAtIndex:0];
    NSRange match = [self.lblBentoName.text rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet] options:0 range:first];
    if (match.location != NSNotFound) {
        // self.lblBentoName.text starts with a letter
        [self.delegate onClickedMinuteButton:self];
    }
    else {
        [self.delegate onClickedMinuteButtonForAddons:self];
    }
}

- (IBAction)onRemove:(id)sender
{   
    [self.delegate onClickedRemoveButton:self];
}

- (void)setNormalState
{
    [UIView animateWithDuration:0.3f animations:^{
        self.btnMinute.hidden = YES;
        self.btnRemove.hidden = YES;
        
        self.lblBentoName.frame = CGRectMake(15, self.lblBentoName.frame.origin.y, self.lblBentoName.frame.size.width, self.lblBentoName.frame.size.height);
        self.lblBentoPrice.hidden = NO;
    } completion:^(BOOL finished) {

    }];
}

- (void)setEditState
{
    [UIView animateWithDuration:0.3f animations:^{
        self.btnMinute.hidden = NO;
        self.btnRemove.hidden = YES;
        
        self.lblBentoName.frame = CGRectMake(15 + 30, self.lblBentoName.frame.origin.y, self.lblBentoName.frame.size.width, self.lblBentoName.frame.size.height);
        self.lblBentoPrice.hidden = NO;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)setRemoveState
{
    [UIView animateWithDuration:0.3f animations:^{
        self.btnMinute.hidden = YES;
        self.btnRemove.hidden = NO;
        
        self.lblBentoName.frame = CGRectMake(15, self.lblBentoName.frame.origin.y, self.lblBentoName.frame.size.width, self.lblBentoName.frame.size.height);
        self.lblBentoPrice.hidden = YES;
    } completion:^(BOOL finished) {
        
    }];
}

@end
