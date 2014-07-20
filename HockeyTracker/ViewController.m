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
    
    [self runLoop];
}

- (IBAction)clickedStop {
    NSLog(@"Clicked stop");
    loop = NO;
    [tonePlayer stop];
}

- (IBAction)clickedCapture {
    NSLog(@"Clicked capture");
    
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
        
        NSUInteger iWidth = image.size.width;
        NSUInteger iHeight = image.size.height;
        
        self.snapshotView.image = image;
        
        CGImageRef cgImageRef = [image CGImage];
        
        [capturedImage setImage:cgImageRef];
        
        if(touchColor != NULL) {
            // Show binary blob
            [capturedImage processImage:touchColor];
        }
    }];
}

- (void)singleTapGestureCaptured:(UITapGestureRecognizer *)gesture
{
    CGPoint touchPoint=[gesture locationInView:self.snapshotView];
    
    NSInteger rawWidth = [capturedImage getWidth];
    NSInteger rawHeight = [capturedImage getHeight];
    
    NSInteger rawX = rawWidth * (touchPoint.x/self.snapshotView.frame.size.width);
    NSInteger rawY = rawHeight * (touchPoint.y/self.snapshotView.frame.size.height);
    
    touchColor = [capturedImage getPixel:rawX y:rawY];
    
    CGFloat red = [touchColor getRed];
    CGFloat green = [touchColor getGreen];
    CGFloat blue = [touchColor getBlue];
    
    [colorPatch1 setColor:red green:green blue:blue];
    
    // Now show binary
    [capturedImage processImage:touchColor];
}

- (void) runLoop {
    NSLog(@"Loop");
    
    if(loop == YES) {
        [self performSelector:@selector(runLoop) withObject:self afterDelay:1.0];
        [self clickedCapture];
        
        NSInteger playerLocation = [capturedImage getPlayerLocation];
        
        NSInteger frequency = (playerLocation * 4000 / 100) + 500;
        NSLog(@"Frequency is %d", frequency);
        
        [tonePlayer play:frequency];
    }
}
@end
