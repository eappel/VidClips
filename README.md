# README

This is my final project for CS 2049 - Intermediate iOS Development.  It was built in a week and a half so it is still pretty fragile.  For a list of known bugs, [click here](https://github.com/eappel/VidClips#bugs). 

##RUNNING THE PROJECT
This project uses cocoa pods, so make sure to build from the workspace file, not the xcodeproj.  

####3rd party libraries used:  
[GPUImage](https://github.com/BradLarson/GPUImage) to filter recorded videos in post-processing  
[FRDLivelyButton](https://github.com/sebastienwindal/FRDLivelyButton) to animate navigation buttons between views

##DESIGN

###[VCAppDelegate](https://github.com/eappel/VidClips/blob/master/VidClips/VCAppDelegate.m)
The app delegate creates the navigation controller and sets up its view controller hierarchy.

###[VCNavigationController](https://github.com/eappel/VidClips/blob/master/VidClips/VCNavigationViewController.m)
This UINavigationController subclass enables customization of the navigation buttons to work with [FRDLivelyButton](https://github.com/sebastienwindal/FRDLivelyButton).  In `viewDidLoad`, two buttons (leftButton & rightButton) are initialized and added to the view.  The child view controllers then use the `leftButton` and `rightButton` properties of VCNavigationController to dynamically set the button styles. The one drawback to this method is that it limits the button appearance to the built-in button styles of the library.

###[VCGalleryViewController](https://github.com/eappel/VidClips/blob/master/VidClips/VCGalleryViewController.m)
The gallery view controller relies on user defaults to fetch the number of videos the user has saved. The `generateThumbnailForRowAtIndexPath` and `generateLabelForRowAtIndexPath` methods are used to generate the appropriate background image and timestamp label for each cell. 

###[VCSaveAndShareViewController](https://github.com/eappel/VidClips/blob/master/VidClips/VCSaveAndShareViewController.m)
This ViewController gets initialized with a video url from the `didSelectRowAtIndexPath` delegate method in VCGalleryViewController. It uses an `AVPlayer` wrapped in a `UIView` to play and loop the video.  From this screen users can save the video to their photo library, attach it in an email, or send it in a text message.

###[VCRecordViewController](https://github.com/eappel/VidClips/blob/master/VidClips/VCRecordViewController.m)
This ViewController handles recording videos and is heavily based on [Apple’s RosyWriter](https://developer.apple.com/library/ios/samplecode/RosyWriter/Introduction/Intro.html).  When the view appears, `setUpCaptureSession` creates a new capture session and adds audio and video inputs/outputs to the session.  The method also adds a preview layer to the view.  When a user touches and holds down anywhere on the screen, the app starts recording a new video clip to a file.  On touch up, the url is stored in an array, which gets passed to VCPostProcessingViewController when the user is ready to edit the video.  Lastly, a `NSTimer` is used to keep track of how much time has elapsed and limits the cumulative duration of all the recorded clips to 5 seconds long.

###[VCPostProcessingViewController](https://github.com/eappel/VidClips/blob/master/VidClips/VCPostProcessingViewController.m)
This ViewController handles filtering and saving videos.  A `UIPageViewController` is used to handle swiping between different filters.  When a user swipes to a new filter, `preloadNextFilterwithPrevIndex` determines the next filter in the stack and starts processing it to a new file.  If processing finishes before the user swipes to the next filter, that next filter is played from the `pageViewController:didFinishAnimating:` delegate method.  However, if the user swipes to the next filter before it is finished being processed, `observeValueForKeyPath:ofObject:` handles playing the filtered version when the assetWriter is done processing.  To make this work, a VCMovieWriterProgressObject is used to add key-value observers in `viewDidAppear` for each filter type.  As a result, we can monitor whether a file is finished or still being written when the pageViewController animates. If you are wondering why it matters whether or not the assetWriter is finished writing, in order to play a video it needs to be done processing; since AVPlayer is initialized with the video asset, we need to make sure the video asset isn't still being changed when we go to play it.  
  
Each new filter is saved to a unique file so we only need to process the original video one time per filter. These files are saved so long as the user stays on the processing screen. So in the worst case scenario, if the user swipes through all 15 filters, VidClips will have 16 variations of the movie file (including the non-filtered version) stored in memory. When the user cancels or saves the video, these files are cleared from memory in `viewWillDissapear`.

##BUGS

01. Filter Freezing — This bug occurs in VCPostProcessingViewController when the GPUImageWriter freezes and doesn’t finish processing a filtered video.  This bug can be identified when the console logs a bunch of lines in the format - "Current frame time : 7.265985 ms" - that are not followed by “GPUImageMovieWriter Finished Writing”. A couple of factors can contribute to this bug including swiping the PageViewController too fast and recording longer videos. I’ve spent a couple hours trying to figure out how to prevent this and as far as I can tell, it’s a bug within the GPUImage framework. However, it's entirely possible that there is a threading issue on my end. The app breaks when this bug occurs because it relies on the completion handler of the assetWriter (called `movieWriter` in the file) to change the asset writing status. So, if the assetWriter never finishes writing, the completion block is never executed, resulting in filters never get played.  Canceling the video and re-recording should fix this.  To minimize the likelihood of running into this bug, record shorter videos and don’t try changing the filters too quickly.

02. Blank or Black Thumbnails — Occasionally, the `generateThumbnailForRowAtIndexPath` method will generate blank or entirely black thumbnail frames. I have some ideas on how to ensure that this doesn’t happen but I haven't had time to implement them yet.  If you save a video and don't see it in the gallery, try tapping the area where it should be to see if a blank thumbnail was created.

These are the major bugs I found myself running into when testing the app. If you run into these, try restarting the app or deleting it from your phone and re-compile it. Also, please note that I've only tested on a 5s so if you are using an earlier model iPhone, you may run into additional bugs.

##License
    The MIT License (MIT)

    Copyright (c) 2014 Eric Appel

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.