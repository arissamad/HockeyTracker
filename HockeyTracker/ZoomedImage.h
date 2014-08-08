//
//  ZoomedImage.h
//  HockeyTracker
//
//  Created by Aris Samad Yahaya on 8/7/14.
//  Copyright (c) 2014 Sir Apps-a-Lot. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SColor.h"

@interface ZoomedImage : NSObject

-(void) setup:(UIImageView *) incomingImageView;
-(void) setImage:(CGImageRef) cgImageRef;

-(NSInteger) getWidth;
-(NSInteger) getHeight;

-(SColor *) getPixel:(NSInteger) x y:(NSInteger)y;
-(void) mark:(NSInteger) startX y:(NSInteger)startY;

@end
