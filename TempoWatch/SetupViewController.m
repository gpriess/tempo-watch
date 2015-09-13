//
//  SetupViewController.m
//  TempoWatch
//
//  Created by Mark Linington on 9/13/15.
//  Copyright © 2015 MarkLinington. All rights reserved.
//

#import "SetupViewController.h"
#import "PlayerController.h"
@import HealthKit;

@interface SetupViewController () <SPTAuthViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *logo;
@property (weak, nonatomic) IBOutlet UITextView *descriptionText;
@property (weak, nonatomic) IBOutlet UIButton *button;

@property (nonatomic) NSUInteger state;

@end

@implementation SetupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.state = 0;
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)requestHRAccess:(id)sender {
    if(self.state == 0)
    {
        if(HKHealthStore.isHealthDataAvailable)
        {
            HKHealthStore *store = [[HKHealthStore alloc] init];
            HKQuantityType *heartReate = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
            [store requestAuthorizationToShareTypes:nil readTypes:[NSSet setWithObjects:heartReate, nil] completion:^(BOOL success, NSError * _Nullable error)
            {
                [self transition];
                NSLog(@"Hit");
            }];
        }
        else
        {
            // Probably want to alert that this won't work without health data
        }
    }
    else if(self.state == 1)
    {
        // Log in to Spotify
        SPTAuthViewController *authController = [SPTAuthViewController authenticationViewController];
        authController.delegate = self;
        authController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        authController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        
        self.modalPresentationStyle = UIModalPresentationCurrentContext;
        self.definesPresentationContext = YES;
        
        [self presentViewController:authController animated:NO completion:nil];
    }
    else if(self.state == 2)
    {
        [self performSegueWithIdentifier:@"SetupComplete" sender:self];
    }
}

- (void) transition;
{
    if(self.state == 0)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.5 animations:^{
                self.logo.alpha = 0;
                self.descriptionText.alpha = 0;
                self.button.alpha = 0;
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:1 animations:^{
                    [self.logo setImage:[UIImage imageNamed:@"spotify"]];
                    self.descriptionText.text = @"We get all of our songs from Spotify.\n\n A Spotify premium account is required to use Tempo.";
                    [self.button setTitle:@"Login to Spotify" forState:UIControlStateNormal];
                    self.logo.alpha = 1;
                    self.descriptionText.alpha = 1;
                    self.button.alpha = 1;
                }];
            }];
            self.state = 1;
        });
    }
    if(self.state == 1)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.5 animations:^{
                self.logo.alpha = 0;
                self.descriptionText.alpha = 0;
                self.button.alpha = 0;
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:1 animations:^{
                    [self.logo setImage:[UIImage imageNamed:@"Logo"]];
                    self.descriptionText.text = @"That's it! You're all set.";
                    [self.button setTitle:@"Begin using Tempo" forState:UIControlStateNormal];
                    self.logo.alpha = 1;
                    self.descriptionText.alpha = 1;
                    self.button.alpha = 1;
                }];
            }];
        });
        self.state = 2;
    }
}

- (void) authenticationViewController:(SPTAuthViewController *)authenticationViewController didLoginWithSession:(SPTSession *)session
{
    [self transition];
}

- (void) authenticationViewController:(SPTAuthViewController *)authenticationViewController didFailToLogin:(NSError *)error
{
    
}

- (void) authenticationViewControllerDidCancelLogin:(SPTAuthViewController *)authenticationViewController
{
    
}

@end
