//
//  SocketHandler.h
//  Bento
//
//  Created by Joseph Lau on 10/28/15.
//  Copyright © 2015 bentonow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Bento-Swift.h"

@protocol SocketHandlerDelegate <NSObject>

@optional
- (void)socketHandlerDidAuthenticate;
- (void)socketHandlerDidUpdateLocationWith:(float)lat and:(float)lng;

@end

@interface SocketHandler : NSObject

@property (nonatomic, strong) SocketIOClient *socket;
@property (nonatomic) id delegate;

@property (nonatomic) NSString *username;
@property (nonatomic) NSString *token;
@property (nonatomic) NSString *driverId;

+ (instancetype)sharedSocket;

- (void)connectAndAuthenticate:(NSString*)username token:(NSString *)token driverId:(NSString *)driverId;
- (void)closeSocket;

@end
