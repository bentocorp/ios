//
//  SocketHandler.m
//  Bento
//
//  Created by Joseph Lau on 10/28/15.
//  Copyright © 2015 bentonow. All rights reserved.
//

#import "SocketHandler.h"

@implementation SocketHandler

+ (instancetype)sharedSocket {
    static SocketHandler *sharedSocket = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedSocket = [[SocketHandler alloc] init];
        // Do any other initialization stuff here...
    });
    return sharedSocket;
}

#pragma mark HOUSTON API
- (NSString *)getHoustonAPI {
    #ifdef DEV_MODE
        return @"https://houston.dev.bentonow.com:8443";
    #else
        return @"https://houston.bentonow.com:8443";
    #endif
}

- (void)connectAndAuthenticate:(NSString *)username token:(NSString *)token driverId:(NSString *)driverId {
    NSLog(@"connectAndAuthenticate called");
    
    self.username = username;
    self.token = token;
    self.driverId = driverId;
    
    [self connectUser];
}

#pragma mark Connect
- (void)connectUser {
    #ifdef DEV_MODE
        self.socket = [[SocketIOClient alloc] initWithSocketURL:@"https://node.dev.bentonow.com:8443" opts: @{@"ReconnectWait": @1}];
    #else
        self.socket = [[SocketIOClient alloc] initWithSocketURL:@"https://node.bentonow.com:8443" opts: @{@"ReconnectWait": @1}];
    #endif
    
    [self configureHandlers];
    
    [self.socket connectWithTimeoutAfter:10 withTimeoutHandler:^{
        NSLog(@"connect timed out");
    }];
}

#pragma mark Register Listeners
- (void)configureHandlers {
    [self.socket on:@"connect" callback:^(NSArray *data, SocketAckEmitter *ack) {
        NSLog(@"connect triggered");
        
        [self authenticateUser];
    }];
    
    [self.socket on:@"disconnect" callback:^(NSArray *data, SocketAckEmitter *ack) {
        NSLog(@"disconnect triggered");
    }];
    
    [self.socket on:@"error" callback:^(NSArray *data, SocketAckEmitter *ack) {
        NSLog(@"error triggered");
    }];
    
    [self.socket on:@"reconnect" callback:^(NSArray *data, SocketAckEmitter *ack) {
        NSLog(@"reconnect triggered");
    }];
    
    [self.socket on:@"reconnectAttempt" callback:^(NSArray *data, SocketAckEmitter *ack) {
        NSLog(@"reconnectAttempt triggered");
    }];
}

#pragma mark Authenticate
- (void)authenticateUser {
    NSString *apiString = [NSString stringWithFormat:@"/api/authenticate?username=%@&token=%@", self.username, self.token];
    [self.socket emitWithAck:@"get" withItems:@[apiString]](0, ^(NSArray *data) {
        NSLog(@"socket did authenticate");
        
        NSString *jsonString = data[0];
        NSError *jsonError;
        NSData *objectData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData options:NSJSONReadingMutableContainers error:&jsonError];
        
        NSLog(@"json - %@", json);

        [self listenToChannels];
    });
}

#pragma mark Listen To
- (void)listenToChannels {
    
    // Ex. { rid: rst_7#5y, from: "houston", to: "c-5", subject: "Test", body: "Hi!" }
    [self.socket on:@"push" callback:^(NSArray *data, SocketAckEmitter *ack) {
        NSLog(@"push data - %@", data);
        
        // if driver has accepted my order, node will pass me his clientId, then i take that i call request to track
//        if () {
//            [self requestToTrackDriver:];
//        }
    }];

    [self.socket on:@"loc" callback:^(NSArray *data, SocketAckEmitter *ack) {
        NSLog(@"loc data - %@", data);
        
        // once request to track driver has been made successful, node will send me location coordinates/driver info
        // call delegate method to update coordinates
    }];
}

#pragma mark Request To Track Driver
- (void)requestToTrackDriver {
    NSString *apiString = [NSString stringWithFormat:@"/api/track?client_id=%@", self.driverId];
    [self.socket emitWithAck:@"get" withItems:@[apiString]](0, ^(NSArray *data) {
        
        NSString *jsonString = data[0];
        NSError *jsonError;
        NSData *objectData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData options:NSJSONReadingMutableContainers error:&jsonError];
        
        NSLog(@"json2 - %@", json);
    });
}

#pragma mark Disconnect
- (void)closeSocket:(BOOL)lostConnection {
    [self.socket disconnect];
    [self.socket removeAllHandlers];
}

@end
