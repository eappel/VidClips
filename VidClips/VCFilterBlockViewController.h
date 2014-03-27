//
//  VCFilterBlockViewController.h
//  VidClips
//
//  Created by Eric Appel on 3/19/14.
//  Copyright (c) 2014 Eric Appel. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VCFilterBlockViewController : UIViewController

@property (nonatomic, assign) int index;
@property (nonatomic, strong) NSString *filterName;

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;


@end
