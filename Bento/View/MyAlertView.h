//
//  MyAlertView.h
//  Must
//
//  Created by hanjinghe on 10/16/14.
//  Copyright (c) 2014 Linkqlo. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MyAlertView;

@protocol MyAlertViewDelegate <NSObject>

- (void)alertView:(MyAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;

@end

@interface MyAlertView : UIView
{

}

@property (nonatomic, assign) id<MyAlertViewDelegate> delegate;

- (id)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id )delegate cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitle:(NSString *)otherButtonTitle;

- (void) showInView:(UIView *)view;

@end
