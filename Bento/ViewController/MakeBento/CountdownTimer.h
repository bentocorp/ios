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

- (void)refreshStart;
- (void)refreshPause;
- (void)refreshResume;
- (void)refreshStop;

@property (nonatomic) BOOL isPaused;
@property (nonatomic) NSTimer *timer;
@property (nonatomic) NSString *finalCountDownTimerValue;

@end
