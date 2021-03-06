//
//  EditPhoneNumberView.h
//  Bento
//
//  Created by Joseph Lau on 9/4/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EditPhoneNumberDelegate <NSObject>

- (void)changePhoneNumber:(NSString *)newPhoneNumber;

@end

@interface EditPhoneNumberView : UIView

@property (nonatomic, weak) id <EditPhoneNumberDelegate> delegate;

@end
