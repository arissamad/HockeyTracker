//
//  TonePlayer.h
//  HockeyTracker
//
//  Created by Aris Samad Yahaya on 7/20/14.
//  Copyright (c) 2014 Sir Apps-a-Lot. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioUnit/AudioUnit.h>
#import <AudioToolbox/AudioToolbox.h>

@interface TonePlayer : NSObject

@property double sampleRate;
@property double frequency;
@property double theta;

- (void) setup;
- (void) play:(NSInteger) freq;
- (void) stop;
@end
