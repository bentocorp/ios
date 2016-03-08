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
        self.socket = [[SocketIOClient alloc] initWithSocketURL:@"https://node.dev.bentonow.com:8443" opts: nil];
    #else
        self.socket = [[SocketIOClient alloc] initWithSocketURL:@"https://node.bentonow.com:8443" opts: nil];
    #endif
    
    [self configureHandlers];
    
    [self.socket connectWithTimeoutAfter:10 withTimeoutHandler:^{
        NSLog(@"connect timed out");
    }];
}

#pragma mark Register Listeners
- (void)configureHandlers {
    [self.socket on:@"connect" callback:^(NSArray *data, SocketAckEmitter *ack) {
        NSLog(@"connect triggered - %@", data);
        
        [self.delegate socketHandlerDidConnect];
        
        [self authenticateUser];
    }];
    
    [self.socket on:@"disconnect" callback:^(NSArray *data, SocketAckEmitter *ack) {
        NSLog(@"disconnect triggered - %@", data);
    }];
    
    [self.socket on:@"error" callback:^(NSArray *data, SocketAckEmitter *ack) {
        NSLog(@"error triggered - %@", data);
    }];
    
    [self.socket on:@"reconnect" callback:^(NSArray *data, SocketAckEmitter *ack) {
        NSLog(@"reconnect triggered - %@", data);
    }];
    
    [self.socket on:@"reconnectAttempt" callback:^(NSArray *data, SocketAckEmitter *ack) {
        NSLog(@"reconnectAttempt triggered - %@", data);
    }];
}

#pragma mark Authenticate
- (void)authenticateUser {
    NSString *apiString = [NSString stringWithFormat:@"/api/authenticate?username=%@&token=%@&type=customer", self.username, self.token];
    [self.socket emitWithAck:@"get" withItems:@[apiString]](0, ^(NSArray *data) {
        NSLog(@"socket did authenticate");
        
        NSString *jsonString = data[0];
        NSError *jsonError;
        NSData *objectData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData options:NSJSONReadingMutableContainers error:&jsonError];
        
        int code = [json[@"code"] intValue];
        NSString *msg = json[@"msg"];
        NSDictionary *ret = json[@"ret"];
        
        NSLog(@"code - %i", code);
        NSLog(@"msg - %@", msg);
        NSLog(@"ret - %@", ret);
        
        if (code == 0) {
            if (ret != nil) {
                [self.delegate socketHandlerDidAuthenticate];
                [self listenToChannels];
            }
        }
        else {
            // handle error
            NSLog(@"socket did fail to authenticate");
        }
    });
}

#pragma mark Listen To
- (void)listenToChannels {
    
    // Ex. { rid: rst_7#5y, from: "houston", to: "c-5", subject: "OrderAccepted", body: {orderId: "w/e", driverId: "8"} }
    [self.socket on:@"push" callback:^(NSArray *data, SocketAckEmitter *ack) {
        NSLog(@"push data - %@", data);
        
//        NSString *jsonString = [data[0][@"ret"] stringValue];
//        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:false];
//
//        NSError *error;
//        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:jsonData
//                                                             options:kNilOptions
//                                                               error:&error];
        
//        // if driver has accepted my order, node will pass me his clientId, then i take that i call request to track
//        if (data.subject == "OrderAccepted") { // delivery
//            [self requestToTrackDriver];
//        }
//        else if (data.subject == "OrderArrived") { // assembly pickup
//            // remove map, show text
//        }
//        else if (data.subject == "OrderComplete") { // terminate
//            // pop view controller
//        }
        
    }];

    // Listen to Location
    [self.socket on:@"loc" callback:^(NSArray *data, SocketAckEmitter *ack) {
        NSLog(@"loc data - %@", data);
        
//        NSString *jsonString = [data[0][@"ret"] stringValue];
//        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:false];
//        
//        NSError *error;
//        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:jsonData
//                                                             options:kNilOptions
//                                                               error:&error];
//        
//        [self.delegate socketHandlerDidUpdateLocationWith:[json[@"lat"] floatValue] and:[json[@"long"] floatValue]];
    }];
}

#pragma mark Request To Track Driver
- (void)requestToTrackDriver {
    NSString *apiString = [NSString stringWithFormat:@"/api/track?client_id=d-%ld", (long)self.driverId];
    [self.socket emitWithAck:@"get" withItems:@[apiString]](0, ^(NSArray *data) {
        
        NSString *jsonString = data[0];
        NSError *jsonError;
        NSData *objectData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData options:NSJSONReadingMutableContainers error:&jsonError];
        
        // success
        
        NSLog(@"json2 - %@", json);
    });
}

#pragma mark Disconnect
- (void)closeSocket {
    NSLog(@"close socket");
    [self.socket removeAllHandlers];
    [self.socket disconnect];
}

@end
