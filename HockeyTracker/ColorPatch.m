//
//  ColorPatch.m
//  Analyzerv2
//
//  Created by Aris Samad Yahaya on 7/19/14.
//  Copyright (c) 2014 Sir Apps-a-Lot. All rights reserved.
//

#import "ColorPatch.h"

@implementation ColorPatch {
    UIImageView *imageView;
    unsigned char *rawData;
    
    NSInteger width;
    NSInteger height;
    NSInteger bitsPerComponent;
    NSUInteger bytesPerPixel;
    NSUInteger bytesPerRow;
    
    CGColorSpaceRef colorSpace;
    CGContextRef cgContextRef;
    CGImageRef cgImageRef;
}

@synthesize sampleColorImageView;

-(void) setView:(UIImageView*) incomingImageView {
    sampleColorImageView = incomingImageView;
    width = 10;
    height = 10;
    bitsPerComponent = 8;
    bytesPerPixel = 4;
    bytesPerRow = bytesPerPixel * width;
    
    rawData = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
    colorSpace = CGColorSpaceCreateDeviceRGB();
    
}



- (void) setColor:(CGFloat) red green:(CGFloat) green blue:(CGFloat) blue {
    
    int index = 0;
    for(int y=0; y<height; y++) {
        for(int x=0; x<width; x++) {
            rawData[index] = red;
            rawData[index+1] = green;
            rawData[index+2] = blue;
            rawData[index+3] = 255;
            index += 4;
        }
    }
    
    cgContextRef = CGBitmapContextCreate(rawData, width, height,
                                         bitsPerComponent, bytesPerRow, colorSpace,
                                         kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    cgImageRef = CGBitmapContextCreateImage(cgContextRef);
    
    // Now draw
    CGContextDrawImage(cgContextRef, CGRectMake(0, 0, width, height), cgImageRef);
    
    UIImage *uiImage = [[UIImage alloc] initWithCGImage:cgImageRef scale:1.0 orientation:UIImageOrientationRight];
    self.sampleColorImageView.image = uiImage;
}

@end
