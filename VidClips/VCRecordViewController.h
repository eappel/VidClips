//
//  VCViewController.h
//  VidCam
//
//  Created by Eric Appel on 3/12/14.
//  Copyright (c) 2014 Eric Appel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <FRDLivelyButton.h>

typedef enum {
    RecordingStateInitial,
    RecordingStateRecording,
    RecordingStateFinishedRecording
}RecordingState;

@interface VCRecordViewController : UIViewController

/// The capture session for recording.
@property (nonatomic, strong) AVCaptureSession *captureSession;
/// The preview layer to display video input.
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
/// Recording State of the View Controller.
@property (nonatomic, assign) RecordingState recordingState;
/// Asset writer to the file.
@property (nonatomic, strong) AVAssetWriter *assetWriter;
/// Dispatch queue of assetWriter.
@property (nonatomic) dispatch_queue_t assetWritingQueue;
/// Indicates whether or not assetWriterAudioInput has been initialized sucessfully.
@property (nonatomic, assign) BOOL audioInputReady;
/// Indicates whether or not assetWriterVideoInput has been initialized sucessfully.
@property (nonatomic, assign) BOOL videoInputReady;
/// The audio input to the asset writer.
@property (nonatomic, strong) AVAssetWriterInput* assetWriterAudioInput;
/// The video input to the asset writer.
@property (nonatomic, strong) AVAssetWriterInput* assetWriterVideoInput;
/// Used to determine whether a sample buffer is from the assetWriterAudioInput.
@property (nonatomic, strong) AVCaptureConnection* audioConnection;
/// Used to determine whether a sample buffer is from the assetWriterVideoInput.
@property (nonatomic, strong) AVCaptureConnection* videoConnection;
/// The URL that the next or current video will be written into depending on the RecordingState.
@property (nonatomic, strong) NSURL *fileURL;
/// Array of the URLs of all the clips taken in the recording session.  These will be stitched togetheer in post-processing.
@property (nonatomic, strong) NSMutableArray *fileURLs;
/// The Shape Layer containing the recording timeline on the top of the screen. This path gets animated at every timer tick to show recording progress.
@property (nonatomic, weak) CAShapeLayer *pathLayer;
/// The current width of the recording timeline at the top of the screen (aka self.pathLayer). Indicates the starting point for the next progress animation.
@property (nonatomic, assign) float currentPoint;
/// Gesture recognizer delegating video recording. Records on touch down, stops recording on touch up.
@property (nonatomic, strong) UILongPressGestureRecognizer *recordGestureRecognizer;
/// Hides and shows the navigation buttons.  Alphas are animated in target, handleTap:.
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
/// The bottom right navigation button.  Only revealed once at least 1 second of video is recorded.  Pushes VCPostProcessingViewController.
@property (nonatomic, strong) FRDLivelyButton *doneButton;
/// The bottom left navigation button.  Pops to VCGalleryViewController.
@property (nonatomic, strong) FRDLivelyButton *galleryButton;

@end
