//
//  PhoneLiason.h
//  TempoWatch
//
//  Created by Mark Linington on 9/13/15.
//  Copyright © 2015 MarkLinington. All rights reserved.
//

#import <Foundation/Foundation.h>
@import UIKit;
@import WatchConnectivity;

@interface PhoneLiason : NSObject <WCSessionDelegate>

@property (strong, nonatomic) void (^addedMetadata)(NSString* title, NSString *artist, UIImage *art);

- (instancetype) init;

- (void) pressForward;
- (void) pressBackward;
- (void) pressPlayPause;
- (void) sendHeartRate:(NSNumber *)bpm;

@end
