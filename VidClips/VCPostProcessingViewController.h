//
//  VCPostProcessingViewController.h
//  VidCam
//
//  Created by Eric Appel on 3/12/14.
//  Copyright (c) 2014 Eric Appel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VCNavigationController.h"
#import "VCClipViewer.h"
#import "VCFilterBlockViewController.h"
#import "VCMovieWriterProgressObject.h"
#import <AVFoundation/AVFoundation.h>
#import <GPUImage.h>
#import <FRDLivelyButton.h>

typedef enum {
    GPUImageFilterType_None,
    GPUImageFilterType_Exposure,
    GPUImageFilterType_RGB_Pink,
    GPUImageFilterType_RGB_Green,
    GPUImageFilterType_ToneCurve_Yellow,
    GPUImageFilterType_ToneCurve_Blue,
    GPUImageFilterType_Sepia,
    GPUImageFilterType_Amatorka,
    GPUImageFilterType_MissEtikate,
    GPUImageFilterType_SoftElegance,
    GPUImageFilterType_Pixellate,
    GPUImageFilterType_PolarPixellate,
    GPUImageFilterType_PolkaDot,
    GPUImageFilterType_Halftone,
    GPUImageFilterType_Toon,
    GPUImageFilterType_Emboss,
    GPUImageFilterType_Vignette
}GPUImageFilterType;

@interface VCPostProcessingViewController : UIViewController
{
    GPUImageMovie *movieFile;
    GPUImageOutput<GPUImageInput> *filter;
    GPUImageMovieWriter *movieWriter;
}

@property (nonatomic, strong) NSMutableArray *assets;
@property (nonatomic, assign) int exportCount;
@property (nonatomic, strong) NSURL *compositionURL;
@property (nonatomic, strong) NSURL *movieURL;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) VCMovieWriterProgressObject *writerProgressObject;
@property (nonatomic, strong) UIPageViewController *pageViewController;
@property (nonatomic, assign) GPUImageFilterType currentFilter;
@property (nonatomic, assign) BOOL pageViewControllerShowing;
@property (nonatomic, strong) UISwipeGestureRecognizer *swipeGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, strong) VCClipViewer *viewer;
@property (nonatomic, assign) int activity;
@property (nonatomic, strong) VCFilterBlockViewController *nextFilterBlockViewController;
@property (nonatomic, strong) VCFilterBlockViewController *currentFilterBlockViewController;
@property (nonatomic, assign) int previousFilterIndex;
@property (nonatomic, strong) FRDLivelyButton *cancelButton;
@property (nonatomic, strong) FRDLivelyButton *saveButton;

- (id)initWithClipsFromURLs:(NSMutableArray *) fileURLs;



@end
