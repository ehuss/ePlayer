//
//  Entry.m
//  ePlayer
//
//  Created by Eric Huss on 4/10/13.
//  Copyright (c) 2013 Eric Huss. All rights reserved.
//

#import "Entry.h"
#import "Folder.h"


@implementation Entry

@dynamic addDate;
@dynamic name;
@dynamic playDate;
@dynamic releaseDate;
@dynamic playCount;
@dynamic parents;

- (void)propagatePlayCount:(NSUInteger)count
{
    int newCount = count+[self.playCount integerValue];
    self.playCount = @(newCount);
    for (Entry *folder in self.parents) {
        [folder propagatePlayCount:count];
    }
}

- (void)propagatePlayDate:(NSDate *)date;
{
    NSDate *newDate = [date laterDate:self.playDate];
    self.playDate = newDate;
    for (Entry *folder in self.parents) {
        [folder propagatePlayDate:newDate];
    }
}

- (void)propagateAddDate:(NSDate *)date;
{
    NSDate *newDate = [date laterDate:self.addDate];
    self.addDate = newDate;
    for (Entry *folder in self.parents) {
        [folder propagateAddDate:newDate];
    }
}

- (void)propagateReleaseDate:(NSDate *)date;
{
    NSDate *newDate = [date laterDate:self.releaseDate];
    self.releaseDate = newDate;
    for (Entry *folder in self.parents) {
        [folder propagateReleaseDate:newDate];
    }
}


@end
