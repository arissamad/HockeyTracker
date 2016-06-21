//
//  DataHolder.m
//  HockeyTracker
//
//  Created by Aris Samad Yahaya on 9/20/14.
//  Copyright (c) 2014 Sir Apps-a-Lot. All rights reserved.
//

#import "DataHolder.h"

@implementation DataHolder {
    NSURL *folderUrl;
}

-(NSURL *) getVideoFolderUrl {
    return folderUrl;
}

-(void) setVideoFolderUrl:(NSURL *) incoming {
    folderUrl = incoming;
}

@end
