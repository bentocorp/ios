//
//  CountdownTimer.h
//  Bento
//
//  Created by Joseph Lau on 1/21/16.
//  Copyright © 2016 bentonow. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CountdownTimer : NSObject

+ (CountdownTimer *)sharedInstance;

@property (nonatomic) NSString *lunchCutOffTimeString;
@property (nonatomic) NSString *dinnerCutOffTimeString;
@property (nonatomic) NSString *countDownRemainingMinutesFromServer;
@property (nonatomic) NSString *countDownRemainingMinutesCalculated;

@end
