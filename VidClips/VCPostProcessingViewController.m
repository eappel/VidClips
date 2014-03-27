//
//  VCPostProcessingViewController.m
//  VidCam
//
//  Created by Eric Appel on 3/12/14.
//  Copyright (c) 2014 Eric Appel. All rights reserved.
//

#import "VCPostProcessingViewController.h"
#import "VCFilterBlockViewController.h"
#import "VCMovieWriterProgressObject.h"
#import "VCNavigationController.h"
#import "VCClipViewer.h"
#import <AVFoundation/AVFoundation.h>
#import <GPUImage.h>
#import <FRDLivelyButton.h>

#define HIGHEST_FILTER_ENUM 16

@interface VCPostProcessingViewController () <UIPageViewControllerDelegate, UIPageViewControllerDataSource> {
    NSTimer *revealTimer;
}

@end

@implementation VCPostProcessingViewController

- (id)init
{
    return [self initWithClipsFromURLs:nil];
}

- (id)initWithClipsFromURLs:(NSMutableArray *) fileURLs
{
    self = [super init];
    if(self) {
        NSLog(@"_init: %@", self);
        if (fileURLs.count == 0) {
            NSLog(@"ERROR -- No file urls to fetch video");
        }
        else {
            NSLog(@"ASSET ARRAY NON EMPTY");
            self.assets = [[NSMutableArray alloc] init];
            NSDictionary *optionsDictionary = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
            for (NSURL *url in fileURLs) {
                AVURLAsset *tempAsset = [AVURLAsset URLAssetWithURL:url options:optionsDictionary];
                [self.assets addObject:tempAsset];
            }
            NSLog(@"%lu ASSETS LOADED INTO self.assetURLs", (unsigned long)self.assets.count);
        }
    }
    return self;
}

- (void)viewDidLoad
{
//    NSLog(@"VCPostProcessingViewController did load")
    
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor blackColor]];
    
    self.exportCount = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"exportCount"];
    NSLog(@"export count is: %li", (long)self.exportCount);
    
//    CREATE PAGEVIEWCONTROLLER
    //The page vc is used to switch between filter types
    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationVertical options:nil];
    
    self.pageViewController.delegate = self;
    self.pageViewController.dataSource = self;
    [[self.pageViewController view] setFrame:self.view.bounds];
    
    VCFilterBlockViewController *initialViewController = [self viewControllerForFilterIndex:0];
    
    NSArray *viewControllers = [NSArray arrayWithObject:initialViewController];
    
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    [self.pageViewController.view setAlpha:0.0];
    self.pageViewControllerShowing = NO;
    
    [self addChildViewController:self.pageViewController];
    [self.view addSubview:[self.pageViewController view]];
    [self.pageViewController didMoveToParentViewController:self];
    

    //tap  will toggle nav buttons
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.view addGestureRecognizer:self.tapGestureRecognizer];

    //swipe will toggle pageviewcontroller visibility
    self.swipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    self.swipeGestureRecognizer.direction = (UISwipeGestureRecognizerDirectionUp | UISwipeGestureRecognizerDirectionDown);
    [self.view addGestureRecognizer:self.swipeGestureRecognizer];
    [self.swipeGestureRecognizer setEnabled:NO];
    
    [self.view setUserInteractionEnabled:YES];
}

- (void) viewWillAppear:(BOOL)animated
{
    //remove lingering video files
    GPUImageFilterType filterIterator = 0;
    while (filterIterator <= HIGHEST_FILTER_ENUM) {
        [self removeFileAtURL:[self generateFilterURLForFilterType:filterIterator]];
        filterIterator++;
    }
    
    [self createCompositionWithAssets:self.assets];
}

- (void) viewDidAppear:(BOOL)animated
{
    self.cancelButton = [(VCNavigationController *)self.navigationController leftButton];
    [self.cancelButton addTarget:self action:@selector(cancelButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.cancelButton setStyle:kFRDLivelyButtonStyleClose animated:YES];
    
    self.saveButton = [(VCNavigationController *)self.navigationController rightButton];
    [self.saveButton addTarget:self action:@selector(saveButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.saveButton setStyle:kFRDLivelyButtonStylePlus animated:YES];
    
    // SET THE MOVIE WRITER PROGRESS FOR EACH FILTER TO 0 (INITIAL)
    self.writerProgressObject = [[VCMovieWriterProgressObject alloc] init];
    GPUImageFilterType filterIterator = 1;
    while (filterIterator <= HIGHEST_FILTER_ENUM) {
        NSString *key = [self writerProgressObjectKVCHelper:filterIterator];
        [self.writerProgressObject setValue:[NSNumber numberWithInt:GPUImageMovieWriterStatusInitial] forKey:key];
        [self.writerProgressObject addObserver:self forKeyPath:key options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
        filterIterator++;
    }
    
    // display instructions alert if this is the first time opening the app 
    BOOL isFirstLaunch = [[NSUserDefaults standardUserDefaults] boolForKey:@"isFirstLaunch2"];
    if (!isFirstLaunch) {
        NSString *message = @"To add a filter to your video, swipe up or down.  WARNING: swiping too fast may crash the app.  When you are done editing your video, press the '+' button in the bottom right to save it to the gallery.  To cancel, press the 'x' button in the bottom left.";
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Welcome!"
                                                            message:message
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isFirstLaunch2"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (NSString *)writerProgressObjectKVCHelper:(int)filterIndex
{
    //returns the name of the key for a given filter.
    //...mainly just to override stringOfFilterAtIndex: for Soft Elegance and Polar Pixellate to remove spaces
    NSString *key;
    if (filterIndex == GPUImageFilterType_SoftElegance) {
        key = @"SoftElegance";
    }
    else if (filterIndex == GPUImageFilterType_PolarPixellate) {
        key = @"PolarPixellate";
    }
    else {
        key = [self stringOfFilterAtIndex:filterIndex];
    }
    return key;
}

#pragma page view controller delegate methods
- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers
{
    //    called whenever a swipe gesture begins
//    NSLog(@"pc will");
    
    self.activity = 4.0;
    self.nextFilterBlockViewController = (VCFilterBlockViewController *)[pendingViewControllers objectAtIndex:0];
    if (self.currentFilter == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self filterVideoToURLForType:[self.nextFilterBlockViewController index]];
        });
    }
    
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    //    called when swipe ends, whether a new vc is pushed or not
//    NSLog(@"did finish pvc change");
    if (completed) {
//        NSLog(@"completed");
        self.currentFilter = [self.nextFilterBlockViewController index];
        int prevFilterIndex = [(VCFilterBlockViewController *)[previousViewControllers objectAtIndex:0] index];
        self.previousFilterIndex = prevFilterIndex;
        if (self.currentFilter == 0) {
            [self playFileAtURL:self.compositionURL];
            [self preloadNextFilterwithPrevIndex:prevFilterIndex];
        } else {
            NSURL *assetURL = [self generateFilterURLForFilterType:self.currentFilter];
            if ([self checkURLOccupied:assetURL]) {
                NSLog(@"checking writer progress");
                if ([self.writerProgressObject valueForKey:[self writerProgressObjectKVCHelper:self.currentFilter]] == [NSNumber numberWithInt:GPUImageMovieWriterStatusFinished]) {
                    NSLog(@"Playing From Memory");
                    [self playFileAtURL:assetURL];
                    [self preloadNextFilterwithPrevIndex:prevFilterIndex];
                }
                else {
//                    NSLog(@"waiting for kvo");
                }
            }
            else {
//                NSLog(@"waiting for kvo");
            }
        }
    } else {
//        NSLog(@"pc failed");
    }
}

#pragma page view controller datasource methods
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    
    int index = [(VCFilterBlockViewController *)viewController index];
    
    if (index == 0) {
        return [self viewControllerForFilterIndex:HIGHEST_FILTER_ENUM];
    }
    
    index--;
    
    return [self viewControllerForFilterIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    
    int index = [(VCFilterBlockViewController *)viewController index];
    
    if (index == HIGHEST_FILTER_ENUM) {
        return [self viewControllerForFilterIndex:0];
    }
    
    index++;
    
    return [self viewControllerForFilterIndex:index];
}

- (VCFilterBlockViewController *)viewControllerForFilterIndex:(int)index {
    
    VCFilterBlockViewController *childViewController = [[VCFilterBlockViewController alloc] init];
    childViewController.index = index;
    childViewController.filterName = [self stringOfFilterAtIndex:index];
    return childViewController;
}

- (void) createCompositionWithAssets:(NSMutableArray *)assets
{
    NSLog(@"CREATING INITIAL COMPOSITION");
    AVMutableComposition *composition = [AVMutableComposition composition];
    CMTime current = kCMTimeZero;
    NSError *compositionError = nil;
    for(AVAsset *asset in assets) {
        NSLog(@"tracks: %@", asset.tracks);
        BOOL result = [composition insertTimeRange:CMTimeRangeMake(kCMTimeZero, [asset duration])
                                           ofAsset:asset
                                            atTime:current
                                             error:&compositionError];
        if(!result) {
            if(compositionError) {
                // manage the composition error case
                NSLog(@"COMPOSITION ERROR <--- not really sure what to do with this.");
            }
        } else {
            //current = CMTimeAdd(current, CMTimeMultiply([asset duration], 0.99)); //prevents empty frames between assets from showing
            current = CMTimeAdd(current, [asset duration]); //prevents empty frames between assets from showing
        }
    }
    
//    PLAY CURRENT COMPOSITION (NO FILTERING)
    AVPlayerItem *compositionPlayerItem = [AVPlayerItem playerItemWithAsset:composition];
    AVPlayer *compositionPlayer = [AVPlayer playerWithPlayerItem:compositionPlayerItem];
    [compositionPlayer setMuted:NO];
    compositionPlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:[compositionPlayer currentItem]];
    self.viewer = [[VCClipViewer alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.viewer setPlayer:compositionPlayer];
    [self.view insertSubview:self.viewer atIndex:0];
    [self.viewer.player play];
    NSLog(@"INITIAL VIEWER ADDED");
    

//    EXPORT PLAIN COMPOSITION TO |self.compsitionURL|
    NSLog(@"EXPORTING INITIAL COMPOSITION TO FILE");
    AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:composition presetName:AVAssetExportPreset1280x720];
    [exportSession setOutputFileType:AVFileTypeQuickTimeMovie];
    self.compositionURL = [self setUpURLWithDescription:@"composition"];
    [exportSession setOutputURL:self.compositionURL];
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        NSLog(@"EXPORTED!  YOUR VIDEO CAN NOW BE FOUND AT '%@'", self.compositionURL);
        [self.swipeGestureRecognizer setEnabled:YES];
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            //[self filterVideoToURLForType:1];
//            //[self filterVideoToURLForType:HIGHEST_FILTER_ENUM];
//        });
    }];
}


- (NSURL *)filterVideoToURLForType:(int)type {
    if (type == 0) {
        NSLog(@"filter type was 0");
        return self.compositionURL;
    }
    
    NSURL *targetURL = [self generateFilterURLForFilterType:type];
    if ([self checkURLOccupied:targetURL]) {
        NSLog(@"filter type %i occupied", type);
        return targetURL;
    }
    
    NSLog(@"starting to filter number %i", type);
//    [self.pageViewController.view setUserInteractionEnabled:NO];
    
    NSString *key = [self writerProgressObjectKVCHelper:type];
    [self.writerProgressObject setValue:[NSNumber numberWithInt:GPUImageMovieWriterStatusWriting] forKey:key];
    
    movieFile = [[GPUImageMovie alloc] initWithURL:self.compositionURL];
    movieFile.runBenchmark = YES;
    movieFile.playAtActualSpeed = NO;
    filter = [self getFilterForType:type];
    
    [movieFile addTarget:filter];
    
    //Create asset writer (GPUImage calles it moviewriter)
    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:targetURL size:[UIScreen mainScreen].bounds.size];
    [filter addTarget:movieWriter];
    
    //Configure this for video from the movie file, where we want to preserve all video frames and audio samples
    movieWriter.shouldPassthroughAudio = YES;
    movieFile.audioEncodingTarget = movieWriter;
    [movieFile enableSynchronizedEncodingUsingMovieWriter:movieWriter];
//    [movieFile prepareForImageCapture]; //necessary?
    
    NSLog(@"starting to write to file");
    [movieWriter startRecording];
    [movieFile startProcessing];
    
//    need these weak references b/c of ARC retain warnings in the moviewriter completion block
    __weak GPUImageOutput<GPUImageInput> *_filter = filter;
    __weak GPUImageMovieWriter *_writer = movieWriter;
    __weak VCPostProcessingViewController *_controller = self;
    [movieWriter setCompletionBlock:^{
        NSLog(@"GPUImageMovieWriter Finished Writing");
        [_filter removeTarget:_writer];
//        [movieFile removeTarget:filter]; //necessary?
        [_writer finishRecordingWithCompletionHandler:^{
            NSLog(@"done recording filter %i", type);
            [_controller.writerProgressObject setValue:[NSNumber numberWithInt:GPUImageMovieWriterStatusFinished] forKey:key];
//            [_controller.pageViewController.view setUserInteractionEnabled:YES];
        }];
    }];
    
    return targetURL;
}

- (void) preloadNextFilterwithPrevIndex:(int)prevFilter
{
//    NSLog(@"loading");
    if (self.currentFilter > prevFilter && self.currentFilter!=HIGHEST_FILTER_ENUM) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self filterVideoToURLForType:self.currentFilter+1];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.currentFilter == 0) {
                [self filterVideoToURLForType:HIGHEST_FILTER_ENUM];
            } else {
                [self filterVideoToURLForType:self.currentFilter-1];
            }
        });
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
//    NSLog(@"Observing keypath: %@", keyPath);
    if ([keyPath isEqualToString:[self writerProgressObjectKVCHelper:self.currentFilter]]) { // <- MEANS THE VC WAS WAITING FOR THE FINISH
        if ([change objectForKey:NSKeyValueChangeNewKey] == [NSNumber numberWithInt:GPUImageMovieWriterStatusFinished]) { // && old key is initial/writing
//            NSLog(@"PLAYING FILE FROM OBSERVER");
            [self playFileAtURL:[self generateFilterURLForFilterType:self.currentFilter]];
            [self preloadNextFilterwithPrevIndex:self.previousFilterIndex];
        }
    }
//    ELSE -> MEANS THIS IS A PREWRITTEN ASSET
}


- (void)playFileAtURL:(NSURL *)url
{
    //PLAY FILE FOR GIVEN URL
//    NSLog(@"setting up video player");
    [[(VCFilterBlockViewController *)[self.pageViewController.viewControllers objectAtIndex:0] activityIndicatorView] stopAnimating];
    AVPlayer *compositionPlayer = [AVPlayer playerWithURL:url];
    [compositionPlayer setMuted:NO];
    compositionPlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:[compositionPlayer currentItem]];
    [self.viewer setPlayer:compositionPlayer];
    [self.viewer.player play];
    NSLog(@"playing file at url path: %@", url.path);
}

- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    //loop back to time=0 when video ends
    AVPlayerItem *player = [notification object];
    [player seekToTime:kCMTimeZero];
    if ([(VCFilterBlockViewController *)[self.pageViewController.viewControllers objectAtIndex:0] activityIndicatorView]) {
        [[(VCFilterBlockViewController *)[self.pageViewController.viewControllers objectAtIndex:0] activityIndicatorView] removeFromSuperview];
    }
}

- (NSURL *) setUpURLWithDescription:(NSString *)description {
    // Assemble a unique file URL for either a composition or export
    NSString *fileName = [NSString stringWithFormat:@"%@%i.mov", description, self.exportCount];
    NSLog(@"==========Video for current CapSesh will be written into:==================%@================", fileName);
    NSError* error = nil;
    NSURL *returnURL = [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:fileName];
    
    // Remove file from the path of the file URL, if one already exists there
    if([[NSFileManager defaultManager] fileExistsAtPath:returnURL.path]){
        [[NSFileManager defaultManager] removeItemAtURL:returnURL error:&error];
        NSLog(@"REMOVING FILE AT PATH: %@", returnURL.path);
    }
    return returnURL;
}

- (NSURL *)generateFilterURLForFilterType:(int) type
{
    if (type == 0) {
        return self.compositionURL;
    }
    // Assemble the file URL
    NSString *fileName = [NSString stringWithFormat:@"filter%i.mov", type];
    NSURL *returnURL = [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:fileName];
    
    return returnURL;
}

- (BOOL) checkURLOccupied:(NSURL *)url {
    // CHECK IF THERE IS ALREADY A FILE WRITTEN INTO THE URL
    if([[NSFileManager defaultManager] fileExistsAtPath:url.path]){
        NSLog(@"File already exists at %@", url.path);
        return YES;
    }
    NSLog(@"File unoccupied at %@", url.path);
    return NO;
}

- (void) removeFileAtURL:(NSURL *)url {
    // Remove file from the path of the file URL if one already exists there
    NSError* error = nil;
    if([[NSFileManager defaultManager] fileExistsAtPath:url.path]){
        [[NSFileManager defaultManager] removeItemAtURL:url error:&error];
        NSLog(@"REMOVING FILE AT URL %@", url);
    }
}

- (BOOL) saveVideoURLToUserDefaults:(NSURL *)url
{
//    NOTE --- SAVING URLS AS STRINGS.  WHEN LOADING, MUST RECREATE NSURL USING URLWITHSTRING()
    NSMutableArray *savedVideosArray = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"savedExports"]];  //get current array of urls from usr defs
    NSLog(@"Before Saving URL, video Count is: %lu", (unsigned long)savedVideosArray.count);
    [savedVideosArray addObject:[url absoluteString]];
    [[NSUserDefaults standardUserDefaults] setObject:savedVideosArray forKey:@"savedExports"];
    return [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSArray *) loadURLsFromUserDefautls
{
    //used to check if urls were saved correctly
    NSArray *savedVideosArray = [NSArray arrayWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"savedExports"]];
    return savedVideosArray;
}

- (void) cancelButtonPressed:(UIButton *) sender
{
    [self cleanUp:NO];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) saveButtonPressed:(UIButton *) sender
{
    int prev = (int)[self loadURLsFromUserDefautls].count;
    int target = prev + 1;
    [self cleanUp:YES];
    while (prev < target) //wait until defaults finishes saving current export, then pop vc
    {
        prev = (int)[self loadURLsFromUserDefautls].count;
    }
    [self.navigationController popToRootViewControllerAnimated:YES];
}

-(void)startTimer
{
    if (revealTimer == nil) {
//        NSLog(@"STARTING TIMER");
        self.activity = 4.0;
        revealTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                       target:self
                                                     selector:@selector(updateTimer)
                                                     userInfo:nil
                                                      repeats:YES];
    }
}

-(void)updateTimer{
//    NSLog(@"UPDATING TIMER");
    self.activity--;
    if (self.activity<=0) {
        if (self.pageViewControllerShowing) { //just making sure
//            NSLog(@"STOPPING TIMER");
            [UIView animateWithDuration:0.5 animations:^{
                [self.pageViewController.view setAlpha:0.0];
            }];
            [self setPageViewControllerShowing:NO];
            [self.swipeGestureRecognizer setEnabled:YES];
            [revealTimer invalidate];
            revealTimer = nil;
        } else {
            NSLog(@"ERROR WITH TIMER");
        }
    }
}

- (void) handleTap:(UITapGestureRecognizer *) sender
{
    //toggle the opacity of the navigation buttons
    [UIView beginAnimations:@"toggleButtons" context:nil];
    [UIView setAnimationDuration:0.5];
    if (self.cancelButton.alpha == 0.0f) {
        [self.cancelButton setAlpha:1.0f];
    } else {
        [self.cancelButton setAlpha:0.0f];
    }
    if (self.saveButton.alpha == 0.0) {
        [self.saveButton setAlpha:1.0];
    } else {
        [self.saveButton setAlpha:0.0];
    }
    [UIView commitAnimations];
}

- (void)handleSwipe:(UISwipeGestureRecognizer *) sender
{
    //toggle the opacity of the pageviewcontroller
    switch (sender.state) {
        case UIGestureRecognizerStateRecognized:
        {
            if (!self.pageViewControllerShowing) {
                [UIView animateWithDuration:0.5 animations:^{
                    [self.pageViewController.view setAlpha:1.0];
                }];
                [self setPageViewControllerShowing:YES];
                [sender setEnabled:NO];
                [self startTimer];
            }
            break;
        }
        default:
            break;
    }
}

- (void)cleanUpURLs
{
    GPUImageFilterType filterIterator = 0;
    while (filterIterator <= HIGHEST_FILTER_ENUM) {
        [self removeFileAtURL:[self generateFilterURLForFilterType:filterIterator]];
        filterIterator++;
    }
}

- (void) cleanUp:(BOOL)didSave;
{

//    EXPORT FILERED VIDEO TO NEW URL AND SAVE TO USER DEFAULTS
    if (didSave) {
        NSDictionary *optionsDictionary = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
        AVURLAsset *export = [AVURLAsset URLAssetWithURL:[self generateFilterURLForFilterType:self.currentFilter] options:optionsDictionary];
        NSLog(@"EXPORTING MOVIE TO FILE");
        AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:export presetName:AVAssetExportPreset1280x720];
        [exportSession setOutputFileType:AVFileTypeQuickTimeMovie];
        NSURL *destinationURL = [self setUpURLWithDescription:@"export"];
        [exportSession setOutputURL:destinationURL];
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            NSLog(@"EXPORTED FILTERED VIDEO TO URL: %@", destinationURL);
            if ([self saveVideoURLToUserDefaults:destinationURL]) {
                NSLog(@"FILTERED VIDEO SAVED TO USER DEFAUTLS");
                self.exportCount++; //once I implement navigation and filtering, only do this once the video is saved
                [[NSUserDefaults standardUserDefaults] setInteger:self.exportCount forKey:@"exportCount"];
                int rowCount = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"rowCount"];
                rowCount++;
                [[NSUserDefaults standardUserDefaults] setInteger:rowCount forKey:@"rowCount"];
                [[NSUserDefaults standardUserDefaults] synchronize];
//            DELETE ALL FILTERED VIDEO FILES FROM MEMORY
                [self cleanUpURLs];
            }
        }];
    } else {
        [self cleanUpURLs];
    }
    
//    REMOVE OBSERVERS
    GPUImageFilterType filterIterator = 1;
    while (filterIterator <= HIGHEST_FILTER_ENUM) {
        NSString *key = [self writerProgressObjectKVCHelper:filterIterator];
        [self.writerProgressObject removeObserver:self forKeyPath:key];
        filterIterator++;
    }
    
//    REMOVE PLAYER
    [self.viewer.player pause];
    [self.viewer removeFromSuperview];
    
    
//    REMOVE VIEWS AND RECOGNIZERS
    
//    SET PROPERTIES TO nil
    //includes wordlistobject roperties
    
    NSLog(@"cleanup done");
}



-(void) viewWillDisappear:(BOOL)animated
{
//    NSLog(@"VIEW DISAPEARRING");
    [UIView beginAnimations:@"toggleButtonAlphas" context:nil];
    [UIView setAnimationDuration:0.5];
    [[(VCNavigationController *)self.navigationController leftButton] setAlpha:1.0f];
    [[(VCNavigationController *)self.navigationController rightButton] setAlpha:1.0f];
    [UIView commitAnimations];
    
    [filter removeTarget:movieWriter];
    
    [self.cancelButton removeTarget:self action:@selector(cancelButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.saveButton removeTarget:self action:@selector(saveButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
}

- (NSString *)stringOfFilterAtIndex:(int)filterIndex
{
    //returns a string containing the name for a given filter
    switch (filterIndex) {
        case GPUImageFilterType_None:
        {
            return @"No Filter";
            break;
        }
        case GPUImageFilterType_Exposure:
        {
            return @"Exposure";
            break;
        }
        case GPUImageFilterType_RGB_Pink:
        {
            return @"Pink";
            break;
        }
        case GPUImageFilterType_RGB_Green:
        {
            return @"Green";
            break;
        }
        case GPUImageFilterType_ToneCurve_Yellow:
        {
            return @"Yellow";
            break;
        }
        case GPUImageFilterType_ToneCurve_Blue:
        {
            return @"Blue";
            break;
        }
            
        case GPUImageFilterType_Sepia:
        {
            return @"Sepia";
            break;
        }
        case GPUImageFilterType_Amatorka:
        {
            return @"Amatorka";
            break;
        }
        case GPUImageFilterType_MissEtikate:
        {
            return @"Etikate";
            break;
        }
        case GPUImageFilterType_SoftElegance:
        {
            return @"Soft Elegance";
            break;
        }
        case GPUImageFilterType_Pixellate:
        {
            return @"Pixellate";
            break;
        }
        case GPUImageFilterType_PolarPixellate:
        {
            return @"Polar Pixellate";
            break;
        }
        case GPUImageFilterType_PolkaDot:
        {
            return @"Dots";
            break;
        }
        case GPUImageFilterType_Halftone:
        {
            return @"Halftone";
            break;
        }
        case GPUImageFilterType_Toon:
        {
            return @"Toon";
            break;
        }
        case GPUImageFilterType_Emboss:
        {
            return @"Emboss";
            break;
        }
        case GPUImageFilterType_Vignette:
        {
            return @"Vignette";
            break;
        }
        default:
            return @"";
            break;
    }
}

- (id)getFilterForType:(int)filterType
{
    //returns a GPUImageOutput<GPUImageInput> for a given filter type
    switch (filterType) {
        case GPUImageFilterType_Exposure:
        {
            GPUImageOutput<GPUImageInput> *videoFilter = [[GPUImageExposureFilter alloc] init];
            [(GPUImageExposureFilter *)videoFilter setExposure:0.5];
            return videoFilter;
            break;
        }
        case GPUImageFilterType_RGB_Pink:
        {
            GPUImageOutput<GPUImageInput> *videoFilter = [[GPUImageRGBFilter alloc] init];
            [(GPUImageRGBFilter *)videoFilter setGreen:0.0];
            return videoFilter;
            break;
        }
        case GPUImageFilterType_RGB_Green:
        {
            GPUImageOutput<GPUImageInput> *videoFilter = [[GPUImageRGBFilter alloc] init];
            [(GPUImageRGBFilter *)videoFilter setGreen:2.0];
            return videoFilter;
            break;
        }
        case GPUImageFilterType_ToneCurve_Yellow:
        {
            GPUImageOutput<GPUImageInput> *videoFilter = [[GPUImageToneCurveFilter alloc] init];
            [(GPUImageToneCurveFilter *)videoFilter setBlueControlPoints:[NSArray arrayWithObjects:[NSValue valueWithCGPoint:CGPointMake(0.0, 0.0)],
                                                                          [NSValue valueWithCGPoint:CGPointMake(0.5, 0.0)],
                                                                          [NSValue valueWithCGPoint:CGPointMake(1.0, 0.75)], nil]];
            return videoFilter;
            break;
        }
        case GPUImageFilterType_ToneCurve_Blue:
        {
            GPUImageOutput<GPUImageInput> *videoFilter = [[GPUImageToneCurveFilter alloc] init];
            [(GPUImageToneCurveFilter *)videoFilter setBlueControlPoints:[NSArray arrayWithObjects:[NSValue valueWithCGPoint:CGPointMake(0.0, 0.0)],
                                                                          [NSValue valueWithCGPoint:CGPointMake(0.5, 1.0)],
                                                                          [NSValue valueWithCGPoint:CGPointMake(1.0, 0.75)], nil]];
            return videoFilter;
            break;
        }
        case GPUImageFilterType_Sepia:
        {
            GPUImageOutput<GPUImageInput> *videoFilter = [[GPUImageSepiaFilter alloc] init];
            return videoFilter;
            break;
        }
        case GPUImageFilterType_Amatorka:
        {
            GPUImageOutput<GPUImageInput> *videoFilter = [[GPUImageAmatorkaFilter alloc] init];
            return videoFilter;
            break;
        }
        case GPUImageFilterType_MissEtikate:
        {
            GPUImageOutput<GPUImageInput> *videoFilter = [[GPUImageMissEtikateFilter alloc] init];
            return videoFilter;
            break;
        }
        case GPUImageFilterType_SoftElegance:
        {
            GPUImageOutput<GPUImageInput> *videoFilter = [[GPUImageSoftEleganceFilter alloc] init];
            return videoFilter;
            break;
        }
        case GPUImageFilterType_Pixellate:
        {
            GPUImageOutput<GPUImageInput> *videoFilter = [[GPUImagePixellateFilter alloc] init];
            [(GPUImagePixellateFilter *)videoFilter setFractionalWidthOfAPixel:0.025];
            return videoFilter;
            break;
        }
        case GPUImageFilterType_PolarPixellate:
        {
            GPUImageOutput<GPUImageInput> *videoFilter = [[GPUImagePolarPixellateFilter alloc] init];
            [(GPUImagePolarPixellateFilter *)videoFilter setPixelSize:CGSizeMake(0.05, 0.05)];
            return videoFilter;
            break;
        }
        case GPUImageFilterType_PolkaDot:
        {
            GPUImageOutput<GPUImageInput> *videoFilter = [[GPUImagePolkaDotFilter alloc] init];
            [(GPUImagePolkaDotFilter *)videoFilter setFractionalWidthOfAPixel:0.025];
            return videoFilter;
            break;
        }
        case GPUImageFilterType_Halftone:
        {
            GPUImageOutput<GPUImageInput> *videoFilter = [[GPUImageHalftoneFilter alloc] init];
            [(GPUImageHalftoneFilter *)videoFilter setFractionalWidthOfAPixel:0.01];
            return videoFilter;
            break;
        }
        case GPUImageFilterType_Toon:
        {
            GPUImageOutput<GPUImageInput> *videoFilter = [[GPUImageToonFilter alloc] init];
            return videoFilter;
            break;
        }
        case GPUImageFilterType_Emboss:
        {
            GPUImageOutput<GPUImageInput> *videoFilter = [[GPUImageEmbossFilter alloc] init];
            [(GPUImageEmbossFilter *)videoFilter setIntensity:1.0];
            return videoFilter;
            break;
        }
        case GPUImageFilterType_Vignette:
        {
            GPUImageOutput<GPUImageInput> *videoFilter = [[GPUImageVignetteFilter alloc] init];
            [(GPUImageVignetteFilter *)videoFilter setVignetteEnd:0.75];
            return videoFilter;
            break;
        }
        default:
            return nil;
            break;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
