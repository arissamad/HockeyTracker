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
    JAProcessor *jaProcessor;
    
    unsigned char *originalRawData;
    unsigned char *binaryRawData;
    
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
    
    UIImageView *hsbImageView;
    
    BOOL isFirstTime;
    int resizeFactor;
}

-(void) setup:(UIImageView *) incomingHsbImageView {
    
    resizeFactor = 4;
    
    bitsPerComponent = 8;
    bytesPerPixel = 4;
    
    colorSpace = CGColorSpaceCreateDeviceRGB();
    grayColorSpace = CGColorSpaceCreateDeviceGray();
    
    hsbImageView = incomingHsbImageView;
    
    isFirstTime = true;
    
    jaProcessor = [JAProcessor new];
}

-(void) setImage:(CGImageRef) incomingCgImageRef {
    cgImageRef = incomingCgImageRef;
    
    if(isFirstTime == true) {
        width = CGImageGetWidth(cgImageRef);
        height = CGImageGetHeight(cgImageRef);

        NSLog(@"Original dimensions: %d, %d", width, height);
        
        width = width / resizeFactor;
        height = height / resizeFactor;
        
        NSLog(@"Resized dimensions: %d, %d", width, height);
        
        arrayLength = height * width * 4;
        simpleLength = height * width;
        
        binaryRawData = (unsigned char*) calloc(simpleLength, sizeof(unsigned char));
        
        bytesPerRow = bytesPerPixel * width;
        //bytesPerRow = CGImageGetBytesPerRow(cgImageRef);
        
        originalRawData = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
        
        isFirstTime = false;
    }
    
    //NSLog(@"CapturedImage width:%d height:%d", width, height);
    
    CGContextRef context = CGBitmapContextCreate(originalRawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    // Now draw into originalRawData
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImageRef);
    CGContextRelease(context);
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
    
    SColor *color = [SColor new];
    [color setRed:red green:green blue:blue];
    
    return color;
}

-(void) setColor1:(SColor *) color {
    [jaProcessor setBandWithByte:color.getRed withByte:color.getGreen withByte:color.getBlue];
}

// This does the conversion to HSB and finding the blob
-(void) processImage {
    
    IOSByteArray *byteArray = [IOSByteArray arrayWithBytes:(char *)originalRawData count:arrayLength];
    
    [jaProcessor processRawDataWithByteArray:byteArray withInt:width withInt:height];

    NSLog(@"Test 2");
    
    // Get the binary data, and convert into IOS world
    IOSByteArray *binaryDataArray = [jaProcessor getBinaryData];
    
    [binaryDataArray getBytes:(char *)binaryRawData length: simpleLength];
    
    CGContextRef binaryCgContextRef = CGBitmapContextCreate(binaryRawData, width, height, bitsPerComponent, width, grayColorSpace, nil);
    CGImageRef binaryCgImage = CGBitmapContextCreateImage(binaryCgContextRef);
    
    UIImage *hsbImage = [[UIImage alloc] initWithCGImage:binaryCgImage];
    hsbImageView.image = hsbImage;
     
     
    CGContextRelease(binaryCgContextRef);
    CGImageRelease(binaryCgImage);
}

-(NSInteger) getPlayerLocation {
    return [jaProcessor getPlayerLocation];
}


-(void) releaseForLater {
}

@end
