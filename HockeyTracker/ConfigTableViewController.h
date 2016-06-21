//
//  ConfigTableViewController.h
//  HockeyTracker
//
//  Created by Aris Samad Yahaya on 9/7/14.
//  Copyright (c) 2014 Sir Apps-a-Lot. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FileListViewController.h"

#import "DataHolder.h"
@class DataHolder;

@interface ConfigTableViewController : UITableViewController

-(void) setData:(DataHolder*) incoming;

@end