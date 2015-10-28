//
//  SocketHandler.h
//  Bento
//
//  Created by Joseph Lau on 10/28/15.
//  Copyright © 2015 bentonow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Bento-Swift.h"

@interface SocketHandler : NSObject

// porpeties
@property (nonatomic, strong) SocketIOClient *socket;

// class methods
+ (instancetype)sharedSocket;

// instance methods
- (void)connectAndAuthenticate:(NSString *)username password:(NSString *)password;

@end
