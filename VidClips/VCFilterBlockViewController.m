//
//  VCFilterBlockViewController.m
//  VidClips
//
//  Created by Eric Appel on 3/19/14.
//  Copyright (c) 2014 Eric Appel. All rights reserved.
//

#import "VCFilterBlockViewController.h"

@interface VCFilterBlockViewController ()

@end

@implementation VCFilterBlockViewController

- (id)initWithFilterName:(NSString *)filterName;
{
    [self setFilterName:filterName];
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
    
    [self setupView];
}

- (void)setupView
{
    UIGraphicsBeginImageContext(self.view.frame.size);

    UIColor* color = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 1];
    UIColor* color2 = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 0.175];
    
    CGRect rectangleRect = CGRectMake(40, 224, 240, 120);
    
    UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRect: rectangleRect];
    [color2 setFill];
    [rectanglePath fill];
    [color setStroke];
    rectanglePath.lineWidth = 2;
    [rectanglePath stroke];
    
    UIImage *blockImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    UIImageView *blockImageView = [[UIImageView alloc] initWithImage:blockImage];
    
    self.view = blockImageView;
    
    CGRect textRect = CGRectMake(50, 258, 220, 52);
    UILabel *filterLabel = [[UILabel alloc] initWithFrame:textRect];
    [filterLabel setText:self.filterName];
    [filterLabel setTextAlignment:NSTextAlignmentCenter];
    [filterLabel setTextColor:[UIColor whiteColor]];
    
    int fontSize = 40;
    UIFont* textFont = [UIFont fontWithName: @"Helvetica-Light" size: fontSize];
    NSDictionary *attributes = @{ NSFontAttributeName: textFont};
    CGSize size = [filterLabel.text sizeWithAttributes:attributes];//get size of text
    while (size.width > 220) {
        fontSize--;
        textFont = [UIFont fontWithName: @"Helvetica-Light" size: fontSize];
        attributes = @{ NSFontAttributeName: textFont};
        size = [filterLabel.text sizeWithAttributes:attributes];
    }
    [filterLabel setFont:textFont];
    
    [self.view addSubview:filterLabel];
    
    self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(150, 315, 20, 20)];
}

- (void)viewWillAppear:(BOOL)animated
{
    if (self.index!=0) {
        [self.view addSubview:self.activityIndicatorView];
        [self.activityIndicatorView startAnimating];
    }
}

- (void) viewDidDisappear:(BOOL)animated
{
    [self.activityIndicatorView removeFromSuperview];

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
