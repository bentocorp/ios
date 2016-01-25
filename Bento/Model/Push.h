//
//  Push.h
//  Bento
//
//  Created by Joseph Lau on 10/28/15.
//  Copyright © 2015 bentonow. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Push : NSObject

@property (nonatomic) NSString *createdAt;
@property (nonatomic) NSString *rid;
@property (nonatomic) NSString *from;
@property (nonatomic) NSString *to;
@property (nonatomic) NSString *subject;
@property (nonatomic) id body;

@end
