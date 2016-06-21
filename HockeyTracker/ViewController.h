//
//  ViewController.h
//  HockeyTracker
//
//  Created by Aris Samad Yahaya on 7/19/14.
//  Copyright (c) 2014 Sir Apps-a-Lot. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <ImageIO/CGImageProperties.h>
#import "JAProcessor.h"

#import "ColorPatch.h"
#import "CapturedImage.h"
#import "ZoomedImage.h"
#import "SColor.h"
#import "TonePlayer.h"

#import "ConfigTableViewController.h"

@interface ViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIView *mainVideoView;
@property (strong, nonatomic) IBOutlet UIImageView *snapshotView;
@property (strong, nonatomic) IBOutlet UIImageView *binaryView;

@property (strong, nonatomic) IBOutlet UIImageView *color1View;
@property (strong, nonatomic) IBOutlet UIImageView *color2View;
@property (strong, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) IBOutlet UIButton *lockLabel;


- (IBAction)clickedStart;
- (IBAction)clickedStop;
- (IBAction)clickedCapture;
- (IBAction)clickedLock;

@end
