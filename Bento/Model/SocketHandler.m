//
//  SocketHandler.m
//  Bento
//
//  Created by Joseph Lau on 10/28/15.
//  Copyright © 2015 bentonow. All rights reserved.
//

#import "SocketHandler.h"



@implementation SocketHandler
{
    __block NSString *userID;
    __block NSString *authtoken;
}

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

- (void)connectAndAuthenticate:(NSString*)email token:(NSString *)token {
    NSLog(@"'connectAndAuthenticate' called");
    
    self.email = email;
    self.token = token;
    
    [self connectUser];
}

#pragma mark Connect
- (void)connectUser {
    
    #ifdef DEV_MODE
        self.socket = [[SocketIOClient alloc] initWithSocketURL:@"https://node.dev.bentonow.com:8443" opts: @{@"ReconnectWait": @1}];
    #else
        self.socket = [[SocketIOClient alloc] initWithSocketURL:@"https://node.bentonow.com:8443" opts: nil];
    #endif
    
    [self configureHandlers];
    
    [self.socket connectWithTimeoutAfter:10 withTimeoutHandler:^{
        // handle connection error
    }];
}

- (void)configureHandlers {
    [self.socket on:@"connect" callback:^(NSArray *data, SocketAckEmitter *ack) {
        NSLog(@"connect triggered");
        
        [self authenticateUser:self.email token:self.token];
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
- (void)authenticateUser:(NSString*)email token:(NSString *)token {

    [self.socket emitWithAck:@"get" withItems:@[@"/api/authenticate?username=%@&token=%@&type=c"]](0, ^(NSArray *data) {
    
        NSLog(@"socket authenticated");
        
        NSString *jsonString = data[0];
        NSError *jsonError;
        NSData *objectData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData
                                                             options:NSJSONReadingMutableContainers
                                                               error:&jsonError];
        
        NSLog(@"json - %@", json);
        
        NSDictionary *ret = json[@"ret"];
        userID = ret[@"uid"]; // ?
        authtoken = ret[@"token"];
        
        // once authetnciated socket,
        
        
        [self listenToChannels];
    });
}

#pragma mark Listen To
- (void)listenToChannels {
    
    // Ex. { rid: rst_7#5y, from: "houston", to: "c-5", subject: "Test", body: "Hi!" }
//    [self.socket on:@"push" callback:^(NSArray *data, SocketAckEmitter *ack) {
//        NSLog(@"push data - %@", data);
//        
//        // if driver has accepted my order, node will pass me his clientId
//        // then i take that i call request to track
//        if () {
//            [self requestToTrackDriver:];
//        }
//    }];
    
    // Ex. { clientId: d-8, status: "connected" } note: not really needed for customer app
//    [self.socket on:@"stat" callback:^(NSArray * data, SocketAckEmitter * ack) {
//        NSLog(@"stat data - %@", data);
//    }];
    
    /* 
    Ex.
    {
     clientId: d-10,
     lat: 127.901,
     lng: 90.123
    }
    */
    [self.socket on:@"loc" callback:^(NSArray *data, SocketAckEmitter *ack) {
        NSLog(@"loc data - %@", data);
        
        // once request to track driver has been made, node will send me location coordinates/driver info
        // this is where i call delegate method to maybe prompt an alert
        // which routes to Settings -> Current Orders -> Current Order
    }];
}

#pragma mark Request To Track Driver
- (void)requestToTrackDriver: (NSString *)driverId
{
    [self.socket emitWithAck:@"get" withItems:@[@"/api/track?client_id=d-10"]](0, ^(NSArray *data) {
        
        NSString *jsonString = data[0];
        NSError *jsonError;
        NSData *objectData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData
                                                             options:NSJSONReadingMutableContainers
                                                               error:&jsonError];
        
        NSLog(@"json2 - %@", json);
    });
}

#pragma mark Disconnect
- (void)closeSocket:(BOOL)lostConnection {
    [self.socket disconnect];
    [self.socket removeAllHandlers];
}

@end
