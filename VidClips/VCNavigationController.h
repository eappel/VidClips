//
//  VCNavigationController.h
//  VidClips
//
//  Created by Eric Appel on 3/13/14.
//  Copyright (c) 2014 Eric Appel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FRDLivelyButton.h>

@interface VCNavigationController : UINavigationController

@property (nonatomic, strong) FRDLivelyButton *leftButton;
@property (nonatomic, strong) FRDLivelyButton *rightButton;

@end
