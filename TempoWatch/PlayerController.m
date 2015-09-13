//
//  ViewController.m
//  TempoWatch
//
//  Created by Mark Linington on 9/12/15.
//  Copyright © 2015 MarkLinington. All rights reserved.
//

#import "Config.h"
#import "PlayerController.h"
#import "WatchLiason.h"
#import <Spotify/SPTDiskCache.h>
#import <UIKit/UIKit.h>
@import HealthKit;
@import WatchConnectivity;

const NSString *kBaseURL = @"http://developer.echonest.com/api/v4/song/search?api_key=OVKZFPDQEXGKAD634&min_tempo=%i&max_tempo=%i&min_danceability=%d&sort=song_hotttnesss-desc&results=20&bucket=id:spotify&bucket=tracks&limit=true";

@interface PlayerController () <SPTAudioStreamingDelegate, SPTAudioStreamingPlaybackDelegate, WCSessionDelegate, SPTAuthViewDelegate>

@property (atomic, readwrite) SPTAuthViewController *authViewController;

@property (atomic, strong) NSMutableArray *previousHRSamples;

@property (weak, nonatomic) IBOutlet UILabel *heartRateLabel;
@property (weak, nonatomic) IBOutlet UILabel *tempoLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *coverView;

@property (strong, atomic) WatchLiason *liason;

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
    
    // Initialize queue
    self.previousHRSamples = [[NSMutableArray alloc] init];
    
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
    
    self.liason = [[WatchLiason alloc] init];
    [self.liason setReversePressed:^{
        // Executes when reverse is pressed
    }];
    [self.liason setForwardPressed:^{
        // Executes when forward is pressed
    }];
    [self.liason setPlayPausePressed:^{
        // Executes when play or pause is pressed
    }];
    
    __block PlayerController *safeSelf = self;
    [self.liason setHeartRateUpdate:^(NSNumber *currentBPM) {
        dispatch_async(dispatch_get_main_queue(), ^{
            safeSelf.heartRateLabel.text = [NSString stringWithFormat:@"%i",currentBPM.intValue];
        });
    }];
    
    self.tempoLabel.text = @"n/a";
    UIImage *cage = [UIImage imageNamed:@"cage"];
    self.coverView.image = [self blurImage:cage blurRadius:20.0];
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
        self.coverView.image = nil;
        return;
    }
    
//    [self.spinner startAnimating];
    
    [SPTTrack trackWithURI:self.player.currentTrackURI
                   session:auth.session
                  callback:^(NSError *error, SPTTrack *track) {
                      
                      self.titleLabel.text = track.name;
//                      self.albumLabel.text = track.album.name;
                      
                      SPTPartialArtist *artist = [track.artists objectAtIndex:0];
//                      self.titleLabel.text = artist.name;
                      
                      NSURL *imageURL = track.album.largestCover.imageURL;
                      if (imageURL == nil) {
                          NSLog(@"Album %@ doesn't have any images!", track.album);
                          self.coverView.image = nil;
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
//                              [self.spinner stopAnimating];
                              self.coverView.image = image;
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

//




-(void)updatePlaylistWithMinTempo:(NSUInteger)min maxTempo:(NSUInteger)max andDancibility:(NSNumber*)dancibility
{
    
    
    NSString *urlString = [NSString stringWithFormat:kBaseURL,min,max,dancibility];
    NSURL *bigList = [NSURL URLWithString:urlString];
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:bigList];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError)
     {
         //data
         NSDictionary *marksDic = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
         
         NSArray *songArray = marksDic[@"response"][@"songs"];
         NSMutableArray *prettySongs = [[NSMutableArray alloc] init];
         [songArray enumerateObjectsUsingBlock:^(NSDictionary *_Nonnull song, NSUInteger idx, BOOL * _Nonnull stop) {
             [prettySongs addObject:[NSURL URLWithString:song[@"tracks"][0][@"foreign_id"]]];
         }];
         
         [self.player playURIs:prettySongs fromIndex:0 callback:^(NSError *error) {
             if (error != nil) {
                 NSLog(@"*** Starting playback got error: %@", error);
                 return;
             }
         }];
     }];
}




// This is the callback from the watch that receives the heart rate
- (void)session:(WCSession *)session didReceiveMessage:(nonnull NSDictionary<NSString *,id> *)message
{
    NSNumber *currentBPM = message[@"rate"];
    self.heartRateLabel.text = [NSString stringWithFormat:@"%i",currentBPM.intValue];
    NSLog(@"Current heart rate is %@", currentBPM);
    
    
    if (self.previousHRSamples.count > 5) {
        [self.previousHRSamples removeObjectAtIndex:0];
    }
    [self.previousHRSamples addObject:currentBPM];
    
    int mostRecentHR = [self.previousHRSamples.lastObject intValue];
    int oldestHR = [self.previousHRSamples[0] intValue];
    
    if(abs(oldestHR-mostRecentHR) > 10)
    {
        // Update song list with mostRecentHR
        [self updatePlaylistWithMinTempo:MAX(MIN(oldestHR, mostRecentHR),60) maxTempo:MAX(MAX(oldestHR, mostRecentHR), 70) andDancibility:@0.5];
    }
    
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
