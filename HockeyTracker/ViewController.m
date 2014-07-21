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
    
    NSString *videoFilePath;
    
    CGColorSpaceRef rgbColorSpace;
    
    CapturedImage *capturedImage;
    ColorPatch *colorPatch1;
    ColorPatch *colorPatch2;
    
    SColor *touchColor;
    
    TonePlayer *tonePlayer;
    
    BOOL loop;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    tonePlayer = [TonePlayer new];
    [tonePlayer setup];
    
    rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    colorPatch1 = [ColorPatch new];
    [colorPatch1 setView:self.color1View];
    
    capturedImage = [CapturedImage new];
    [capturedImage setup:self.binaryView];
    
    [self.snapshotView setUserInteractionEnabled:YES];
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapGestureCaptured:)];
    //Default value for cancelsTouchesInView is YES, which will prevent buttons to be clicked
    //singleTap.cancelsTouchesInView = NO;
    [self.snapshotView addGestureRecognizer:singleTap];
    
    
    captureSession = [AVCaptureSession new];
    captureSession.sessionPreset = AVCaptureSessionPresetMedium;
    
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
    NSURL *url = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd_HH-mm-ss"];
    
    NSString *dateStr = [dateFormatter stringFromDate:[NSDate date]];
    NSString *nameStr = [NSString stringWithFormat:@"mymovie-%@.mov", dateStr];
    
    
    url = [url URLByAppendingPathComponent:nameStr];
    
    NSLog(@"New video path is %@", [url path]);
    
    videoFilePath = url.path;
    
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
    
    NSLog(@"Initialized");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)clickedStart {
    
    NSLog(@"Clicked start");
    
    loop = YES;
    [captureOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:videoFilePath] recordingDelegate:self];
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
}

- (IBAction)clickedCapture {
    [self manualCaptureImage];
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
    
    [stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error)
    {
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        
        UIImage *image = [[UIImage alloc] initWithData:imageData];
        
        self.snapshotView.image = image;
        
        CGImageRef cgImageRef = [image CGImage];
        
        [capturedImage setImage:cgImageRef];
        
        if(touchColor != NULL) {
            // Show binary blob
            
            //NSDate *p1 = [NSDate date];
            [capturedImage processImage];
            //NSDate *p2 = [NSDate date];
            
            NSInteger playerLocation = [capturedImage getPlayerLocation];
            
            NSInteger frequency = (playerLocation * 3000 / 100) + 300;
            
            if(playerLocation == 0) frequency = 0;
            
            //NSLog(@"Frequency is %d", frequency);
            
            [tonePlayer play:frequency];
            
            //NSTimeInterval p2Time = [p2 timeIntervalSinceDate:p1];
            
            //NSLog(@"Performance: %f", p2Time);
        }

        if(loop == YES) {
            [self performSelector:@selector(autoCaptureImage) withObject:self afterDelay:0.1];
        }
    }];
}

- (void)singleTapGestureCaptured:(UITapGestureRecognizer *)gesture
{
    CGPoint touchPoint = [gesture locationInView:self.snapshotView];
    
    NSInteger rawWidth = [capturedImage getWidth];
    NSInteger rawHeight = [capturedImage getHeight];
    
    NSLog(@"Raw dimensions: (%d, %d)", rawWidth, rawHeight);
    
    NSInteger rawX = rawWidth * (touchPoint.x/self.snapshotView.frame.size.width);
    NSInteger rawY = rawHeight * (touchPoint.y/self.snapshotView.frame.size.height);
    
    touchColor = [capturedImage getPixel:rawX y:rawY];
    
    [colorPatch1 setColor:touchColor];
    
    [capturedImage setColor1:touchColor];
    
    // Now show binary
    [capturedImage processImage];
}

- (void) saveFile:(NSString *) path
{
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

@end
