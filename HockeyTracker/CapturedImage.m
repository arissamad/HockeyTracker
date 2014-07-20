//
//  CapturedImage.m
//  Analyzerv2
//
//  Created by Aris Samad Yahaya on 7/19/14.
//  Copyright (c) 2014 Sir Apps-a-Lot. All rights reserved.
//

#import "CapturedImage.h"
#import "JAProcessor.h"

@implementation CapturedImage {
    unsigned char *originalRawData;
    
    NSInteger width;
    NSInteger height;
    
    NSUInteger arrayLength;
    NSUInteger simpleLength;
    
    NSInteger bitsPerComponent;
    NSUInteger bytesPerPixel;
    NSUInteger bytesPerRow;
    
    CGColorSpaceRef colorSpace;
    CGColorSpaceRef grayColorSpace;
    
    CGContextRef cgContextRef;
    CGImageRef cgImageRef;
    
    unsigned char *binaryRawData;
    
    UIImageView *hsbImageView;
    
    BOOL isFirstTime;
}

-(void) setup:(UIImageView *) incomingHsbImageView {
    bitsPerComponent = 8;
    bytesPerPixel = 4;
    
    colorSpace = CGColorSpaceCreateDeviceRGB();
    grayColorSpace = CGColorSpaceCreateDeviceGray();
    
    hsbImageView = incomingHsbImageView;
    
    isFirstTime = true;
}

-(void) setImage:(CGImageRef) incomingCgImageRef {
    cgImageRef = incomingCgImageRef;
    
    if(isFirstTime == true) {
        width = CGImageGetWidth(cgImageRef);
        height = CGImageGetHeight(cgImageRef);
        
        arrayLength = height * width * 4;
        simpleLength = height * width;
        
        binaryRawData = (unsigned char*) calloc(simpleLength, sizeof(unsigned char));
        
        bytesPerRow = bytesPerPixel * width;
        
        originalRawData = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
        
        isFirstTime = false;
    }
    
    NSLog(@"CapturedImage width:%d height:%d", width, height);
    
    CGContextRef context = CGBitmapContextCreate(originalRawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    // Now draw into originalRawData
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImageRef);
}

-(NSInteger) getWidth {
    return width;
}

-(NSInteger) getHeight {
    return height;
}

-(SColor *) getPixel:(NSInteger) x y:(NSInteger)y {
    int byteIndex = (bytesPerRow * y) + (x * bytesPerPixel);
    
    CGFloat red   = originalRawData[byteIndex]; // A number between 0 and 255.
    CGFloat green = originalRawData[byteIndex + 1];
    CGFloat blue  = originalRawData[byteIndex + 2];
    
    NSLog(@"Color is %f %f %f", red, green, blue);
    
    SColor *color = [SColor new];
    [color setRed:red green:green blue:blue];
    
    return color;
}

// This does the conversion to HSB and finding the blog
-(void) processImage:(SColor *) theColor {
    
    IOSByteArray *byteArray = [IOSByteArray arrayWithBytes:(char *)originalRawData count:arrayLength];
    
    JAProcessor *jaProcessor = [JAProcessor new];
    [jaProcessor processRawDataWithByteArray:byteArray withInt:width withInt:height
                                    withByte:theColor.getRed withByte:theColor.getGreen withByte:theColor.getBlue];
    
    // Get the binary data, and convert into IOS world
    IOSByteArray *binaryDataArray = [jaProcessor getBinaryData];
    
    [binaryDataArray getBytes:(char *)binaryRawData length: simpleLength];
    
    int count0 = 0;
    int count1 = 0;
    
    for(int i=0; i<simpleLength; i++) {
        if(binaryRawData[i] == 0) {
            count0++;
        } else {
            binaryRawData[i] = 255;
            count1++;
        }
    }
    
    NSLog(@"Binary count (0, 1): (%d, %d)", count0, count1);
    
    CGContextRef binaryCgContextRef = CGBitmapContextCreate(binaryRawData, width, height, bitsPerComponent, width, grayColorSpace, nil);
    CGImageRef binaryCgImage = CGBitmapContextCreateImage(binaryCgContextRef);
    
    UIImage *hsbImage = [[UIImage alloc] initWithCGImage:binaryCgImage /*scale:1.0 orientation:UIImageOrientationRight*/];
    hsbImageView.image = hsbImage;
    
    CGContextRelease(binaryCgContextRef);
}

@end
