//
//  VCSaveAndShareViewController.m
//  VidClips
//
//  Created by Eric Appel on 3/17/14.
//  Copyright (c) 2014 Eric Appel. All rights reserved.
//

#import "VCSaveAndShareViewController.h"
#import "VCClipViewer.h"
#import "VCNavigationController.h"
#import <AVFoundation/AVFoundation.h>
#import <FRDLivelyButton.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <MessageUI/MessageUI.h>

@interface VCSaveAndShareViewController () <MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate> {
    NSTimer *revealTimer;
}

@property (nonatomic, strong) NSURL *videoURL;

@property (nonatomic, strong) FRDLivelyButton *backButton;

@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;

@property (nonatomic, strong) UIButton *saveButton;
@property (nonatomic, strong) UIButton *messageButton;
@property (nonatomic, strong) UIButton *emailButton;

@property (nonatomic, assign) BOOL buttonsVisible;

@property (nonatomic, assign) int activity;

@end

@implementation VCSaveAndShareViewController

- (id)init
{
    return [self initWithVideoFromURL:nil];
}

- (id)initWithVideoFromURL:(NSURL *) fileURL
{
    self = [super init];
    if(self) {
        NSLog(@"_init: %@", self);
        if (fileURL == nil) {
            NSLog(@"ERROR -- No file url to fetch video");
        }
        else {
            NSLog(@"ASSET ARRAY NON EMPTY");
            self.videoURL = fileURL;
            NSLog(@"Video URL loaded as: %@", [self.videoURL absoluteString]);
        }
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSDictionary *optionsDictionary = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *videoAsset = [AVURLAsset URLAssetWithURL:self.videoURL options:optionsDictionary];
    AVPlayerItem *videoPlayerItem = [AVPlayerItem playerItemWithAsset:videoAsset];
    AVPlayer *videoPlayer = [AVPlayer playerWithPlayerItem:videoPlayerItem];
    [videoPlayer setMuted:NO];
    videoPlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:[videoPlayer currentItem]];
    
    VCClipViewer *viewer = [[VCClipViewer alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [viewer setPlayer:videoPlayer];
    [viewer.player play];
    [self.view addSubview:viewer];
    
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.view addGestureRecognizer:self.tapGestureRecognizer];
    [self.view setUserInteractionEnabled:YES];
    
    self.saveButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 64, 64)];
    [self.saveButton setBackgroundImage:[UIImage imageNamed:@"photos.png"] forState:UIControlStateNormal];
    [self.saveButton addTarget:self action:@selector(saveVideoToCameraRoll:) forControlEvents:UIControlEventTouchUpInside];
    [self.saveButton addTarget:self action:@selector(buttonTouchDown:) forControlEvents:UIControlEventTouchDown];
    [self.saveButton setCenter:CGPointMake(self.view.frame.size.width - self.saveButton.frame.size.width + 20, self.view.frame.size.height / 3.0f)];
    [self.view addSubview:self.saveButton];
    
    self.messageButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 64, 64)];
    [self.messageButton setBackgroundImage:[UIImage imageNamed:@"messages.png"] forState:UIControlStateNormal];
    [self.messageButton addTarget:self action:@selector(messageButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.messageButton addTarget:self action:@selector(buttonTouchDown:) forControlEvents:UIControlEventTouchDown];
    [self.messageButton setCenter:CGPointMake(self.view.frame.size.width - self.messageButton.frame.size.width + 20, self.view.frame.size.height / 2.0f)];
    [self.view addSubview:self.messageButton];
    
    self.emailButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 64, 64)];
    [self.emailButton setBackgroundImage:[UIImage imageNamed:@"mail.png"] forState:UIControlStateNormal];
    [self.emailButton addTarget:self action:@selector(emailButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.emailButton addTarget:self action:@selector(buttonTouchDown:) forControlEvents:UIControlEventTouchDown];
    [self.emailButton setCenter:CGPointMake(self.view.frame.size.width - self.emailButton.frame.size.width + 20, 2 * self.view.frame.size.height / 3.0f)];
    [self.view addSubview:self.emailButton];
    
    [self setButtonsVisible:YES];

}

- (void) viewWillAppear:(BOOL)animated
{
//    NSLog(@"VCSaveAndShareViewController will appear");
    [UIView beginAnimations:@"toggleRightButtonAlpha" context:nil];
    [UIView setAnimationDuration:0.5];
    [[(VCNavigationController *)self.navigationController rightButton] setAlpha:0.0f];
    [UIView commitAnimations];
    
    self.backButton = [(VCNavigationController *)self.navigationController leftButton];
    [self.backButton addTarget:self action:@selector(backButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.backButton setStyle:kFRDLivelyButtonStyleHamburger animated:YES];
    
    self.activity = 3;
    [self toggleTimer];
}

- (void)viewDidAppear:(BOOL)animated
{
//    NSLog(@"VCSaveAndShareViewController did appear");
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    AVPlayerItem *player = [notification object];
    [player seekToTime:kCMTimeZero];
}

- (void) handleTap:(UITapGestureRecognizer *) sender {
    [self toggleSaveAndShareButtons];
}

- (void) backButtonPressed:(UIButton *) sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) toggleSaveAndShareButtons
{
    [UIView beginAnimations:@"slidebuttons" context:nil];
    [UIView setAnimationDuration:0.2];
    if (self.buttonsVisible) {
        CGAffineTransform slideOut = CGAffineTransformMakeTranslation(84, 0);
        self.saveButton.transform = slideOut;
        self.messageButton.transform = slideOut;
        self.emailButton.transform = slideOut;
        [self setButtonsVisible:NO];
        [self toggleTimer];
    } else {
        CGAffineTransform slideIn = CGAffineTransformMakeTranslation(0, 0);
        self.saveButton.transform = slideIn;
        self.messageButton.transform = slideIn;
        self.emailButton.transform = slideIn;
        [self setButtonsVisible:YES];
        self.activity = 3;
        [self toggleTimer];
    }
    [UIView commitAnimations];
    
}

-(void) buttonTouchDown:(UIButton *) sender
{
    [UIView beginAnimations:@"scaledown" context:nil];
    [UIView setAnimationDuration:0.1];
    CGAffineTransform scaleDown = CGAffineTransformMakeScale(0.5f, 0.5f);
    sender.transform = scaleDown;
    [UIView commitAnimations];
}

-(void) buttonReScale:(UIButton *) sender
{
    [UIView beginAnimations:@"rescale" context:nil];
    [UIView setAnimationDuration:0.4];
    CGAffineTransform rescale = CGAffineTransformMakeScale(1.0f, 1.0f);
    sender.transform = rescale;
    [UIView commitAnimations];
}


- (void)saveVideoToCameraRoll:(UIButton *) sender
{
    NSLog(@"Save Button Pressed");
    [self buttonReScale:sender];
	ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
	[library writeVideoAtPathToSavedPhotosAlbum:self.videoURL
								completionBlock:^(NSURL *assetURL, NSError *error) {
									if (error) {
                                        CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
                                            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
                                                                                                message:[error localizedFailureReason]
                                                                                               delegate:nil
                                                                                      cancelButtonTitle:@"OK"
                                                                                      otherButtonTitles:nil];
                                            [alertView show];
                                        });
                                    } else {
                                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Success!"
                                                                                            message:@"Video Saved To Camera Roll"
                                                                                           delegate:nil
                                                                                  cancelButtonTitle:@"OK"
                                                                                  otherButtonTitles:nil];
                                        [alertView show];
                                    }
								}];
}

- (void)emailButtonPressed:(UIButton *)sender
{
    NSLog(@"Email Button Pressed");
    [self buttonReScale:sender];

    //initialize the mail compose view controller
    MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc] init];
    mailController.mailComposeDelegate = self;//this requires that this viewController declares that it adheres to <MFMailComposeViewControllerDelegate>, and implements a couple of delegate methods which we did not implement in class
    
    //set a subject for the email
    [mailController setSubject:@"Check out my awesome video!"];
    
    // get the image data and add it as an attachment to the email
    NSData *videoData = [NSData dataWithContentsOfURL:self.videoURL];
    [mailController addAttachmentData:videoData mimeType:@"video/quicktime" fileName:@"My Video"];
    
    // Show mail compose view controller
    [self presentViewController:mailController animated:YES completion:nil];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {//gets called after user sends or cancels
    
    //dismiss the mail compose view controller
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)messageButtonPressed:(UIButton *)sender
{
    NSLog(@"Message Button Pressed");
    [self buttonReScale:sender];

    if(![MFMessageComposeViewController canSendText]) {
        UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Your device doesn't support SMS" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [warningAlert show];
        return;
    }
    
    NSString *message = @"Check out my awesome video!";
    
    MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
    messageController.messageComposeDelegate = self;
    [messageController setBody:message];
    [messageController addAttachmentURL:self.videoURL withAlternateFilename:@"My Video"];
    
    // Present message view controller on screen
    [self presentViewController:messageController animated:YES completion:nil];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult) result
{
    switch (result) {
        case MessageComposeResultCancelled:
            break;
            
        case MessageComposeResultFailed:
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error!"
                                                                message:@"Unable To Send SMS"
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
            [alertView show];

            break;
        }
            
        case MessageComposeResultSent:
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Success!"
                                                                message:@"Video Sent"
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
            [alertView show];

            break;
        }
        default:
            break;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)toggleTimer{
    if (revealTimer == nil) {
//        NSLog(@"STARTING TIMER");
        self.activity = 3;
        revealTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                       target:self
                                                     selector:@selector(updateTimer)
                                                     userInfo:nil
                                                      repeats:YES];
    } else {
//        NSLog(@"STOPPING TIMER");
        [revealTimer invalidate];
        revealTimer = nil;
        self.activity = 0;
    }
}

-(void)updateTimer{
//    NSLog(@"UPDATING TIMER");
    
    self.activity--;
    
    if (self.activity<=0) {
        if (self.buttonsVisible) { //just making sure
//            NSLog(@"STOPPING TIMER");
            [self toggleSaveAndShareButtons];
            [revealTimer invalidate];
            revealTimer = nil;
        } else {
            NSLog(@"ERROR WITH TIMER");
        }
    }
}



- (void) viewWillDisappear:(BOOL)animated
{
    [UIView beginAnimations:@"toggleRigtButtonAlpha" context:nil];
    [UIView setAnimationDuration:0.5];
    [[(VCNavigationController *)self.navigationController rightButton] setAlpha:1.0f];
    [UIView commitAnimations];
    
    [self.backButton removeTarget:self action:@selector(backButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
