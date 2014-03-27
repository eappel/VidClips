//
//  VCNavigationController.m
//  VidClips
//
//  Created by Eric Appel on 3/13/14.
//  Copyright (c) 2014 Eric Appel. All rights reserved.
//

#import "VCNavigationController.h"

@interface VCNavigationController ()

@end

@implementation VCNavigationController

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
//    [self setNavigationBarHidden:YES]; // doesnt do anything
    
    self.leftButton = [[FRDLivelyButton alloc] initWithFrame:CGRectMake(10,self.view.frame.size.height - 38 ,36,28)];
    self.rightButton = [[FRDLivelyButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 46,self.view.frame.size.height - 38 ,36,28)];
    
    [self.leftButton setOptions:@{ kFRDLivelyButtonHighlightScale: @(0.5f),
                                 kFRDLivelyButtonLineWidth: @(4.0f),
                                 kFRDLivelyButtonHighlightedColor: [UIColor blackColor],
                                 kFRDLivelyButtonColor: [UIColor whiteColor]
                                 }];
    [self.rightButton setOptions:@{ kFRDLivelyButtonHighlightScale: @(0.5f),
                                   kFRDLivelyButtonLineWidth: @(4.0f),
                                   kFRDLivelyButtonHighlightedColor: [UIColor blackColor],
                                   kFRDLivelyButtonColor: [UIColor whiteColor]
                                   }];
    
    [self.view addSubview:self.leftButton];
    [self.view addSubview:self.rightButton];
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
