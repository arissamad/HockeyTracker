//
//  Color.m
//  Analyzerv2
//
//  Created by Aris Samad Yahaya on 7/19/14.
//  Copyright (c) 2014 Sir Apps-a-Lot. All rights reserved.
//

#import "SColor.h"

@implementation SColor {
    CGFloat red;
    CGFloat green;
    CGFloat blue;
}

-(void) setRed:(CGFloat) incomingRed green:(CGFloat) incomingGreen blue:(CGFloat) incomingBlue {
    red = incomingRed;
    green = incomingGreen;
    blue = incomingBlue;
}

-(CGFloat) getRed {
    return red;
}

-(CGFloat) getGreen {
    return green;
}

-(CGFloat) getBlue {
    return blue;
}

@end