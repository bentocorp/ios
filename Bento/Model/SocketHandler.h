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

@property (nonatomic, strong) SocketIOClient *socket;
@property (nonatomic) NSString *username;
@property (nonatomic) NSString *token;

+ (instancetype)sharedSocket;

- (void)connectAndAuthenticate:(NSString*)username token:(NSString *)token;

@end
