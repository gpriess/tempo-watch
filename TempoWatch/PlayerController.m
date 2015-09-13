//
//  ViewController.m
//  TempoWatch
//
//  Created by Mark Linington on 9/12/15.
//  Copyright © 2015 MarkLinington. All rights reserved.
//

#import "Config.h"
#import "PlayerController.h"
#import <Spotify/SPTDiskCache.h>
#import <UIKit/UIKit.h>
@import HealthKit;
@import WatchConnectivity;

@interface PlayerController () <SPTAudioStreamingDelegate, WCSessionDelegate, SPTAuthViewDelegate>

@property (atomic, readwrite) SPTAuthViewController *authViewController;

@property (weak, nonatomic) IBOutlet UILabel *tempoLabel;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *albumLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (weak, nonatomic) IBOutlet UIImageView *coverView;

@property (nonatomic, strong) SPTAudioStreamingController *player;

@end

@implementation PlayerController

// Image blur function courtesy of Stack Overflow :D
- (UIImage*)blurImage:(UIImage*)image blurRadius:(CGFloat)radius{
    
    CIImage *ciImage = [CIImage imageWithCGImage:image.CGImage];
    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [filter setValue:ciImage forKey:kCIInputImageKey];
    [filter setValue:@(radius) forKey:kCIInputRadiusKey];
    
    CIImage *outputCIImage = filter.outputImage;
    CIContext *context = [CIContext contextWithOptions:nil];
    
    return [UIImage imageWithCGImage: [context createCGImage:outputCIImage fromRect:ciImage.extent]];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Requests access to health data on first run of the phone
    if(HKHealthStore.isHealthDataAvailable)
    {
        HKHealthStore *store = [[HKHealthStore alloc] init];
        HKQuantityType *heartReate = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
        [store requestAuthorizationToShareTypes:nil readTypes:[NSSet setWithObjects:heartReate, nil] completion:^(BOOL success, NSError * _Nullable error) {
            NSLog(@"Hit");
        }];
    }
    else
    {
        // Probably want to alert that this won't work without health data
    }
    
    // Sets up WatchConnectivity to receive updates from the watch with the new heart rate
    [[WCSession defaultSession] setDelegate:self];
    [[WCSession defaultSession] activateSession];
    
    self.tempoLabel.text = @"n/a";
    UIImage *cage = [UIImage imageNamed:@"cage"];
    self.coverView.image = [self blurImage:cage blurRadius:20.0];
    
    [[WCSession defaultSession] sendMessage:@{@"image":cage} replyHandler:nil errorHandler:nil];
}

// Music styles
// rock, pop, country, metal, alternative, jazz, punk, classical, techno, dubstep


-(void)showPlayer {
//    self.firstLoad = NO;
//    self.statusLabel.text = @"Logged in.";
//    [self performSegueWithIdentifier:@"ShowPlayer" sender:nil];
    [self handleNewSession];
}



// It worked if this code is hit
- (void)authenticationViewController:(SPTAuthViewController *)viewcontroller didLoginWithSession:(SPTSession *)session {
    //    self.statusLabel.text = @"";
   [self showPlayer];
}

- (void)openLoginPage {
    //    self.statusLabel.text = @"Logging in...";
    
    self.authViewController = [SPTAuthViewController authenticationViewController];
    self.authViewController.delegate = self;
    self.authViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    self.authViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    self.modalPresentationStyle = UIModalPresentationCurrentContext;
    self.definesPresentationContext = YES;

    [self presentViewController:self.authViewController animated:NO completion:nil];
}







// Return tempo string
+(NSString*) getTempoStringForBPM:(NSUInteger)bpm {
    if (bpm <= 60) {
        return @"Largo";
    }
    else if (bpm <= 76) {
        return @"Adagio";
    }
    else if (bpm <= 120) {
        return @"Moderato";
    }
    else if (bpm <= 168) {
        return @"Allegro";
    }
    else if (bpm <= 200) {
        return @"Presto";
    }
    return @"Prestissimo";
}

-(void)updateUI {
    SPTAuth *auth = [SPTAuth defaultInstance];
    
    if (self.player.currentTrackURI == nil) {

        return;
    }
    
//    [self.spinner startAnimating];
    
    [SPTTrack trackWithURI:self.player.currentTrackURI
                   session:auth.session
                  callback:^(NSError *error, SPTTrack *track) {

                      
                      SPTPartialArtist *artist = [track.artists objectAtIndex:0];
                      self.artistLabel.text = artist.name;
                      
                      NSURL *imageURL = track.album.largestCover.imageURL;
                      if (imageURL == nil) {
                          NSLog(@"Album %@ doesn't have any images!", track.album);

                          return;
                      }
                      
                      // Pop over to a background queue to load the image over the network.
                      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                          NSError *error = nil;
                          UIImage *image = nil;
                          NSData *imageData = [NSData dataWithContentsOfURL:imageURL options:0 error:&error];
                          
                          if (imageData != nil) {
                              image = [UIImage imageWithData:imageData];
                          }
                          
                          
                          // …and back to the main queue to display the image.
                          dispatch_async(dispatch_get_main_queue(), ^{

                              if (image == nil) {
                                  NSLog(@"Couldn't load cover image with error: %@", error);
                                  return;
                              }
                          });

                      });
                      
                  }];
}


-(void)handleNewSession {
    SPTAuth *auth = [SPTAuth defaultInstance];
    
    if (self.player == nil) {
        self.player = [[SPTAudioStreamingController alloc] initWithClientId:auth.clientID];
        self.player.playbackDelegate = self;
        self.player.diskCache = [[SPTDiskCache alloc] initWithCapacity:1024 * 1024 * 64];
    }
    
    [self.player loginWithSession:auth.session callback:^(NSError *error) {
        
        if (error != nil) {
            NSLog(@"*** Enabling playback got error: %@", error);
            return;
        }
        
        [self updateUI];
        
        
        
        NSURL *trackURI = [NSURL URLWithString:@"spotify:track:58s6EuEYJdlb0kO7awm3Vp"];
        [self.player playURIs:@[ trackURI ] fromIndex:0 callback:^(NSError *error) {
            if (error != nil) {
                NSLog(@"*** Starting playback got error: %@", error);
                return;
            }
        }];
    }];
}


#pragma mark - Track Player Delegates

- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didReceiveMessage:(NSString *)message {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Message from Spotify"
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
}

- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didFailToPlayTrack:(NSURL *)trackUri {
    NSLog(@"failed to play track: %@", trackUri);
}

- (void) audioStreaming:(SPTAudioStreamingController *)audioStreaming didChangeToTrack:(NSDictionary *)trackMetadata {
    NSLog(@"track changed = %@", [trackMetadata valueForKey:SPTAudioStreamingMetadataTrackURI]);
    [self updateUI];
}

- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didChangePlaybackStatus:(BOOL)isPlaying {
    NSLog(@"is playing = %d", isPlaying);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// This is the callback from the watch that receives the heart rate
- (void)session:(WCSession *)session didReceiveMessage:(nonnull NSDictionary<NSString *,id> *)message
{
    NSNumber *currentBPM = message[@"rate"];
    NSLog(@"Current heart rate is %@", currentBPM);
}




- (void)renewTokenAndShowPlayer {
    //    self.statusLabel.text = @"Refreshing token...";
    SPTAuth *auth = [SPTAuth defaultInstance];
    
    [auth renewSession:auth.session callback:^(NSError *error, SPTSession *session) {
        auth.session = session;
        
        if (error) {
            //            self.statusLabel.text = @"Refreshing token failed.";
            NSLog(@"*** Error renewing session: %@", error);
            return;
        }
        
        [self showPlayer];
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    SPTAuth *auth = [SPTAuth defaultInstance];
    
    // Check if we have a token at all
    if (auth.session == nil) {
        //        self.statusLabel.text = @"";
        return;
    }
    // Check if it's still valid
//    if ([auth.session isValid] && self.firstLoad) {
        // It's still valid, show the player.
//        [self showPlayer];
//        return;
    // Oh noes, the token has expired, if we have a token refresh service set up, we'll call tat one.
    //    self.statusLabel.text = @"Token expired.";
    if (auth.hasTokenRefreshService) {
        [self renewTokenAndShowPlayer];
        return;
    }
    
    // Else, just show login dialog
}


-(IBAction)rewind:(id)sender {
    [self.player skipPrevious:nil];
}

-(IBAction)playPause:(id)sender {
    [self.player setIsPlaying:!self.player.isPlaying callback:nil];
}

-(IBAction)fastForward:(id)sender {
    [self.player skipNext:nil];
}

- (void)authenticationViewControllerDidCancelLogin:(SPTAuthViewController *)authenticationViewController {
    //    self.statusLabel.text = @"Login cancelled.";
}
    
- (IBAction)loginClicked:(id)sender {
    [self openLoginPage];
}
    
    
@end
