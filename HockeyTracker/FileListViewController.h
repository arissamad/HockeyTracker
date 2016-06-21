//
//  FileListViewController.h
//  HockeyTracker
//
//  Created by Aris Samad Yahaya on 9/7/14.
//  Copyright (c) 2014 Sir Apps-a-Lot. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <AVFoundation/AVAsset.h>

#import "FileCell.h"

#import "DataHolder.h"

@interface FileListViewController : UITableViewController
-(void) setData:(DataHolder*) incoming;
@end
