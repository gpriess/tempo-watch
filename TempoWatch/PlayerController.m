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

@interface PlayerController () <SPTAudioStreamingDelegate, WCSessionDelegate>


@property (weak, nonatomic) IBOutlet UILabel *tempoLabel;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *albumLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (weak, nonatomic) IBOutlet UIImageView *coverView;

@property (nonatomic, strong) SPTAudioStreamingController *player;

@end

@implementation PlayerController

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
        // Probably want to aler that this won't work without health data
    }
    
    // Sets up WatchConnectivity to receive updates from the watch with the new heart rate
    [[WCSession defaultSession] setDelegate:self];
    [[WCSession defaultSession] activateSession];
    
    self.tempoLabel.text = @"n/a";
}

// Music styles
// rock, pop, country, metal, alternative, jazz, punk, classical, techno, dubstep


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
//                      self.artistLabel.text = artist.name;
                      
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
        
        NSURLRequest *playlistReq = [SPTPlaylistSnapshot createRequestForPlaylistWithURI:[NSURL URLWithString:@"spotify:user:cariboutheband:playlist:4Dg0J0ICj9kKTGDyFu0Cv4"]
                                                                             accessToken:auth.session.accessToken
                                                                                   error:nil];
        
        [[SPTRequest sharedHandler] performRequest:playlistReq callback:^(NSError *error, NSURLResponse *response, NSData *data) {
            if (error != nil) {
                NSLog(@"*** Failed to get playlist %@", error);
                return;
            }
            
            SPTPlaylistSnapshot *playlistSnapshot = [SPTPlaylistSnapshot playlistSnapshotFromData:data withResponse:response error:nil];
            
            [self.player playURIs:playlistSnapshot.firstTrackPage.items fromIndex:0 callback:nil];
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

@end
