//
//  PlayMusic.m
//  TempoWatch
//
//  Created by Mark Linington on 9/12/15.
//  Copyright © 2015 MarkLinington. All rights reserved.
//

#import "PlayMusic.h"

@interface PlayMusic ()
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
    
    self.monitorSession = [[HKWorkoutSession alloc] initWithActivityType:HKWorkoutActivityTypeOther locationType:HKWorkoutSessionLocationTypeIndoor];
    self.monitorSession.delegate = self;
    
    self.store = [[HKHealthStore alloc] init];
//    HKAuthorizationStatus *status = [self.store authorizationStatusForType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate]];
    
    [self.store requestAuthorizationToShareTypes:nil readTypes:[NSSet setWithArray:@[[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate]]] completion:^(BOOL success, NSError * _Nullable error) {
        NSLog(@"Was successful %i", success);
    }];
    [self.store startWorkoutSession:self.monitorSession];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

#pragma mark - HKWorkoutSessionDelegate

- (void)workoutSession:(HKWorkoutSession *)workoutSession didChangeToState:(HKWorkoutSessionState)toState fromState:(HKWorkoutSessionState)fromState date:(NSDate *)date
{
    NSLog(@"New state: %ld", (long)toState);
    self.heartRateQuery = [[HKAnchoredObjectQuery alloc]
                           initWithType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate]
                           predicate:nil
                           anchor:nil
                           limit:HKObjectQueryNoLimit
                           resultsHandler:^(HKAnchoredObjectQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable sampleObjects, NSArray<HKDeletedObject *> * _Nullable deletedObjects, HKQueryAnchor * _Nullable newAnchor, NSError * _Nullable error)
    {
    }];
    [self.heartRateQuery setUpdateHandler:^(HKAnchoredObjectQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable sampleObjects, NSArray<HKDeletedObject *> * _Nullable deletedObjects, HKQueryAnchor * _Nullable newAnchor, NSError * _Nullable error) {
        NSLog(@"New sample %@", sampleObjects);
    }];
    
    [self.store executeQuery:self.heartRateQuery];
    
}

- (void)workoutSession:(HKWorkoutSession *)workoutSession didFailWithError:(NSError *)error
{
    NSLog(@"Failed");
}

@end
