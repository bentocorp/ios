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
    [formatter setDateFormat:@"mm:ss"];
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
    
    // Lunch Mode
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Lunch"]) {
        if (currentTime >= (lunchCutOffTime-countDownRemainingTime) && currentTime < lunchCutOffTime) {
            self.finalCountDownTimerValue = [NSString stringWithFormat:@"Time Remaining %@", [self convertSecondsToMMSSString:(lunchCutOffTime - currentTime)]];
            return YES;
        }
    }
    // Dinner Mode
    else if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"LunchOrDinner"] isEqualToString:@"Dinner"]) {
        if (currentTime >= (dinnerCutOffTime-countDownRemainingTime) && currentTime < dinnerCutOffTime) {
            self.finalCountDownTimerValue = [NSString stringWithFormat:@"Time Remaining %@", [self convertSecondsToMMSSString:(dinnerCutOffTime - currentTime)]];
            return YES;
        }
    }
    
    return NO;
}


@end
