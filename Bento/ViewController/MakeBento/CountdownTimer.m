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
        _isPaused = NO;
    }
    
    return self;
}

#pragma mark Refresh Logic
- (void)refreshStart {
    if (_timer != nil) {
        return;
    }
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(checkTime) userInfo:nil repeats:YES];
}

- (void)refreshPause {
    if (_isPaused) {
        return;
    }
    
    _isPaused = YES;
    [_timer invalidate];
    _timer = nil;
}

- (void)refreshResume {
    if (!_isPaused) {
        return;
    }
    
    _isPaused = NO;
    _timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(checkTime) userInfo:nil repeats:YES];
}

- (void)refreshStop {
    if (_timer == nil) {
        return;
    }
    
    [_timer invalidate];
    _timer = nil;
}

#pragma mark

- (NSString *)getCurrentDateString {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    return [formatter stringFromDate:[NSDate new]];
}

- (NSString *)combineDate:(NSString *)date withTime:(NSString *)time {
    return [NSString stringWithFormat:@"%@ %@", date , time];
}

- (NSDate *)convertDateAndTimeStringToNSDate:(NSString *)dateAndTimeString {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    return [formatter dateFromString:dateAndTimeString];
}

- (NSString *)convertSecondsToMMSSString:(NSTimeInterval)seconds {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:seconds];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"m:ss"];
    return [formatter stringFromDate:date];
}

- (BOOL)shouldShowCountDown {
    // current time
    NSTimeInterval currentTime = [[NSDate date]  timeIntervalSince1970];
    
    // cut off time
    NSTimeInterval lunchCutOffTime = [[self convertDateAndTimeStringToNSDate:[self combineDate:[self getCurrentDateString] withTime:[[BentoShop sharedInstance] getLunchCutOffTime]]] timeIntervalSince1970];
    
    NSTimeInterval dinnerCutOffTime = [[self convertDateAndTimeStringToNSDate:[self combineDate:[self getCurrentDateString] withTime:[[BentoShop sharedInstance] getDinnerCutOffTime]]] timeIntervalSince1970];
    
    // countdown remaining time
    NSTimeInterval countDownRemainingTime = [[[BentoShop sharedInstance] getCountDownMinutes] integerValue] * 60;
    
    // from 12AM -> Lunch Cut-off (10AM)
    if (currentTime < lunchCutOffTime) {
        NSLog(@"Checking Lunch cut-off time!");
        
        if (currentTime >= (lunchCutOffTime-countDownRemainingTime) && currentTime < lunchCutOffTime) {
            self.finalCountDownTimerValue = [NSString stringWithFormat:@"%@", [self convertSecondsToMMSSString:(lunchCutOffTime - currentTime)]];
            
            NSLog(@"Currently counting down to Lunch cut-off time! - %@", self.finalCountDownTimerValue);
            
            return YES;
        }
    }
    // from Lunch Cut-off (10AM) -> Dinner Cut-ff (3PM)
    else if (currentTime < dinnerCutOffTime) {
        NSLog(@"Checking Dinner cut-off time!");
        
        if (currentTime >= (dinnerCutOffTime-countDownRemainingTime) && currentTime < dinnerCutOffTime) {
            self.finalCountDownTimerValue = [NSString stringWithFormat:@"%@", [self convertSecondsToMMSSString:(dinnerCutOffTime - currentTime)]];
            
            NSLog(@"Currently counting down to Dinner cut-off time! - %@", self.finalCountDownTimerValue);
            
            return YES;
        }
    }
    
    return NO;
}

- (void)checkTime {
    if (_isPaused == NO) {
        if ([self shouldShowCountDown]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"showCountDownTimer" object:nil];
        }
    }
}


@end
