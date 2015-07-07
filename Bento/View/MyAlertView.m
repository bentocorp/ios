//
//  MyAlertView.m
//  Must
//
//  Created by hanjinghe on 10/16/14.
//  Copyright (c) 2014 Linkqlo. All rights reserved.
//

#import "MyAlertView.h"

#define BUTTON_HEIGHT 44
#define GAP 24
#define GAP_CONTENT 20

@interface MyAlertView()

@property (nonatomic, assign) UIView *viewBack;

@end

@implementation MyAlertView

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    
    return self;
}

- (id)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id )delegate cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitle:(NSString *)otherButtonTitle
{
    CGRect rect = [[UIScreen mainScreen] bounds];
    
    self = [self initWithFrame:rect];
    if (self) {
        
    }
    
    UIColor *textColor = [UIColor whiteColor];
    UIColor *lineColor = [UIColor colorWithRed:125.0f / 255.0f green:172.0f / 255.0f blue:79.0f / 255.0f alpha:1.0f];
    
    self.delegate = delegate;
    
    float width = CGRectGetWidth(rect);
    float height = CGRectGetHeight(rect);
    
    UIView *viewBack = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    viewBack.backgroundColor = [UIColor blackColor];
    viewBack.alpha = 0.5f;
    
    [self addSubview:viewBack];
    self.viewBack = viewBack;
    viewBack = nil;
    
    if (title != nil && title.length > 0)
    {
        message = [NSString stringWithFormat:@"%@\n%@", title, message];
    }
    
    UILabel *label = [UILabel new];
    label.font = [UIFont fontWithName:@"Open Sans" size:16.0f];
    label.numberOfLines = 100;
    label.textAlignment = NSTextAlignmentCenter;
    label.frame = CGRectMake(0, 0, width - (GAP + GAP_CONTENT) * 2, height);
    label.textColor = [UIColor colorWithRed:87.0f / 255.0f green:96.0f / 255.0f blue:112.0f / 255.0f alpha:1.0f];
    
    // DEPRECATED
//    CGSize szMessage = [message sizeWithFont:label.font constrainedToSize:label.frame.size];
    
    CGRect textRect = [message boundingRectWithSize:label.frame.size
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:@{NSFontAttributeName:label.font}
                                         context:nil];
    CGSize szMessage = textRect.size;
    
    label.frame = CGRectMake(0, 0, width - (GAP + GAP_CONTENT) * 2, szMessage.height);
    label.text = message;
    
    float viewWidth = width - GAP * 2;
    float viewHeight = szMessage.height  + GAP_CONTENT * 2 + BUTTON_HEIGHT;
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(GAP, 0, viewWidth, viewHeight)];
    view.backgroundColor = [UIColor whiteColor];
    
    UIView *viewButtonBack = [[UIView alloc] initWithFrame:CGRectMake(0, view.frame.size.height - BUTTON_HEIGHT, view.frame.size.width, BUTTON_HEIGHT)];
    viewButtonBack.backgroundColor = [UIColor colorWithRed:138.0f / 255.0f green:187.0f / 255.0f blue:90.0f / 255.0f alpha:1.0f];
    
    if(cancelButtonTitle != nil && otherButtonTitle != nil)
    {
        UILabel *line = [[UILabel alloc] initWithFrame:CGRectMake(viewButtonBack.frame.size.width / 2, 2, 1, viewButtonBack.frame.size.height - 4)];
        line.backgroundColor = lineColor;
        
        [viewButtonBack addSubview:line];
        line = nil;
    }
    
    [view addSubview:viewButtonBack];
    viewButtonBack = nil;
    
    label.center = CGPointMake(CGRectGetWidth(view.frame) / 2, GAP_CONTENT + szMessage.height / 2);
    
    [view addSubview:label];
    label = nil;
    
    float pos = szMessage.height  + GAP_CONTENT * 2;
    
    if (cancelButtonTitle != nil && otherButtonTitle != nil)
    {
        UIButton *button1 = [UIButton buttonWithType:UIButtonTypeCustom];
        [button1 addTarget:self action:@selector(clickButton1) forControlEvents:UIControlEventTouchUpInside];
        button1.frame = CGRectMake(GAP_CONTENT, pos, (CGRectGetWidth(view.frame) - GAP_CONTENT * 2) / 2, BUTTON_HEIGHT);
        
        [button1 setTitle:cancelButtonTitle forState:UIControlStateNormal];
        button1.titleLabel.font = [UIFont fontWithName:@"Open Sans" size:16.0f];
        [button1 setTitleColor:textColor forState:UIControlStateNormal];
        
        [view addSubview:button1];
        
        UIButton *button2 = [UIButton buttonWithType:UIButtonTypeCustom];
        [button2 addTarget:self action:@selector(clickButton2) forControlEvents:UIControlEventTouchUpInside];
        button2.frame = CGRectMake(CGRectGetWidth(view.frame) / 2, pos, (CGRectGetWidth(view.frame) - GAP_CONTENT * 2) / 2, BUTTON_HEIGHT);
        
        [button2 setTitle:otherButtonTitle forState:UIControlStateNormal];
        button2.titleLabel.font = [UIFont fontWithName:@"Open Sans bold" size:16.0f];
        [button2 setTitleColor:textColor forState:UIControlStateNormal];
        
        [view addSubview:button2];
    }
    else if (cancelButtonTitle != nil)
    {
        UIButton *button1 = [UIButton buttonWithType:UIButtonTypeCustom];
        [button1 addTarget:self action:@selector(clickButton1) forControlEvents:UIControlEventTouchUpInside];
        button1.frame = CGRectMake(GAP_CONTENT, pos, (CGRectGetWidth(view.frame) - GAP_CONTENT * 2), BUTTON_HEIGHT);
        
        [button1 setTitle:cancelButtonTitle forState:UIControlStateNormal];
        button1.titleLabel.font = [UIFont fontWithName:@"Open Sans" size:16.0f];
        [button1 setTitleColor:textColor forState:UIControlStateNormal];
        
        [view addSubview:button1];
    }
    else if (otherButtonTitle != nil)
    {
        UIButton *button2 = [UIButton buttonWithType:UIButtonTypeCustom];
        [button2 addTarget:self action:@selector(clickButton2) forControlEvents:UIControlEventTouchUpInside];
        button2.frame = CGRectMake(GAP_CONTENT, pos, (CGRectGetWidth(view.frame) - GAP_CONTENT * 2), BUTTON_HEIGHT);
        
        [button2 setTitle:cancelButtonTitle forState:UIControlStateNormal];
        button2.titleLabel.font = [UIFont fontWithName:@"Open Sans bold" size:16.0f];
        [button2 setTitleColor:textColor forState:UIControlStateNormal];
        
        [view addSubview:button2];
    }
    
    view.center = CGPointMake(width / 2, height / 2);
    
    view.layer.cornerRadius = 7;
    view.clipsToBounds = YES;
    
    [self addSubview:view];
    view = nil;
    
    return self;
}

- (void)clickButton1
{
    [UIView animateWithDuration:0.3f animations:^{
        
        self.viewBack.alpha = 0.0f;
        
    } completion:^(BOOL finished) {
        
        [self removeFromSuperview];
        
        if (self.delegate)
            [self.delegate alertView:self clickedButtonAtIndex:0];
    }];
}

- (void) clickButton2
{
    [UIView animateWithDuration:0.3f animations:^{
        
        self.viewBack.alpha = 0.0f;
        
    } completion:^(BOOL finished) {
        
        [self removeFromSuperview];
        
        if (self.delegate)
            [self.delegate alertView:self clickedButtonAtIndex:1];
    }];
}

- (void) showInView:(UIView *)view
{
    //[view addSubview:self];
    
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    
    [window addSubview:self];
    
    self.viewBack.alpha = 0.0f;
    
    [UIView animateWithDuration:0.3f animations:^{
        
        self.viewBack.alpha = 0.5f;

    } completion:^(BOOL finished) {

    }];
}

@end
