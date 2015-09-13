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

    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(150, 150), NO, art.scale);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect area = CGRectMake(0, 0, 150, 150);
    
    CGContextScaleCTM(context, 1, -1);
    CGContextTranslateCTM(context, 0, -150);
    
    CGContextSaveGState(context);
    CGContextClipToMask(context, area, art.CGImage);
    
    UIColor *mycolor = [UIColor colorWithRed:24/255.0f green:24/255.0f blue:24/255.0f alpha:0.50];
    
    [mycolor set];
    
    CGContextFillRect(context, area);
    
    CGContextRestoreGState(context);
    
    CGContextSetBlendMode(context, kCGBlendModeMultiply);
    
    CGContextDrawImage(context, area, art.CGImage);
    
    UIImage *filteredImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    
    
    

    
    NSDictionary *message = @{@"title":title,
                              @"artist":artist,
                              @"art":UIImageJPEGRepresentation(filteredImage, 1)};
    
    [[WCSession defaultSession] sendMessage:message replyHandler:^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {
        NSLog(@"Success");
    } errorHandler:^(NSError * _Nonnull error)
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
