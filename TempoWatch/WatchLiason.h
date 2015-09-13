//
//  WatchLiason.h
//  TempoWatch
//
//  Created by Mark Linington on 9/12/15.
//  Copyright © 2015 MarkLinington. All rights reserved.
//

#import <Foundation/Foundation.h>
@import UIKit;

@interface WatchLiason : NSObject

- (instancetype) init;

- (void) sendMetadataTitle:(NSString *)title andArtist:(NSString *)artist andArt:(UIImage *)art;

@property (strong, nonatomic) void (^playPausePressed)();
@property (strong, nonatomic) void (^forwardPressed)();
@property (strong, nonatomic) void (^reversePressed)();
@property (strong, nonatomic) void (^heartRateUpdate)(NSNumber *bpm);

@end
