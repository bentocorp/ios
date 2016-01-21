//
//  CountdownTimer.m
//  Bento
//
//  Created by Joseph Lau on 1/21/16.
//  Copyright © 2016 bentonow. All rights reserved.
//

#import "CountdownTimer.h"
#import "BentoShop.h"

@implementation CountdownTimer

+ (CountdownTimer *)sharedInstance {
    
    // 1
    static CountdownTimer *_sharedInstance = nil;
    
    // 2
    static dispatch_once_t oncePredicate;
    
    // 3
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[CountdownTimer alloc] init];
    });
    return _sharedInstance;
}

- (id)init {
    if (self = [super init]) {
        self.lunchCutOffTimeString = [[BentoShop sharedInstance] getLunchCutOffTime];
        self.dinnerCutOffTimeString = [[BentoShop sharedInstance] getDinnerCutOffTime];
        self.countDownRemainingMinutesFromServer = [[BentoShop sharedInstance] getCountDownMinutes];
        
        if (self.lunchCutOffTimeString != nil && self.dinnerCutOffTimeString != nil) {
            [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(checkTimeRemaining) userInfo:nil repeats:YES];
        }
    }
    
    return self;
}

- (NSString *)getCurrentDateString {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    return [formatter stringFromDate:[NSDate new]];
}

- (NSString *)combineDate:(NSString *)date withTime:(NSString *)time {
    return [NSString stringWithFormat:@"%@ %@", date , time];
}

- (void)checkTimeRemaining {
    NSString *lunchCutOffDateAndtimeString = [self combineDate:[self getCurrentDateString] withTime:self.lunchCutOffTimeString];
    NSString * dinnerCutOffDateAndTimeString = [self combineDate:[self getCurrentDateString] withTime:self.dinnerCutOffTimeString];
    
    
}



@end
