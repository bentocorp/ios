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
                // update token
                self.token = ret[@"token"];
                
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
    [self.socket on:@"push" callback:^(NSArray *data, SocketAckEmitter *ack) {
        NSString *jsonString = data[0];
        NSError *jsonError;
        NSData *objectData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData options:NSJSONReadingMutableContainers error:&jsonError];
        
        NSLog(@"loc data - %@", json);
        
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
        NSString *jsonString = data[0];
        NSError *jsonError;
        NSData *objectData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData options:NSJSONReadingMutableContainers error:&jsonError];
        
        NSLog(@"loc data - %@", json);
        
        float lat = [json[@"lat"] floatValue];
        float lng = [json[@"lng"] floatValue];
        
        [self.delegate socketHandlerDidUpdateLocationWith:lat and:lng];
    }];
}

#pragma mark Tracking
- (void)getLastSavedLocation {
    NSString *apiString = [NSString stringWithFormat:@"/api/gloc?token=%@&clientId=d-%@", self.token, self.driverId];
    [self.socket emitWithAck:@"get" withItems:@[apiString]](0, ^(NSArray *data) {
        
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
            if ([ret isEqual:[NSNull null]] == false) {
                
                float lat = [ret[@"lat"] floatValue];
                float lng = [ret[@"lng"] floatValue];
                
                [self.delegate socketHandlerDidGetLastSavedLocation:lat and:lng];
                
                [self requestToTrackDriver];
            }
        }
        else {
            // handle error
        }
    });
}

- (void)requestToTrackDriver {
    NSString *apiString = [NSString stringWithFormat:@"/api/track?clientId=d-%@", self.driverId];
    [self.socket emitWithAck:@"get" withItems:@[apiString]](0, ^(NSArray *data) {
        
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
            
        }
        else {
            // handle error
        }
    });
}

- (void)untrack {
    NSString *apiString = [NSString stringWithFormat:@"/api/untrack?clientId=d-%@", self.driverId];
    [self.socket emitWithAck:@"get" withItems:@[apiString]](0, ^(NSArray *data) {
        
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
            
        }
        else {
            // handle error
        }
    });
}

#pragma mark Disconnect
- (void)closeSocket {
    NSLog(@"close socket");
    [self.socket removeAllHandlers];
    [self.socket disconnect];
}

@end
