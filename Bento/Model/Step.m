//
//  Step.m
//  Bento
//
//  Created by Joseph Lau on 3/3/16.
//  Copyright © 2016 bentonow. All rights reserved.
//

#import "Step.h"

@implementation Step

- (id)initWithDictionary:(NSDictionary *)dictionary {
    if (self = [super init]) {
        
        self.startLocation = CLLocationCoordinate2DMake([dictionary[@"start_location"][@"lat"] floatValue], [dictionary[@"start_location"][@"lng"] floatValue]);
        self.endLocation = CLLocationCoordinate2DMake([dictionary[@"end_location"][@"lat"] floatValue], [dictionary[@"end_location"][@"lng"] floatValue]);
        self.duration = [dictionary[@"duration"][@"value"] intValue];
        
        NSString *polyline = dictionary[@"polyline"][@"points"];
        self.pathCoordinates = [self decodePolyLine:polyline];
    }
    
    return self;
}

// http://iosguy.com/2012/05/22/tracing-routes-with-mapkit/
- (NSMutableArray *)decodePolyLine:(NSString *)encodedStr {
    NSMutableString *encoded = [[NSMutableString alloc] initWithCapacity:[encodedStr length]];
    [encoded appendString:encodedStr];
    [encoded replaceOccurrencesOfString:@"\\\\" withString:@"\\"
                                options:NSLiteralSearch
                                  range:NSMakeRange(0, [encoded length])];
    NSInteger len = [encoded length];
    NSInteger index = 0;
    NSMutableArray *array = [[NSMutableArray alloc] init];
    NSInteger lat=0;
    NSInteger lng=0;
    while (index < len) {
        NSInteger b;
        NSInteger shift = 0;
        NSInteger result = 0;
        do {
            b = [encoded characterAtIndex:index++] - 63;
            result |= (b & 0x1f) << shift;
            shift += 5;
        } while (b >= 0x20);
        NSInteger dlat = ((result & 1) ? ~(result >> 1) : (result >> 1));
        lat += dlat;
        shift = 0;
        result = 0;
        do {
            b = [encoded characterAtIndex:index++] - 63;
            result |= (b & 0x1f) << shift;
            shift += 5;
        } while (b >= 0x20);
        NSInteger dlng = ((result & 1) ? ~(result >> 1) : (result >> 1));
        lng += dlng;
        NSNumber *latitude = [[NSNumber alloc] initWithFloat:lat * 1e-5];
        NSNumber *longitude = [[NSNumber alloc] initWithFloat:lng * 1e-5];
        
        CLLocation *location = [[CLLocation alloc] initWithLatitude:[latitude floatValue] longitude:[longitude floatValue]];
        [array addObject:location];
    }
    
    return array;
}

@end
