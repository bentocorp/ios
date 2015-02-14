//
//  FacebookManager.h
//  Inkive
//
//  Created by Alexey Ishkov on 17/11/2013.
//  Copyright (c) 2013 Inkive Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FacebookSDK/FacebookSDK.h>

extern NSString * const kFacebookNotificationSessionOpened;
extern NSString * const kFacebookNotificationFriendsUploaded;
extern NSString * const kFacebookNotificationAlbumsUploaded;
extern NSString * const kFacebookNotificationAlbumPhotosUploaded;
extern NSString * const kFacebookNotificationPhotoUploaded;

@protocol FBManagerDelegate <NSObject>
-(void)FBLogin:(BOOL)flag;
@end

@interface FacebookManager : NSObject

@property (nonatomic, readonly) NSMutableArray *albums;
@property (nonatomic, readonly) NSMutableDictionary *friends;
@property (nonatomic, assign) id<FBManagerDelegate> delegate;

+ (FacebookManager *)sharedInstance;

- (BOOL)isSessionOpen;

- (void)login;
- (void)logout;

- (void)loadUserDetailsWithCompletionHandler:(void(^)(NSDictionary<FBGraphUser> *, NSError *))completionHandler;
- (void)loadUserInfo:(NSString *)user_id handle:(void(^)(NSDictionary<FBGraphUser> *, NSError *))completionHandler;
- (void)loadFriends;
- (void)loadFriendsWithCompletionHandler:(void(^)(NSMutableDictionary *, NSError *))completionHandler;;
- (void)loadAlbumsWithUserId:(NSString *)user_id;
- (void)loadAlbumWithId:(NSString *)album_id forFriend:(BOOL)isFriendAlbum;
- (void)loadPhotoWithId:(NSString *)item_id;

- (NSDictionary<FBGraphUser> *)userDetails;

- (void)postImage:(UIImage *)image
          message:(NSString *)message
            place:(NSString *)place
            album:(NSString *)album_id;

- (void)postMessage:(NSString *)message
              image:(UIImage *)image
            linkURL:(NSString *)linkURL
             imgURL:(NSString *)imgURL;

- (BOOL)handleOpenURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication;

@end
