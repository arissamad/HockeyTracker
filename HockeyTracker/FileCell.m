//
//  FileCell.m
//  HockeyTracker
//
//  Created by Aris Samad Yahaya on 9/7/14.
//  Copyright (c) 2014 Sir Apps-a-Lot. All rights reserved.
//

#import "FileCell.h"

@implementation FileCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
