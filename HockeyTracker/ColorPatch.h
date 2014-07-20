//
//  ColorPatch.h
//  Analyzerv2
//
//  Created by Aris Samad Yahaya on 7/19/14.
//  Copyright (c) 2014 Sir Apps-a-Lot. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ColorPatch : NSObject {
    UIImageView *sampleColorImageView;
}

@property (nonatomic, retain) UIImageView *sampleColorImageView;

-(void) setView:(UIImageView*) incomingImageView;
-(void) setColor:(CGFloat) red green:(CGFloat) green blue:(CGFloat) blue;

@end
