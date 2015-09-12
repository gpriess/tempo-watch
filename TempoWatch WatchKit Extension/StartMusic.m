//
//  InterfaceController.m
//  TempoWatch WatchKit Extension
//
//  Created by Mark Linington on 9/12/15.
//  Copyright © 2015 MarkLinington. All rights reserved.
//

#import "StartMusic.h"


@interface StartMusic()
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceImage *image;

@end


@implementation StartMusic

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    // Configure interface objects here.
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    [self.image setImageNamed:@"heart"];
    NSLog(@"Hit");
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}


@end



