//
//  FileCell.h
//  HockeyTracker
//
//  Created by Aris Samad Yahaya on 9/7/14.
//  Copyright (c) 2014 Sir Apps-a-Lot. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FileCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UIImageView *image;
@property (strong, nonatomic) IBOutlet UILabel *fileName;
@property (strong, nonatomic) IBOutlet UILabel *date;
@property (strong, nonatomic) IBOutlet UILabel *numberLabel;
@end
