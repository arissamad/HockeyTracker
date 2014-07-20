//
//  Color.h
//  Analyzerv2
//
//  Created by Aris Samad Yahaya on 7/19/14.
//  Copyright (c) 2014 Sir Apps-a-Lot. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SColor : NSObject

-(void) setRed:(CGFloat) incomingRed green:(CGFloat) incomingGreen blue:(CGFloat) incomingBlue;

-(CGFloat) getRed;
-(CGFloat) getGreen;
-(CGFloat) getBlue;

@end
