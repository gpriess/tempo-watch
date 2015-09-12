	//
//  PlayMusic.m
//  TempoWatch
//
//  Created by Mark Linington on 9/12/15.
//  Copyright © 2015 MarkLinington. All rights reserved.
//

#import "PlayMusic.h"
@import WatchConnectivity;

@interface PlayMusic () <WCSessionDelegate>
@property (strong, nonatomic) HKHealthStore *store;
@property (strong, nonatomic) HKWorkoutSession *monitorSession;
@property (strong, nonatomic) HKAnchoredObjectQuery *heartRateQuery;
@end

@implementation PlayMusic

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    // Configure interface objects here.
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    
    [[WCSession defaultSession] setDelegate:self];
    [[WCSession defaultSession] activateSession];
    
    self.monitorSession = [[HKWorkoutSession alloc] initWithActivityType:HKWorkoutActivityTypeOther locationType:HKWorkoutSessionLocationTypeIndoor];
    self.monitorSession.delegate = self;
    
    self.store = [[HKHealthStore alloc] init];
    [self.store startWorkoutSession:self.monitorSession];
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
    }];
    
    // Every time a new heart rate is received this handler is called
    [self.heartRateQuery setUpdateHandler:^(HKAnchoredObjectQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable sampleObjects, NSArray<HKDeletedObject *> * _Nullable deletedObjects, HKQueryAnchor * _Nullable newAnchor, NSError * _Nullable error)
    {
        HKUnit *bpmUnit = [HKUnit unitFromString:@"count/min"];
        HKQuantitySample *mostRecentHeartQuantity = sampleObjects.lastObject;
        NSNumber *mostRecentRate = [NSNumber numberWithDouble:[mostRecentHeartQuantity.quantity doubleValueForUnit:bpmUnit]];
        
        // After getting an NSNumber that is BPM, we use WatchConnectivity to send that to the phone
        [[WCSession defaultSession] sendMessage:@{@"rate":mostRecentRate} replyHandler:nil errorHandler:^(NSError * _Nonnull error) {
            NSLog(@"HIT ERROR %@",error);
        }];
    }];
    
    [self.store executeQuery:self.heartRateQuery];
    
}

- (void)workoutSession:(HKWorkoutSession *)workoutSession didFailWithError:(NSError *)error
{
    NSLog(@"Failed");
}

@end
