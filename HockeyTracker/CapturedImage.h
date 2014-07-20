//
//  CapturedImage.h
//  Analyzerv2
//
//  Created by Aris Samad Yahaya on 7/19/14.
//  Copyright (c) 2014 Sir Apps-a-Lot. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SColor.h"

@interface CapturedImage : NSObject

-(void) setup:(UIImageView *) incomingHsbImageView;
-(void) setImage:(CGImageRef) cgImageRef;
-(SColor *) getPixel:(NSInteger) x y:(NSInteger)y;
-(void) processImage:(SColor *) theColor;

-(NSInteger) getWidth;
-(NSInteger) getHeight;
-(NSInteger) getPlayerLocation;

@end