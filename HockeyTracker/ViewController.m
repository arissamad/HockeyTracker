//
//  ViewController.m
//  HockeyTracker
//
//  Created by Aris Samad Yahaya on 7/19/14.
//  Copyright (c) 2014 Sir Apps-a-Lot. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController {
    AVCaptureSession *captureSession;
    AVCaptureDevice *cameraDevice;
    AVCaptureDevice *micDevice;
    
    AVCaptureMovieFileOutput *captureOutput;
    AVCaptureStillImageOutput *stillImageOutput;
    
    NSURL *folderUrl;
    NSDateFormatter *dateFormatter;
    NSString *videoFilePath;
    
    CGColorSpaceRef rgbColorSpace;
    
    CapturedImage *capturedImage;
    ZoomedImage *zoomedImage;
    
    ColorPatch *colorPatch1;
    ColorPatch *colorPatch2;
    
    SColor *touchColor;
    
    TonePlayer *tonePlayer;
    
    NSInteger frequency;
    
    BOOL loop;
    
    NSDate *previousLoop;
    NSDate *preAsync;
    
    int currDirection;
    
    BOOL isLocked;
    
    DataHolder *dataHolder;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    currDirection = 0;
    isLocked = NO;
    dataHolder = [DataHolder new];
    
    tonePlayer = [TonePlayer new];
    [tonePlayer setup];
    
    rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    colorPatch1 = [ColorPatch new];
    [colorPatch1 setView:self.color1View];
    
    capturedImage = [CapturedImage new];
    [capturedImage setup:self.binaryView];
    
    zoomedImage = [ZoomedImage new];
    [zoomedImage setup:self.snapshotView];
    
    [self.snapshotView setUserInteractionEnabled:YES];
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapGestureCaptured:)];
    //Default value for cancelsTouchesInView is YES, which will prevent buttons to be clicked
    //singleTap.cancelsTouchesInView = NO;
    [self.snapshotView addGestureRecognizer:singleTap];
    
    
    captureSession = [AVCaptureSession new];
    captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    
    cameraDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] firstObject];
    NSLog(@"Selected video device: %@", [cameraDevice localizedName]);
    
    micDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
    NSLog(@"Selected mic device: %@", [micDevice localizedName]);
    
    NSError *nsError;
    
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:cameraDevice error:&nsError];
    [captureSession addInput:deviceInput];
    
    AVCaptureDeviceInput *micInput = [AVCaptureDeviceInput deviceInputWithDevice:micDevice error:&nsError];
    [captureSession addInput:micInput];
    
    stillImageOutput = [AVCaptureStillImageOutput new];
    [captureSession addOutput:stillImageOutput];
    
    captureOutput = [AVCaptureMovieFileOutput new];
    [captureSession addOutput:captureOutput];
    
    // Movie file needs correct orientation
    AVCaptureConnection *videoConnection = nil;
    
    for ( AVCaptureConnection *connection in [captureOutput connections] )
    {
        for ( AVCaptureInputPort *port in [connection inputPorts] )
        {
            if ( [[port mediaType] isEqual:AVMediaTypeVideo] )
            {
                videoConnection = connection;
            }
        }
    }
    
    if([videoConnection isVideoOrientationSupported]) // **Here it is, its always false**
    {
        [videoConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
    }
    
    // Now make video file path
    folderUrl = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
    
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd_HH-mm-ss"];
    
    // Prepare video preview
    AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:captureSession];
    
    AVCaptureConnection *previewLayerConnection= previewLayer.connection;
    
    if ([previewLayerConnection isVideoOrientationSupported]) {
        [previewLayerConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
    }
    
    
    [previewLayer setFrame:self.mainVideoView.bounds];
    [[self.mainVideoView layer] addSublayer:previewLayer];
    
    // Start capture session
    [captureSession startRunning];
    
    previousLoop = [NSDate date];
    
    
    NSArray *codecs = [stillImageOutput availableImageDataCodecTypes];
    
    for(int i=0; i<codecs.count; i++) {
        NSLog(@"Codecs: %@", codecs[i]);
    }
    
    NSArray *formats = [stillImageOutput availableImageDataCVPixelFormatTypes];
    for(int i=0; i<formats.count; i++) {
        NSLog(@"Formats: %@", formats[i]);
    }
    
    NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA], (id)kCVPixelBufferPixelFormatTypeKey, nil];
    
    //stillImageOutput.outputSettings = outputSettings;

    
    NSLog(@"Initialized");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)clickedStart {
    NSLog(@"Clicked start");
    
    NSString *dateStr = [dateFormatter stringFromDate:[NSDate date]];
    NSString *nameStr = [NSString stringWithFormat:@"mymovie-%@.mov", dateStr];
    NSURL *finalUrl = [folderUrl URLByAppendingPathComponent:nameStr];
    NSLog(@"New video path is %@", [finalUrl path]);

    videoFilePath = finalUrl.path;

    self.statusLabel.text = [NSString stringWithFormat:@"Path: %@", nameStr];
    
    loop = YES;
    [captureOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:videoFilePath] recordingDelegate:self];
    
    // Don't let iPhone go to sleep
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    
    [self autoCaptureImage];
}

- (IBAction)clickedStop {
    NSLog(@"Clicked stop");
    
    loop = NO;
    [captureOutput stopRecording];
    [self saveFile:videoFilePath];
    [UIApplication sharedApplication].idleTimerDisabled = NO;

    [tonePlayer stop];
    
    // Do another stop 1 second later, in case the other capture loop asynchronously fired.
    [tonePlayer performSelector:@selector(stop) withObject:tonePlayer afterDelay:1.0];
}

- (IBAction)clickedCapture {
    [self manualCaptureImage];
}

- (IBAction)clickedLock {
    
    NSError *error = nil;
    if(isLocked == NO) {
        isLocked = YES;
        [_lockLabel setTitle:@"Unlock" forState:UIControlStateNormal];
        
        if ([cameraDevice lockForConfiguration:&error]) {
            [cameraDevice setExposureMode:AVCaptureExposureModeLocked];
            [cameraDevice setWhiteBalanceMode:AVCaptureWhiteBalanceModeLocked];
            [cameraDevice unlockForConfiguration];
        }
        NSLog(@"White balance and exposure locked!.");
    } else {
        isLocked = NO;
        [_lockLabel setTitle:@"Lock" forState:UIControlStateNormal];
        if ([cameraDevice lockForConfiguration:&error]) {
            [cameraDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
            [cameraDevice setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
            [cameraDevice unlockForConfiguration];
        }
        NSLog(@"Unlocked.");
    }
}

- (void) autoCaptureImage {
    [self captureImage:NO];
}

- (void) manualCaptureImage {
    [self captureImage:YES];
}

- (void) captureImage:(BOOL) isManual {
    if(isManual == NO && loop == NO) return;
    
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in stillImageOutput.connections) {
        
        
        
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo] ) {
                videoConnection = connection;
                
                // Set correct orientation for still image.
                if ([videoConnection isVideoOrientationSupported]) {
                    videoConnection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
                }
                
                break;
            }
        }
        if (videoConnection) { break; }
    }
    
    preAsync = [NSDate date];
    [stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error)
    {
        NSDate *loopStart = [NSDate date];
        NSTimeInterval asyncTime = [loopStart timeIntervalSinceDate:previousLoop];
        //NSLog(@"Async time: %f", asyncTime);
        
        NSTimeInterval pureAsyncTime = [loopStart timeIntervalSinceDate:preAsync];
        //NSLog(@"Pure Async time: %f", pureAsyncTime);
        
        if(pureAsyncTime > 0.4) {
            NSLog(@"----- SLOW -----");
        }
        
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        
        UIImage *image = [[UIImage alloc] initWithData:imageData];
        
        self.snapshotView.image = image;
        
        CGImageRef cgImageRef = [image CGImage];
        
        // This is needed for later processing
        [capturedImage setImage:cgImageRef];
        
        if(isManual == YES) {
            [zoomedImage setImage:cgImageRef];
        }
        
        if(touchColor != NULL && isManual == NO) {
            // Show binary blob
            
            //NSDate *p1 = [NSDate date];
            [capturedImage processImage];
            //NSDate *p2 = [NSDate date];
            
            NSInteger playerLocation = [capturedImage getPlayerLocation];
            
            if(playerLocation == 0) {
                // Player disappeared. Slowly move frequency to the middle, don't abrubtly remove frequency.
                NSInteger midFrequency = 1800;
                if(frequency > midFrequency - 200 && frequency < midFrequency + 200) {
                    frequency = midFrequency;
                } else if(frequency <= midFrequency - 200) {
                    frequency += 100;
                } else if(frequency >= midFrequency + 200) {
                    frequency -= 100;
                }
                NSLog(@"Frequency adjusting: %d", frequency);
            } else {
                
                if(playerLocation <= 45) {
                    currDirection = -1;
                } else if(playerLocation >= 55) {
                    currDirection = 1;
                } else {
                    // btw 45 and 55
                    if(currDirection == -1 && playerLocation < 50) {
                        // Keep moving
                        NSLog(@"Turning left, almost at the middle.");
                    }
                    else if(currDirection == -1 && playerLocation >= 50) {
                        // Reached middle! Now give it some room to move between 45 and 55 without turning the camera
                        currDirection = 0;
                        NSLog(@"Done turning left! Hit middle.");
                    }
                    else if(currDirection == 1 && playerLocation > 50) {
                        // Keep moving
                        NSLog(@"Turning right, almost at the middle.");
                    }
                    else if(currDirection == 1 && playerLocation <=50) {
                        // Reached middle! Now give it some room to move between 45 and 55 without turning the camera
                        currDirection = 0;
                        NSLog(@"Done turning right! Hit middle.");
                    }
                    else if(currDirection == 0) {
                        // "Calm" it down. No need to move the camera at all.
                        playerLocation = 50;
                        NSLog(@"Staying calm, object within 45 and 55.");
                    }
                }
                
                frequency = (playerLocation * 3000 / 100) + 500; // Increase the offset if the device says "moving left" when the object is in the middle.
            }
            
            [tonePlayer play:frequency];
            
            //NSTimeInterval p2Time = [p2 timeIntervalSinceDate:p1];
            
            //NSLog(@"Performance: %f", p2Time);
        }

        if(loop == YES) {
            [self performSelector:@selector(autoCaptureImage) withObject:self afterDelay:0.01];
        }
        
        previousLoop = [NSDate date];
        NSTimeInterval synchronousTime = [previousLoop timeIntervalSinceDate:loopStart];
        //NSLog(@"Processing: %f", synchronousTime);
    }];
}

- (void)singleTapGestureCaptured:(UITapGestureRecognizer *)gesture
{
    CGPoint touchPoint = [gesture locationInView:self.snapshotView];
    
    NSInteger rawWidth = [zoomedImage getWidth];
    NSInteger rawHeight = [zoomedImage getHeight];
    
    NSLog(@"Raw dimensions: (%d, %d)", rawWidth, rawHeight);
    
    NSInteger rawX = rawWidth * (touchPoint.x/self.snapshotView.frame.size.width);
    NSInteger rawY = rawHeight * (touchPoint.y/self.snapshotView.frame.size.height);
    
    touchColor = [zoomedImage getPixel:rawX y: rawY];
    
    [colorPatch1 setColor:touchColor];
    
    [capturedImage setColor1:touchColor];
    
    // Now show binary
    [capturedImage processImage];
    
    [zoomedImage mark:rawX y:rawY];
}

- (void) saveFile:(NSString *) path
{
    self.statusLabel.text = @"Saving...";
    BOOL isCompatible = UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(path);
    NSLog(@"Is compatible %hhd", isCompatible);
    UISaveVideoAtPathToSavedPhotosAlbum(path, self, @selector(onSave:didFinishSavingWithError:contextInfo:), nil);
}

- (void) onSave:(NSString *) videoPath
didFinishSavingWithError: (NSError *) error
    contextInfo: (void *) contextInfo
{
    NSLog(@"onSave to %@", videoPath);
    NSLog(@"Error: %@", error.domain);
    
    self.statusLabel.text = [NSString stringWithFormat:@"Saved!"];
    
    [self fs:videoPath];
}

- (void) fs:(NSString *) url
{
    NSError *attributesError = nil;
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:url error:&attributesError];
    
    int fileSize = [fileAttributes fileSize];
    NSLog(@"File size of %@ is %d", url, fileSize);
}


@end



@implementation ViewController (AVCaptureFileOutputRecordingDelegate)

- (void) captureOutput:(AVCaptureFileOutput *)captureOutput
didStartRecordingToOutputFileAtURL:(NSURL *)fileURL
       fromConnections:(NSArray *)connections
{
    NSLog(@"did start recording");
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSLog(@"ViewController -> Config");
    ConfigTableViewController *vc = [segue destinationViewController];
    
    [dataHolder setVideoFolderUrl:folderUrl];
    
    [vc setData:dataHolder];
}

@end
