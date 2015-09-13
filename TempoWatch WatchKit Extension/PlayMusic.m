//
//  PlayMusic.m
//  TempoWatch
//
//  Created by Mark Linington on 9/12/15.
//  Copyright © 2015 MarkLinington. All rights reserved.
//

#import "PlayMusic.h"
#import "PhoneLiason.h"
@import WatchConnectivity;

@interface PlayMusic () <WCSessionDelegate>

@property (strong, nonatomic) HKHealthStore *store;
@property (strong, nonatomic) HKWorkoutSession *monitorSession;
@property (strong, nonatomic) HKAnchoredObjectQuery *heartRateQuery;

@property (strong, nonatomic) PhoneLiason *liason;

// UI Elements
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *currentHeartRate;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceImage *heartDisplay;

@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *songTitle;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *artistName;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceGroup *backgroundGroup;
@property (unsafe_unretained) IBOutlet WKInterfaceButton *playPauseButton;

@property BOOL pauseOn;


@property BOOL hasHeartRate;

@end

@implementation PlayMusic

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    self.hasHeartRate = NO;
    
    // Configure interface objects here.
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];

    self.liason = [[PhoneLiason alloc] init];
    __block PlayMusic *safeSelf = self;
    [self.liason setAddedMetadata:^(NSString *title, NSString *artist, UIImage *art) {
        NSLog(@"New data");
        [safeSelf.songTitle setText:title];
        [safeSelf.artistName setText:artist];
        [safeSelf.backgroundGroup setBackgroundImage:art];
    }];
    
    self.monitorSession = [[HKWorkoutSession alloc] initWithActivityType:HKWorkoutActivityTypeOther locationType:HKWorkoutSessionLocationTypeIndoor];
    self.monitorSession.delegate = self;
    
    self.store = [[HKHealthStore alloc] init];
    [self.store startWorkoutSession:self.monitorSession];
    
    if(HKHealthStore.isHealthDataAvailable)
    {
        HKQuantityType *heartReate = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
        [self.store requestAuthorizationToShareTypes:nil readTypes:[NSSet setWithObjects:heartReate, nil] completion:^(BOOL success, NSError * _Nullable error) {
            NSLog(@"Hit");
        }];
    }
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [self.store stopQuery:self.heartRateQuery];
    [self.store endWorkoutSession:self.monitorSession];
    [super didDeactivate];
}

#pragma mark - HKWorkoutSessionDelegate

- (void)workoutSession:(HKWorkoutSession *)workoutSession didChangeToState:(HKWorkoutSessionState)toState fromState:(HKWorkoutSessionState)fromState date:(NSDate *)date
{
    // Sets up query to fetch heart rates
    self.heartRateQuery = [[HKAnchoredObjectQuery alloc]
                           initWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate]
                           predicate:nil
                           anchor:nil
                           limit:HKObjectQueryNoLimit
                           resultsHandler:^(HKAnchoredObjectQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable sampleObjects, NSArray<HKDeletedObject *> * _Nullable deletedObjects, HKQueryAnchor * _Nullable newAnchor, NSError * _Nullable error)
    {
        NSLog(@"Hit");
    }];
    
    // Every time a new heart rate is received this handler is called
    __block PlayMusic *blockSafeSelf = self;
    [self.heartRateQuery setUpdateHandler:^(HKAnchoredObjectQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable sampleObjects, NSArray<HKDeletedObject *> * _Nullable deletedObjects, HKQueryAnchor * _Nullable newAnchor, NSError * _Nullable error)
    {
        HKUnit *bpmUnit = [HKUnit unitFromString:@"count/min"];
        HKQuantitySample *mostRecentHeartQuantity = sampleObjects.lastObject;
        NSNumber *mostRecentRate = [NSNumber numberWithDouble:[mostRecentHeartQuantity.quantity doubleValueForUnit:bpmUnit]];
        
        if(self.hasHeartRate == NO)
        {
            blockSafeSelf.hasHeartRate = YES;
            dispatch_async(dispatch_get_main_queue(), ^{
                [blockSafeSelf animateWithDuration:0.5 animations:^{
                    blockSafeSelf.heartDisplay.alpha = 1;
                    blockSafeSelf.currentHeartRate.alpha = 1;
                }];
                blockSafeSelf.currentHeartRate.text = [NSString stringWithFormat:@"%i", mostRecentRate.intValue];
            });
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                blockSafeSelf.currentHeartRate.text = [NSString stringWithFormat:@"%i", mostRecentRate.intValue];
            });
        }
        
        // After getting an NSNumber that is BPM, we use WatchConnectivity to send that to the phone
        [blockSafeSelf.liason sendHeartRate:mostRecentRate];
    }];
    
    [self.store executeQuery:self.heartRateQuery];
    
}

- (void)workoutSession:(HKWorkoutSession *)workoutSession didFailWithError:(NSError *)error
{
    NSLog(@"Failed");
}

- (IBAction)rewind {
    [self.liason pressBackward];
}
- (IBAction)playPause {
    [self.liason pressPlayPause];
    if (self.pauseOn) {
        self.pauseOn = false;
        [self.playPauseButton setBackgroundImageNamed:@"red-pause"];
    } else {
        self.pauseOn = true;
        [self.playPauseButton setBackgroundImageNamed:@"red-play"];
    }
    
}
- (IBAction)forward {
    [self.liason pressForward];
}

@end
