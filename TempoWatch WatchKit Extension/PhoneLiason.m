//
//  PhoneLiason.m
//  TempoWatch
//
//  Created by Mark Linington on 9/13/15.
//  Copyright © 2015 MarkLinington. All rights reserved.
//

#import "PhoneLiason.h"

@implementation PhoneLiason

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

- (void) pressForward
{
    [[WCSession defaultSession] sendMessage:@{@"forward":@YES} replyHandler:nil errorHandler:^(NSError * _Nonnull error) {
        NSLog(@"Error sending forward");
    }];
}

- (void) pressBackward
{
    [[WCSession defaultSession] sendMessage:@{@"reverse":@YES} replyHandler:nil errorHandler:^(NSError * _Nonnull error) {
        NSLog(@"Error sending reverse");
    }];
}

- (void) pressPlayPause
{
    [[WCSession defaultSession] sendMessage:@{@"playpause":@YES} replyHandler:nil errorHandler:^(NSError * _Nonnull error) {
        NSLog(@"Error sending play/pause");
    }];
}

- (void) sendHeartRate:(NSNumber *)bpm
{
    [[WCSession defaultSession] sendMessage:@{@"rate":bpm} replyHandler:nil errorHandler:^(NSError * _Nonnull error) {
        NSLog(@"Error sending play pause");
    }];
}

- (void) sendUpdateRequest
{
    [[WCSession defaultSession] sendMessage:@{@"update":@YES} replyHandler:nil errorHandler:^(NSError * _Nonnull error) {
        NSLog(@"Error sending update request");
    }];
}

- (void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *,id> *)message
{
    NSString *title = message[@"title"];
    NSString *artist = message[@"artist"];
    UIImage *albumArt = [UIImage imageWithData:message[@"art"]];
    NSNumber *isPlaying = message[@"playing"];
    
    self.addedMetadata(title,artist,albumArt,isPlaying);
}


@end
