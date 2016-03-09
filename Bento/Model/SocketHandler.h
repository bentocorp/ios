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
- (void)socketHandlerDidConnect;
- (void)socketHandlerDidAuthenticate;
- (void)socketHandlerDidGetLastSavedLocation:(float)lat and:(float)lng;
- (void)socketHandlerDidUpdateLocationWith:(float)lat and:(float)lng;
- (void)socketHandlerDidDisconnect;

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
- (void)getLastSavedLocation;
- (void)untrack;

@end
