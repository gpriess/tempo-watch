//
//  WatchLiason.m
//  TempoWatch
//
//  Created by Mark Linington on 9/12/15.
//  Copyright © 2015 MarkLinington. All rights reserved.
//

#import "WatchLiason.h"
@import WatchConnectivity;

@interface WatchLiason () <WCSessionDelegate>

@end

@implementation WatchLiason

- (instancetype) init
{
    self = [super init];
    if(self)
    {
        [[WCSession defaultSession] setDelegate:self];
        [[WCSession defaultSession] activateSession];
    }
    return self;
}

- (void) sendMetadataTitle:(NSString *)title andArtist:(NSString *)artist andArt:(UIImage *)art
{
    NSDictionary *message = @{@"title":title,
                              @"artist":artist,
                              @"art":art};
    
    [[WCSession defaultSession] sendMessage:message replyHandler:nil errorHandler:^(NSError * _Nonnull error)
    {
        NSLog(@"Error sending metadata");
    }];
}

- (void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *,id> *)message
{
    if(message[@"rate"])
    {
        self.heartRateUpdate(message[@"rate"]);
    }
    if(message[@"playpause"])
    {
        self.playPausePressed();
    }
    if(message[@"forward"])
    {
        self.forwardPressed();
    }
    if(message[@"reverse"])
    {
        self.reversePressed();
    }
}

@end
