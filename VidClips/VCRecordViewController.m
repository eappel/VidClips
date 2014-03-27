//
//  VCViewController.m
//  VidCam
//
//  Created by Eric Appel on 3/12/14.
//  Copyright (c) 2014 Eric Appel. All rights reserved.
//

#import "VCRecordViewController.h"
#import "VCPostProcessingViewController.h"
#import "VCGalleryViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <FRDLivelyButton.h>
#import "VCNavigationController.h"

@interface VCRecordViewController () <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate> {
    NSTimer *recordingTimer;
    NSDate *lastDate;
    NSTimeInterval elapsed;
    BOOL isRunning;
}

@end

@implementation VCRecordViewController

- (void)viewDidLoad
{
//    NSLog(@"VCRecordViewController did load");
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor blackColor]];
    [self setBackgroundImage];
    [self.navigationController setNavigationBarHidden:YES];
}
- (void)viewWillAppear:(BOOL)animated
{
//    NSLog(@"VCRecordViewController will appear");
    
    self.fileURLs = [[NSMutableArray alloc] init];
    
    //Add gesture recognizers to screen
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.view addGestureRecognizer:self.tapGestureRecognizer];
    self.recordGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handlePress:)];
    [self.view setUserInteractionEnabled:YES];
    [self.view addGestureRecognizer:self.recordGestureRecognizer];
    
    //Initialize some instance vars and properties
    isRunning = FALSE;
    elapsed = 0.0f;
    self.currentPoint = 0.0f;
    
    //Animate navigation buttons to correct styles
    self.galleryButton = [(VCNavigationController *)self.navigationController leftButton];
    [self.galleryButton addTarget:self action:@selector(galleryButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.galleryButton setStyle:kFRDLivelyButtonStyleHamburger animated:YES];

    self.doneButton = [(VCNavigationController *)self.navigationController rightButton];
    [self.doneButton addTarget:self action:@selector(doneButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.doneButton setStyle:kFRDLivelyButtonStyleArrowRight animated:YES];
    [self.doneButton setAlpha:0.0f];
}

- (void)viewDidAppear:(BOOL)animated
{
//    NSLog(@"VCRecordViewController did appear");

    [self setUpCaptureSession]; // sets up audio and video inputs/outputs. creates preview layer. creates assset writing queue
    [self.captureSession startRunning];//start the flow of data
    
    // display instructions alert if this is the first time opening the app
    BOOL isFirstLaunch = [[NSUserDefaults standardUserDefaults] boolForKey:@"isFirstLaunch"];
    if (!isFirstLaunch) {
        NSString *message = @"To record a video, simply press and hold. You may record videos up to 5 seconds long, consisting of as many clips as you want. The minimum video length is 1 second. To reveal the navigation buttons, touch down with one finger.  Enjoy!";
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Welcome!"
                                                            message:message
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isFirstLaunch"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void) setBackgroundImage
{
    UIGraphicsBeginImageContext(CGSizeMake(100, 80));
    
    //// the following code was generated using PaintCode
    UIColor* color1 = [UIColor whiteColor];
    UIColor* color2 = [UIColor blackColor];
    
    UIBezierPath* roundedRectanglePath = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(0, 10, 65, 58) cornerRadius: 10];
    [[UIColor whiteColor] setFill];
    [roundedRectanglePath fill];
    
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(98.5, 0.5)];
    [bezierPath addLineToPoint: CGPointMake(65.5, 39.5)];
    [bezierPath addLineToPoint: CGPointMake(98.5, 78.5)];
    [bezierPath addLineToPoint: CGPointMake(98.5, 0.5)];
    [bezierPath closePath];
    [color1 setFill];
    [bezierPath fill];
    
    UIBezierPath* bezier2Path = [UIBezierPath bezierPath];
    [bezier2Path moveToPoint: CGPointMake(105.5, 12.5)];
    [bezier2Path addLineToPoint: CGPointMake(82.5, 39.5)];
    [bezier2Path addLineToPoint: CGPointMake(105.5, 66.5)];
    [bezier2Path addLineToPoint: CGPointMake(105.5, 12.5)];
    [bezier2Path closePath];
    [color2 setFill];
    [bezier2Path fill];
    
    UIBezierPath* roundedRectangle2Path = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(0, 17, 56, 44) cornerRadius: 10];
    [color2 setFill];
    [roundedRectangle2Path fill];
    
    UIImage *backgroundImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIImageView *imgview = [[UIImageView alloc] initWithImage:backgroundImage];
    [imgview setCenter:self.view.center];
    [self.view insertSubview:imgview atIndex:0];
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    [activityIndicator setCenter:CGPointMake(self.view.center.x - 20.0f, self.view.center.y)];
    [self.view insertSubview:activityIndicator atIndex:1];
    [activityIndicator startAnimating];
}

- (void) setUpCaptureSession
{
//    NSLog(@"SETUP CAPTURE SESSION");
    
    //CREATE CAPTURE SESSION AND SET PRESET
    self.captureSession = [[AVCaptureSession alloc] init];
    if (![self.captureSession canSetSessionPreset:AVCaptureSessionPresetHigh]) {
        if (![self.captureSession canSetSessionPreset:AVCaptureSessionPresetMedium]) {
            [self.captureSession setSessionPreset:AVCaptureSessionPresetLow];
        }
        else {
            [self.captureSession setSessionPreset:AVCaptureSessionPresetMedium];
        }
    }
    else {
        [self.captureSession setSessionPreset:AVCaptureSessionPresetHigh]; // default value, not really necessary to set explicitly
    }
    
    /*
     *Audio connection
     */
    //CREATE AUDIO INPUT
    AVCaptureDevice *microphone = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *microphoneInput = [AVCaptureDeviceInput deviceInputWithDevice:microphone error:nil];
    if ([self.captureSession canAddInput:microphoneInput])
        [self.captureSession addInput:microphoneInput];
    
    //CREATE AUDIO OUTPUT
    AVCaptureAudioDataOutput *audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    dispatch_queue_t audioCaptureQueue = dispatch_queue_create("edu.cornell.audioCaptureQueueName", DISPATCH_QUEUE_SERIAL); // audio dispatch queue
    [audioOutput setSampleBufferDelegate:self queue:audioCaptureQueue];
    if ([self.captureSession canAddOutput:audioOutput])
        [self.captureSession addOutput:audioOutput];
    self.audioConnection = [audioOutput connectionWithMediaType:AVMediaTypeAudio];
    
    /*
     *Video Connection
     */
    //CREATE VIDEO INPUT
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *captureDevice;
    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionFront) //get the front facing camera
            captureDevice = device;
    }
    AVCaptureDeviceInput *videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:captureDevice error:nil];
    if ([self.captureSession canAddInput:videoInput])
        [self.captureSession addInput:videoInput];
    
    //CREATE VIDEO OUTPUT
    AVCaptureVideoDataOutput *videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    [videoOutput setAlwaysDiscardsLateVideoFrames:YES];
    [videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    dispatch_queue_t videoCaptureQueue = dispatch_queue_create("edu.cornell.videoCaptureQueueName", DISPATCH_QUEUE_SERIAL); // video dispatch queue
	[videoOutput setSampleBufferDelegate:self queue:videoCaptureQueue];
	if ([self.captureSession canAddOutput:videoOutput])
		[self.captureSession addOutput:videoOutput];
	self.videoConnection = [videoOutput connectionWithMediaType:AVMediaTypeVideo];
    //set the orientation of the video into the videoDataOutput connection
    for ( AVCaptureConnection *connection in videoOutput.connections ) {
        for ( AVCaptureInputPort *port in [connection inputPorts] ) {
            if ( [[port mediaType] isEqual:AVMediaTypeVideo] ) {
                connection.videoOrientation = AVCaptureVideoOrientationPortrait;
            }
        }
    }
    
//    CREATE PREVIEW LAYER
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    self.previewLayer.frame = self.view.bounds;
    [self.view.layer insertSublayer:self.previewLayer atIndex:2];
    
//    CREATE ASSET WRITING QUEUE
    self.assetWritingQueue = dispatch_queue_create("edu.cornell.assetWritingQueueName", DISPATCH_QUEUE_SERIAL);
}

- (BOOL) setupAssetWriterAudioInput:(CMFormatDescriptionRef)currentFormatDescription
{
	const AudioStreamBasicDescription *currentASBD = CMAudioFormatDescriptionGetStreamBasicDescription(currentFormatDescription);
    
	size_t aclSize = 0;
	const AudioChannelLayout *currentChannelLayout = CMAudioFormatDescriptionGetChannelLayout(currentFormatDescription, &aclSize);
	NSData *currentChannelLayoutData = nil;
	
	// AVChannelLayoutKey must be specified, but if we don't know any better give an empty data and let AVAssetWriter decide.
	if ( currentChannelLayout && aclSize > 0 )
		currentChannelLayoutData = [NSData dataWithBytes:currentChannelLayout length:aclSize];
	else
		currentChannelLayoutData = [NSData data];
	
	NSDictionary *audioCompressionSettings = [NSDictionary dictionaryWithObjectsAndKeys:
											  [NSNumber numberWithInteger:kAudioFormatMPEG4AAC], AVFormatIDKey,
											  [NSNumber numberWithFloat:currentASBD->mSampleRate], AVSampleRateKey,
											  [NSNumber numberWithInt:64000], AVEncoderBitRatePerChannelKey,
											  [NSNumber numberWithInteger:currentASBD->mChannelsPerFrame], AVNumberOfChannelsKey,
											  currentChannelLayoutData, AVChannelLayoutKey,
											  nil];
	if ([self.assetWriter canApplyOutputSettings:audioCompressionSettings forMediaType:AVMediaTypeAudio]) {
		self.assetWriterAudioInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:audioCompressionSettings];
		self.assetWriterAudioInput.expectsMediaDataInRealTime = YES;
		if ([self.assetWriter canAddInput:self.assetWriterAudioInput])
			[self.assetWriter addInput:self.assetWriterAudioInput];
		else {
            NSLog(@"COULD NOT ADD ASSET WRITER AUDIO INPUT");
            return NO;
		}
	}
	else {
		NSLog(@"COULD NOT APPLY AUDIO OUTPUT SETTINGS");
        return NO;
	}
    return YES;
}

- (BOOL) setupAssetWriterVideoInput:(CMFormatDescriptionRef)currentFormatDescription
{
	float bitsPerPixel;
	CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(currentFormatDescription);
	int numPixels = dimensions.width * dimensions.height;
	int bitsPerSecond;
	
	// Assume that lower-than-SD resolutions are intended for streaming, and use a lower bitrate
	if ( numPixels < (640 * 480) )
		bitsPerPixel = 4.05; // This bitrate matches the quality produced by AVCaptureSessionPresetMedium or Low.
	else
		bitsPerPixel = 11.4; // This bitrate matches the quality produced by AVCaptureSessionPresetHigh.
	
	bitsPerSecond = numPixels * bitsPerPixel;
	
	NSDictionary *videoCompressionSettings = [NSDictionary dictionaryWithObjectsAndKeys:
											  AVVideoCodecH264, AVVideoCodecKey,
											  [NSNumber numberWithInteger:dimensions.width], AVVideoWidthKey,
											  [NSNumber numberWithInteger:dimensions.height], AVVideoHeightKey,
											  [NSDictionary dictionaryWithObjectsAndKeys:
											   [NSNumber numberWithInteger:bitsPerSecond], AVVideoAverageBitRateKey,
											   [NSNumber numberWithInteger:30], AVVideoMaxKeyFrameIntervalKey,
											   nil], AVVideoCompressionPropertiesKey,
											  nil];
	if ([self.assetWriter canApplyOutputSettings:videoCompressionSettings forMediaType:AVMediaTypeVideo]) {
		self.assetWriterVideoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:videoCompressionSettings];
		self.assetWriterVideoInput.expectsMediaDataInRealTime = YES;
		if ([self.assetWriter canAddInput:self.assetWriterVideoInput])
			[self.assetWriter addInput:self.assetWriterVideoInput];
		else {
            NSLog(@"COULD NOT ADD ASSET WRITER VIDEO INPUT");
            return NO;
		}
	}
	else {
		NSLog(@"COULD NOT APPLY VIDEO OUTPUT SETTINGS");
        return NO;
	}
    return YES;
}

- (void) writeSampleBuffer:(CMSampleBufferRef)sampleBuffer ofType:(NSString *)mediaType
{
	if ( self.assetWriter.status == AVAssetWriterStatusUnknown ) {
        if ([self.assetWriter startWriting]) {
//            NSLog(@"SUCCESSFULLY WRITING");
			CMTime startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            [self.assetWriter startSessionAtSourceTime:startTime];
		}
		else {
            NSLog(@"FAILED STARTING TO WRITE with: %@", [self.assetWriter error]);
		}
	}
	
	if ( self.assetWriter.status == AVAssetWriterStatusWriting ) {
//        NSLog(@"about to write video");
		if (mediaType == AVMediaTypeVideo) {
			if (self.assetWriterVideoInput.isReadyForMoreMediaData) {
				if (![self.assetWriterVideoInput appendSampleBuffer:sampleBuffer]) {
                    NSLog(@"vidfailed with: %@", [self.assetWriter error]);
				}
			}
		}
		else if (mediaType == AVMediaTypeAudio) {
//            NSLog(@"about to write audio");
			if (self.assetWriterAudioInput.isReadyForMoreMediaData) {
				if (![self.assetWriterAudioInput appendSampleBuffer:sampleBuffer]) {
                    NSLog(@"audfailed with: %@", [self.assetWriter error]);
				}
			}
		}
	}
}

- (void)processPixelBuffer: (CVImageBufferRef)pixelBuffer
{
    //Can use this method to filter video as it is being processed
    CVPixelBufferLockBaseAddress( pixelBuffer, 0 );
    
    int bufferWidth = (int) CVPixelBufferGetWidth(pixelBuffer);
    int bufferHeight = (int) CVPixelBufferGetHeight(pixelBuffer);
    unsigned char *pixel = (unsigned char *)CVPixelBufferGetBaseAddress(pixelBuffer);
    
    int bytesPerPixel = 4;
    for( int row = 0; row < bufferWidth; row++ ) {
        for( int column = 0; column < bufferHeight; column++ ) {
            //pixel[1] = greenValue; // De-green (second pixel in BGRA is green)
            pixel = pixel + bytesPerPixel;
        }
    }
    CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 );
}

- (void) captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
//    NSLog(@"got sample buffer, video count is %i", (int)self.fileURLs.count);

    if (elapsed >= 4.9) // the 0.1 accounts for timing delays on sample buffer processing threads
    {
        // Manually stop the capture session
        self.assetWriterAudioInput = nil;
        self.assetWriterVideoInput = nil;

        [self.assetWriterAudioInput markAsFinished];
        [self.assetWriterVideoInput markAsFinished];
        
        [self.recordGestureRecognizer setEnabled:NO];
    } else {
        if (connection == self.videoConnection) {
            CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);      // set pixelbuffer to current samplebuffer
            [self processPixelBuffer:pixelBuffer];     // synchronously process the pixel buffer.  
        }
        if (self.recordingState == RecordingStateRecording && self.assetWriter) {
//            NSLog(@"writing, %@, assetWriter status = %i", connection, (int)self.assetWriter.status);
            NSLog(@"writing");

            CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
            CFRetain(sampleBuffer); //needs to be retained otherwise it will be released before being written, since dispatch_async returns immediately
            dispatch_async(self.assetWritingQueue, ^{
                  {
                    if (connection == self.videoConnection) {
                        // Initialize the video input if this is not done yet
                        if (!self.videoInputReady)
                            self.videoInputReady = [self setupAssetWriterVideoInput:formatDescription];
                        
                        // Write video data to file
                        if (self.videoInputReady && self.audioInputReady)
                            [self writeSampleBuffer:sampleBuffer ofType:AVMediaTypeVideo];
                    }
                    else if (connection == self.audioConnection) {
                        // Initialize the audio input if this is not done yet
                        if (!self.audioInputReady)
                            self.audioInputReady = [self setupAssetWriterAudioInput:formatDescription];
                        
                        // Write audio data to file
                        if (self.audioInputReady && self.videoInputReady)
                            [self writeSampleBuffer:sampleBuffer ofType:AVMediaTypeAudio];
                    }
                }
                CFRelease(sampleBuffer);
            });
        }
    }
}

- (void) handleTap:(UITapGestureRecognizer *) sender
{
    if (elapsed > 1.0) {  // only show the done arrow if video is at least 1 second long
        [UIView beginAnimations:@"toggleDoneButtonAlpha" context:nil];
        [UIView setAnimationDuration:0.5];
        if (self.doneButton.alpha == 0.0f) {
            [self.doneButton setAlpha:1.0f];
        } else {
            [self.doneButton setAlpha:0.0f];
        }
        [UIView commitAnimations];
    }
    [UIView beginAnimations:@"toggleGalleryButtonAlpha" context:nil];
    [UIView setAnimationDuration:0.5];
    if (self.galleryButton.alpha == 0.0) {
        [self.galleryButton setAlpha:1.0];
    } else {
        [self.galleryButton setAlpha:0.0];
    }
    if (elapsed >= 4.9) {
        [self.doneButton setAlpha:1.0f];
        [self.galleryButton setAlpha:1.0];
    }
    [UIView commitAnimations];
}

- (void) handlePress: (UILongPressGestureRecognizer *) sender
{
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
        {
            NSLog(@"=============================begin recording=============================");
             //self.recordingState = RecordingStateRecording; // change recording state, start collecting sample buffers
            [self startRecording];
            [self toggleTimer];
            if (self.doneButton.alpha == 1.0f | self.galleryButton.alpha == 1.0f) {
                [self handleTap:self.tapGestureRecognizer];
            }
            break;
        }
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateEnded:
        {
            NSLog(@"=============================recording stopped=============================");
            [self pauseCaptureSession]; // calls [self stopRecording]
            [self toggleTimer];
            if (self.galleryButton.alpha == 0.0f) {
                [self handleTap:self.tapGestureRecognizer];
            }
            [self resumeCaptureSession];
            break;
        }
        default:
            break;
    }
}

- (UIBezierPath *)createPath
{
    //Creates a new path for the recording indicator / timeline at the top of the screen.
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(self.currentPoint, 3)];
    [bezierPath addLineToPoint: CGPointMake(self.currentPoint +2, 3)];
    return bezierPath;
}

- (UIBezierPath *)updatePath:(UIBezierPath *)currentPath;
{
    [currentPath addLineToPoint:CGPointMake(self.currentPoint +2, 3)];
    return currentPath;
}

- (void)startAnimation
{
    if (self.pathLayer == nil)
    {
        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        
        shapeLayer.path = [[self createPath] CGPath];
        shapeLayer.strokeColor = [[UIColor whiteColor] CGColor];
        shapeLayer.fillColor = nil;
        shapeLayer.lineWidth = 6.0f;
        shapeLayer.lineJoin = kCALineCapSquare;
        
        [self.view.layer addSublayer:shapeLayer];
        self.pathLayer = shapeLayer;
    } else
    {
        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        
        UIBezierPath *currentPath = [UIBezierPath bezierPathWithCGPath:self.pathLayer.path];
        shapeLayer.path = [[self updatePath:currentPath] CGPath];
        shapeLayer.strokeColor = [[UIColor whiteColor] CGColor];
        shapeLayer.fillColor = nil;
        shapeLayer.lineWidth = 6.0f;
        shapeLayer.lineJoin = kCALineCapSquare;
        
        [self.view.layer addSublayer:shapeLayer];
        self.pathLayer = shapeLayer;
    }
    
    CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    pathAnimation.duration = 1.0f/30.0f;
    pathAnimation.fromValue = @(0.0f);
    pathAnimation.toValue = @(1.0f);
    [self.pathLayer addAnimation:pathAnimation forKey:@"strokeEnd"];
    self.currentPoint = self.currentPoint + 2.1;
}


-(void)toggleTimer
{
//    NSLog(@"TOGGLE TIMER, isRecording is: %d", isRunning);
    //Creates a new timer if timer is not already running.  Stops and invalidates the current timer if already running.
    if(!isRunning){
        isRunning = TRUE;
        if (recordingTimer == nil) {
            lastDate = [NSDate date];
            recordingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/30.0
                                                         target:self
                                                       selector:@selector(updateTimer)
                                                       userInfo:nil
                                                        repeats:YES];
        }
    } else{
        isRunning = FALSE;
        [recordingTimer invalidate];
        recordingTimer = nil;
        self.currentPoint = self.currentPoint + 2;
        self.pathLayer = nil;
    }
}

-(void)updateTimer
{
//    NSLog(@"update time");
    [self startAnimation];
    NSDate *currentDate = [NSDate date];
    NSTimeInterval timeInterval = [currentDate timeIntervalSinceDate:lastDate];
    elapsed = elapsed + timeInterval;
    lastDate = [NSDate date];
}

- (NSURL *) setupURL
{
    // Assemble the file URL for a new video clip
    NSString *fileName = [NSString stringWithFormat:@"video%i.mov", (int)self.fileURLs.count];
    NSLog(@"==========Video for current Capture Session will be written into:==================%@================", fileName);
    NSError* error = nil;
    NSURL *returnURL = [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:fileName];
    
    // Remove file from the path of the file URL, if one already exists there
    if([[NSFileManager defaultManager] fileExistsAtPath:returnURL.path]){
        [[NSFileManager defaultManager] removeItemAtURL:returnURL error:&error];
//        NSLog(@"REMOVING FILE AT PATH %@", returnURL.path);
    }
    return returnURL;
}

- (void) pauseCaptureSession
{
    NSLog(@"PAUSE CAPTURE SESSION");
	if ( self.captureSession.isRunning )
		[self.captureSession stopRunning];
    dispatch_async(self.assetWritingQueue, ^{
		if (self.recordingState == RecordingStateRecording) {
			[self stopRecording];
		}
	});
}

- (void) resumeCaptureSession
{
    NSLog(@"RESUME CAPTURE SESSION");
	if ( !self.captureSession.isRunning )
		[self.captureSession startRunning];
        self.recordingState = RecordingStateInitial;
}

- (void) stopAndTearDownCaptureSession
{
    NSLog(@"STOP AND TEAR DOWN CAPTURE SESSION");
    [self.captureSession stopRunning];
    self.captureSession = nil;
    [self.previewLayer removeFromSuperlayer];
    self.previewLayer = nil;
	if (self.assetWritingQueue) {
		self.assetWritingQueue = nil;
	}
}

- (void) startRecording
{
    //initialize assetwriter with correct fileURL if not recording, sets recording state to recording.
    NSLog(@"START RCORDING");
	dispatch_async(self.assetWritingQueue, ^{
        NSLog(@"writing queue");
        if ( self.recordingState != RecordingStateInitial ) {
            NSLog(@"ERROR--TRIED TO START RECORDING WHEN RECORDING STATE NOT INITIAL");
            return;
        }
        
        // Remove the file if one with the same name already exists
        self.fileURL = [self setupURL];
        
        // Create an asset writer
        NSError* assetWriterError = nil;
        self.assetWriter = [[AVAssetWriter alloc] initWithURL:self.fileURL fileType:AVFileTypeQuickTimeMovie error:&assetWriterError];
        if(assetWriterError){
            NSLog(@"Instantiating asset writer failed with error: %@", assetWriterError);
        }else {
            NSLog(@"Asset writer was succesfully instantiated");
        }
        self.recordingState = RecordingStateRecording;
	});
}

- (void) stopRecording
{
    NSLog(@"STOP RECORDING");
	dispatch_async(self.assetWritingQueue, ^{
        //finish asset writing
        [self.assetWriter finishWritingWithCompletionHandler:^{
            NSLog(@"finished writing");
            self.assetWriter = nil;
            self.audioInputReady = NO;
            self.videoInputReady = NO;
            self.recordingState = RecordingStateFinishedRecording;
            NSURL *temp = [[NSURL alloc] initFileURLWithPath:self.fileURL.path];
            [self.fileURLs addObject:temp];
            NSDictionary *optionsDictionary = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
            AVURLAsset *fileAsset = [AVURLAsset URLAssetWithURL:temp options:optionsDictionary];
            NSLog(@"media tracks are: %@", fileAsset.tracks);
        }];
	});
}

- (void) doneButtonPressed:(id)sender {
    VCPostProcessingViewController *postProcessingViewController = [[VCPostProcessingViewController alloc] initWithClipsFromURLs:self.fileURLs];
    [postProcessingViewController setModalTransitionStyle:UIModalTransitionStyleCrossDissolve];
    [self.navigationController pushViewController:postProcessingViewController animated:YES];
}

- (void) galleryButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

-(void) viewWillDisappear:(BOOL)animated
{
    //stop capture session
    [self stopAndTearDownCaptureSession];
    //remove timeline
    NSMutableArray *layerArray = [[NSMutableArray alloc] init];
    for (CALayer *layer in [self.view.layer sublayers]) {
        if ([layer isMemberOfClass:[CAShapeLayer class]]) {
            [layerArray addObject:layer];
        }
    }
    for (CALayer *layer in layerArray) {
        [layer removeFromSuperlayer];
    }
    //remove button targets
    [self.galleryButton removeTarget:self action:@selector(galleryButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.doneButton removeTarget:self action:@selector(doneButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
}

@end
