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
    __block NSString *token;
}

+ (instancetype)sharedSocket
{
    static SocketHandler *sharedSocket = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedSocket = [[SocketHandler alloc] init];
        // Do any other initialization stuff here...
        
        // Socket URL
        sharedSocket.socket = [[SocketIOClient alloc] initWithSocketURL:@"http://54.191.141.101:8081" opts:@{@"log": @YES}];
    });
    return sharedSocket;
}

- (void)connectAndAuthenticate:(NSString *)username password:(NSString *)password
{
    NSLog(@"'connectAndAuthenticate' called");
    
//    [self connectUser:<#(NSString *)#> password:<#(NSString *)#>];
}

#pragma mark Connect
- (void)connectUser:(NSString *)username password:(NSString *)password
{
    [self.socket on:@"connect" callback:^(NSArray *data, SocketAckEmitter *ack) {
        
        NSLog(@"SOCKET CONNECTED");
        
//        [self authenticateUser:<#(NSString *)#> password:<#(NSString *)#>];
    }];
    
    [self.socket connect];
}

#pragma mark Authenticate
- (void)authenticateUser:(NSString *)username password:(NSString *)password
{
    // request to authenticate
    [self.socket emitWithAck:@"get" withItems:@[@"/api/authenticate?username=atlas01&password=password&type=customer"]](0, ^(NSArray *data) {
        
        NSString *jsonString = data[0];
        
        NSError *jsonError;
        NSData *objectData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData
                                                             options:NSJSONReadingMutableContainers
                                                               error:&jsonError];
        
        NSLog(@"json - %@", json);
        
        NSDictionary *ret = json[@"ret"];
        
        userID = ret[@"uid"];
        token = ret[@"token"];
    });
}

#pragma mark Request To Track Driver
- (void)requestToTrackDiver
{
    [self.socket emitWithAck:@"get" withItems:@[@"/api/track?client_id=d-8"]](0, ^(NSArray *data) {
        
        NSString *jsonString = data[0];
        
        NSError *jsonError;
        NSData *objectData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData
                                                             options:NSJSONReadingMutableContainers
                                                               error:&jsonError];
        
        // server lets me know if driver is online/offline and confirms driverID
        NSLog(@"json2 - %@", json);
    });

}

#pragma mark Listen To
- (void)listenToPushChannel
{
    [self.socket on:@"loc" callback:^(NSArray * data, SocketAckEmitter * ack) {
        NSLog(@"loc data - %@", data);
    }];
    
    [self.socket on:@"stat" callback:^(NSArray * data, SocketAckEmitter * ack) {
        NSLog(@"stat data - %@", data);
    }];
}

#pragma mark Disconnect
- (void)closeSocket:(BOOL)lostConnection
{
    [self.socket disconnect];
    [self.socket removeAllHandlers];
}

@end









