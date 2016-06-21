//
//  FileListViewController.m
//  HockeyTracker
//
//  Created by Aris Samad Yahaya on 9/7/14.
//  Copyright (c) 2014 Sir Apps-a-Lot. All rights reserved.
//

#import "FileListViewController.h"

@interface FileListViewController ()

@end

@implementation FileListViewController {
    NSArray *fileNames;
    NSMutableArray *files;
    DataHolder *dataHolder;
    NSFileManager *fileManager;
    NSDateFormatter *dateFormatter;
    NSMutableDictionary *cachedImages;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"FileList viewDidLost");
    
    fileNames = @[@"File 1", @"File 2"];
    
    
    NSURL *folderUrl = [dataHolder getVideoFolderUrl];
    NSLog(@"Folder URL is: %@", folderUrl);
    
    cachedImages = [[NSMutableDictionary alloc] init];
    
    // Retrieve list of files
    NSError *error = nil;
    NSArray *properties = [NSArray arrayWithObjects: NSURLLocalizedNameKey,
                           NSURLCreationDateKey, NSURLLocalizedTypeDescriptionKey, nil];
    
    fileManager = [NSFileManager defaultManager];
    
    NSArray *staticFiles = [fileManager
                      contentsOfDirectoryAtURL:folderUrl
                      includingPropertiesForKeys:properties
                      options:(NSDirectoryEnumerationSkipsHiddenFiles)
                      error:&error];
    
    files = [staticFiles mutableCopy];
    

    dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return files.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FileCell *cell = [tableView dequeueReusableCellWithIdentifier:@"fileCell" forIndexPath:indexPath];
    
    long row = [indexPath row];
    
    NSURL *file = files[row];
    NSString *aPath = [file path];
    
    NSString *name = [fileManager displayNameAtPath:aPath];

    cell.fileName.text = [NSString stringWithFormat:@"%@", name];
    
    NSDictionary* attrs = [fileManager attributesOfItemAtPath:aPath error:nil];
    
    NSDate *creationDate = [attrs fileCreationDate];
    
    NSString *dateText = [dateFormatter stringFromDate:creationDate];

    cell.date.text = dateText;
    
    int rowNumber = row + 1;
    NSString *numberText = [NSString stringWithFormat:@"%d", rowNumber];
    
    cell.numberLabel.text = numberText;
    
    NSString *identifier = [NSString stringWithFormat:@"Cell%d", indexPath.row];
    
    NSLog(@"Identifier: %@", identifier);
    
    cell.image.image = nil;
    
    if([cachedImages objectForKey:identifier] != nil) {
        cell.image.image = [cachedImages valueForKey:identifier];
        NSLog(@"Using cache");
    } else {
        
        char const * s = [identifier  UTF8String];
        dispatch_queue_t queue = dispatch_queue_create(s, 0);

        dispatch_async(queue, ^{
            // Run this NOT on the main thread
//          UIImage *thumbnail = [self getThumbNail:aPath];
            UIImage *thumbnail = [self getThumbNail2:file];

            dispatch_async(dispatch_get_main_queue(), ^{
                // Now run on the main thread again
                
                if ([tableView indexPathForCell:cell].row == indexPath.row) {
                    
                    NSLog(@"Setting cache on Identifier: %@", identifier);
                    [cachedImages setValue:thumbnail forKey:identifier];
                    cell.image.image = thumbnail;
                }
            });//end
        });//end
        
        /*
        [cachedImages setValue:thumbnail forKey:identifier];
        
        cell.image.image = thumbnail;*/
        NSLog(@"tableView for %ld", row);
    }
    
    return cell;
}

-(UIImage *)getThumbNail:(NSString*)stringPath
{
    //stringPath is a path of stored video file from document directory
    NSURL *videoURL = [NSURL fileURLWithPath:stringPath];
    
    MPMoviePlayerController *player = [[MPMoviePlayerController alloc] initWithContentURL:videoURL];
    
    UIImage *thumbnail = [player thumbnailImageAtTime:1.0 timeOption:MPMovieTimeOptionNearestKeyFrame];
    
    //Player autoplays audio on init
    [player stop];
    
    return thumbnail;
}

-(UIImage *)getThumbNail2:(NSURL *) url
{
    AVAsset *asset = [AVAsset assetWithURL:url];
    
    //  Get thumbnail at the very start of the video
    CMTime thumbnailTime = [asset duration];
    thumbnailTime.value = 0;
    
    //  Get image from the video at the given time
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:thumbnailTime actualTime:NULL error:NULL];
    UIImage *thumbnail = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    return thumbnail;
}



// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        long row = indexPath.row;
        NSURL* file = files[row];
        NSString* path = [file path];
        
        NSError *error;
        BOOL success = [fileManager removeItemAtPath:path error:&error];
        if (success) {
            NSLog(@"Successfully deleted.");
            
            [files removeObjectAtIndex:row];
            
            // Delete the row from the data source
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        } else {
            NSLog(@"Did not successfully delete.");
        }
        
    }
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


-(void) setData:(DataHolder*) incoming {
    dataHolder = incoming;
}

@end
