//
//  VCGalleryViewController.m
//  VidClips
//
//  Created by Eric Appel on 3/17/14.
//  Copyright (c) 2014 Eric Appel. All rights reserved.
//

#import "VCGalleryViewController.h"
#import "VCSaveAndShareViewController.h"
#import "VCRecordViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <FRDLivelyButton.h>
#import "VCNavigationController.h"

@interface VCGalleryViewController ()

@property (nonatomic, assign) int rowCount;
@property (nonatomic, strong) FRDLivelyButton *recordButton;
@property (nonatomic, strong) UILabel *hintLabel;

@end

@implementation VCGalleryViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //// Text Drawing
    CGRect textRect = CGRectMake(10, (self.view.frame.size.height / 2) - 75, self.view.frame.size.width - 20, 150);
    self.hintLabel = [[UILabel alloc] initWithFrame:textRect];
    [self.hintLabel setText:@"You haven't saved any videos yet! \n\n If you have recorded a video and it is not showing, pull down to refresh."];
    [self.hintLabel setNumberOfLines:0];
    [self.hintLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [self.hintLabel setTextColor:[UIColor blackColor]];
    [self.hintLabel setTextAlignment:NSTextAlignmentCenter];
    [self.hintLabel setFont:[UIFont fontWithName: @"Futura-Medium" size: [UIFont buttonFontSize]]];
    
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];
}

- (void)viewWillAppear:(BOOL)animated
{
    [UIView beginAnimations:@"toggletheButtonAlphas" context:nil];
    [UIView setAnimationDuration:0.5];
    [[(VCNavigationController *)self.navigationController leftButton] setAlpha:0.0f];
    [[(VCNavigationController *)self.navigationController rightButton] setAlpha:1.0f];
    [UIView commitAnimations];
    
    self.recordButton = [(VCNavigationController *)self.navigationController rightButton];
    [self.recordButton setOptions:@{ kFRDLivelyButtonHighlightScale: @(0.5f),
                                     kFRDLivelyButtonLineWidth: @(4.0f),
                                     kFRDLivelyButtonHighlightedColor: [UIColor blackColor],
                                     kFRDLivelyButtonColor: [UIColor blackColor]
                                     }];
    
    [self.recordButton addTarget:self action:@selector(recordButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.recordButton setStyle:kFRDLivelyButtonStyleCirclePlus animated:YES];
    
    self.rowCount = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"rowCount"];
    
    [self.tableView reloadData];
    if (self.rowCount == 0) {
        [self.view addSubview:self.hintLabel];
    }
}

- (void) recordButtonPressed:(id) sender
{
    VCRecordViewController *recordViewController = [[VCRecordViewController alloc] init];
    [self.navigationController pushViewController:recordViewController animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) refresh:(UIRefreshControl *) sender {
    self.rowCount = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"rowCount"];
    NSLog(@"tableview refreshed");
    [self.tableView reloadInputViews];
    [self.tableView reloadData];
    [sender endRefreshing];
}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.rowCount;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 190;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 10;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    } else {
        for (UIView * view in cell.contentView.subviews){
            [view removeFromSuperview];
        }
    }
    [cell.contentView addSubview:[self generateThumbnailForRowAtIndexPath:indexPath]];
    [cell.contentView addSubview: [self generateLabelForRowAtIndexPath:indexPath]];
    return cell;
}

- (UILabel *)generateLabelForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *urlString = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"savedExports"] objectAtIndex:indexPath.row];
    NSURL *videoURL = [NSURL URLWithString:urlString];
    NSDictionary *optionsDictionary = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:optionsDictionary];
    NSDate *date = asset.creationDate.dateValue;
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"MM/dd/yyyy HH:mm"];
    NSString *dateString = [format stringFromDate:date];

    //// Text Drawing
    CGRect textRect = CGRectMake(0, 156, 310, 24);
    UILabel *dateLabel = [[UILabel alloc] initWithFrame:textRect];
    [dateLabel setText:dateString];
    [dateLabel setTextColor:[UIColor whiteColor]];
    [dateLabel setTextAlignment:NSTextAlignmentRight];
    [dateLabel setFont:[UIFont fontWithName: @"Avenir-Black" size: [UIFont buttonFontSize]]];
    
    return dateLabel;
}

- (UIView *)generateThumbnailForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *urlString = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"savedExports"] objectAtIndex:indexPath.row];
    NSURL *videoURL = [NSURL URLWithString:urlString];
    NSDictionary *optionsDictionary = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:optionsDictionary];
    AVAssetImageGenerator *thumbnailGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    CMTime actualTime;
//    CMTime time = kCMTimeZero;
    CMTime time = CMTimeMake(1, 2); // gets a thumbnail 0.5 seconds into video
    CGImageRef imgRef = [thumbnailGenerator copyCGImageAtTime:time actualTime:&actualTime error:nil];
    
    UIImage *image = [UIImage imageWithCGImage:imgRef];
    // Create rectangle from middle of current image
    CGRect croprect = CGRectMake(0, self.view.frame.size.height/3, self.view.frame.size.width, 180);
    
    // Draw new image in current graphics context
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], croprect);
    
    // Create new cropped UIImage
    UIImage *croppedImage = [UIImage imageWithCGImage:imageRef];
    UIImageView *croppedView = [[UIImageView alloc] initWithImage:croppedImage];
    
    return croppedView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *urlString = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"savedExports"] objectAtIndex:indexPath.row];
    NSURL *videoURL = [NSURL URLWithString:urlString];
    VCSaveAndShareViewController *sasViewController = [[VCSaveAndShareViewController alloc] initWithVideoFromURL:videoURL];
    [self.navigationController pushViewController:sasViewController animated:YES];
}

 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
     if (editingStyle == UITableViewCellEditingStyleDelete) {
         // Delete the row from the data source
         NSMutableArray *videoArray = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"savedExports"]];
         [videoArray removeObjectAtIndex:indexPath.row];
         NSArray *returnArray = [NSArray arrayWithArray:videoArray];
         [[NSUserDefaults standardUserDefaults] setObject:returnArray forKey:@"savedExports"];
         self.rowCount = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"rowCount"];
         self.rowCount--;
         [[NSUserDefaults standardUserDefaults] setInteger:self.rowCount forKey:@"rowCount"];
         if ([[NSUserDefaults standardUserDefaults] synchronize]) {
             [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
         }
     } else if (editingStyle == UITableViewCellEditingStyleInsert) {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
 }

- (void) viewWillDisappear:(BOOL)animated
{
    [UIView beginAnimations:@"toggleButtonAlphas" context:nil];
    [UIView setAnimationDuration:0.5];
    [[(VCNavigationController *)self.navigationController leftButton] setAlpha:1.0f];
    [UIView commitAnimations];
//    reset button to normal options
    [self.recordButton setOptions:@{ kFRDLivelyButtonHighlightScale: @(0.5f),
                                   kFRDLivelyButtonLineWidth: @(4.0f),
                                   kFRDLivelyButtonHighlightedColor: [UIColor blackColor],
                                   kFRDLivelyButtonColor: [UIColor whiteColor]
                                   }];
    [self.recordButton removeTarget:self action:@selector(recordButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.hintLabel removeFromSuperview];
}


/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

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
