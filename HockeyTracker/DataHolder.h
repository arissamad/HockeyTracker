//
//  DataHolder.h
//  HockeyTracker
//
//  Created by Aris Samad Yahaya on 9/20/14.
//  Copyright (c) 2014 Sir Apps-a-Lot. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DataHolder : NSObject
-(NSURL *) getVideoFolderUrl;
-(void) setVideoFolderUrl:(NSURL *) incoming;
@end
