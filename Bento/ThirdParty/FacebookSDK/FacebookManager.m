//
//  FacebookManager.m
//  Inkive
//
//  Created by Alexey Ishkov on 17/11/2013.
//  Copyright (c) 2013 Inkive Inc. All rights reserved.
//

#import "FacebookManager.h"
//#import "NetworkActivity.h"

NSString * const kFacebookNotificationSessionOpened         = @"kFacebookSessionOpened";
NSString * const kFacebookNotificationFriendsUploaded       = @"kFacebookFriendsUploaded";
NSString * const kFacebookNotificationAlbumsUploaded        = @"kFacebookAlbumsUploaded";
NSString * const kFacebookNotificationAlbumPhotosUploaded   = @"kFacebookAlbumPhotosUploaded";
NSString * const kFacebookNotificationPhotoUploaded         = @"kFacebookPhotoUploaded";


@interface FacebookManager ()

@property (nonatomic, retain) NSDictionary<FBGraphUser> *user;
@property (nonatomic, retain) NSDictionary<FBGraphUser> *userAge;
@property (nonatomic, retain) NSMutableArray *albums;
@property (nonatomic, retain) NSMutableDictionary *friends;

@end


@implementation FacebookManager

+ (FacebookManager *)sharedInstance
{
    static FacebookManager *instance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ instance = [FacebookManager new]; });
    return instance;
}

#pragma mark

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_user    release];
    [_albums  release];
    [_friends release];

    [super dealloc];
}

- (id)init
{
    self.user    = nil;
    self.albums  = nil;
    self.friends = nil;
    
    [FBSession.activeSession closeAndClearTokenInformation];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:)  name:UIApplicationDidBecomeActiveNotification  object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:)    name:UIApplicationWillTerminateNotification    object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    return self;
}

#pragma mark - UIApplicationDelegate notifications

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    [FBAppCall handleDidBecomeActive];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    [[FBSession activeSession] close];
}

- (void)applicationWillResignActive:(NSNotification *)notification
{
    [[FBSession activeSession] close];
}

#pragma mark - authorization with Facebook Application or by Safari

- (BOOL)handleOpenURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication
{
    if ([FBAppCall handleOpenURL:url sourceApplication:sourceApplication])
    {
        if ([FBSession.activeSession isOpen])
        {
            //[[NSNotificationCenter defaultCenter] postNotificationName:kFacebookNotificationSessionOpened object:nil userInfo:nil];
            [_delegate FBLogin:YES];
        }
        else
        {
            [self login];
        }
        return YES;
    }
    return NO;
    
//    return [FBAppCall handleOpenURL:url
//                  sourceApplication:sourceApplication
//                    fallbackHandler:^(FBAppCall *call) {
//                        if (call.accessTokenData)
//                        {
//                            if ([FBSession.activeSession isOpen])
//                            {
//                                [[NSNotificationCenter defaultCenter] postNotificationName:kFacebookNotificationSessionOpened object:nil userInfo:nil];
//                            }
//                            else
//                            {
//                                [self login];
//                            }
//                        }
//                    }];
}

#pragma mark

- (BOOL)facebookErrorMessage:(NSError *)error
{
    if (error)
    {
        NSLog(@"Facebook error: %@", error.localizedDescription);
        
        [[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"error_facebook", nil)
                                     message:error.localizedDescription
                                    delegate:nil
                           cancelButtonTitle:NSLocalizedString(@"close", nil)
                           otherButtonTitles:nil] autorelease] show];
        return NO;
    }
    return YES;
}

- (void)clearTokenAndCookies
{
    [[FBSession activeSession] closeAndClearTokenInformation];
    [FBSession setActiveSession:nil];
    
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in [storage cookies])
    {
        if ([[cookie domain] rangeOfString:@"facebook"].location != NSNotFound)
        {
            [storage deleteCookie:cookie];
        }
    }
}

#pragma mark - external

- (BOOL)isSessionOpen
{
    return [FBSession.activeSession isOpen];
}

- (void)login
{
    @synchronized (self)
    {
        if ([FBSession.activeSession isOpen] == NO)
        {
            //[NetworkActivity start];
            [FBSession openActiveSessionWithReadPermissions:@[@"email", /*@"user_about_me", @"user_hometown", @"user_photos", @"user_birthday",*/ @"friends_photos", @"friends_birthday", @"friends_location", @"friends_hometown", @"user_friends"]
                                               allowLoginUI:YES
                                          completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
                                              //[NetworkActivity stop];
                                              
                                              switch (state)
                                              {
                                                  case FBSessionStateCreated:
                                                      //NSLog(@"FBSessionStateCreated");
                                                      break;
                                                      
                                                  case FBSessionStateCreatedTokenLoaded:
                                                      //NSLog(@"FBSessionStateCreatedTokenLoaded");
                                                      break;
                                                      
                                                  case FBSessionStateCreatedOpening:
                                                      //NSLog(@"FBSessionStateCreatedOpening");
                                                      break;
                                                      
                                                  case FBSessionStateOpen:
                                                      //NSLog(@"FBSessionStateOpen");
//                                                      [[NSNotificationCenter defaultCenter] postNotificationName:kFacebookNotificationSessionOpened object:nil userInfo:nil];
                                                      [_delegate FBLogin:YES];
                                                      break;
                                                      
                                                  case FBSessionStateOpenTokenExtended:
                                                      //NSLog(@"FBSessionStateOpenTokenExtended");
                                                      break;
                                                      
                                                  case FBSessionStateClosedLoginFailed:
                                                      //NSLog(@"FBSessionStateClosedLoginFailed");
                                                      [self clearTokenAndCookies];
                                                      break;
                                                      
                                                  case FBSessionStateClosed:
                                                      //NSLog(@"FBSessionStateClosed");
                                                      [self clearTokenAndCookies];
                                                      break;
                                              }
                                              
                                              [self facebookErrorMessage:error];
                                          }];
        }
    }
}

- (void)logout
{
    if ([FBSession.activeSession isOpen])
    {
        [[FBSession activeSession] closeAndClearTokenInformation];
        [FBSession setActiveSession:nil];
    }
}

- (NSDictionary<FBGraphUser> *)userDetails
{
    return [FBSession.activeSession isOpen] ? self.userAge : nil;
}

#pragma mark - permissions

- (void)performWithReadPermission:(NSString *)permission anAction:(void (^)(void))action
{
    if ([FBSession.activeSession.permissions indexOfObject:permission] == NSNotFound)
    {
        @synchronized (self)
        {
            //[NetworkActivity start];
            [FBSession.activeSession requestNewReadPermissions:@[permission]
                                             completionHandler:^(FBSession *session, NSError *error) {
                                                 //[NetworkActivity stop];

                                                 if (error == nil)
                                                 {
                                                     action();
                                                 }
                                                 else if (error.fberrorCategory != FBErrorCategoryUserCancelled)
                                                 {
                                                     [self facebookErrorMessage:error];
                                                 }
                                             }];
        }
    }
    else
    {
        action();
    }
}

- (void)performPublishAction:(void (^)(void))action
{
    if ([FBSession.activeSession.permissions indexOfObject:@"publish_actions"] == NSNotFound ||
        [FBSession.activeSession.permissions indexOfObject:@"publish_stream"]  == NSNotFound)
    {
        @synchronized (self)
        {
            //[NetworkActivity start];
            [FBSession.activeSession requestNewPublishPermissions:@[@"publish_actions", @"publish_stream"]
                                                  defaultAudience:FBSessionDefaultAudienceEveryone
                                                completionHandler:^(FBSession *session, NSError *error) {
                                                    //[NetworkActivity stop];
                                                    
                                                    if (error == nil)
                                                    {
                                                        action();
                                                    }
                                                    else if (error.fberrorCategory != FBErrorCategoryUserCancelled)
                                                    {
                                                        [self facebookErrorMessage:error];
                                                    }
                                                }];
        }
    }
    else
    {
        action();
    }
}

#pragma mark - basic load for graph path

- (void)loadListForGraphPath:(NSString *)graphPath
                  permission:(NSString *)permission
                 keepToArray:(NSMutableArray *)array
           completionHandler:(void(^)(id, NSError *))completionHandler
{
    if ([self isSessionOpen])
    {
        [self performWithReadPermission:permission
                               anAction:^{
                                   FBRequest *request = [[[FBRequest alloc] initWithSession:[FBSession activeSession] graphPath:graphPath] autorelease];
                                   
                                   //[NetworkActivity start];
                                   [request startWithCompletionHandler: ^(FBRequestConnection *connection, NSDictionary *dictionary, NSError *error) {
                                       //[NetworkActivity stop];
                                       
                                       if ([self facebookErrorMessage:error])
                                       {
                                           [array addObjectsFromArray:dictionary[@"data"]];
                                           
                                           NSDictionary *paging = dictionary[@"paging"];
                                           
                                           if (paging && paging[@"next"])
                                           {
                                               NSArray *components = [paging[@"next"] componentsSeparatedByString:@".com/"];
                                               
                                               [self loadListForGraphPath:[components lastObject]
                                                               permission:permission
                                                              keepToArray:array
                                                        completionHandler:completionHandler];
                                           }
                                           else if (completionHandler)
                                           {
                                               completionHandler(array, nil);
                                           }
                                       }
                                       else if (completionHandler)
                                       {
                                           completionHandler(nil, error);
                                       }
                                   }];
                               }];
    }
}

- (void)loadObjectForGraphPath:(NSString *)graphPath
                    permission:(NSString *)permission
             completionHandler:(void(^)(id, NSError *))completionHandler
{
    if ([self isSessionOpen])
    {
        [self performWithReadPermission:permission
                               anAction:^{
                                   FBRequest *request = [FBRequest requestForGraphPath:graphPath];
                                   request.session    = [FBSession activeSession];
                                   
                                   //[NetworkActivity start];
                                   [request startWithCompletionHandler: ^(FBRequestConnection *connection, NSDictionary *dictionary, NSError *error) {
                                       //[NetworkActivity stop];
                                       
                                       completionHandler(dictionary, error);
                                   }];
                               }];
    }
}

#pragma mark - load actions

- (void)loadUserDetailsWithCompletionHandler:(void(^)(NSDictionary<FBGraphUser> *, NSError *))completionHandler
{
    if ([self isSessionOpen])
    {
        //[NetworkActivity start];
        [[FBRequest requestForMe] startWithCompletionHandler: ^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *user, NSError *error) {
            //[NetworkActivity stop];
            
            if ([self facebookErrorMessage:error])
            {
                // Get User Age
                [FBRequestConnection startWithGraphPath:@"/me?fields=age_range"
                                             parameters:nil
                                             HTTPMethod:@"GET"
                                      completionHandler:^(
                                                          FBRequestConnection *connection,
                                                          id result,
                                                          NSError *error
                                                          ) {
                                          if ([self facebookErrorMessage:error])
                                          {
                                              self.user = user;
                                              self.userAge = (NSDictionary<FBGraphUser> *)result;
                                          }
                                          dispatch_async(dispatch_get_main_queue(), ^{
                                              if (completionHandler) completionHandler(user, error);
                                          });
                                      }];
            }
        }];
    }
}

- (void)loadFriends
{
//    [self loadListForGraphPath:@"me/friends"
//                    permission:@"friends_photos"
//                   keepToArray:[NSMutableArray array]
//             completionHandler:^(id object, NSError *error) {
//                 if (error == nil)
//                 {
//                     self.friends = [[[(NSMutableArray *)object sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
//                         return [(NSString *)[(NSDictionary<FBGraphUser> *)obj1 name] compare:(NSString *)[(NSDictionary<FBGraphUser> *)obj2 name]];
//                     }] mutableCopy] autorelease];
//                     
//                     //[[NSNotificationCenter defaultCenter] postNotificationName:kFacebookNotificationFriendsUploaded object:nil userInfo:nil];
//                 }
//                 
//                 [[NSNotificationCenter defaultCenter] postNotificationName:kFacebookNotificationFriendsUploaded object:nil userInfo:nil];
//             }];
    if ([self isSessionOpen])
    {
        [FBRequestConnection startWithGraphPath:@"/me/friends"
                                     parameters:nil
                                     HTTPMethod:@"GET"
                              completionHandler:^(
                                                  FBRequestConnection *connection,
                                                  id result,
                                                  NSError *error
                                                  ) {
                                  if (error == nil)
                                  {
                                      self.friends = (NSMutableDictionary *)result;
                                      [[NSNotificationCenter defaultCenter] postNotificationName:kFacebookNotificationFriendsUploaded object:nil userInfo:nil];
                                  }
                                  else
                                  {
                                      [self facebookErrorMessage:error];
                                  }
                              }];
    }
}

- (void)loadFriendsWithCompletionHandler:(void(^)(NSMutableDictionary *, NSError *))completionHandler
{
    if ([self isSessionOpen])
    {
        [FBRequestConnection startWithGraphPath:@"/me/friends"
                                     parameters:nil
                                     HTTPMethod:@"GET"
                              completionHandler:^(
                                                  FBRequestConnection *connection,
                                                  id result,
                                                  NSError *error
                                                  ) {
                                  if (error == nil)
                                  {
                                      self.friends = (NSMutableDictionary *)result;
                                      completionHandler(self.friends, error);
                                  }
                                  else
                                  {
                                      [self facebookErrorMessage:error];
                                  }
                              }];
    }
}

- (void)loadUserInfo:(NSString *)user_id handle:(void(^)(NSDictionary<FBGraphUser> *, NSError *))completionHandler
{
    if ([self isSessionOpen])
    {
        //[NetworkActivity start];
        [[FBRequest requestForGraphPath:user_id] startWithCompletionHandler: ^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *user, NSError *error) {
            //[NetworkActivity stop];
            
            if ([self facebookErrorMessage:error])
            {

            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completionHandler) completionHandler(user, error);
            });
        }];
    }
}

- (void)loadAlbumsWithUserId:(NSString *)user_id
{
    NSString *key = user_id ?: @"me";
    
    [self loadListForGraphPath:[NSString stringWithFormat:@"%@/albums", key]
                    permission:user_id ? @"friends_photos" : @"user_photos"
                   keepToArray:[NSMutableArray array]
             completionHandler:^(id object, NSError *error) {
                 if (error == nil)
                 {
                     if (user_id == nil) self.albums = (NSMutableArray *)object;
                     [[NSNotificationCenter defaultCenter] postNotificationName:kFacebookNotificationAlbumsUploaded object:key userInfo:@{ @"data" : (NSMutableArray *)object }];
                 }
             }];
}

- (void)loadAlbumWithId:(NSString *)album_id forFriend:(BOOL)isFriendAlbum
{
    [self loadListForGraphPath:[NSString stringWithFormat:@"%@/photos?fields=id,images", album_id]
                    permission:isFriendAlbum ? @"friends_photos" : @"user_photos"
                   keepToArray:[NSMutableArray array]
             completionHandler:^(id object, NSError *error) {
                 if (error == nil)
                 {
                     [[NSNotificationCenter defaultCenter] postNotificationName:kFacebookNotificationAlbumPhotosUploaded object:album_id userInfo:@{ @"data" : (NSMutableArray *)object }];
                 }
             }];
}

- (void)loadPhotoWithId:(NSString *)item_id
{
    [self loadObjectForGraphPath:item_id
                      permission:@"user_photos"
               completionHandler:^(id object, NSError *error) {
                    if ([self facebookErrorMessage:error])
                    {
                        [[NSNotificationCenter defaultCenter] postNotificationName:kFacebookNotificationPhotoUploaded object:nil userInfo:(NSDictionary *)object];
                    }
                }];
}

- (void)postImage:(UIImage *)image
          message:(NSString *)message
            place:(NSString *)place
            album:(NSString *)album_id
{
    if ([self isSessionOpen])
    {
        [self performPublishAction:^{
            NSMutableDictionary *params = [NSMutableDictionary dictionary];
            [params setObject:image forKey:@"source"];
            if ([place length])   [params setObject:place   forKey:@"place"];
            if ([message length]) [params setObject:message forKey:@"message"];
            
            FBRequest *actionRequest = [[[FBRequest alloc] initWithSession:[FBSession activeSession]
                                                                 graphPath:[NSString stringWithFormat:@"%@/photos", album_id ? album_id : @"me"]
                                                                parameters:params
                                                                HTTPMethod:@"POST"] autorelease];
            
            FBRequestConnection *requestConnection = [FBRequestConnection new];
            
            [requestConnection addRequest:actionRequest
                        completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                            //[NetworkActivity stop];
                            [self facebookErrorMessage:error];
                        }];
            
            //[NetworkActivity start];
            [requestConnection start];
        }];
    }
}

- (void)postMessage:(NSString *)message
              image:(UIImage *)image
            linkURL:(NSString *)linkURL
             imgURL:(NSString *)imgURL
{
    if ([self isSessionOpen])
    {
        [self performPublishAction:^{
            NSMutableDictionary *params = [NSMutableDictionary dictionary];
            
            [params setObject:message forKey:@"message"];
            if ([linkURL length])   [params setObject:linkURL  forKey:@"link"];
            if ([imgURL length])   [params setObject:imgURL   forKey:@"picture"];
            if (image != nil) [params setObject:image forKey:@"source"];
            
            FBRequest *actionRequest = [[[FBRequest alloc] initWithSession:[FBSession activeSession]
                                                                 graphPath:@"me/feed"
                                                                parameters:params
                                                                HTTPMethod:@"POST"] autorelease];
            
            FBRequestConnection *requestConnection = [FBRequestConnection new];
            
            [requestConnection addRequest:actionRequest
                        completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                            //[NetworkActivity stop];
                            if ([self facebookErrorMessage:error])
                            {
                                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Success" message:@"You posted the message to Facebook." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                                
                                [alertView show];
                            }
                        }];
            
            //[NetworkActivity start];
            [requestConnection start];
        }];
    }
}

@end
