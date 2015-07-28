//
//  PromoCodeView.h
//  Bento
//
//  Created by hanjinghe on 1/9/15.
//  Copyright (c) 2015 bentonow. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PromoCodeViewDelegate <NSObject>

- (void)setDiscound:(NSInteger)priceDiscount strCouponCode:(NSString *)strCouponCode;

@end

@interface PromoCodeView : UIView

@property (nonatomic, weak) id <PromoCodeViewDelegate> delegate;

@end
