//
//  ZoomedImage.m
//  HockeyTracker
//
//  Created by Aris Samad Yahaya on 8/7/14.
//  Copyright (c) 2014 Sir Apps-a-Lot. All rights reserved.
//

#import "ZoomedImage.h"

@implementation ZoomedImage {
    unsigned char *originalRawData;
    unsigned char *zoomedInData;
    unsigned char *markedData;
    
    NSInteger width;
    NSInteger height;
    
    NSInteger zoomedWidth;
    NSInteger zoomedHeight;
    
    NSUInteger arrayLength;
    NSUInteger simpleLength;
    
    NSInteger bitsPerComponent;
    NSUInteger bytesPerPixel;
    NSUInteger bytesPerRow;
    NSUInteger zoomedBytesPerRow;
    
    CGColorSpaceRef colorSpace;
    
    CGContextRef cgContextRef;
    CGImageRef cgImageRef;
    
    UIImageView *imageView;
    
    BOOL isFirstTime;
    int resizeFactor;
}

-(void) setup:(UIImageView *) incomingImageView {
    resizeFactor = 4;
    
    bitsPerComponent = 8;
    bytesPerPixel = 4;
    
    colorSpace = CGColorSpaceCreateDeviceRGB();
    
    imageView = incomingImageView;
    
    isFirstTime = true;
}

-(void) setImage:(CGImageRef) incomingCgImageRef {
    cgImageRef = incomingCgImageRef;
    
    if(isFirstTime == true) {
        width = CGImageGetWidth(cgImageRef);
        height = CGImageGetHeight(cgImageRef);
        
        NSLog(@"Zoomed Image: Original dimensions: %d, %d", width, height);
        
        zoomedWidth = width/resizeFactor;
        zoomedHeight = height/resizeFactor;
        
        NSLog(@"Zoomed Image: Resized dimensions: %d, %d", zoomedWidth, zoomedHeight);
        
        arrayLength = height * width * 4;
        simpleLength = height * width;
        
        bytesPerRow = bytesPerPixel * width;
        zoomedBytesPerRow = bytesPerPixel * zoomedWidth;
        
        originalRawData = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
        zoomedInData = (unsigned char*) calloc(zoomedHeight * zoomedWidth * 4, sizeof(unsigned char));
        markedData = (unsigned char*) calloc(zoomedHeight * zoomedWidth * 4, sizeof(unsigned char));
        
        isFirstTime = false;
    }
    
    //NSLog(@"CapturedImage width:%d height:%d", width, height);
    
    // First, draw image onto originalRawData
    CGContextRef context = CGBitmapContextCreate(originalRawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImageRef);
    CGContextRelease(context);
    
    // Resize
    for(int y=0; y<zoomedHeight; y++) {
        for(int x=0; x<zoomedWidth; x++) {
            int zoomIndex = ((x * bytesPerPixel) + (y * zoomedBytesPerRow));
            int originalIndex = ((x * bytesPerPixel) + (y * bytesPerRow));
            
            zoomedInData[zoomIndex] = originalRawData[originalIndex];
            zoomedInData[zoomIndex+1] = originalRawData[originalIndex+1];
            zoomedInData[zoomIndex+2] = originalRawData[originalIndex+2];
            zoomedInData[zoomIndex+3] = 255;
        }
    }

    // Now, draw image held in originalRawData onto imageView
    CGContextRef targetCgContextRef = CGBitmapContextCreate(zoomedInData, zoomedWidth, zoomedHeight,
                                                            bitsPerComponent, zoomedBytesPerRow, colorSpace,
                                                            kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGImageRef targetCgImage = CGBitmapContextCreateImage(targetCgContextRef);
    
    UIImage *targetImage = [[UIImage alloc] initWithCGImage:targetCgImage];
    imageView.image = targetImage;

    CGContextRelease(targetCgContextRef);
    CGImageRelease(targetCgImage);
}

-(NSInteger) getWidth {
    return zoomedWidth;
}

-(NSInteger) getHeight {
    return zoomedHeight;
}

-(SColor *) getPixel:(NSInteger) x y:(NSInteger)y {
    int byteIndex = (zoomedBytesPerRow * y) + (x * bytesPerPixel);
    
    CGFloat red   = zoomedInData[byteIndex]; // A number between 0 and 255.
    CGFloat green = zoomedInData[byteIndex + 1];
    CGFloat blue  = zoomedInData[byteIndex + 2];
    
    SColor *color = [SColor new];
    [color setRed:red green:green blue:blue];
    
    return color;
}

-(void) mark:(NSInteger) startX y:(NSInteger)startY {
    int numPixels = 4 * zoomedWidth * zoomedHeight;
    for(int i=0; i<numPixels; i++) {
        markedData[i] = zoomedInData[i];
    }
    
    for(int x=startX-20; x<startX + 20; x++) {
        if(x < 0) continue;
        if(x >= zoomedWidth) continue;
        
        int index = ((x * bytesPerPixel) + (startY * zoomedBytesPerRow));
            
        markedData[index] = 255;
        markedData[index+1] = 0;
        markedData[index+2] = 0;
        markedData[index+3] = 255;
    }
    
    for(int y=startY-20; y<startY + 20; y++) {
        if(y < 0) continue;
        if(y >= zoomedHeight) continue;
        
        int index = ((startX * bytesPerPixel) + (y * zoomedBytesPerRow));

        markedData[index] = 255;
        markedData[index+1] = 0;
        markedData[index+2] = 0;
        markedData[index+3] = 255;
    }
    
    // Now, draw image held in markedData onto imageView
    CGContextRef targetCgContextRef = CGBitmapContextCreate(markedData, zoomedWidth, zoomedHeight,
                                                            bitsPerComponent, zoomedBytesPerRow, colorSpace,
                                                            kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGImageRef targetCgImage = CGBitmapContextCreateImage(targetCgContextRef);
    
    UIImage *targetImage = [[UIImage alloc] initWithCGImage:targetCgImage];
    imageView.image = targetImage;
    
    CGContextRelease(targetCgContextRef);
    CGImageRelease(targetCgImage);
}

@end
