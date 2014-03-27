//
//  VCCaptureProcessor.h
//  VidClips
//
//  Created by Eric Appel on 3/12/14.
//  Copyright (c) 2014 Eric Appel. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@protocol VCCaptureProcessorDelegate;

@interface VCCaptureProcessor : NSObject {
    id<VCCaptureProcessorDelegate> delegate;
}

@property (readwrite, assign) id<VCCaptureProcessorDelegate> delegate;

@end

@protocol VCCaptureProcessorDelegate <NSObject>
@required
- (void)pixelBufferReadyForDisplay:(CVPixelBufferRef)pixelBuffer;	// This method is always called on the main thread.
- (void)recordingWillStart;
- (void)recordingDidStart;
- (void)recordingWillStop;
- (void)recordingDidStop;
@end